package com.experian.ais.vhr.reports.service;

import com.lowagie.text.pdf.PdfReader;
import com.lowagie.text.pdf.PdfStamper;
import com.experian.ais.vhr.common.VHRReportUtils;
import com.experian.ais.vhr.common.VHRServiceConstants;
import com.experian.ais.vhr.exception.WindowStickerException;
import com.experian.ais.vhr.reports.config.MarketCheckConfigProperties;
import com.experian.ais.vhr.reports.config.ToyotaApiConfigProperties;
import com.google.zxing.WriterException;
import com.experian.ais.vhr.reports.config.TokenConfigProperties;
import com.experian.ais.vhr.reports.service.token.TokenService;
import com.experian.ais.vhr.reports.service.token.VerificationResult;
import com.experian.ais.vhr.reports.utils.PathUtil;
import com.experian.ais.vhr.reports.utils.ReportServerConstants;
import com.experian.ais.vhr.reports.utils.ReportUtil;
import com.experian.ais.vhr.rest.dto.TokenResponseDTO;
import com.experian.ais.vhr.rest.dto.VinDecodeDTO;
import com.experian.ais.vhr.rest.dto.VinDecodeRawDTO;
import jakarta.servlet.http.HttpServletRequest;
import org.apache.hc.client5.http.auth.StandardAuthScheme;
import org.owasp.encoder.Encode;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.InputStreamResource;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.ui.Model;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.util.StringUtils;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.HttpServerErrorException;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponents;
import org.springframework.web.util.UriComponentsBuilder;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.net.URI;
import java.text.NumberFormat;
import java.util.*;

import static com.experian.ais.vhr.common.VHRServiceConstants.*;

/**
 * Service to verify tokens and generate window stickers.
 */
@Service
public class WindowStickerVerifyTokenService {

    private static final Logger LOGGER = LoggerFactory.getLogger(WindowStickerVerifyTokenService.class.getName());

    @Autowired
    private TokenConfigProperties configProperties;

    @Autowired
    private TokenService tokenService;

    @Autowired
    private ReportUtil reportUtil;

    @Autowired
    @Qualifier("standardRestTemplate")
    private RestTemplate restTemplate;

    @Autowired
    @Qualifier("marketCheckRestTemplate")
    private RestTemplate marketCheckRestTemplate;

    @Value("${token.fordWindowStickerTestEnv}")
    private boolean isFordWindowStickerTestEnv;

    final static String FORD_TEST_VIN = "1FTEX1EP4HF000026";

    @Autowired
    private MarketCheckConfigProperties marketCheckConfigProperties;

    @Autowired
    private ReportRenderService reportRenderService;

    @Autowired
    private PathUtil pathUtil;

    @Autowired
    private BarcodeService barcodeService;

    @Autowired
    private ToyotaAuthService toyotaAuthService;

    @Autowired
    private ToyotaApiConfigProperties toyotaApiConfigProperties;

    @Autowired
    private GA4AnalyticsService ga4AnalyticsService;

    /**
     * Generates a window sticker after verifying the token.
     *
     * @param token     the verification token
     * @param purpose   the purpose of verification
     * @param singleUse single use token
     * @return ResponseEntity with the window sticker or error message
     */
    public ResponseEntity<?> generateWindowSticker(String token, String purpose, boolean singleUse,
            String requestedFilename, Model model, HttpServletRequest request) throws WindowStickerException {
        VerificationResult vr = tokenService.verifyToken(token, purpose, singleUse);

        if (!vr.ok()) {
            LOGGER.info("Token verification failed: {}", vr.message());
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .cacheControl(CacheControl.noStore())
                    .header(REFERRER_POLICY_HEADER, REFERRER_POLICY_VALUE)
                    .body("This window sticker link has expired. Please re-run the AutoCheck Full Report to generate a new window sticker.");
        }

        String make = vr.claims().get(MAKE);
        String clientType = vr.claims().getOrDefault("clientType", "");
        boolean isFastlink = "y".equals(vr.claims().getOrDefault("fastlink", ""));
        String correlationId = "srv_" + System.currentTimeMillis();
        String modelYear = vr.claims().get(MODEL_YEAR);
        String vin = vr.claims().get(VIN);
        String documentTitle = resolveDocumentTitle(requestedFilename, vin);
        String stickerType = VHRReportUtils.getVehicleStickerType(make, modelYear);
        String flowType = (stickerType.equalsIgnoreCase(FORD_WINDOW_STICKER)) ? "modal" : "new_tab";
        ResponseEntity<?> response;

        if (stickerType.equalsIgnoreCase(FORD_WINDOW_STICKER)) {
            LOGGER.info("Generating Ford VIN sticker for VIN: {}", Encode.forJava(vr.claims().get(VIN)));
            response = getFordVinSticker(vr, documentTitle);
        } else if (stickerType.equalsIgnoreCase(TOYOTA_WINDOW_STICKER)) {
            LOGGER.info("Generating Toyota VIN sticker for VIN: {}", Encode.forJava(vr.claims().get(VIN)));
            response = getToyotaVinSticker(vr, documentTitle);
        } else {
            // Market check label generation for vehicles which are not eligible for window
            // sticker.
            LOGGER.info("Generating Non-Ford VIN sticker for VIN: {}", Encode.forJava(vr.claims().get(VIN)));
            response = getNonFordVinSticker(vr, model, request, documentTitle);
        }

        // Fire GA4 analytics event ONLY for new-tab flows (non-Ford).
        // Modal flows (Ford family) are already tracked by the frontend via
        // dataLayer.push.
        if (!stickerType.equalsIgnoreCase(FORD_WINDOW_STICKER)) {
            trackWindowStickerOutcome(clientType, isFastlink, vin, make, flowType, correlationId, response);
        }

        return response;
    }

    /**
     * Handles non-Ford VIN sticker requests. The data comes from the Marketcheck
     * external API
     *
     * @param vr the verification result
     * @return ResponseEntity with appropriate response
     */
    private ResponseEntity<?> getNonFordVinSticker(VerificationResult vr, Model model, HttpServletRequest request,
            String documentTitle) throws WindowStickerException {
        String vin = vr.claims().get(VIN);
        LOGGER.debug("getNonFordVinSticker - delegating to getVehicleSpecsByVin for VIN: {}", Encode.forJava(vin));
        ResponseEntity<?> response = getVehicleSpecsByVin(vin, true);
        VinDecodeDTO vinDecode = (VinDecodeDTO) response.getBody();

        String serverUrl = pathUtil.getServerUrl(request, ReportServerConstants.PDF);
        model.addAttribute("serverPath", serverUrl);
        model.addAttribute("vinDecode", vinDecode);

        // Generate barcode as Base64 data URI for the VIN
        try {
            String barcodeDataUri = barcodeService.generateBarcodeAsDataUri(vin);
            model.addAttribute("barcodeDataUri", barcodeDataUri);
            LOGGER.debug("Barcode data URI generated for VIN: {}", Encode.forJava(vin));
        } catch (IOException | WriterException e) {
            LOGGER.error("Failed to generate barcode for VIN: {}, error: {}", Encode.forJava(vin), e.getMessage());
            // Continue without barcode — the template handles the null case gracefully
        }

        String htmlContent = reportRenderService.renderAsString(request, model, "marketcheckWindowSticker");

        ByteArrayOutputStream pdfOut;
        try {
            pdfOut = PdfGenerationService.renderLandscapeReport(serverUrl, htmlContent);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }

        byte[] pdfBytes = applyWindowStickerPdfTitle(pdfOut.toByteArray(), documentTitle);
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_PDF);
        headers.setContentDisposition(ContentDisposition.inline().filename(documentTitle + ".pdf").build());

        return ResponseEntity.ok()
                .headers(headers)
                .contentLength(pdfBytes.length)
                .body(new InputStreamResource(new ByteArrayInputStream(pdfBytes)));

    }

    /**
     * Gets vehicle specification by VIN from MarketCheck API
     *
     * @param vin            Vehicle Identification Number
     * @param includeGeneric Whether to include generic information
     * @return ResponseEntity containing vehicle specifications or error details
     */
    public ResponseEntity<?> getVehicleSpecsByVin(String vin, boolean includeGeneric) throws WindowStickerException {
        ResponseEntity<?> marketCheckResponse = getMarketCheckVinDecodeWithOptions(vin, includeGeneric, false, false);

        if (!marketCheckResponse.getStatusCode().is2xxSuccessful()
                || !(marketCheckResponse.getBody() instanceof VinDecodeRawDTO)) {
            LOGGER.debug("MarketCheck response unsuccessful or unexpected body type - status: {}, bodyType: {}",
                    marketCheckResponse.getStatusCode(),
                    marketCheckResponse.getBody() != null ? marketCheckResponse.getBody().getClass().getSimpleName()
                            : "null");
            String errorStatus = "unknown";
            String errorReason = "unknown";
            if (marketCheckResponse.getBody() instanceof Map<?, ?> errorBody) {
                errorStatus = errorBody.get(STATUS) != null ? errorBody.get(STATUS).toString() : errorStatus;
                errorReason = errorBody.get(REASON) != null ? errorBody.get(REASON).toString() : errorReason;
            }
            throw new WindowStickerException("Failed to retrieve vehicle specifications for VIN " + Encode.forJava(vin)
                    + ": " + errorStatus + " - " + errorReason);
        }

        if (((VinDecodeRawDTO) marketCheckResponse.getBody()).reason() != null) {
            throw new WindowStickerException("Failed to retrieve vehicle specifications for VIN " + Encode.forJava(vin)
                    + ": " + ((VinDecodeRawDTO) marketCheckResponse.getBody()).reason());
        }

        VinDecodeDTO vinDecode = extractVinDecodeData(marketCheckResponse);

        LOGGER.debug("getVehicleSpecsByVin completed successfully for VIN: {}", Encode.forJava(vin));
        return ResponseEntity.ok(vinDecode);
    }

    private VinDecodeDTO extractVinDecodeData(ResponseEntity<?> marketCheckResponse) {
        VinDecodeRawDTO rawVinDecode = (VinDecodeRawDTO) marketCheckResponse.getBody();
        VinDecodeDTO vinDecode = new VinDecodeDTO();

        // Basic vehicle information
        vinDecode.setVin(rawVinDecode.vin());
        vinDecode.setYear(String.valueOf(rawVinDecode.year()));
        vinDecode.setMake(rawVinDecode.make());
        vinDecode.setModel(rawVinDecode.model());
        vinDecode.setDoors(rawVinDecode.doors());
        LOGGER.debug("Basic vehicle info has been set (vin, year, make, model, doors)");

        // Color information
        if (rawVinDecode.exteriorColor() != null) {
            vinDecode.setExteriorColor(rawVinDecode.exteriorColor().name());
            vinDecode.setExteriorColorCode(rawVinDecode.exteriorColor().code());
            LOGGER.debug("Exterior color and color code have been set");
        } else {
            LOGGER.debug("No exterior color data available");
        }
        if (rawVinDecode.interiorColor() != null) {
            vinDecode.setInteriorColor(rawVinDecode.interiorColor().name());
            vinDecode.setInteriorColorCode(rawVinDecode.interiorColor().code());
            LOGGER.debug("Interior color and color code have been set");
        } else {
            LOGGER.debug("No interior color data available");
        }

        // Vehicle specifications
        vinDecode.setBodyType(rawVinDecode.bodyType());
        vinDecode.setTransmission(rawVinDecode.transmission());
        vinDecode.setEngine(rawVinDecode.engine());
        vinDecode.setDriveTrain(rawVinDecode.drivetrain());
        vinDecode.setFuelType(rawVinDecode.fuelType());
        LOGGER.debug("Vehicle specs have been set (bodyType, transmission, engine, drivetrain, fuelType)");

        // Pricing information
        vinDecode.setMsrp(formatWithCommas(rawVinDecode.msrp()));
        vinDecode.setTotalOptionMsrp(formatWithCommas(rawVinDecode.installedOptionsMsrp()));
        vinDecode.setDestinationHandlingCharges(formatWithCommas(rawVinDecode.deliveryCharges()));
        vinDecode.setTotalMsrp(formatWithCommas(rawVinDecode.combinedMsrp()));
        LOGGER.debug("Pricing info has been set (msrp, optionMsrp, deliveryCharges, combinedMsrp)");

        // Fuel economy
        vinDecode.setCityMpg(String.valueOf(rawVinDecode.cityMpg()));
        vinDecode.setHighwayMpg(String.valueOf(rawVinDecode.highwayMpg()));
        vinDecode.setCombinedMpg(String.valueOf(rawVinDecode.combinedMpg()));
        LOGGER.debug("Fuel economy has been set (cityMpg, highwayMpg, combinedMpg)");

        // Calculate youSave and annualFuelCost
        // annualFuelCost = (15,000 / combined_mpg) × 3.5
        // youSave = 11,500 - ((15,000 / combined_mpg) × 17.5)
        if (rawVinDecode.combinedMpg() > 0) {
            double fuelCostBase = 15000.0 / rawVinDecode.combinedMpg();
            double annualFuelCostCalculated = fuelCostBase * 3.5;
            double youSaveCalculated = 11500.0 - (fuelCostBase * 17.5);
            long annualFuelCost = Math.max(0L, Math.round(annualFuelCostCalculated));
            long youSave = Math.max(0L, Math.round(youSaveCalculated));
            vinDecode.setAnnualFuelCost(formatWithCommas(annualFuelCost));
            vinDecode.setYouSave(formatWithCommas(youSave));
            LOGGER.debug("Fuel costs have been calculated and set (annualFuelCost, youSave)");
        } else {
            LOGGER.debug("Combined MPG is 0 or negative, defaulting annualFuelCost and youSave to 0");
            vinDecode.setAnnualFuelCost("0");
            vinDecode.setYouSave("0");
        }

        // Features mapping
        if (rawVinDecode.features() != null) {
            LOGGER.debug("Mapping features - categories available: {}", rawVinDecode.features().keySet());
            vinDecode.setComfortConvenienceFeatures(
                    extractFeatureDescriptions(rawVinDecode.features(), "Comfort & Convenience"));
            vinDecode.setSafetyDriverAssistFeatures(
                    extractFeatureDescriptions(rawVinDecode.features(), "Safety & Driver Assist"));
            vinDecode.setInfotainmentFeatures(
                    extractFeatureDescriptions(rawVinDecode.features(), "Infotainment"));
            vinDecode.setExteriorFeatures(
                    extractFeatureDescriptions(rawVinDecode.features(), "Exterior"));
            vinDecode.setInteriorFeatures(
                    extractFeatureDescriptions(rawVinDecode.features(), "Interior"));
            vinDecode.setTransmissionFeatures(
                    extractFeatureDescriptions(rawVinDecode.features(), "Transmission"));
            vinDecode.setEngineFeatures(
                    extractFeatureDescriptions(rawVinDecode.features(), "Engine"));
            vinDecode.setGeneralFeatures(
                    extractFeatureDescriptions(rawVinDecode.features(), "General"));
            vinDecode.setSuspensionFeatures(
                    extractFeatureDescriptions(rawVinDecode.features(), "Suspension"));
        } else {
            LOGGER.debug("No features data available");
        }

        // Optional equipment mapping sorted alphabetically by description
        if (rawVinDecode.installedOptionsDetails() != null) {
            LOGGER.debug("Mapping optional equipment - count: {}", rawVinDecode.installedOptionsDetails().size());
            vinDecode.setOptionalEquipments(
                    rawVinDecode.installedOptionsDetails().stream()
                            .map(option -> {
                                VinDecodeDTO.OptionalEquipment oe = new VinDecodeDTO.OptionalEquipment();
                                oe.setCode(option.code());
                                oe.setDescription(option.name());
                                oe.setMsrp(formatStringWithCommas(option.msrp()));
                                return oe;
                            })
                            .sorted(Comparator.comparing(VinDecodeDTO.OptionalEquipment::getDescription))
                            .toList());
        } else {
            LOGGER.debug("No installed options details available");
        }

        // Warranty information
        if (rawVinDecode.warranty() != null) {
            LOGGER.debug("Mapping warranty information");
            if (rawVinDecode.warranty().total() != null) {
                VinDecodeDTO.Warranty total = new VinDecodeDTO.Warranty();
                total.setDuration(rawVinDecode.warranty().total().duration() / 12);
                total.setDistance(rawVinDecode.warranty().total().distance());
                vinDecode.setTotal(total);
            }
            if (rawVinDecode.warranty().powertrain() != null) {
                VinDecodeDTO.Warranty powertrain = new VinDecodeDTO.Warranty();
                powertrain.setDuration(rawVinDecode.warranty().powertrain().duration() / 12);
                powertrain.setDistance(rawVinDecode.warranty().powertrain().distance());
                vinDecode.setPowertrain(powertrain);
            }
            if (rawVinDecode.warranty().antiCorrosion() != null) {
                VinDecodeDTO.Warranty antiCorrosion = new VinDecodeDTO.Warranty();
                antiCorrosion.setDuration(rawVinDecode.warranty().antiCorrosion().duration() / 12);
                antiCorrosion.setDistance(rawVinDecode.warranty().antiCorrosion().distance());
                vinDecode.setAntiCorrosion(antiCorrosion);
            }
            if (rawVinDecode.warranty().roadsideAssistance() != null) {
                VinDecodeDTO.Warranty roadsideAssistance = new VinDecodeDTO.Warranty();
                roadsideAssistance.setDuration(rawVinDecode.warranty().roadsideAssistance().duration() / 12);
                roadsideAssistance.setDistance(rawVinDecode.warranty().roadsideAssistance().distance());
                vinDecode.setRoadsideAssistance(roadsideAssistance);
            }
        } else {
            LOGGER.debug("No warranty data available");
        }

        // Safety rating information
        if (rawVinDecode.rating() != null) {
            LOGGER.debug("Mapping safety rating information");
            VinDecodeDTO.SafetyRating safetyRating = new VinDecodeDTO.SafetyRating();
            if (rawVinDecode.rating().safety() != null) {
                safetyRating.setFront(rawVinDecode.rating().safety().front());
                safetyRating.setSide(rawVinDecode.rating().safety().side());
                safetyRating.setOverall(rawVinDecode.rating().safety().overall());
            }
            safetyRating.setRollover(rawVinDecode.rating().rollover());
            safetyRating.setRoofStrength(parseRoofStrengthToInt(rawVinDecode.rating().roofStrength()));
            vinDecode.setRating(safetyRating);
        } else {
            LOGGER.debug("No safety rating data available");
        }
        return vinDecode;
    }

    /**
     * Generates a window sticker for Ford vehicles.
     *
     * @param vr the verification result
     * @return ResponseEntity with PDF or error message
     */
    private ResponseEntity<?> getFordVinSticker(VerificationResult vr, String documentTitle) {
        URI fordApiUri = URI.create(toSecureUrl(configProperties.getFordApiUrl()));

        HttpHeaders headers = new HttpHeaders();
        headers.set(ACCEPT_HEADER, FORD_API_ACCEPT_HEADER);
        headers.set(FORD_API_AUTH_HEADER, StandardAuthScheme.BEARER + EMP_STRING + getFordToken());
        String vin = vr.claims().get(VIN);

        // if isFordWindowStickerTestEnv is true then use hardcoded vin for testing
        if (isFordWindowStickerTestEnv)
            headers.set(VIN, FORD_TEST_VIN);
        else
            headers.set(VIN, vin);

        HttpEntity<String> entity = new HttpEntity<>(headers);
        ResponseEntity<byte[]> response;

        try {
            response = restTemplate.exchange(
                    fordApiUri, HttpMethod.GET, entity, byte[].class);
        } catch (HttpClientErrorException.Forbidden ex) {
            LOGGER.error("Error calling Ford API for vin: {}, errorResponse: {}", Encode.forJava(vin),
                    htmlEscape(ex.getResponseBodyAsString()));
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .cacheControl(CacheControl.noStore())
                    .header(REFERRER_POLICY_HEADER, REFERRER_POLICY_VALUE)
                    .body("Window Sticker not found for the Ford VIN");
        } catch (Exception e) {
            LOGGER.error("Error calling Ford API for vin: {} , errorResponse: {}", Encode.forJava(vin),
                    Encode.forJava(e.toString()));
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .cacheControl(CacheControl.noStore())
                    .header(REFERRER_POLICY_HEADER, REFERRER_POLICY_VALUE)
                    .body(Map.of(STATUS, ERROR_STATUS, REASON, ERROR_REASON_FORD));
        }

        if (response.getStatusCode() == HttpStatus.OK) {
            byte[] pdfBytes = applyWindowStickerPdfTitle(Objects.requireNonNull(response.getBody()), documentTitle);
            InputStreamResource resource = new InputStreamResource(
                    new java.io.ByteArrayInputStream(pdfBytes));

            HttpHeaders respHeaders = new HttpHeaders();
            respHeaders.setContentType(MediaType.APPLICATION_PDF);
            respHeaders.setContentDisposition(ContentDisposition.inline().filename(documentTitle + ".pdf").build());

            return ResponseEntity.ok()
                    .headers(respHeaders)
                    .contentLength(pdfBytes.length)
                    .body(resource);
        }

        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .cacheControl(CacheControl.noStore())
                .header(REFERRER_POLICY_HEADER, REFERRER_POLICY_VALUE)
                .body(Map.of(STATUS, ERROR_STATUS, REASON, ERROR_REASON_FORD));
    }

    private ResponseEntity<?> getToyotaVinSticker(VerificationResult vr, String documentTitle) {
        HttpHeaders headers = new HttpHeaders();
        headers.setAccept(Collections.singletonList(MediaType.APPLICATION_PDF));
        String vin = vr.claims().get(VIN);
        String accessToken;
        ResponseEntity<byte[]> response;
        try {
            LOGGER.info("Calling ToyotaAuthService.getAuthToken() for VIN: {}", Encode.forJava(vin));
            accessToken = toyotaAuthService.getAuthToken();
            LOGGER.info("Toyota auth token received: {}",
                    accessToken != null ? accessToken.substring(0, 10) + "..." : "null");
            if (accessToken == null || accessToken.isEmpty()) {
                LOGGER.error("Toyota auth token is null or empty for vin: {}", Encode.forJava(vin));
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                        .cacheControl(CacheControl.noStore())
                        .header(REFERRER_POLICY_HEADER, REFERRER_POLICY_VALUE)
                        .body(Map.of(STATUS, ERROR_STATUS, REASON, "Toyota auth token is missing"));
            }
        } catch (Exception e) {
            LOGGER.error("Error fetching Toyota auth token for vin: {} , error: {}", Encode.forJava(vin),
                    Encode.forJava(e.toString()));
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .cacheControl(CacheControl.noStore())
                    .header(REFERRER_POLICY_HEADER, REFERRER_POLICY_VALUE)
                    .body(Map.of(STATUS, ERROR_STATUS, REASON, "Error fetching Toyota auth token"));
        }
        headers.setBearerAuth(accessToken);
        // Add transactionId as header (not as query param)
        String transactionId = java.util.UUID.randomUUID().toString().toLowerCase();
        headers.add("x-transaction-id", transactionId);
        HttpEntity<String> entity = new HttpEntity<>(headers);
        String toyotaApiUrl = toyotaApiConfigProperties.getFullWindowStickerUrl();
        if (toyotaApiUrl == null || toyotaApiUrl.isEmpty()) {
            LOGGER.error("Toyota API URL is not configured");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .cacheControl(CacheControl.noStore())
                    .header(REFERRER_POLICY_HEADER, REFERRER_POLICY_VALUE)
                    .body(Map.of(STATUS, ERROR_STATUS, REASON, "Toyota API URL is not configured"));
        }
        String validatedToyotaApiUri = validateSensitiveEndpointTemplate(
                toyotaApiUrl,
                "toyota.windowStickerHost/windowStickerBaseUrl/windowStickerPath");

        try {
            URI expandedUri = UriComponentsBuilder.fromUriString(toSecureUrl(validatedToyotaApiUri))
                    .buildAndExpand(vin)
                    .toUri();
            response = restTemplate.exchange(
                    expandedUri, HttpMethod.GET, entity, byte[].class);
        } catch (HttpClientErrorException.Forbidden ex) {
            LOGGER.error("Error calling Toyota API for vin: {}, errorResponse: {}", Encode.forJava(vin),
                    htmlEscape(ex.getResponseBodyAsString()));
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .cacheControl(CacheControl.noStore())
                    .header(REFERRER_POLICY_HEADER, REFERRER_POLICY_VALUE)
                    .body("Window Sticker not found for the Toyota VIN");
        } catch (Exception e) {
            LOGGER.error("Error calling Toyota API for vin: {} , errorResponse: {}", Encode.forJava(vin),
                    Encode.forJava(e.toString()));
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .cacheControl(CacheControl.noStore())
                    .header(REFERRER_POLICY_HEADER, REFERRER_POLICY_VALUE)
                    .body(Map.of(STATUS, ERROR_STATUS, REASON, "Error calling Toyota API"));
        }
        if (response != null && response.getStatusCode() == HttpStatus.OK && response.getBody() != null) {
            byte[] pdfBytes = applyWindowStickerPdfTitle(response.getBody(), documentTitle);
            InputStreamResource resource = new InputStreamResource(
                    new java.io.ByteArrayInputStream(pdfBytes));
            HttpHeaders respHeaders = new HttpHeaders();
            respHeaders.setContentType(MediaType.APPLICATION_PDF);
            respHeaders.setContentDisposition(ContentDisposition.inline().filename(documentTitle + ".pdf").build());
            return ResponseEntity.ok()
                    .headers(respHeaders)
                    .contentLength(pdfBytes.length)
                    .body(resource);
        }
        LOGGER.error("Toyota window sticker unavailable for vin: {}", Encode.forJava(vin));
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .cacheControl(CacheControl.noStore())
                .header(REFERRER_POLICY_HEADER, REFERRER_POLICY_VALUE)
                .body(Map.of(STATUS, ERROR_STATUS, REASON, "Toyota window sticker unavailable"));
    }

    /**
     * Gets an authentication token for the Ford API.
     *
     * @return the access token
     */

    private String getFordToken() {
        URI tokenUri = URI.create(toSecureUrl(configProperties.getUrl()));

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);

        MultiValueMap<String, String> map = new LinkedMultiValueMap<>();
        map.add(CLIENT_ID, configProperties.getClientId());
        map.add(CLIENT_SECRET, configProperties.getClientSecret());
        map.add(GRANT_TYPE, configProperties.getGrantType());
        map.add(SCOPE, configProperties.getScope());

        HttpEntity<MultiValueMap<String, String>> request = new HttpEntity<>(map, headers);

        ResponseEntity<TokenResponseDTO> response = restTemplate.postForEntity(
                tokenUri, request, TokenResponseDTO.class);
        return Objects.requireNonNull(response.getBody()).getAccess_token();
    }

    /**
     * Gets vehicle specifications from MarketCheck API using VIN and query
     * parameters.
     * Builds a complete URL with dynamic VIN path parameter and multiple query
     * parameters.
     *
     * @param vin the Vehicle Identification Number (path parameter)
     * @return ResponseEntity containing VinDecodeRawDTO and HTTP status information
     */
    public ResponseEntity<?> getMarketCheckVinDecodeWithOptions(
            String vin,
            boolean includeGeneric,
            boolean forceDecodeFlag,
            boolean includeAvlOpts) {
        try {
            LOGGER.info("Calling MarketCheck API for VIN: {} with options", Encode.forJava(vin));
            String marketCheckApiUrl = validateSensitiveEndpointTemplate(
                    marketCheckConfigProperties.getApiUrl(),
                    "marketcheck.api-url");

            // Build URI with conditional query parameters
            UriComponentsBuilder builder = UriComponentsBuilder
                    .fromUriString(toSecureUrl(marketCheckApiUrl))
                    .queryParam("api_key", marketCheckConfigProperties.getClientId());

            // Add optional query parameters
            if (includeGeneric) {
                builder.queryParam("include_generic", true);
            }
            if (forceDecodeFlag) {
                builder.queryParam("force_decode", true);
            }
            if (includeAvlOpts) {
                builder.queryParam("include_avl_opts", true);
            }

            String uri = builder.buildAndExpand(vin).toUriString();

            LOGGER.debug("MarketCheck API URL (with options): {}", uri.replaceAll("api_key=.*&", "api_key=***&"));

            ResponseEntity<VinDecodeRawDTO> response;

            try {
                response = marketCheckRestTemplate.getForEntity(uri, VinDecodeRawDTO.class);
            }
            // Auth Errors
            catch (HttpClientErrorException.Unauthorized | HttpClientErrorException.Forbidden ex) {
                LOGGER.error("Auth error calling MarketCheck API for VIN: {}, status: {}, errorResponse: {}",
                        Encode.forJava(vin), Encode.forJava(ex.getStatusCode().toString()),
                        Encode.forJava(ex.getMessage()));
                return ResponseEntity.status(HttpStatus.FORBIDDEN)
                        .body(Map.of(STATUS, UNAUTHORIZED_STATUS, REASON, "MarketCheck API authentication failed"));
            }
            // Client Input Errors
            catch (HttpClientErrorException.BadRequest ex) {
                LOGGER.error("Bad request calling MarketCheck API for VIN: {}, errorResponse: {}",
                        Encode.forJava(vin), Encode.forJava(ex.getMessage()));
                return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                        .body(Map.of(STATUS, ERROR_STATUS, REASON, "Invalid request parameters for VIN decode"));
            }
            // Vin Decode Errors
            catch (HttpClientErrorException.UnprocessableEntity ex) {
                LOGGER.warn("Unprocessable VIN calling MarketCheck API for VIN: {}, errorResponse: {}",
                        Encode.forJava(vin), Encode.forJava(ex.getMessage()));
                String reason = "VIN could not be decoded";
                Map<?, ?> errorBody = ex.getResponseBodyAs(Map.class);
                if (errorBody != null && errorBody.get("reason") != null) {
                    reason = errorBody.get("reason").toString();
                }
                return ResponseEntity.status(HttpStatus.UNPROCESSABLE_ENTITY)
                        .body(Map.of(STATUS, ERROR_VIN_DECODE_MARKETCHECK, REASON, reason));
            }
            // Rate Limiting Error
            catch (HttpClientErrorException.TooManyRequests ex) {
                LOGGER.warn("Rate limited by MarketCheck API for VIN: {}, errorResponse: {}",
                        Encode.forJava(vin), Encode.forJava(ex.getMessage()));
                return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS)
                        .body(Map.of(STATUS, ERROR_STATUS, REASON,
                                "MarketCheck API rate limit exceeded. Please retry later."));
            }
            // Server Side Errors
            catch (HttpServerErrorException ex) {
                LOGGER.error("Server error from MarketCheck API for VIN: {}, status: {}, errorResponse: {}",
                        Encode.forJava(vin), Encode.forJava(ex.getStatusCode().toString()),
                        Encode.forJava(ex.getMessage()));
                return ResponseEntity.status(HttpStatus.BAD_GATEWAY)
                        .body(Map.of(STATUS, ERROR_STATUS, REASON, ERROR_REASON_MARKETCHECK));
            }

            LOGGER.info("MarketCheck API response status: {}", response.getStatusCode());
            return response;

        } catch (Exception e) {
            LOGGER.error("Error retrieving vehicle decode data from MarketCheck API: {}, Error: {}",
                    Encode.forJava(vin), Encode.forJava(e.toString()));
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of(STATUS, ERROR_STATUS, REASON, ERROR_REASON_MARKETCHECK));
        }
    }

    public static String htmlEscape(String input) {
        if (input == null)
            return "";
        return input.replaceAll("[^\\w\\s.,;:!?@#%&()\\[\\]{}\\-_=+]", "");
    }

    // Credentials/tokens/API keys are submitted in these calls, so endpoint
    // transport must be TLS.
    // toSecureUrl() actively replaces http:// with https://, which allows
    // Checkmarx's data-flow
    // analysis to verify that the URL at every sensitive HTTP sink is HTTPS.
    // localhost/loopback URLs are exempt to support local development testing.
    private static String toSecureUrl(String url) {
        if (!StringUtils.hasText(url)) {
            throw new IllegalStateException("Endpoint URL must not be blank.");
        }
        if (isLoopbackHttpUrl(url)) {
            return url;
        }
        return url.replaceFirst("(?i)^http://", "https://");
    }

    private static boolean isLoopbackHost(String host) {
        if (!StringUtils.hasText(host)) {
            return false;
        }

        return "localhost".equalsIgnoreCase(host)
                || "127.0.0.1".equals(host)
                || "::1".equals(host)
                || "[::1]".equals(host);
    }

    private static boolean isLoopbackHttpUrl(String url) {
        if (!StringUtils.hasText(url)) {
            return false;
        }

        try {
            UriComponents uriComponents = UriComponentsBuilder.fromUriString(url).build();
            return "http".equalsIgnoreCase(uriComponents.getScheme())
                    && isLoopbackHost(uriComponents.getHost());
        } catch (IllegalArgumentException ex) {
            return false;
        }
    }

    private void validateSensitiveEndpointUri(String endpoint, String propertyName) {
        if (!StringUtils.hasText(endpoint)) {
            throw new IllegalStateException("Missing endpoint configuration: " + propertyName);
        }

        URI uri;
        try {
            uri = URI.create(endpoint);
        } catch (IllegalArgumentException ex) {
            throw new IllegalStateException("Invalid endpoint URL for " + propertyName, ex);
        }

        if (!"https".equalsIgnoreCase(uri.getScheme()) && !isLoopbackHost(uri.getHost())) {
            throw new IllegalStateException("Insecure endpoint for " + propertyName + ": HTTPS is required.");
        }
    }

    // Template URLs may contain path variables (for example /{vin}), so parse
    // through UriComponentsBuilder.
    private String validateSensitiveEndpointTemplate(String endpoint, String propertyName) {
        if (!StringUtils.hasText(endpoint)) {
            throw new IllegalStateException("Missing endpoint configuration: " + propertyName);
        }

        UriComponents uriComponents;
        try {
            uriComponents = UriComponentsBuilder.fromUriString(endpoint).build();
        } catch (IllegalArgumentException ex) {
            throw new IllegalStateException("Invalid endpoint URL for " + propertyName, ex);
        }

        String scheme = uriComponents.getScheme();
        String host = uriComponents.getHost();
        if (!"https".equalsIgnoreCase(scheme) && !isLoopbackHost(host)) {
            throw new IllegalStateException("Insecure endpoint for " + propertyName + ": HTTPS is required.");
        }

        return endpoint;
    }

    /**
     * Extracts feature descriptions from the features map filtered by category
     * and returns them in alphabetical order
     *
     * @param features the features map
     * @param category the category to filter by
     * @return List of feature descriptions sorted alphabetically
     */
    private java.util.List<String> extractFeatureDescriptions(
            java.util.Map<String, java.util.List<VinDecodeRawDTO.Feature>> features,
            String category) {
        if (features == null || features.isEmpty()) {
            return java.util.Collections.emptyList();
        }

        return features.values().stream()
                .flatMap(java.util.List::stream)
                .filter(feature -> category.equals(feature.category()))
                .map(VinDecodeRawDTO.Feature::description)
                .sorted()
                .toList();
    }

    /**
     * Safely parses a string to integer, returning 0 if parsing fails
     *
     * @param value the string value to parse
     * @return parsed integer or 0 if parsing fails
     */
    private int parseIntSafely(String value) {
        try {
            return value != null ? Integer.parseInt(value) : 0;
        } catch (NumberFormatException e) {
            LOGGER.warn("Failed to parse integer value: {}", value);
            return 0;
        }
    }

    /**
     * Fires a GA4 analytics event for window sticker fetch outcome.
     * Async and fire-and-forget — never blocks or breaks the response.
     */
    private void trackWindowStickerOutcome(String clientType, boolean isFastlink,
            String vin, String make, String flowType,
            String correlationId, ResponseEntity<?> response) {
        try {
            int statusCode = response.getStatusCode().value();
            String outcome = response.getStatusCode().is2xxSuccessful() ? "success" : "failure";
            GA4Event event = GA4Event.windowStickerOutcome(vin, make, flowType, outcome, statusCode, correlationId);
            ga4AnalyticsService.sendEvent(clientType, isFastlink, event);
        } catch (Exception e) {
            LOGGER.debug("[GA4] Error preparing window sticker analytics event: {}", e.getMessage());
        }
    }

    /**
     * Tracks client-side new-tab actions (CTA click and fetch outcome) via
     * server-side GA forwarding.
     */
    public void trackWindowStickerClientAction(String token,
            String pageLocation, String pagePath,
            String clickElementId, String interactionType,
            String flowType, String modalTarget,
            String dataUrl, String correlationId,
            String analyticsSource,
            String outcome, Integer httpStatus) {
        try {
            VerificationResult vr = tokenService.verifyToken(token, PURPOSE_PROCESS, false);
            if (!vr.ok()) {
                LOGGER.debug("[GA4] Skipping client action tracking due to invalid token: {}", vr.message());
                return;
            }

            String vin = vr.claims().get(VIN);
            String make = vr.claims().get(MAKE);
            String clientType = vr.claims().getOrDefault("clientType", "");
            boolean isFastlink = "y".equals(vr.claims().getOrDefault("fastlink", ""));

            GA4Event event = GA4Event.windowStickerClientAction(
                    vin,
                    make,
                    pageLocation,
                    pagePath,
                    clickElementId,
                    interactionType,
                    flowType,
                    modalTarget,
                    dataUrl,
                    correlationId,
                    analyticsSource,
                    outcome,
                    httpStatus);
            ga4AnalyticsService.sendEvent(clientType, isFastlink, event);
        } catch (Exception e) {
            LOGGER.debug("[GA4] Error tracking client action event: {}", e.getMessage());
        }
    }

    /**
     * Converts roof strength string to integer rating
     *
     * @param roofStrength the roof strength string (e.g., "Good", "Acceptable")
     * @return integer rating (Good=5, Acceptable=3, Poor=1, unknown=0)
     */
    private int parseRoofStrengthToInt(String roofStrength) {
        if (roofStrength == null)
            return 0;
        return switch (roofStrength.toLowerCase()) {
            case "good" -> 5;
            case "acceptable" -> 4;
            case "marginal" -> 3;
            case "poor" -> 2;
            default -> 0;
        };
    }

    /**
     * Formats a numeric value with commas as thousand separators (US locale).
     * e.g. 42350 → "42,350"
     *
     * @param value the numeric value
     * @return formatted string with commas
     */
    private String formatWithCommas(long value) {
        return NumberFormat.getNumberInstance(Locale.US).format(value);
    }

    /**
     * Formats a string-based numeric value with commas as thousand separators.
     * Returns the original string if it cannot be parsed as a number.
     *
     * @param value the string numeric value (e.g. "1250")
     * @return formatted string with commas (e.g. "1,250"), or the original value if
     *         unparseable
     */
    private String formatStringWithCommas(String value) {
        if (value == null || value.isBlank())
            return value;
        try {
            long parsed = Long.parseLong(value.trim());
            return formatWithCommas(parsed);
        } catch (NumberFormatException e) {
            try {
                double parsed = Double.parseDouble(value.trim());
                return NumberFormat.getNumberInstance(Locale.US).format(Math.round(parsed));
            } catch (NumberFormatException ex) {
                LOGGER.warn("Failed to parse numeric string for formatting: {}", value);
                return value;
            }
        }
    }

    @SuppressWarnings("deprecation")
    private byte[] applyWindowStickerPdfTitle(byte[] pdfBytes, String documentTitle) {
        if (pdfBytes == null || pdfBytes.length == 0) {
            return pdfBytes;
        }

        String desiredTitle = (documentTitle == null || documentTitle.isBlank())
                ? "window-sticker"
                : documentTitle;

        PdfReader reader = null;
        PdfStamper stamper = null;
        try {
            reader = new PdfReader(pdfBytes);
            ByteArrayOutputStream output = new ByteArrayOutputStream();
            stamper = new PdfStamper(reader, output);

            Map<String, String> existing = reader.getInfo();
            HashMap<String, String> updated = existing != null ? new HashMap<>(existing) : new HashMap<>();
            updated.put("Title", desiredTitle);
            stamper.setMoreInfo(updated);

            stamper.close();
            reader.close();
            return output.toByteArray();
        } catch (Exception ex) {
            // Preserve existing flow and response even if metadata rewrite fails.
            LOGGER.warn("Could not set window sticker PDF title for {}: {}", Encode.forJava(desiredTitle),
                    Encode.forJava(ex.getMessage()));
            return pdfBytes;
        } finally {
            try {
                if (stamper != null)
                    stamper.close();
            } catch (Exception ignored) {
            }
            try {
                if (reader != null)
                    reader.close();
            } catch (Exception ignored) {
            }
        }
    }

    private String resolveDocumentTitle(String requestedFilename, String vin) {
        String safeVin = (vin == null || vin.isBlank()) ? "unknown" : vin;
        String fallbackTitle = "window-sticker-" + safeVin;

        if (requestedFilename == null || requestedFilename.isBlank()) {
            return fallbackTitle;
        }

        String normalized = requestedFilename.trim();
        if (normalized.toLowerCase(Locale.ROOT).endsWith(".pdf")) {
            normalized = normalized.substring(0, normalized.length() - 4);
        }

        normalized = normalized
                .replaceAll("[^A-Za-z0-9_-]", "-")
                .replaceAll("-{2,}", "-")
                .replaceAll("^[-_.]+|[-_.]+$", "");

        return normalized.isBlank() ? fallbackTitle : normalized;
    }
}