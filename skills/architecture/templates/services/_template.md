# {Service Name}

> **ID:** SVC-XX | **Domain:** [DOM-YY](../domains/yy.md) | **Status:** active

## Purpose

{1 sentence describing what this service does}

## Technology Stack

| Category | Technology | Radar Status |
|----------|------------|--------------|
| Runtime | [Ruby 3.3](../docs/tech-radar.md#tech-ruby-3) | Adopt |
| Database | [PostgreSQL 15](../docs/tech-radar.md#tech-postgres) | Adopt |
| Cache/State | [Redis 7](../docs/tech-radar.md#tech-redis) | Adopt |
| Messaging | [RabbitMQ 3.12](../docs/tech-radar.md#tech-rabbitmq) | Adopt |
| Testing | [RSpec](../docs/tech-radar.md#tech-rspec) | Adopt |

**Repo:** `org/{name}`

## Configuration

| Env Var | Required | Description |
|---------|----------|-------------|
| `RABBITMQ_URL` | yes | Message broker connection |
| `REDIS_URL` | yes | State storage connection |
| `DATABASE_URL` | yes | PostgreSQL connection |

## Contracts

| Type | Link |
|------|------|
| RabbitMQ | [example-topic](../contracts/rabbitmq/example-topic.md#svc-xx) |
| State | [example-state](../contracts/state/example-state.md) |

## Commands

```bash
# Start
foreman start

# Test
RAILS_ENV=test bundle exec rspec

# Lint
bundle exec rubocop
```
