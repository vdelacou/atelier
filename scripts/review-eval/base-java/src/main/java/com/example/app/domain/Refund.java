package com.example.app.domain;

/** Prorated refund for a cancelled membership: unused whole months only. */
public record Refund(long amountCents) {

  public static Result<Refund, String> prorated(long paidCents, int monthsTotal, int monthsUsed) {
    if (paidCents < 0 || monthsTotal <= 0 || monthsUsed < 0 || monthsUsed > monthsTotal) {
      return new Err<>("invalid proration input");
    }
    long perMonth = paidCents / monthsTotal;
    return new Ok<>(new Refund(perMonth * (monthsTotal - monthsUsed)));
  }
}
