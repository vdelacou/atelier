package com.example.app.domain;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import org.junit.jupiter.api.Test;

class MemberIdTest {

  @Test
  void aWellFormedMemberIdParses() {
    assertEquals(new Ok<MemberId, String>(new MemberId("m-42abc")), MemberId.parse("m-42abc"));
  }

  @Test
  void anIdWithoutTheMemberPrefixIsRefused() {
    assertEquals(new Err<MemberId, String>("invalid_member_id"), MemberId.parse("42abc"));
  }

  @Test
  void constructingAnInvalidIdDirectlyIsABug() {
    assertThrows(IllegalArgumentException.class, () -> new MemberId("nope"));
  }
}
