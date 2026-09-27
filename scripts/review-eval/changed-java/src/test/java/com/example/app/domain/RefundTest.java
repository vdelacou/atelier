package com.example.app.domain;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

class RefundTest {

  @Test
  void aMemberWhoUsedFourOfTwelveMonthsGetsEightMonthsBack() {
    assertEquals(new Ok<Refund, Refund.Error>(new Refund(7000)), Refund.prorated(12000, 12, 4));
  }

  @Test
  void aFullyUsedMembershipRefundsNothing() {
    assertEquals(new Ok<Refund, Refund.Error>(new Refund(0)), Refund.prorated(12000, 12, 12));
  }

  @Test
  void negativeUsageIsRefusedAsInvalidInput() {
    assertEquals(new Err<Refund, Refund.Error>(Refund.Error.INVALID_INPUT), Refund.prorated(12000, 12, -1));
  }
}
