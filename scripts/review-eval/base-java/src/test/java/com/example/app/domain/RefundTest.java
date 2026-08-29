package com.example.app.domain;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

class RefundTest {

  @Test
  void aMemberWhoUsedFourOfTwelveMonthsGetsEightMonthsBack() {
    assertEquals(new Ok<Refund, String>(new Refund(8000)), Refund.prorated(12000, 12, 4));
  }

  @Test
  void aFullyUsedMembershipRefundsNothing() {
    assertEquals(new Ok<Refund, String>(new Refund(0)), Refund.prorated(12000, 12, 12));
  }

  @Test
  void negativeUsageIsRefusedAsInvalidInput() {
    assertEquals(new Err<Refund, String>("invalid proration input"), Refund.prorated(12000, 12, -1));
  }
}
