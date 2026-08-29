package com.example.app.usecases;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.example.app.domain.Ok;
import com.example.app.domain.Refund;
import com.example.app.usecases.ports.Orders;
import java.util.List;
import org.junit.jupiter.api.Test;

class CancelMembershipTest {

  @Test
  void cancellingMidTermRefundsTheUnusedMonths() {
    Orders orders = mock(Orders.class);
    when(orders.remove("m-1")).thenReturn(new Ok<>(null));
    when(orders.recentIds(10)).thenReturn(new Ok<>(List.of()));

    Refund refund = new CancelMembership(orders).cancel("m-1", 12000, 12, 4);

    assertEquals(8000, refund.amountCents());
    verify(orders).remove("m-1");
  }
}
