package com.blueoptima.clients.ratelimit;

import org.apache.http.client.methods.HttpRequestBase;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.aspectj.lang.ProceedingJoinPoint;

public class RateLimitUtil {

  private static final Logger logger = LogManager.getLogger(RateLimitUtil.class);

  public static String getUrlEndPointForIndividualEndpointMonitoring(
      ProceedingJoinPoint joinPoint) {
    if (joinPoint == null || joinPoint.getArgs() == null || joinPoint.getArgs().length == 0) {
      return "NA";
    }
    try {
      String input = "NA";
      if (joinPoint.getArgs()[0] instanceof HttpRequestBase) {
        input = ((HttpRequestBase) joinPoint.getArgs()[0]).getURI().toString();

      } else if (joinPoint.getArgs()[0] instanceof String) {
        input = (joinPoint.getArgs()[0]).toString();
      }
      int questionMarkIndex = input.indexOf("?");
      if (questionMarkIndex != -1) {
        return input.substring(0, questionMarkIndex);
      }
      return input;
    } catch (Exception e) {
      logger.error("Error while getting url endpoint ", e);
      return "NA";
    }
  }


}
