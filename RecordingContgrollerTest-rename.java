package com.openreach.orfta.orftaservice.controller.test;

import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.net.URI;

import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Mockito;
import org.mockito.MockitoAnnotations;
import org.mockito.Spy;
import org.springframework.core.env.Environment;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.junit4.SpringRunner;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.RequestBuilder;
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.client.RestTemplate;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.openreach.orfta.orftaservice.configuration.BasicConfiguration;
import com.openreach.orfta.orftaservice.configuration.RecordingConfiguration;
import com.openreach.orfta.orftaservice.controller.RecordingController;
import com.openreach.orfta.orftaservice.dto.CommonResponseDTO;
import com.openreach.orfta.orftaservice.dto.RepositoryRequestDTO;
import com.openreach.orfta.orftaservice.exceptions.OrftaServiceAdvicer;
import com.openreach.orfta.orftaservice.service.RecordingServiceImpl;
import com.openreach.orfta.orftaservice.test.DataConstructor;

@RunWith(SpringRunner.class)

@TestPropertySource("classpath:orfta-service.properties")

public class RecordingControllerTest extends DataConstructor {
	@InjectMocks
	RecordingController recordingController;

	@Spy
	@InjectMocks
	RecordingServiceImpl recordingService;
    private MockMvc mockMvc;
	
	@Mock
	RecordingConfiguration recordingConfiguration;

	@Mock
	RestTemplate restTemplate;
	
    private MockRestServiceServer mockServer;
	
	@Mock
	Environment env;
	
	@Mock
	BasicConfiguration configuration;
	
	@Before
	public void init() {

		MockitoAnnotations.initMocks(this);
		this.mockMvc = MockMvcBuilders.standaloneSetup(recordingController)
				.setControllerAdvice(new OrftaServiceAdvicer()).build();
		ReflectionTestUtils.setField(recordingController, "recordingService", recordingService);
		ReflectionTestUtils.setField(recordingService, "restTemplate", restTemplate);
		ReflectionTestUtils.setField(recordingService, "recordingConfiguration", recordingConfiguration);
		mockServer = MockRestServiceServer.createServer(restTemplate);
	}
	@Test
	public void repositoryDiscountListTest() throws Throwable {
		ResponseEntity<CommonResponseDTO> response = new ResponseEntity<CommonResponseDTO>(HttpStatus.OK);
		ObjectMapper mapper = new ObjectMapper();
		RepositoryRequestDTO repositoryRequestDTO=new RepositoryRequestDTO();
		Integer pageNum=123;
		Mockito.when(recordingConfiguration.getRepositoryDiscountList())
				.thenReturn("http://persistence/ms/persistence/recording/repositoryDiscountList");
		RequestBuilder requestBuilder1 = MockMvcRequestBuilders.post("/recording/repositoryDiscountList")
				.content(mapper.writeValueAsString(repositoryRequestDTO)).contentType(MediaType.APPLICATION_JSON)
				.param("pageNum", "0").accept(MediaType.APPLICATION_JSON);
		Mockito.when(restTemplate.postForEntity(Mockito.any(URI.class),
				Mockito.any(CommonResponseDTO.class), Mockito.any(Class.class))).thenReturn(response);
		try {
			MvcResult result1 = mockMvc.perform(requestBuilder1).andExpect(status().isOk()).andReturn();
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
	@Test
	public void addRepositoryDiscountTest() throws Throwable {
		ResponseEntity<CommonResponseDTO> response = new ResponseEntity<CommonResponseDTO>(HttpStatus.OK);
		ObjectMapper mapper = new ObjectMapper();
		RepositoryRequestDTO repositoryRequestDTO=new RepositoryRequestDTO();
		Integer pageNum=123;
		Mockito.when(recordingConfiguration.getAddRepositoryDiscount())
				.thenReturn("http://persistence/ms/persistence/recording/addRepositoryDiscount");
		RequestBuilder requestBuilder1 = MockMvcRequestBuilders.post("/recording/addRepositoryDiscount")
				.content(mapper.writeValueAsString(repositoryRequestDTO)).contentType(MediaType.APPLICATION_JSON);
		Mockito.when(restTemplate.postForEntity(Mockito.any(URI.class),
				Mockito.any(CommonResponseDTO.class), Mockito.any(Class.class))).thenReturn(response);
		try {
			MvcResult result1 = mockMvc.perform(requestBuilder1).andExpect(status().isOk()).andReturn();
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
	
	
	@Test
	public void modifyRepositoryDiscountTest() throws Throwable {
		ResponseEntity<CommonResponseDTO> response = new ResponseEntity<CommonResponseDTO>(HttpStatus.OK);
		ObjectMapper mapper = new ObjectMapper();
		RepositoryRequestDTO repositoryRequestDTO=new RepositoryRequestDTO();
		Mockito.when(recordingConfiguration.getModifyRepositoryDiscount())
				.thenReturn("http://persistence/ms/persistence/recording/modifyRepositoryDiscount");
		RequestBuilder requestBuilder1 = MockMvcRequestBuilders.post("/recording/modifyRepositoryDiscount")
				.content(mapper.writeValueAsString(repositoryRequestDTO)).contentType(MediaType.APPLICATION_JSON);
		Mockito.when(restTemplate.postForEntity(Mockito.any(URI.class),
				Mockito.any(CommonResponseDTO.class), Mockito.any(Class.class))).thenReturn(response);
		try {
			MvcResult result1 = mockMvc.perform(requestBuilder1).andExpect(status().isOk()).andReturn();
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
	@Test
	public void deleteRepositoryDiscounTest() throws Throwable {
		ResponseEntity<CommonResponseDTO> response = new ResponseEntity<CommonResponseDTO>(HttpStatus.OK);
		ObjectMapper mapper = new ObjectMapper();
		RepositoryRequestDTO repositoryRequestDTO=new RepositoryRequestDTO();
		Mockito.when(recordingConfiguration.getDeleteRepositoryDiscount())
				.thenReturn("http://persistence/ms/persistence/recording/deleteRepositoryDiscount");
		RequestBuilder requestBuilder1 = MockMvcRequestBuilders.post("/recording/deleteRepositoryDiscount")
				.content(mapper.writeValueAsString(repositoryRequestDTO)).contentType(MediaType.APPLICATION_JSON);
		Mockito.when(restTemplate.postForEntity(Mockito.any(URI.class),
				Mockito.any(CommonResponseDTO.class), Mockito.any(Class.class))).thenReturn(response);
		try {
			MvcResult result1 = mockMvc.perform(requestBuilder1).andExpect(status().isOk()).andReturn();
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
	@Test
	public void repositoryDiscountAuditListTest() {
		ResponseEntity<CommonResponseDTO> response = new ResponseEntity<CommonResponseDTO>(HttpStatus.OK);
		Mockito.when(recordingConfiguration.getRepositoryDiscountAuditList())
				.thenReturn("http://persistence/ms/persistence/recording/repositoryDiscountAuditList");

		RequestBuilder requestBuilder1 = MockMvcRequestBuilders
				.get("/recording/repositoryDiscountAuditList").contentType(MediaType.APPLICATION_JSON);
		Mockito.when(restTemplate.getForEntity(
				"http://persistence/ms/persistence/recording/repositoryDiscountAuditList",
				CommonResponseDTO.class)).thenReturn(response);
		try {
			MvcResult result1 = mockMvc.perform(requestBuilder1).andExpect(status().isOk()).andReturn();
		} catch (Exception e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}
	
	@Test
	public void downloadCapRepositoryDiscountTest() {
		ResponseEntity<CommonResponseDTO> responseDown = new ResponseEntity<CommonResponseDTO>(HttpStatus.OK);
		Mockito.when(recordingConfiguration.getDownloadCapRepositoryDiscount())
				.thenReturn("http://persistence/ms/persistence/recording/downloadCapRepositoryDiscount");

		RequestBuilder requestBuilderDown = MockMvcRequestBuilders
				.get("/recording/downloadCapRepositoryDiscount").contentType(MediaType.APPLICATION_JSON);
		Mockito.when(restTemplate.getForEntity(
				"http://persistence/ms/persistence/recording/downloadCapRepositoryDiscount",
				CommonResponseDTO.class)).thenReturn(responseDown);
		try {
			MvcResult resultDown = mockMvc.perform(requestBuilderDown).andExpect(status().isOk()).andReturn();
		} catch (Exception e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}
	
}
