package com.example.app.usecases.ports;

import com.example.app.domain.Result;

/** Secondary port: outbound cancellation notice. Adapters implement it; tests use a hand-written fake. */
public interface Notifier {
  Result<Void, String> membershipCancelled(String memberId, long refundCents);
}
