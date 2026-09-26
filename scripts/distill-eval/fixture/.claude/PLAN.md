# Plan: send the monthly export to the finance team's SFTP (2026-09-24)

## Steps and definition of done
1. [x] An SFTP adapter behind the `ExportSink` port, with its fake and a contract test.
2. [ ] Retry on a connection reset (in progress: the adapter retries, the test for the third failure is red).
3. [ ] The cron schedule on the first of the month at 06:00 UTC.

## Notes
- The finance team's host rejects files over 50 MB; the September export is 31 MB.
