# GitHub Copilot instructions

This is a Windows productivity and automation suite written for AutoHotkey v2.

- Treat `AGENTS.md` as the canonical repository guide and consult its focused documentation links when relevant.
- Follow the working agreement and definition of done in `AGENTS.md`.
- Inspect the working tree before editing and preserve unrelated or user-owned changes.
- Use AutoHotkey v2 syntax; do not introduce v1 compatibility code.
- Preserve the CapsLock startup ordering described in `AGENTS.md`.
- Follow the include direction and activation rules in `docs/ARCHITECTURE.md`; declare immediate dependencies instead of including `Lib/Core.ahk`.
- Use relative `#Include` paths. Resolve runtime repository paths through `Lib/Core/Paths.ahk`; never hard-code a checkout path.
- Reuse existing shared classes and functions before adding another implementation.
- Do not edit or expose ignored profiles, secrets, settings, or runtime logs.
- Update the focused documentation when changing apps, startup, tests, workflows, credentials, or external connections.
- Run the smallest relevant test suite while working and the full suite for shared code, startup, includes, logging, or test infrastructure.
- Review the complete diff for scope, correctness, secrets, and accidental generated files before finishing.
- Work through a branch and pull request for tracked changes. Never merge a pull request unless the maintainer explicitly asks.
