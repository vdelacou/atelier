package com.example.app.usecases.ports;

import com.example.app.domain.MemberId;
import com.example.app.domain.Refund;
import com.example.app.domain.Result;

/** Secondary port: outbound cancellation notice. Adapters implement it; tests use a hand-written fake. */
public interface Notifier {

  sealed interface NotifyError permits NotifyError.CrmUnreachable, NotifyError.CrmRejected {
    record CrmUnreachable(String detail) implements NotifyError {}

    record CrmRejected(int status) implements NotifyError {}
  }

  Result<Void, NotifyError> membershipCancelled(MemberId memberId, Refund refund);
}
