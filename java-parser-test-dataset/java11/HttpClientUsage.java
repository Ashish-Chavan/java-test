/**
 * Java 11 Feature: HttpClient API (JEP 321)
 * Standardized HTTP client supporting HTTP/1.1 and HTTP/2,
 * both synchronous and asynchronous request models.
 */
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.concurrent.CompletableFuture;

public class HttpClientUsage {

    public static void main(String[] args) throws Exception {

        // Build a reusable HttpClient
        HttpClient client = HttpClient.newBuilder()
            .version(HttpClient.Version.HTTP_2)
            .followRedirects(HttpClient.Redirect.NORMAL)
            .connectTimeout(Duration.ofSeconds(10))
            .build();

        // Build a GET request
        HttpRequest getRequest = HttpRequest.newBuilder()
            .uri(URI.create("https://httpbin.org/get"))
            .timeout(Duration.ofSeconds(15))
            .header("Accept", "application/json")
            .GET()
            .build();

        // Synchronous send
        HttpResponse<String> syncResponse = client.send(
            getRequest,
            HttpResponse.BodyHandlers.ofString()
        );
        System.out.println("Status: " + syncResponse.statusCode());
        System.out.println("Body length: " + syncResponse.body().length());

        // Build a POST request with a string body
        HttpRequest postRequest = HttpRequest.newBuilder()
            .uri(URI.create("https://httpbin.org/post"))
            .header("Content-Type", "application/json")
            .POST(HttpRequest.BodyPublishers.ofString("{\"key\": \"value\"}"))
            .build();

        // Asynchronous send returning CompletableFuture
        CompletableFuture<HttpResponse<String>> asyncFuture = client.sendAsync(
            postRequest,
            HttpResponse.BodyHandlers.ofString()
        );

        asyncFuture
            .thenApply(HttpResponse::statusCode)
            .thenAccept(status -> System.out.println("Async status: " + status))
            .join();

        // Discard body handler (when response body is not needed)
        HttpRequest headRequest = HttpRequest.newBuilder()
            .uri(URI.create("https://httpbin.org/status/200"))
            .build();

        HttpResponse<Void> discardResponse = client.send(
            headRequest,
            HttpResponse.BodyHandlers.discarding()
        );
        System.out.println("Discard response status: " + discardResponse.statusCode());
    }
}
