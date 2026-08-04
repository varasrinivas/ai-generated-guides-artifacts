# Boot 4 migration notes (condensed ground truth)

Distilled from the official Spring Boot 4.0 Migration Guide (spring-projects/spring-boot
wiki), Framework 7 / Security 7 release notes, and our pilot migration. Keep this SHORT —
every phase prompt re-reads it, so its size is a recurring context tax. Verify against the
official wiki before each new migration wave.

## Baseline

- Target: Spring Boot 4.x (4.1 current). Java 17 floor, 21/25 recommended. Start from 3.5.x.
- Ships on Framework 7, Jakarta EE 11, Security 7, Hibernate 7.x, Jackson 3, JUnit 6.
- Spring Cloud train: 2025.1.x — pin 2025.1.1 or later; earlier releases do not work with
  Boot 4.0.1+.

## Tier 1 — won't compile

- Starter renames: `starter-web` → `starter-webmvc`; `starter-aop` → `starter-aspectj`
  (keep it if you use Micrometer `@Timed`/`@Counted`).
- Undertow removed (no Servlet 6.1 release): `starter-undertow` no longer resolves —
  return to Tomcat or Jetty, then check container-default deltas (see gotchas:
  Tomcat caps header *count* at 100 vs Undertow's 200).
- Batch 6 relocations: `core.job.Job`, `core.step.Step`, `core.job.parameters.*`,
  `infrastructure.repeat.RepeatStatus`.
- `HttpStatus.UNPROCESSABLE_ENTITY` → `UNPROCESSABLE_CONTENT` (RFC 9110); the
  api-docs reason phrase changes with it.
- RestTemplate/RestClient need `starter-restclient`; WebClient-only apps: `starter-webclient`.
- Removed: `WebSecurityConfigurerAdapter`, `.and()` chaining, `authorizeRequests()`,
  `Mvc/AntPathRequestMatcher` (→ `PathPatternRequestMatcher`), OkHttp3, embedded launch
  scripts, reactive Pulsar.
- Jackson: annotations stay at `com.fasterxml.jackson.annotation`; everything else moves to
  `tools.jackson`. Mapper customization = `JsonMapper` bean, not `ObjectMapper`. API renames
  ride along: `JsonSerializer` → `ValueSerializer`, `SerializerProvider` →
  `SerializationContext`, `write*Field` → `write*Property` (exceptions now unchecked);
  Boot side: `@JsonComponent` → `@JacksonComponent`,
  `Jackson2ObjectMapperBuilderCustomizer` → `JsonMapperBuilderCustomizer`.
- `HttpHeaders` no longer implements `MultiValueMap` (`asMultiValueMap()` is the deprecated
  fallback).
- Modules relocated to `org.springframework.boot.<module>` packages; `BootstrapRegistry` and
  `EnvironmentPostProcessor` moved. In-house starters must rework against the new packages.
  (`AutoConfiguration.imports` registration is unchanged — that dates to Boot 2.7/3.0.)

## Tier 2 — won't run

- Micrometer metrics need `spring-boot-starter-micrometer-metrics`; OTLP export moved to
  `spring-boot-starter-opentelemetry`.
- Batch 6: in-memory metadata is the default — add `spring-boot-starter-batch-jdbc` BEFORE
  first run or job history silently stops persisting. Metadata SQL: `BATCH_JOB_SEQ` was
  renamed `BATCH_JOB_INSTANCE_SEQ` — run the `migration/6.0` script shipped in
  spring-batch-core per environment; `initialize-schema: always` will not do it (its
  errors are swallowed by the `continue-on-error` default).
- Flyway auto-configuration moved out of `spring-boot-autoconfigure` into
  `spring-boot-flyway`: add `spring-boot-starter-flyway` — explicit `flyway-core` is not
  enough, and databases that already carry the schema mask the gap.
- Empty-map YAML placeholders (`key: {}`) for `Map` properties now fail startup —
  Framework 7's binder no longer converts the flattened empty string
  (`ConverterNotFoundException`). Delete the placeholder.
- `@Retryable`/`@ConcurrencyLimit` moved into core Framework (`@EnableResilientMethods`);
  Boot no longer manages `spring-retry`.
- Testcontainers 2.x required — modules re-prefixed `testcontainers-`, container classes
  relocated, so imports break too.
- Batch 5 job instances that failed cannot be restarted under Batch 6 (parameter
  serialization changed) — drain or abandon them before cutting over.
- Classic Starter POMs are the documented escape hatch if modularization becomes a long
  tail: adopt, get green, then migrate to selective modules.

## Tier 3 — runs wrong (audit, never assume)

- Jackson 3 default flips: dates ISO-8601 (`WRITE_DATES_AS_TIMESTAMPS` false), properties
  sorted alphabetically, `FAIL_ON_UNKNOWN_PROPERTIES` false, all classpath modules
  auto-registered. Property namespaces shifted in 4.0 (`spring.jackson.read.*` →
  `spring.jackson.json.read.*`), and 4.1 re-introduced `spring.jackson.read.*`/`write.*`
  for format-common features — both exist on 4.1 with different scopes.
- `WRITE_DATES_AS_TIMESTAMPS` moved `SerializationFeature` → `DateTimeFeature`: a copied
  Boot 3 `spring.jackson.serialization.*` override silently stops applying. Use
  `spring.jackson.datatype.datetime.*`.
- Security 7: method security defaults to `AuthorizationManager`; PathPattern request
  matching; PKCE on by default with Authorization Server; OAuth2 password grant gone.
- Actuator liveness/readiness probes on by default.
- `PropertyMapper` null handling changed.
- SpEL expressions capped at 10,000 operations by default.
- 4.1: HTTP-client SSRF mitigation via `InetAddressFilter` can block outbound calls —
  verify egress after upgrade.
- springdoc's Boot-4 line still ships jackson-databind 2.x beside Jackson 3, so
  `com.fasterxml` imports compile and silently bypass `JsonMapper` conventions —
  ban them in main code.

## Tests (Phase 5/7)

- `@MockBean`/`@SpyBean` → `@MockitoBean`/`@MockitoSpyBean` (from `spring-test`; NOT 1:1 —
  review each usage).
- `@SpringBootTest` no longer auto-configures MockMvc → add `@AutoConfigureMockMvc`;
  TestRestTemplate needs `@AutoConfigureTestRestTemplate`; `@WithMockUser` needs
  `spring-boot-starter-security-test`.
- Test slices modularized: `@WebMvcTest`/MockMvc → `spring-boot-webmvc-test`
  (`org.springframework.boot.webmvc.test.autoconfigure`); `TestRestTemplate` →
  `spring-boot-resttestclient`; MockMvc security wiring → `spring-boot-starter-security-test`.
- JUnit 6 (Jupiter). (`junit-vintage-engine` has not been transitive since Boot 2.4.)
