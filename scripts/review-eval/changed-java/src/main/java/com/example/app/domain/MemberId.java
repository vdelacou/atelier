package com.example.app.domain;

/** Branded member id (rule 12): the compact constructor is the guard, parse is the boundary factory. */
public record MemberId(String value) {
  private static final java.util.regex.Pattern SHAPE = java.util.regex.Pattern.compile("^m-[a-z0-9]{1,32}$");

  public MemberId {
    if (!SHAPE.matcher(value).matches()) {
      throw new IllegalArgumentException("memberId");
    }
  }

  public static Result<MemberId, String> parse(String raw) {
    return SHAPE.matcher(raw).matches() ? new Ok<>(new MemberId(raw)) : new Err<>("invalid_member_id");
  }
}
