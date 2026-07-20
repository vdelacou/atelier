# PLAN: apply P6 rows 15.5 and 10.3 to the canon (DONE, uncommitted)

User accepted 15.5 and 10.3; both applied. Held: 11.3 (direction call), 12.7 (option choice).
One coherent commit pending confirm.

- [x] 15.5: TLS DO script in dos-and-donts.md replaced with the EXIT-CODE form (loop over
      ssl3/tls1/tls1_1, accepted = handshake completes = openssl exits 0). NOT the drafted grep:
      proved live it false-FAILs (openssl prints `Protocol: TLSv1.3` even on a REFUSED old
      protocol). OK line claims only what this openssl can probe (ssl3 unprobeable on OpenSSL 3.x).
- [x] 10.3: Do line widened to admit a typed query builder that emits visible SQL, removing the
      contradiction with 10.4's own builder DO. Don't unchanged. Optional example add deferred.
- [x] reliability.md:30 widened to match (hand SQL or a visible-SQL query builder).
- [x] proposed-revisions.md: 10.3 and 15.5 marked ACCEPTED 2026-07-20; 15.5 records the exit-code
      form as landed and why the grep was dropped.
- [x] conformance-matrix.md: re-pinned dos-and-donts hash (5ff047..b4f) + lines (3403 to 3409);
      header bullet now names 5.3/10.3/15.5; row 10.3 Note updated. Row 15.5 unchanged (no matrix impact).
- [x] Verified: drift gate green + selftest green; `bash -n` on the new TLS script OK; the diff has no
      em dash (the one grep hit was this file quoting the check command, now reworded); LESSONS + PLAN updated.

Change set: dos-and-donts.md, reliability.md, proposed-revisions.md, conformance-matrix.md, LESSONS.md,
PLAN.md. One commit.

Next: confirm commit. Still open from the prior turn: 11.3 (pick direction, bring the sub up to the prose's
anomaly ask, or soften the prose toward the sub's burn-rate stance) and 12.7 (Option A new 12.7 with the
115 to 116 cascade, or Option B fold into 12.1). Phase 5 field test remains the only external item.
