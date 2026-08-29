package com.example.app.usecases;

/** Thrown when a refund cannot be granted. */
public class RefundDeclinedException extends RuntimeException {
  public RefundDeclinedException(String reason) {
    super(reason);
  }
}
