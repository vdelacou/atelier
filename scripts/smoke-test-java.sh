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
#   - every gate passes on a conforming tree: the fast pre-commit-java hook
#     (size, pom sanity, suppressions, gitleaks, identity, disciplines, spotless)
#     as a real hooked commit, plus the
#     CI gates (verify with the JaCoCo tiers, PIT) run directly, and commit-msg
#   - every gate FAILS on the violation it exists to block: a version range,
#     a -SNAPSHOT dependency, a mock library in the pom (hook and enforcer),
#     a suppression in three forms (PMD rule, inert NOPMD, the tripwire),
#     an oversized commit, a junk commit message, a
#     misformatted file, a warning under -Werror, a domain class importing a
#     use-case (ArchUnit, rule 37), a complexity-11 method (PMD), an order-
#     dependent test chain, an untested domain class (JaCoCo 100 tier), and a
#     covered-but-unasserted method (PIT threshold)
#
# Scope: this proves OUR canonical config and shipped assets against the
# current JDK + Maven toolchain. It does not boot Quarkus (test the code you
# own; trust your dependencies), but its last section builds the documented
# Quarkus delta on the real platform BOM, where two gates once broke. ./mvnw in
# the fixture is a thin shim to the system mvn: the hook requires the wrapper's
# presence, but the wrapper distribution itself is not the surface under test.
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

# Cleanup never decides the verdict: the checks do. A background `git gc --auto`
# (disabled below) or any late writer made rm report "Directory not empty", and
# with no explicit exit the trap's status became the script's (a green run exited 1).
cleanup() { rm -rf "$FX" 2>/dev/null || true; }
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
git config gc.auto 0   # no detached gc racing the cleanup
git config user.name "atelier-smoke"
git config user.email "atelier-smoke@users.noreply.github.com"

# --- shipped assets, per references/java-quarkus.md (Gates and hooks) ---
cp "$SKILL/assets/pre-commit-java" .githooks/pre-commit
cp "$SKILL/assets/commit-msg" .githooks/commit-msg
cp "$SKILL/assets/check-commit-size.sh" "$SKILL/assets/check-pom.sh" "$SKILL/assets/check-commit-messages.sh" "$SKILL/assets/check-commit-range.sh" "$SKILL/assets/pit-changed.sh" scripts/
cp "$SKILL/assets/check-pii-channels.sh" "$SKILL/assets/check-io-deadlines.sh" \
   "$SKILL/assets/check-data-lifecycle.sh" "$SKILL/assets/check-isolation-tests.sh" scripts/
cp "$SKILL/assets/check-no-suppressions.sh" "$SKILL/assets/check-identity.sh" "$SKILL/assets/check-disciplines.sh" scripts/
cp "$SKILL/assets/java/pmd-ruleset.xml" pmd-ruleset.xml
# The dependency rule as a test (rule 37): a shipped asset, copied as a real bootstrap does.
mkdir -p src/test/java/com/example/app/architecture
cp "$SKILL/assets/java/LayerRulesTest.java" src/test/java/com/example/app/architecture/
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
# The four invariant domain files are shipped assets, not hand-written here:
# copy them exactly as a real bootstrap does (java-quarkus.md, Bootstrap
# checklist), so this test exercises what ships. They already declare
# package com.example.app.domain, matching this fixture.
cp "$SKILL/assets/java/Result.java" "$SKILL/assets/java/Ok.java" \
   "$SKILL/assets/java/Err.java" "$SKILL/assets/java/Email.java" \
   src/main/java/com/example/app/domain/

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
      case Ok<Email, Email.Error>(var email) -> store.save(email);
      case Err<Email, Email.Error>(var e) -> new Err<>("invalid_email");
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
    assertEquals(new Err<Email, Email.Error>(Email.Error.MALFORMED), Email.parse("not-an-email"));
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

# Rule 36: the suite runs in a random order. The two orderers live in the test
# resources, as references/java-quarkus.md (Testing, Random order) writes them.
mkdir -p src/test/resources
cat > src/test/resources/junit-platform.properties <<'EOF'
junit.jupiter.testmethod.order.default=org.junit.jupiter.api.MethodOrderer$Random
junit.jupiter.testclass.order.default=org.junit.jupiter.api.ClassOrderer$Random
EOF

# Formatting is machine-owned: normalise the skeleton once, then check must hold.
expect_ok "spotless:apply normalises the skeleton" ./mvnw -q spotless:apply

echo
echo "== gates pass on a conforming tree =="
expect_ok "spotless:check (rule 8)" ./mvnw -q spotless:check
expect_ok "verify: -Werror compile, tests, JaCoCo tiers (rules 11, 15, coverage)" ./mvnw -q verify
expect_ok "the five ArchUnit rules ran green inside verify (rules 37 and 20)" \
  grep -q "Tests run: 5, Failures: 0, Errors: 0" target/surefire-reports/com.example.app.architecture.LayerRulesTest.txt

# Rule 36 proves it can fail: a three-step chain, each test reading the step
# the previous one left in a static field, is green in declaration order
# (MethodName order, forced on the command line, which overrides the properties
# file) and red under five of the six orders the random orderer can pick, so
# at least one of eight seeds shows it. Each seed is a full Maven run: the trap
# stops at its first red, the conforming green loop takes three seeds. A
# two-test pair is not enough: java.util.Random shuffles two elements the same
# way for many small seeds (found 2026-09-06).
cat > src/test/java/com/example/app/domain/OrderDependentTest.java <<'EOF'
package com.example.app.domain;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

class OrderDependentTest {
  private static int step = 0;

  @Test
  void aFirst() {
    step += 1;
    assertEquals(1, step);
  }

  @Test
  void bSecond() {
    step += 1;
    assertEquals(2, step);
  }

  @Test
  void cThird() {
    step += 1;
    assertEquals(3, step);
  }
}
EOF
expect_ok "an order-dependent chain passes in declaration order (the trap is real)" \
  ./mvnw -q test -Dtest=OrderDependentTest '-Djunit.jupiter.testmethod.order.default=org.junit.jupiter.api.MethodOrderer$MethodName'
expect_ok "random order exposes the order-dependent chain under at least one of eight seeds (rule 36)" \
  bash -c 'for s in 1 2 3 4 5 6 7 8; do ./mvnw -q test -Dtest=OrderDependentTest -Djunit.jupiter.execution.order.random.seed=$s >/dev/null 2>&1 || exit 0; done; exit 1'
rm src/test/java/com/example/app/domain/OrderDependentTest.java
expect_ok "the conforming suite is green under three seeds of the random orderer" \
  bash -c 'for s in 1 2 3; do ./mvnw -q test -Djunit.jupiter.execution.order.random.seed=$s >/dev/null 2>&1 || exit 1; done'
expect_ok "PIT mutation >= 90 on domain+usecases (rule 14 analogue)" ./mvnw -q test-compile org.pitest:pitest-maven:mutationCoverage
expect_ok "check-pom.sh on the canonical pom (rule 19)" bash scripts/check-pom.sh
expect_ok "check-no-suppressions.sh --all on the clean tree (rule 15)" bash scripts/check-no-suppressions.sh --all
expect_ok "commit-msg accepts a Conventional Commit (rule 23)" \
  bash -c 'printf "feat(smoke): walking skeleton\n" > .msg && .githooks/commit-msg .msg'

# The initial scaffold exceeds the size gate by design; --no-verify on an
# initial scaffold is the one sanctioned bypass (workflow.md, Never bypass).
git add -A
git commit -q --no-verify -m "chore(smoke): initial scaffold (size-gate bypass: initial scaffold)"

# A real hooked commit: a small green slice through the fast hook end to end.
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
expect_ok "a small conforming commit passes the fast pre-commit hook + commit-msg" \
  git commit -q -m "feat(domain): premium discount rule"
expect_ok "check-commit-messages.sh passes on a conventional history" \
  bash scripts/check-commit-messages.sh

# The mutation cadence (2026-09-03): CI mutates the changed classes only, on
# every event, resolving the range the way the commit gates do; the full sweep
# is the scheduled mutation-java.yml. The narrowed run proves the pom's
# `${pitest.targetClasses}` property takes a comma-separated override.
expect_ok "pit-changed.sh on a push resolves github.event.before..HEAD and runs PIT on the changed class" \
  bash -c 'env -u BASE -u GITHUB_BASE_REF GITHUB_EVENT_NAME=push GITHUB_EVENT_BEFORE="$(git rev-parse HEAD~1)" bash scripts/pit-changed.sh > pit-changed.out 2>&1'
expect_ok "pit-changed.sh targeted exactly the committed domain class" \
  grep -q "targeting 1 class(es): com.example.app.domain.Discount" pit-changed.out
expect_err "pit-changed.sh fails loudly when the base ref does not resolve" \
  env BASE=no-such-ref bash scripts/pit-changed.sh
expect_ok "pit-changed.sh exits 0 with a message when nothing in scope changed" \
  bash -c 'BASE=HEAD bash scripts/pit-changed.sh | grep -q "no classes in mutation scope changed"'
expect_ok "ci-java.yml mutates the changed classes only, never the full sweep" \
  bash -c 'grep -q "pit-changed.sh" "$1" && ! grep -q "pitest-maven:mutationCoverage" "$1"' _ "$SKILL/assets/ci-java.yml"
# JUnit logs its random-order seed below INFO, so no run printed one until the workflow
# picked, printed and passed it (2026-09-27); the seeds above prove the flag replays.
expect_ok "ci-java.yml prints the JUnit seed and passes it to verify (rule 36)" \
  bash -c 'grep -q "junit random-order seed" "$1" && grep -q "verify -Djunit.jupiter.execution.order.random.seed=" "$1"' _ "$SKILL/assets/ci-java.yml"
expect_ok "mutation-java.yml is the scheduled full sweep" \
  bash -c 'grep -q "schedule:" "$1" && grep -q "pitest-maven:mutationCoverage" "$1" && ! grep -q "pull_request" "$1"' _ "$SKILL/assets/mutation-java.yml"

echo
echo "== each gate blocks its target violation =="

# 1. check-pom.sh blocks a version range.
sed -i.bak 's|<version>${junit.version}</version>|<version>[5.0,)</version>|' pom.xml && rm pom.xml.bak
expect_err "check-pom.sh blocks a version range" bash scripts/check-pom.sh
git checkout -q pom.xml

# 1b. The canonical pom keeps every pin in a property, and a range there passed both
# gates until 2026-09-27 (junit resolved to 6.1.3). check-pom.sh reads version
# properties now, and the enforcer's banDynamicVersions rejects it on its own message.
sed -i.bak 's|<junit.version>5.14.4</junit.version>|<junit.version>[5.14,)</junit.version>|' pom.xml && rm pom.xml.bak
expect_err "check-pom.sh blocks a range held in a version property" bash scripts/check-pom.sh
if ./mvnw -q validate >"$LOG" 2>&1; then cat "$LOG"; fail "enforcer banDynamicVersions rejects a property range (expected non-zero exit)"
elif grep -q "banned dynamic version" "$LOG"; then pass "enforcer banDynamicVersions rejects a range held in a version property"
else cat "$LOG"; fail "enforcer: validate failed, but not on banDynamicVersions"; fi
git checkout -q pom.xml

# 2. check-pom.sh blocks a -SNAPSHOT dependency.
sed -i.bak 's|<version>${junit.version}</version>|<version>5.11.0-SNAPSHOT</version>|' pom.xml && rm pom.xml.bak
expect_err "check-pom.sh blocks a -SNAPSHOT dependency" bash scripts/check-pom.sh
git checkout -q pom.xml

# 2b. Rule 13: a mock library in the pom. check-pom.sh rejects the declaration in
# the fast hook; the enforcer's bannedDependencies rejects it (and any transitive
# route) in every mvn run, on its own message, so a red for another reason is not
# proof. The clean pom was green through verify above.
python3 - <<'PYEOF2'
import pathlib
p = pathlib.Path('pom.xml')
p.write_text(p.read_text().replace('\n  <dependencies>\n', '\n  <dependencies>\n    <dependency>\n      <groupId>org.mockito</groupId>\n      <artifactId>mockito-core</artifactId>\n      <version>5.20.0</version>\n      <scope>test</scope>\n    </dependency>\n', 1))
PYEOF2
expect_err "check-pom.sh blocks a mock library in the pom (rule 13)" bash scripts/check-pom.sh
if ./mvnw -q validate >"$LOG" 2>&1; then cat "$LOG"; fail "enforcer bannedDependencies rejects mockito-core (rule 13) (expected non-zero exit)"
elif grep -q "(rule 13)" "$LOG"; then pass "enforcer bannedDependencies rejects mockito-core (rule 13)"
else cat "$LOG"; fail "enforcer: validate failed, but not on the rule 13 ban"; fi
git checkout -q pom.xml
# Quarkus renamed its Mockito extension quarkus-junit-mockito (3.37 and later ship
# both names), and JMock is a mock library too; the fast gate knew neither until
# 2026-09-27.
for coord in 'io.quarkus:quarkus-junit-mockito' 'org.jmock:jmock-junit5'; do
  g="${coord%%:*}" a="${coord##*:}"
  python3 - "$g" "$a" <<'PYEOF2'
import pathlib, sys
g, a = sys.argv[1], sys.argv[2]
p = pathlib.Path('pom.xml')
p.write_text(p.read_text().replace('\n  <dependencies>\n', f'\n  <dependencies>\n    <dependency>\n      <groupId>{g}</groupId>\n      <artifactId>{a}</artifactId>\n      <version>1.0.0</version>\n      <scope>test</scope>\n    </dependency>\n', 1))
PYEOF2
  expect_err "check-pom.sh blocks $a (rule 13)" bash scripts/check-pom.sh
  git checkout -q pom.xml
done

# 2c. No test run is a red build: with no tests JaCoCo skips its check and the tiers
# passed vacuously until 2026-09-27 (a new module, a deleted test tree).
mv src/test "$FX/test.off"
rm -rf target/test-classes   # the compiled tests would still run from here
if ./mvnw -q verify >"$LOG" 2>&1; then cat "$LOG"; fail "verify fails when no test runs (expected non-zero exit)"
elif grep -q "No tests to run" "$LOG"; then pass "verify fails when no test runs (failIfNoTests; JaCoCo would skip)"
else cat "$LOG"; fail "verify failed with no tests, but not on failIfNoTests"; fi
mv "$FX/test.off" src/test

# 3. The size gate blocks an oversized staged change.
seq 1 301 | sed 's/^/line /' > oversized.txt
git add oversized.txt
expect_err "check-commit-size.sh blocks a 301-line staged change" bash scripts/check-commit-size.sh
git reset -q oversized.txt && rm oversized.txt

# 4. commit-msg rejects a junk message.
expect_err "commit-msg rejects a junk message" \
  bash -c 'printf "wip stuff\n" > .msg && .githooks/commit-msg .msg'
rm -f .msg

# 4b. check-commit-messages.sh catches what --no-verify let through.
git commit -q --no-verify --allow-empty -m "wip stuff"
expect_err "check-commit-messages.sh catches a --no-verify bypass" \
  bash scripts/check-commit-messages.sh
# On a push to main HEAD == origin/main, so the old default range was empty and
# the gate passed vacuously; the shipped workflow now exports github.event.before.
git update-ref refs/remotes/origin/main HEAD
expect_err "check-commit-messages.sh still catches the bypass on a push where origin/main == HEAD" \
  env -u GITHUB_BASE_REF GITHUB_EVENT_NAME=push bash scripts/check-commit-messages.sh
git update-ref -d refs/remotes/origin/main
git reset -q --soft HEAD~1

# 4c. check-commit-range.sh: the CI half of the commit-size gate (canon 8.1).
expect_ok "check-commit-range.sh selftest (the gate proves itself)" \
  bash scripts/check-commit-range.sh --selftest
expect_ok "check-commit-range.sh passes on small commits" \
  bash scripts/check-commit-range.sh HEAD~1 HEAD
python3 - <<'PYEOF2'
import pathlib
for i in range(12):
    pathlib.Path(f'oversized{i}.txt').write_text('x\n' * 40)
PYEOF2
git add oversized*.txt
git commit -q --no-verify -m 'chore: oversized commit that bypassed the hook'
expect_err "check-commit-range.sh catches an oversized commit in the range" \
  bash scripts/check-commit-range.sh HEAD~1 HEAD
git reset -q --mixed HEAD~1   # keeps every other untracked file the later scenarios need
rm -f oversized*.txt

# 4c. Rule 26 (2026-09-09): the identity guard is hook gate 5 in this variant. A Java
# file naming the committer is red standalone and through the hook, with the rule
# number; the scaffold under its one-word git name passes --all.
git config user.name 'Ada Lovelace'
cat > src/main/java/com/example/app/domain/Credit.java <<'EOF'
package com.example.app.domain;

// Reviewed by Ada Lovelace
public interface Credit {
  static int apply(int cents) {
    return cents;
  }
}
EOF
git add src/main/java/com/example/app/domain/Credit.java
expect_err "identity guard blocks a Java comment naming the committer (rule 26)" bash scripts/check-identity.sh
if bash .githooks/pre-commit >"$LOG" 2>&1; then cat "$LOG"; fail "the Java hook accepted a file naming the committer (rule 26)"
elif grep -q 'hard rule 26' "$LOG"; then pass "the Java hook stops on the identity gate (rule 26)"
else cat "$LOG"; fail "the Java hook failed, but not on the identity gate"; fi
git reset -q -- src/main/java/com/example/app/domain/Credit.java && rm src/main/java/com/example/app/domain/Credit.java
git config user.name 'atelier-smoke'
expect_ok "identity guard passes the scaffold under a one-word git name with --all (rule 26)" bash scripts/check-identity.sh --all

# 4d. The four discipline tripwires on their JAVA triggers (rules 27-30). All
# four ship Java detection (@QueryParam, HttpClient, hard delete, api/ routes),
# so the Java variant gets them proven the same way the Bun smoke proves the
# TypeScript side: each guard red on its violation, green once fixed.
mkdir -p src/main/java/com/example/app/{api,infra} src/test/java/com/example/app/api

cat > src/main/java/com/example/app/api/LookupResource.java <<'EOF'
package com.example.app.api;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.QueryParam;

public class LookupResource {
  @GET
  public String find(@QueryParam("email") String email) {
    return email;
  }
}
EOF
git add src/main/java/com/example/app/api/LookupResource.java
expect_err "pii guard blocks a Java @QueryParam(\"email\")" bash scripts/check-pii-channels.sh
# Since 2026-09-10 the three safe guards are hook gate 6 through check-disciplines.sh.
if bash .githooks/pre-commit >"$LOG" 2>&1; then cat "$LOG"; fail "the Java hook accepted a @QueryParam(\"email\") (rule 27)"
elif grep -q "rule 27" "$LOG"; then pass "the Java hook stops on the discipline tripwires (rule 27)"
else cat "$LOG"; fail "the Java hook failed, but not on the discipline tripwires"; fi
git rm -q --cached src/main/java/com/example/app/api/LookupResource.java
rm src/main/java/com/example/app/api/LookupResource.java

cat > src/main/java/com/example/app/infra/CrmClient.java <<'EOF'
package com.example.app.infra;

import java.net.http.HttpClient;

public final class CrmClient {
  private final HttpClient client = HttpClient.newBuilder().build();

  public HttpClient client() {
    return client;
  }
}
EOF
git add src/main/java/com/example/app/infra/CrmClient.java
expect_err "deadline guard blocks a Java HttpClient with no timeout" bash scripts/check-io-deadlines.sh
python3 - <<'PYEOF2'
import pathlib
p = pathlib.Path('src/main/java/com/example/app/infra/CrmClient.java')
p.write_text(p.read_text().replace(
    'HttpClient.newBuilder().build()',
    'HttpClient.newBuilder().connectTimeout(java.time.Duration.ofSeconds(2)).build()'))
PYEOF2
git add src/main/java/com/example/app/infra/CrmClient.java
expect_ok "deadline guard passes once the Java client has connectTimeout" bash scripts/check-io-deadlines.sh
git rm -q --cached src/main/java/com/example/app/infra/CrmClient.java
rm src/main/java/com/example/app/infra/CrmClient.java

cat > src/main/java/com/example/app/infra/OrderRepo.java <<'EOF'
package com.example.app.infra;

public final class OrderRepo {
  public void purge(String id) {
    db.deleteById(id);
  }
}
EOF
git add src/main/java/com/example/app/infra/OrderRepo.java
expect_err "lifecycle guard blocks a Java hard delete" bash scripts/check-data-lifecycle.sh
git rm -q --cached src/main/java/com/example/app/infra/OrderRepo.java
rm src/main/java/com/example/app/infra/OrderRepo.java

cat > src/main/java/com/example/app/api/InvoiceResource.java <<'EOF'
package com.example.app.api;

import jakarta.ws.rs.GET;

public class InvoiceResource {
  @GET
  public String get() {
    return "invoice";
  }
}
EOF
git add src/main/java/com/example/app/api/InvoiceResource.java
expect_err "isolation guard blocks a Java resource with no 404 test" bash scripts/check-isolation-tests.sh
# A 404 that lives only in a comment used to satisfy the guard (2026-09-02).
cat > src/test/java/com/example/app/api/InvoiceResourceTest.java <<'EOF'
package com.example.app.api;

import org.junit.jupiter.api.Test;

class InvoiceResourceTest {
  @Test
  void crossTenantReadIsNotFound() {
    // another owner's invoice must look absent: 404, never 403
  }
}
EOF
git add src/test/java/com/example/app/api/InvoiceResourceTest.java
expect_err "isolation guard ignores a Java 404 that lives only in a comment" bash scripts/check-isolation-tests.sh
cat > src/test/java/com/example/app/api/InvoiceResourceTest.java <<'EOF'
package com.example.app.api;

import static io.restassured.RestAssured.given;

import org.junit.jupiter.api.Test;

class InvoiceResourceTest {
  @Test
  void crossTenantReadIsNotFound() {
    given().auth().oauth2(ownerAToken).when().get("/invoices/" + ownerBInvoice).then().statusCode(404);
  }
}
EOF
git add src/test/java/com/example/app/api/InvoiceResourceTest.java
expect_ok "isolation guard passes once the Java 404 test is staged" bash scripts/check-isolation-tests.sh
git reset -q
rm -rf src/main/java/com/example/app/api src/test/java/com/example/app/api

# 5. spotless:check fails on a misformatted file.
printf 'package com.example.app.domain;\n\npublic class Ugly{public static int x(){return 1;}}\n' \
  > src/main/java/com/example/app/domain/Ugly.java
expect_err "spotless:check blocks a misformatted file" ./mvnw -q spotless:check
rm src/main/java/com/example/app/domain/Ugly.java

# 5b. "No wildcard imports" is a check since 2026-09-27 (Spotless forbidWildcardImports);
# google-java-format alone keeps a wildcard, so this file is otherwise well formatted.
printf 'package com.example.app.domain;\n\nimport java.util.*;\n\npublic final class Wild {\n  private Wild() {}\n\n  public static List<String> none() {\n    return new ArrayList<>();\n  }\n}\n' \
  > src/main/java/com/example/app/domain/Wild.java
if ./mvnw -q spotless:check >"$LOG" 2>&1; then cat "$LOG"; fail "spotless:check blocks a wildcard import (expected non-zero exit)"
elif grep -q "WildcardImports" "$LOG"; then pass "spotless:check blocks a wildcard import (forbidWildcardImports)"
else cat "$LOG"; fail "spotless:check failed, but not on forbidWildcardImports"; fi
rm src/main/java/com/example/app/domain/Wild.java

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

# 6a. Rule 37: the dependency rule as a test. A domain class that imports a
# use-case compiles (javac knows no layers) and fails LayerRulesTest on the
# first `mvn test`; the log must carry the violation, so a red for another
# reason is not proof.
cat > src/main/java/com/example/app/domain/Leaky.java <<'EOF'
package com.example.app.domain;

import com.example.app.usecases.RegisterUser;

public final class Leaky {
  private Leaky() {}

  public static Class<?> peek() {
    return RegisterUser.class;
  }
}
EOF
if ./mvnw -q test >"$LOG" 2>&1; then cat "$LOG"; fail "LayerRulesTest rejects a domain class importing a use-case (rule 37) (expected non-zero exit)"
elif grep -q "Architecture Violation" "$LOG"; then pass "LayerRulesTest rejects a domain class importing a use-case (rule 37)"
else cat "$LOG"; fail "LayerRulesTest: mvn test failed, but not on an Architecture Violation"; fi
rm src/main/java/com/example/app/domain/Leaky.java
# 6a-bis. Rule 20 (2026-09-19): file IO stays at the edges. A domain class reading the
# disk through java.nio.file compiles and fails LayerRulesTest; the same import in infra
# is the sanctioned place and stays green (proven in the conforming pass above, where
# the five rules run over the skeleton).
cat > src/main/java/com/example/app/domain/DiskReader.java <<'EOF'
package com.example.app.domain;

import java.nio.file.Files;
import java.nio.file.Path;

public final class DiskReader {
  private DiskReader() {}

  public static boolean present(String p) {
    return Files.exists(Path.of(p));
  }
}
EOF
if ./mvnw -q test >"$LOG" 2>&1; then cat "$LOG"; fail "LayerRulesTest rejects a domain class reading the disk (rule 20) (expected non-zero exit)"
elif grep -q "Architecture Violation" "$LOG"; then pass "LayerRulesTest rejects a domain class reading the disk through java.nio.file (rule 20)"
else cat "$LOG"; fail "LayerRulesTest: mvn test failed, but not on an Architecture Violation"; fi
rm src/main/java/com/example/app/domain/DiskReader.java

# 6b. Rule 35: PMD blocks a method of cyclomatic complexity 11 (ten guards)
# and passes complexity 10 (nine), pinning the boundary. pmd:check alone, so
# the JaCoCo tier does not also fail on the untested planted class.
gen_guards() { { echo 'package com.example.app.domain;'; echo ''; echo 'public final class Branchy {'; echo '  private Branchy() {}'; echo ''; echo '  public static int score(int[] v) {'; local i=1; while [ "$i" -le "$1" ]; do echo "    if (v[$i] > $i) return $i;"; i=$((i + 1)); done; echo '    return 0;'; echo '  }'; echo '}'; } > src/main/java/com/example/app/domain/Branchy.java; }
gen_guards 10
expect_err "PMD blocks a method of cyclomatic complexity 11 (rule 35)" ./mvnw -q pmd:check
gen_guards 9
expect_ok "PMD accepts complexity 10, the cap itself" ./mvnw -q pmd:check
rm src/main/java/com/example/app/domain/Branchy.java

# 6b-bis. Rule 4 (2026-09-19): PMD's SystemPrintln and our NoPrintStackTrace XPath rule,
# both named in target/pmd.xml so a red for another reason is not proof. AvoidPrintStackTrace,
# PMD's own, stays silent on 7.17 and is not shipped.
cat > src/main/java/com/example/app/domain/Shouty.java <<'EOF'
package com.example.app.domain;

public final class Shouty {
  private Shouty() {}

  public static int parse(String s) {
    try {
      return Integer.parseInt(s);
    } catch (NumberFormatException e) {
      e.printStackTrace();
      System.err.println(s);
      return 0;
    }
  }
}
EOF
expect_err "PMD blocks System.err and printStackTrace (rule 4)" ./mvnw -q pmd:check
expect_ok "the PMD violations are SystemPrintln and NoPrintStackTrace, not a bystander" \
  bash -c 'grep -q "rule=\"SystemPrintln\"" target/pmd.xml && grep -q "rule=\"NoPrintStackTrace\"" target/pmd.xml'
rm src/main/java/com/example/app/domain/Shouty.java

# 6c. Rule 15, the Java half (2026-09-08), three layers each proven red. The PMD rule
# flags @SuppressWarnings in verify (the rule name lands in target/pmd.xml; -q hides
# it from the console). The impossible suppressMarker makes // NOPMD inert, so a
# complexity-11 method behind it is red. The tripwire catches the forms PMD cannot,
# @SuppressWarnings("PMD") first among them, and NOSONAR, on the staged lines.
cat > src/main/java/com/example/app/domain/Quiet.java <<'EOF'
package com.example.app.domain;

public final class Quiet {
  private Quiet() {}

  @SuppressWarnings("unchecked")
  public static int one() {
    return 1;
  }
}
EOF
expect_err "PMD blocks @SuppressWarnings (rule 15)" ./mvnw -q pmd:check
expect_ok "the PMD violation is the NoSuppressWarnings rule, not a bystander" grep -q 'rule="NoSuppressWarnings"' target/pmd.xml
rm src/main/java/com/example/app/domain/Quiet.java
gen_guards 10
sed -i.bak 's|public static int score(int\[\] v) {|public static int score(int[] v) { // NOPMD|' src/main/java/com/example/app/domain/Branchy.java && rm src/main/java/com/example/app/domain/Branchy.java.bak
grep -q "NOPMD" src/main/java/com/example/app/domain/Branchy.java || { fail "fixture: the NOPMD marker was not planted"; }
expect_err "a // NOPMD comment is inert: complexity 11 behind it is still red (rule 15)" ./mvnw -q pmd:check
rm src/main/java/com/example/app/domain/Branchy.java
cat > src/main/java/com/example/app/domain/Quiet.java <<'EOF'
package com.example.app.domain;

@SuppressWarnings("PMD")
public final class Quiet {
  private Quiet() {}
}
EOF
git add src/main/java/com/example/app/domain/Quiet.java
expect_err "check-no-suppressions.sh blocks a staged @SuppressWarnings(\"PMD\"), the form PMD cannot see (rule 15)" bash scripts/check-no-suppressions.sh
cat > src/main/java/com/example/app/domain/Quiet.java <<'EOF'
package com.example.app.domain;

public final class Quiet {
  private Quiet() {}

  public static int one() {
    return 1; // NOSONAR
  }
}
EOF
git add src/main/java/com/example/app/domain/Quiet.java
expect_err "check-no-suppressions.sh blocks a staged NOSONAR (rule 15)" bash scripts/check-no-suppressions.sh
git rm -q --cached src/main/java/com/example/app/domain/Quiet.java
rm src/main/java/com/example/app/domain/Quiet.java


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
# The narrowed run sees the same violation: the new class is untracked, so it
# is in pit-changed.sh's scope, and PIT on that one class alone is red.
expect_err "pit-changed.sh catches the surviving mutants in an untracked new class" \
  bash -c 'BASE=HEAD bash scripts/pit-changed.sh'
rm src/main/java/com/example/app/domain/Unasserted.java src/test/java/com/example/app/domain/UnassertedTest.java

# Logic in a nested class is in scope: pit-changed.sh targeted the outer class alone
# until 2026-09-27, so this weak test scored 100 (1 mutant) where Pricing$* scores 33.
cat > src/main/java/com/example/app/domain/Pricing.java <<'EOF'
package com.example.app.domain;

public final class Pricing {
  private Pricing() {}

  public static int total(int cents) {
    return Rules.discount(cents);
  }

  static final class Rules {
    private Rules() {}

    static int discount(int cents) {
      if (cents > 1000) {
        return cents - 100;
      }
      return cents;
    }
  }
}
EOF
cat > src/test/java/com/example/app/domain/PricingTest.java <<'EOF'
package com.example.app.domain;

import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class PricingTest {
  @Test
  void totalsArePositive() {
    assertTrue(Pricing.total(2000) > 0);
  }
}
EOF
expect_ok "pit-changed.sh mutates a changed class's nested classes too (red on the threshold)" \
  bash -c 'BASE=HEAD bash scripts/pit-changed.sh > pit-nested.out 2>&1; st=$?; grep -q "Pricing\$\*" pit-nested.out && grep -q "below threshold" pit-nested.out && [ "$st" -ne 0 ]'
rm -f src/main/java/com/example/app/domain/Pricing.java src/test/java/com/example/app/domain/PricingTest.java pit-nested.out

# A module's sources need PIT in that module: the root run passed them as "nothing
# changed" until 2026-09-27; it now refuses loudly.
mkdir -p svc/src/main/java/com/example/app/domain
printf 'package com.example.app.domain;\n\npublic final class Tax {\n  private Tax() {}\n}\n' > svc/src/main/java/com/example/app/domain/Tax.java
expect_ok "pit-changed.sh refuses a module's changed classes instead of passing them" \
  bash -c 'BASE=HEAD bash scripts/pit-changed.sh > pit-module.out 2>&1; st=$?; grep -q "live in a module" pit-module.out && [ "$st" -ne 0 ]'
rm -rf svc pit-module.out

echo "== the Quarkus delta (java-quarkus.md, The Quarkus delta) =="
# The fixture above is framework-free. A real service imports the Quarkus BOM,
# and two gates of the canonical pom broke on it until 2026-09-27: the BOM's
# own tree fails requireUpperBoundDeps (jctools on 3.39.5), and the MicroProfile
# Config API behind @ConfigProperty trips -Xlint:classfile under -Werror. This
# builds a second tree from the extracted canonical pom plus the documented
# delta, proves both failures on the pre-fix shape, then the delta green.
QFX="$FX/quarkus"
mkdir -p "$QFX"/src/main/java/com/example/app/{domain,usecases,infra} \
         "$QFX"/src/test/java/com/example/app/{usecases,architecture}
cp "$SKILL/assets/java/Result.java" "$SKILL/assets/java/Ok.java" \
   "$SKILL/assets/java/Err.java" "$SKILL/assets/java/Email.java" "$QFX/src/main/java/com/example/app/domain/"
cp "$SKILL/assets/java/LayerRulesTest.java" "$QFX/src/test/java/com/example/app/architecture/"
cat > "$QFX/src/main/java/com/example/app/infra/Greeting.java" <<'EOF'
package com.example.app.infra;

import jakarta.enterprise.context.ApplicationScoped;
import org.eclipse.microprofile.config.inject.ConfigProperty;

@ApplicationScoped
public class Greeting {
  private final String name;

  Greeting(@ConfigProperty(name = "greeting.name", defaultValue = "world") String name) {
    this.name = name;
  }

  public String text() {
    return "hello " + name;
  }
}
EOF
cat > "$QFX/src/main/java/com/example/app/usecases/Normalize.java" <<'EOF'
package com.example.app.usecases;

public final class Normalize {
  private Normalize() {}

  public static String trim(String raw) {
    return raw.strip();
  }
}
EOF
cat > "$QFX/src/test/java/com/example/app/usecases/NormalizeTest.java" <<'EOF'
package com.example.app.usecases;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

class NormalizeTest {
  @Test
  void trimsSurroundingSpace() {
    assertEquals("a", Normalize.trim(" a "));
  }
}
EOF
extract_fence "$DOC" '### The Quarkus delta' > "$QFX/delta.xml"
extract_fence "$DOC" '### Canonical `pom.xml`' > "$QFX/canonical.xml"
# Apply the delta's three labelled fragments to the canonical pom; $1 = full
# (both edits) or bom-only (the pre-fix shape: BOM in, the two edits not made).
quarkus_pom() {
  python3 - "$QFX/canonical.xml" "$QFX/delta.xml" "$1" > "$QFX/pom.xml" <<'PYEOF2'
import re, sys
pom, delta, mode = open(sys.argv[1]).read(), open(sys.argv[2]).read(), sys.argv[3]
parts = re.split(r'^<!--.*-->\n', delta, flags=re.M)
prop, dm, ext = (p.rstrip('\n') for p in parts[1:4])
indent = lambda s, n: '\n'.join((' ' * n + l) if l else l for l in s.split('\n'))
pom = pom.replace('  </properties>\n', indent(prop, 4) + '\n  </properties>\n\n' + indent(dm, 2) + '\n', 1)
pom = pom.replace('  <dependencies>\n    <dependency>\n      <groupId>org.junit.jupiter</groupId>',
                  '  <dependencies>\n' + indent(ext, 4) + '\n    <dependency>\n      <groupId>org.junit.jupiter</groupId>', 1)
if mode == 'full':
    pom = pom.replace('                <requireUpperBoundDeps />\n', '', 1)
    pom = pom.replace('      <artifactId>junit-jupiter</artifactId>\n      <version>${junit.version}</version>\n',
                      '      <artifactId>junit-jupiter</artifactId>\n', 1)
    pom = re.sub(r'    <junit\.version>[^<]*</junit\.version>\n', '', pom, count=1)
print(pom, end='')
PYEOF2
}
cd "$QFX"
expect_ok "the delta's fragments are in the reference (property, BOM import, extensions)" \
  bash -c 'grep -q "quarkus.platform.version" delta.xml && grep -q "<scope>import</scope>" delta.xml && grep -q "quarkus-rest" delta.xml'
quarkus_pom bom-only
expect_ok "the BOM without the delta fails validate on requireUpperBoundDeps (the pre-fix shape)" \
  bash -c 'mvn -B -q validate > q.log 2>&1; st=$?; grep -q "RequireUpperBoundDeps" q.log && [ "$st" -ne 0 ]'
quarkus_pom full
sed 's|<arg>-Xlint:all,-classfile</arg>|<arg>-Xlint:all</arg>|' pom.xml > pom.plain-xlint.xml
expect_ok "a @ConfigProperty bean fails -Werror under a plain -Xlint:all (the pre-fix shape)" \
  bash -c 'mvn -B -q -f pom.plain-xlint.xml compile > q.log 2>&1; st=$?; grep -q "warnings found and -Werror specified" q.log && [ "$st" -ne 0 ]'
rm pom.plain-xlint.xml
expect_ok "the Quarkus delta resolves, compiles under -Werror, and passes LayerRulesTest and the tests" \
  mvn -B -q test
# On the real classpath the domain ban covers MicroProfile, SmallRye and Vert.x too: a
# domain type returning Mutiny's Uni passed LayerRulesTest until 2026-09-27.
cat > src/main/java/com/example/app/domain/Later.java <<'EOF'
package com.example.app.domain;

import io.smallrye.mutiny.Uni;

public final class Later {
  private Later() {}

  public static Uni<String> value() {
    return Uni.createFrom().item("x");
  }
}
EOF
expect_ok "LayerRulesTest rejects a domain class returning Mutiny's Uni (rule 37)" \
  bash -c 'mvn -B -q test -Dtest=LayerRulesTest > arch.log 2>&1; st=$?; grep -q "domainKnowsNoFramework" arch.log && [ "$st" -ne 0 ]'
rm src/main/java/com/example/app/domain/Later.java arch.log

echo "== the CVE watchdog is armed (audit-java.yml; the plugin's own default never fails) =="
# dependency-check's failBuildOnCVSS defaults to 11 ("the build will never
# fail"), and until 2026-09-27 the workflow ran the goal unpinned and
# unconfigured. A live red case needs the multi-GB NVD database, so this proves
# the wiring instead: the goal the workflow runs resolves the pom's pinned
# version and threshold (a debug read of the resolved parameters; with
# autoUpdate off and no database the goal then exits non-zero, as expected).
expect_ok "audit-java.yml runs the goal with the NVD key from a secret" \
  bash -c 'grep -q "org.owasp:dependency-check-maven:check" "$0" && grep -q "NVD_API_KEY: \${{ secrets.NVD_API_KEY }}" "$0"' "$SKILL/assets/audit-java.yml"
expect_ok "the goal resolves the pinned plugin with failBuildOnCVSS 7 and the NVD key variable" \
  bash -c 'mvn -B -X -f canonical.xml org.owasp:dependency-check-maven:check -DautoUpdate=false > dc.log 2>&1; grep -q "(f) failBuildOnCVSS = 7.0" dc.log && grep -q "(f) nvdApiKeyEnvironmentVariable = NVD_API_KEY" dc.log'
cd "$FX"

echo
if [ "$FAILURES" -gt 0 ]; then
  echo "smoke-test-java: $FAILURES check(s) failed"
  exit 1
fi
echo "smoke-test-java: all checks passed"
exit 0
