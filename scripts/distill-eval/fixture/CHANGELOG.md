# Changelog

## [1.4.0] - 2026-09-20

### Changed
- Stripe webhook events land in the `webhook_events` table; the in-process queue is gone.

### Removed
- The legacy XML export. The finance team imports the CSV export now.
