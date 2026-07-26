# {Domain Name}

> **ID:** DOM-XX | **Owner:** {team} | **Status:** active

## Purpose

{1-2 sentences: what business capability this domain provides}

## Boundaries

| Owns | Depends On |
|------|------------|
| {Aggregate/Concept} | [DOM-YY](./other.md) via {what} |

## Services

| Service | Responsibility | Status |
|---------|----------------|--------|
| [SVC-XX](../services/xx.md) | {one line} | active |

## Inter-Domain Contracts

| Direction | Domain | Exchange | Contract |
|-----------|--------|----------|----------|
| -> produces | DOM-OTHER | example_topic | [example.state](../contracts/rabbitmq/example-topic.md#examplestate) |
| <- consumes | DOM-OTHER | other_topic | [other.*](../contracts/rabbitmq/other-topic.md) |

## Diagrams

- [L2 Containers](../diagrams/L2/{slug}.mmd)
- [L3 Components](../diagrams/L3/{slug}.mmd)

## Key Invariants

1. {Business rule that must always hold}
2. {Another invariant}
