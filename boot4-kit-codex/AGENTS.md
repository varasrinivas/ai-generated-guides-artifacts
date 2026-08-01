# AGENTS.md

## Project
- Spring Boot 3.5.x monolith / microservice (state which)
- Build: Maven (./mvnw) | Java 17 → migrating to Java 21
- Test: JUnit 5, Mockito, Testcontainers
- Modules: api, service, persistence, batch

## Migration Context
We are migrating from Spring Boot 3.5.x to 4.x.
Authoritative reference: the official Spring Boot 4.0
Migration Guide (spring-projects/spring-boot wiki)

## Rules
- Never change business logic while fixing migration breaks
- One migration category per branch/commit
- Always run ./mvnw clean verify before declaring a task done
- Flag ANY Jackson serialization change for human review
- Do not upgrade Spring Cloud / third-party BOMs without
  checking Boot 4 compatibility first
- Prefer explicit starters over transitive dependencies

## Commands
- Build: ./mvnw clean verify
- Single test: ./mvnw test -Dtest=ClassName
- Run locally: ./mvnw spring-boot:run -Dspring-boot.run.profiles=local
