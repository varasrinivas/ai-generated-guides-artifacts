# Gotchas — every surprise from real migrations

Append an entry every time a migration surprises you; every service migrated after you
benefits on its next `/plugin marketplace update`. Format: symptom → cause → fix.

## No errors, but metrics disappeared
Micrometer metrics silently gone after the bump. Cause: metrics now require the explicit
`spring-boot-starter-micrometer-metrics` starter (the official guide lists it only as a
table row). Fix: add the starter; if you export OTLP, also add
`spring-boot-starter-opentelemetry`.

## Batch jobs run but history stops persisting
No startup error; job repository is silently in-memory. Cause: Batch 6 defaults to
in-memory metadata. Fix: add `spring-boot-starter-batch-jdbc` BEFORE the first post-bump
run in any environment that matters.

## Spring Cloud fails at startup on Boot 4.0.1+
Cause: Spring Cloud releases before 2025.1.1 do not work with Boot 4.0.1+. Fix: pin 2025.1.1 or later
(2025.1.2 covers Boot 4.0.7 and 4.1.0).

## Header-manipulation code stops compiling or behaves oddly
Cause: `HttpHeaders` no longer implements `MultiValueMap`. Fix: migrate to the typed
accessors; `asMultiValueMap()` is a deprecated stopgap only.

## A @MockitoBean swap changed test behavior
Cause: `@MockitoBean` is not a 1:1 replacement for `@MockBean` (different reset/context
semantics). Fix: review each swapped usage instead of batch-replacing blindly.

## Outbound HTTP calls fail only in some environments (4.1)
Cause: 4.1's SSRF mitigation (`InetAddressFilter`) can block egress. Fix: verify outbound
calls after upgrade; configure the filter for legitimate internal targets.
