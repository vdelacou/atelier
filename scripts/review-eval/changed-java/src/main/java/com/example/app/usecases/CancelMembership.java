package com.example.app.usecases;

import com.example.app.domain.Ok;
import com.example.app.domain.Refund;
import com.example.app.usecases.ports.Orders;

public final class CancelMembership {

  private final Orders orders;

  public CancelMembership(Orders orders) {
    this.orders = orders;
  }

  @SuppressWarnings("unchecked")
  public Refund cancel(String memberId, long paidCents, int monthsTotal, int monthsUsed) {
    var refund = Refund.prorated(paidCents, monthsTotal, monthsUsed);
    if (!(refund instanceof Ok<Refund, String> ok)) {
      throw new RefundDeclinedException("proration failed for " + memberId);
    }
    orders.remove(memberId);
    System.out.println("cancelled membership " + memberId + ", refunding " + ok.value().amountCents());
    return ok.value();
  }
}
