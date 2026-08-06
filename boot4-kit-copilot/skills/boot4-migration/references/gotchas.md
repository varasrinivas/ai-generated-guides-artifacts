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

## The Undertow starter simply stops resolving at the bump
`'dependencies.dependency.version' for spring-boot-starter-undertow is missing`
on the first Boot 4 build. Cause: Boot 4 removed Undertow support (no Servlet
6.1 release exists). Fix: return to Tomcat (drop the tomcat exclusion and the
undertow starter) or move to Jetty — then read the next entry.

## After the Undertow-to-Tomcat swap, header-heavy requests get bare 400s
Requests with many headers fail with 400 and an empty body while small requests
are fine. Cause: Undertow accepted 200 request headers by default; Tomcat's
default is 100, and no Boot property exposes the count (the 16KB-style size
limits are a different knob and map fine). Fix: a `WebServerFactoryCustomizer`
that casts the protocol handler to `AbstractHttp11Protocol` and calls
`setMaxHeaderCount(200)`.

## Flyway runs no migrations after the bump — and old databases hide it
No Flyway lines in the startup log; on a fresh database the app dies with
Hibernate `ddl-auto=validate` "missing table"; on any seeded database it starts
clean and the gap is invisible. Cause: `FlywayAutoConfiguration` moved out of
`spring-boot-autoconfigure` into the new `spring-boot-flyway` module — an
explicit `flyway-core` dependency is not enough. Fix: depend on
`spring-boot-starter-flyway` (keep the database-specific flyway module).

## First nightly Batch job after cutover dies on a primary-key collision
`expiryJob`-style scheduled jobs fail on `BATCH_JOB_INSTANCE` PK conflicts in
every environment that has real job history — but not in dev. Cause: Batch 6
renamed `BATCH_JOB_SEQ` to `BATCH_JOB_INSTANCE_SEQ`; with
`initialize-schema: always`, Boot's script runner creates the new sequence at 1
beside the orphaned old one and swallows every "already exists" error
(`spring.batch.jdbc.continue-on-error` defaults true) — zero log output. Fix:
run the migration script shipped inside spring-batch-core
(`org/springframework/batch/core/migration/6.0/migration-postgresql.sql`, one
`ALTER SEQUENCE ... RENAME`) per environment before the first Boot 4 start.

## Startup fails with ConverterNotFoundException on an empty-map property
Any environment whose YAML carries a `key: {}` placeholder for a `Map` property
dies at binding. Cause: the YAML loader flattens `{}` to an empty string and
Framework 7's binder no longer converts `""` to `Map`. Fix: delete the
placeholder (an absent key binds the field's default); document the keys in a
comment instead of writing an empty literal.

## Two Jackson majors ship in the fat jar
`BOOT-INF/lib` carries jackson-databind 2.x and 3.x side by side. Cause: the
springdoc Boot-4 line still depends on Jackson 2 for its own serialization.
Consequence: `com.fasterxml` stays importable at compile scope, and code that
uses it silently bypasses every `JsonMapper` convention you configured. Fix:
ban `com.fasterxml` imports in main code (enforcer/ArchUnit) and track
springdoc's Jackson 3 migration.

## Post-bump goldens differ because verification itself added rows
The golden re-capture shows extra collection entries that no serialization
change explains. Cause: the behavior-auditor's live probes POST real
submissions between the two captures, mutating the dataset the goldens read.
Fix: capture post-bump goldens BEFORE dispatching the auditor, or diff
collection fixtures order-insensitively per row and explain each extra row.
