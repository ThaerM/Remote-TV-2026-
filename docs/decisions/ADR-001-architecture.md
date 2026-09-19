# ADR-001: Feature-First Architecture with a Dedicated TV Layer

## Status

Accepted (Foundation phase)

## Context

Remote TV 2026 needs to support many unrelated TV ecosystems, each with
different discovery, pairing, transport, and command semantics, while
keeping the UI and shared app logic completely unaware of which
ecosystem it's currently talking to. A single service class handling all
TV brands (the "giant `TVRemoteService`" the product brief explicitly
warns against) would force branching logic (`if (samsung) ... else if
(lg) ...`) throughout the codebase and make it impossible to test one
platform's behavior in isolation.

## Decision

Structure the codebase as feature-first (`lib/features/<feature>/`) for
user-facing screens, with a separate top-level `lib/tv/` layer holding:

- `tv/domain/` - platform-agnostic models and the `TvProvider` interface
- `tv/providers/<platform>/` - one implementation per TV ecosystem
- `tv/providers/registry/` - the `TvProviderRegistry` that holds all of them
- `tv/application/` - `TvSessionController`, the only thing features talk to

`core/` holds cross-cutting concerns with no feature or TV-domain
knowledge: design tokens, logging, storage abstractions.

## Consequences

- Adding a new TV platform is additive: a new `tv/providers/<platform>/`
  directory plus one registry line, no changes to `features/*`.
- Features depend on `tv/domain` + `tv/application`, never on a concrete
  provider - enforced by convention and reviewed in code review, not by a
  build-time barrier (no separate packages in this foundation; revisit if
  the team grows and needs harder boundaries).
- Slightly more directories/files than a flatter structure for a project
  this size today, which is a reasonable cost given the explicit
  multi-platform requirement.
