package com.example.app.usecases;

import com.example.app.domain.MemberId;
import com.example.app.domain.Ok;
import com.example.app.domain.Refund;
import com.example.app.usecases.ports.Orders;

public final class CancelMembership {

  private final Orders orders;

  public CancelMembership(Orders orders) {
    this.orders = orders;
  }

  @SuppressWarnings("unchecked")
  public Refund cancel(MemberId memberId, long paidCents, int monthsTotal, int monthsUsed) {
    var refund = Refund.prorated(paidCents, monthsTotal, monthsUsed);
    if (!(refund instanceof Ok<Refund, Refund.Error> ok)) {
      throw new RefundDeclinedException("proration failed for " + memberId.value());
    }
    orders.remove(memberId.value());
    System.out.println("cancelled membership " + memberId.value() + ", refunding " + ok.value().amountCents());
    return ok.value();
  }
}
