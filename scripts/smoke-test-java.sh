#!/usr/bin/env bash
#
# End-to-end smoke test of the atelier skill's Java (Quarkus) variant.
#
# Scaffolds a throwaway Maven repo from the canonical pom.xml extracted out of
# references/java-quarkus.md (so doc drift fails CI, not just asset drift),
# lays the minimal atelier-style skeleton (sealed Result, a value record, one
# use-case with a hand-written fake), copies the shipped hook assets, then
# proves:
#
#   - every gate passes on a conforming tree, including a real hooked commit
#     through pre-commit-java (size, pom sanity, spotless, verify with the
#     JaCoCo tiers, PIT) and commit-msg
#   - every gate FAILS on the violation it exists to block: a version range,
#     a -SNAPSHOT dependency, an oversized commit, a junk commit message, a
#     misformatted file, a warning under -Werror, an untested domain class
#     (JaCoCo 100 tier), and a covered-but-unasserted method (PIT threshold)
#
# Scope: this proves OUR canonical config and shipped assets against the
# current JDK + Maven toolchain. It does not boot Quarkus (test the code you
# own; trust your dependencies), and ./mvnw in the fixture is a thin shim to
# the system mvn: the hook requires the wrapper's presence, but the wrapper
# distribution itself is not the surface under test.
#
# Run locally: bash scripts/smoke-test-java.sh   (needs JDK 21+, mvn, git)
# Run in CI:   .github/workflows/ci.yml
#
# Network access required for the first Maven plugin resolution.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILL="$REPO_ROOT/skills/atelier"
DOC="$SKILL/references/java-quarkus.md"
FX="$(mktemp -d "${TMPDIR:-/tmp}/atelier-smoke-java.XXXXXX")"
LOG="$FX/.step.log"
FAILURES=0

cleanup() { rm -rf "$FX"; }
trap cleanup EXIT

pass() { echo "  ok:   $1"; }
fail() { echo "  FAIL: $1"; FAILURES=$((FAILURES + 1)); }

expect_ok() {
  local desc="$1"; shift
  if "$@" >"$LOG" 2>&1; then pass "$desc"; else cat "$LOG"; fail "$desc"; fi
}

expect_err() {
  local desc="$1"; shift
  if "$@" >"$LOG" 2>&1; then cat "$LOG"; fail "$desc (expected non-zero exit)"; else pass "$desc"; fi
}

# Print the body of the first fenced code block that follows a markdown heading.
extract_fence() {
  local file="$1" heading="$2"
  awk -v h="$heading" '
    index($0, h) == 1 { found = 1; next }
    found && /^```/ { if (inblock) exit; inblock = 1; next }
    inblock { print }
  ' "$file"
}

command -v mvn >/dev/null 2>&1 || { echo "smoke-test-java: 'mvn' not on PATH" >&2; exit 1; }
command -v java >/dev/null 2>&1 || { echo "smoke-test-java: 'java' not on PATH" >&2; exit 1; }

echo "== scaffold fixture ($FX) =="
mkdir -p "$FX"/{scripts,.githooks,.mvn}
mkdir -p "$FX"/src/main/java/com/example/app/{domain,usecases/ports}
mkdir -p "$FX"/src/test/java/com/example/app/{domain,usecases}
cd "$FX"
git init -q
git config user.name "atelier-smoke"
git config user.email "atelier-smoke@users.noreply.github.com"

# --- shipped assets, per references/java-quarkus.md (Gates and hooks) ---
cp "$SKILL/assets/pre-commit-java" .githooks/pre-commit
cp "$SKILL/assets/commit-msg" .githooks/commit-msg
cp "$SKILL/assets/check-commit-size.sh" "$SKILL/assets/check-pom.sh" scripts/
chmod +x .githooks/pre-commit .githooks/commit-msg scripts/*.sh
git config core.hooksPath .githooks

# --- canonical configs, extracted from the reference doc ---
extract_fence "$DOC" '### Canonical `pom.xml`' > pom.xml
grep -q '<artifactId>app</artifactId>' pom.xml || { fail "extract canonical pom.xml from java-quarkus.md"; exit 1; }
extract_fence "$DOC" '`.mvn/jvm.config` (one line, committed):' > .mvn/jvm.config
grep -q 'add-exports' .mvn/jvm.config || { fail "extract .mvn/jvm.config from java-quarkus.md"; exit 1; }
pass "canonical pom.xml + .mvn/jvm.config extracted from references/java-quarkus.md"

# The hook requires the Maven wrapper; a shim to the system mvn keeps the
# fixture lean (the wrapper distribution is not the surface under test).
printf '#!/usr/bin/env bash\nexec mvn "$@"\n' > mvnw
chmod +x mvnw

printf 'target/\n' > .gitignore

# --- minimal atelier-style skeleton: sealed Result, a value record, a use-case ---
cat > src/main/java/com/example/app/domain/Result.java <<'EOF'
package com.example.app.domain;

public sealed interface Result<T, E> permits Ok, Err {}
EOF

cat > src/main/java/com/example/app/domain/Ok.java <<'EOF'
package com.example.app.domain;

public record Ok<T, E>(T value) implements Result<T, E> {}
EOF

cat > src/main/java/com/example/app/domain/Err.java <<'EOF'
package com.example.app.domain;

public record Err<T, E>(E error) implements Result<T, E> {}
EOF

cat > src/main/java/com/example/app/domain/Email.java <<'EOF'
package com.example.app.domain;

public record Email(String value) {
  public Email {
    if (!value.matches("^[^@\\s]+@[^@\\s]+$")) {
      throw new IllegalArgumentException("email");
    }
  }

  public static Result<Email, String> parse(String raw) {
    return raw.matches("^[^@\\s]+@[^@\\s]+$") ? new Ok<>(new Email(raw)) : new Err<>("invalid_email");
  }
}
EOF

cat > src/main/java/com/example/app/usecases/ports/UserStore.java <<'EOF'
package com.example.app.usecases.ports;

import com.example.app.domain.Email;
import com.example.app.domain.Result;

public interface UserStore {
  Result<Void, String> save(Email email);
}
EOF

cat > src/main/java/com/example/app/usecases/RegisterUser.java <<'EOF'
package com.example.app.usecases;

import com.example.app.domain.Email;
import com.example.app.domain.Err;
import com.example.app.domain.Ok;
import com.example.app.domain.Result;
import com.example.app.usecases.ports.UserStore;

public final class RegisterUser {
  private final UserStore store;

  public RegisterUser(UserStore store) {
    this.store = store;
  }

  public Result<Void, String> register(String raw) {
    return switch (Email.parse(raw)) {
      case Ok<Email, String>(var email) -> store.save(email);
      case Err<Email, String>(var e) -> new Err<>(e);
    };
  }
}
EOF

cat > src/test/java/com/example/app/domain/EmailTest.java <<'EOF'
package com.example.app.domain;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import org.junit.jupiter.api.Test;

class EmailTest {
  @Test
  void aWellFormedAddressParsesToItsValue() {
    assertEquals(new Ok<>(new Email("a@b.co")), Email.parse("a@b.co"));
  }

  @Test
  void aMalformedAddressParsesToInvalidEmail() {
    assertEquals(new Err<Email, String>("invalid_email"), Email.parse("not-an-email"));
  }

  @Test
  void constructingAMalformedAddressDirectlyIsABug() {
    assertThrows(IllegalArgumentException.class, () -> new Email("not-an-email"));
  }
}
EOF

cat > src/test/java/com/example/app/usecases/RegisterUserTest.java <<'EOF'
package com.example.app.usecases;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.example.app.domain.Email;
import com.example.app.domain.Err;
import com.example.app.domain.Ok;
import com.example.app.domain.Result;
import com.example.app.usecases.ports.UserStore;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.Test;

class RegisterUserTest {
  static final class MemoryUserStore implements UserStore {
    final List<Email> saved = new ArrayList<>();
    private final String failWith;

    MemoryUserStore() {
      this(null);
    }

    MemoryUserStore(String failWith) {
      this.failWith = failWith;
    }

    @Override
    public Result<Void, String> save(Email email) {
      if (failWith != null) {
        return new Err<>(failWith);
      }
      saved.add(email);
      return new Ok<>(null);
    }
  }

  @Test
  void aValidAddressIsRegisteredAndPersisted() {
    var store = new MemoryUserStore();
    assertEquals(new Ok<Void, String>(null), new RegisterUser(store).register("a@b.co"));
    assertEquals(List.of(new Email("a@b.co")), store.saved);
  }

  @Test
  void aMalformedAddressIsRefusedAndNothingIsPersisted() {
    var store = new MemoryUserStore();
    assertEquals(new Err<Void, String>("invalid_email"), new RegisterUser(store).register("nope"));
    assertTrue(store.saved.isEmpty());
  }

  @Test
  void aStoreFailureSurfacesAsTheUseCaseError() {
    var store = new MemoryUserStore("io");
    assertEquals(new Err<Void, String>("io"), new RegisterUser(store).register("a@b.co"));
  }
}
EOF

# Formatting is machine-owned: normalise the skeleton once, then check must hold.
expect_ok "spotless:apply normalises the skeleton" ./mvnw -q spotless:apply

echo
echo "== gates pass on a conforming tree =="
expect_ok "spotless:check (rule 8)" ./mvnw -q spotless:check
expect_ok "verify: -Werror compile, tests, JaCoCo tiers (rules 11, 15, coverage)" ./mvnw -q verify
expect_ok "PIT mutation >= 90 on domain+usecases (rule 14 analogue)" ./mvnw -q test-compile org.pitest:pitest-maven:mutationCoverage
expect_ok "check-pom.sh on the canonical pom (rule 19)" bash scripts/check-pom.sh
expect_ok "commit-msg accepts a Conventional Commit (rule 23)" \
  bash -c 'printf "feat(smoke): walking skeleton\n" > .msg && .githooks/commit-msg .msg'

# The initial scaffold exceeds the size gate by design; --no-verify on an
# initial scaffold is the one sanctioned bypass (workflow.md, Never bypass).
git add -A
git commit -q --no-verify -m "chore(smoke): initial scaffold (size-gate bypass: initial scaffold)"

# A real hooked commit: a small green slice through all six gates end to end.
cat > src/main/java/com/example/app/domain/Discount.java <<'EOF'
package com.example.app.domain;

public interface Discount {
  static int apply(int cents) {
    return cents * 80 / 100;
  }
}
EOF
cat > src/test/java/com/example/app/domain/DiscountTest.java <<'EOF'
package com.example.app.domain;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

class DiscountTest {
  @Test
  void aPremiumDiscountIsExactlyTwentyPercent() {
    assertEquals(80, Discount.apply(100));
  }
}
EOF
./mvnw -q spotless:apply >/dev/null 2>&1
git add src/main/java/com/example/app/domain/Discount.java src/test/java/com/example/app/domain/DiscountTest.java
expect_ok "a small conforming commit passes the full 6-gate hook + commit-msg" \
  git commit -q -m "feat(domain): premium discount rule"

echo
echo "== each gate blocks its target violation =="

# 1. check-pom.sh blocks a version range.
sed -i.bak 's|<junit.version>5.11.0</junit.version>|<junit.version>5.11.0</junit.version><!--x-->|' pom.xml && rm pom.xml.bak
sed -i.bak 's|<version>${junit.version}</version>|<version>[5.0,)</version>|' pom.xml && rm pom.xml.bak
expect_err "check-pom.sh blocks a version range" bash scripts/check-pom.sh
git checkout -q pom.xml

# 2. check-pom.sh blocks a -SNAPSHOT dependency.
sed -i.bak 's|<version>${junit.version}</version>|<version>5.11.0-SNAPSHOT</version>|' pom.xml && rm pom.xml.bak
expect_err "check-pom.sh blocks a -SNAPSHOT dependency" bash scripts/check-pom.sh
git checkout -q pom.xml

# 3. The size gate blocks an oversized staged change.
seq 1 301 | sed 's/^/line /' > oversized.txt
git add oversized.txt
expect_err "check-commit-size.sh blocks a 301-line staged change" bash scripts/check-commit-size.sh
git reset -q oversized.txt && rm oversized.txt

# 4. commit-msg rejects a junk message.
expect_err "commit-msg rejects a junk message" \
  bash -c 'printf "wip stuff\n" > .msg && .githooks/commit-msg .msg'
rm -f .msg

# 5. spotless:check fails on a misformatted file.
printf 'package com.example.app.domain;\n\npublic class Ugly{public static int x(){return 1;}}\n' \
  > src/main/java/com/example/app/domain/Ugly.java
expect_err "spotless:check blocks a misformatted file" ./mvnw -q spotless:check
rm src/main/java/com/example/app/domain/Ugly.java

# 6. -Werror blocks a compiler warning (rawtypes).
cat > src/main/java/com/example/app/domain/Raw.java <<'EOF'
package com.example.app.domain;

import java.util.ArrayList;
import java.util.List;

public interface Raw {
  static List warned() {
    return new ArrayList();
  }
}
EOF
expect_err "-Werror blocks a rawtypes warning (rule 15)" ./mvnw -q compile
rm src/main/java/com/example/app/domain/Raw.java

# 7. The JaCoCo 100 tier blocks an untested domain class.
cat > src/main/java/com/example/app/domain/Untested.java <<'EOF'
package com.example.app.domain;

public interface Untested {
  static int dead(int n) {
    return n + 1;
  }
}
EOF
expect_err "JaCoCo tier blocks an untested domain class" ./mvnw -q verify
rm src/main/java/com/example/app/domain/Untested.java

# 8. PIT blocks a covered-but-unasserted method (line coverage green, mutants survive).
cat > src/main/java/com/example/app/domain/Unasserted.java <<'EOF'
package com.example.app.domain;

public interface Unasserted {
  static int surcharge(int cents) {
    return cents * 105 / 100;
  }
}
EOF
cat > src/test/java/com/example/app/domain/UnassertedTest.java <<'EOF'
package com.example.app.domain;

import org.junit.jupiter.api.Test;

class UnassertedTest {
  @Test
  void coversWithoutAsserting() {
    var unused = Unasserted.surcharge(100);
  }
}
EOF
expect_err "PIT blocks surviving mutants behind green line coverage" \
  ./mvnw -q test-compile org.pitest:pitest-maven:mutationCoverage
rm src/main/java/com/example/app/domain/Unasserted.java src/test/java/com/example/app/domain/UnassertedTest.java

echo
if [ "$FAILURES" -gt 0 ]; then
  echo "smoke-test-java: $FAILURES check(s) failed"
  exit 1
fi
echo "smoke-test-java: all checks passed"
