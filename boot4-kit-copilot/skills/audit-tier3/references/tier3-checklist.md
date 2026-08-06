# Tier-3 checklist

Behavior that compiles, starts, and is still wrong. Work these in order.

## 1. Jackson 3

For every DTO and custom serializer, compare Boot 3 vs Boot 4 serialization:
nulls, dates, enums, unknown properties, module registration. Write a
characterization test per risky DTO pinning the exact expected JSON.

Known default flips:
- Dates are ISO-8601 now (`WRITE_DATES_AS_TIMESTAMPS` false).
- Properties are sorted alphabetically.
- `FAIL_ON_UNKNOWN_PROPERTIES` is false.
- All classpath modules are auto-registered
  (`spring.jackson.find-and-add-modules=false` opts out).
- Customization means a `JsonMapper` bean, not `ObjectMapper`.
- `WRITE_DATES_AS_TIMESTAMPS` moved from `SerializationFeature` to
  `DateTimeFeature`, so a copied Boot 3
  `spring.jackson.serialization.*` override silently stops applying.
  It is `spring.jackson.datatype.datetime.*` now.

## 2. PropertyMapper

Find all `.from().to()` chains. The new default skips the call when the
source is null; `.always()` restores the old behavior. Custom
auto-configuration is where this bites.

## 3. Spring Batch

Confirm whether `spring-boot-starter-batch-jdbc` is needed to keep
database-backed job metadata, or the new in-memory default is
acceptable. Check whether job history already exists that would
silently stop persisting.

Pre-cutover: job instances that failed under Batch 5 cannot be
restarted under 6 — parameter serialization changed. Drain or abandon
them first.

## 4. Security 7

Diff effective authorization per endpoint against Boot 3: method
security defaults (now `AuthorizationManager`), request matching (now
PathPattern-based), and PKCE, which is on by default with Authorization
Server.

## 5. Observability

Confirm metrics actually flow. `spring-boot-starter-micrometer-metrics`
is separate now, and missing it produces no error — just an empty
dashboard. Actuator liveness/readiness probes are on by default.
