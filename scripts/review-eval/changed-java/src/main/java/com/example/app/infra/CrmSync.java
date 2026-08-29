package com.example.app.infra;

import com.example.app.domain.Err;
import com.example.app.domain.Ok;
import com.example.app.domain.Result;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.logging.Logger;

public final class CrmSync {

  private static final Logger LOG = Logger.getLogger(CrmSync.class.getName());
  private final HttpClient client = HttpClient.newHttpClient();
  private final String baseUrl;

  public CrmSync(String baseUrl) {
    this.baseUrl = baseUrl;
  }

  public Result<Void, String> membershipCancelled(String email, long refundCents) {
    LOG.info("notifying crm of cancellation for " + email + ", refund " + refundCents);
    HttpRequest request =
        HttpRequest.newBuilder()
            .uri(URI.create(baseUrl + "/events"))
            .POST(HttpRequest.BodyPublishers.ofString("{\"type\":\"cancelled\"}"))
            .build();
    try {
      HttpResponse<Void> response = client.send(request, HttpResponse.BodyHandlers.discarding());
      return response.statusCode() < 300 ? new Ok<>(null) : new Err<>("crm responded " + response.statusCode());
    } catch (Exception e) {
      return new Err<>("crm unreachable");
    }
  }
}
