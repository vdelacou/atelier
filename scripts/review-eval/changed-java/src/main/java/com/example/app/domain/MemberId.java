package com.example.app.domain;

import java.util.regex.Pattern;

/** Branded member id (rule 12): the compact constructor is the guard, parse is the boundary factory. */
public record MemberId(String value) {
  private static final Pattern SHAPE = Pattern.compile("^m-[a-z0-9]{1,32}$");

  public MemberId {
    if (!SHAPE.matcher(value).matches()) {
      throw new IllegalArgumentException("memberId");
    }
  }

  public enum Error {
    MALFORMED
  }

  public static Result<MemberId, Error> parse(String raw) {
    return SHAPE.matcher(raw).matches() ? new Ok<>(new MemberId(raw)) : new Err<>(Error.MALFORMED);
  }
}
