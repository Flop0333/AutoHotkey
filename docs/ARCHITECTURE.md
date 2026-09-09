# AutoHotkey architecture

This repository uses AutoHotkey v2 `#Include` directives for source composition and ordinary objects and function objects for runtime composition. An include makes a definition available; it should not decide which implementation an application uses or activate optional behavior.

## Dependency direction

Maintained includes form a directed acyclic graph:

```text
entry point / composition root
    -> feature controller
        -> application service
            -> state or reusable library
                -> focused helper or extension
```

- Reusable files include their immediate dependencies rather than `Lib/Core.ahk`.
- Reusable files under `Lib/` do not import applications, dashboards, or secrets. Profile-aware utilities may read the current profile directly when that keeps their default behavior simple.
- Files outside `Startup/` do not include startup bootstrap files.
- An application may expose one focused feature root, but broad catch-all barrels are avoided.
- Vendored examples and the WebView setup template are not application dependencies and are excluded explicitly from the maintained graph check.

`Lib/Core.ahk` remains only as a compatibility facade for external or personal scripts. Repository code must not depend on it.

## Definitions and activation

Library inclusion should be inert apart from explicitly named language extensions. It must not launch applications, start timers, change the working directory, or install process-wide handlers.

Executable entry points own activation. For example:

```ahk
#Include ..\Lib\Core\OnError.ahk

OnError(HandleUnhandledError)
```

Optional features follow the same rule: including Spell Checker or Fake Working Mode exposes definitions, while the Macro Board explicitly enables the behavior it owns.

Files under `Lib/Extensions/` that intentionally augment an AutoHotkey prototype or built-in function are process-wide by design. Include those files deliberately and do not hide them behind an unrelated feature.

## Manual dependency injection

AutoHotkey does not need a dependency-injection container. Constructors, objects, and function objects provide the useful part of dependency injection directly.

The Age of Efficiency composition root selects JSON repositories:

```ahk
AppsState.Initialize(AppsDatabaseService(), LogAndNotifyInfo)
```

Tests can pass an in-memory repository with the same `Load()` and `Store(items)` methods. Use similar seams for other effects only when the testing benefit outweighs the extra indirection in production code.

Prefer injection when a dependency performs I/O, starts a process, displays UI, reads machine-specific state, or needs a fake in a unit test. Pure helpers can be called directly.

## Include paths

- Use paths relative to the file containing the directive.
- Use Windows backslashes consistently in maintained AHK source.
- Keep the repository's established unquoted relative form; quote only where a tool or parser requires it.
- Do not use absolute machine paths, variable-based include paths, or include-directory directives. These cannot be represented reliably in the static dependency graph.
- Use `<LibraryName>` only for a library intentionally installed in an AutoHotkey library search location, not for ordinary repository-local code. The checker models a matching file under the repository's `Lib/`; otherwise it treats the lookup as external.

## Validation

Run the dependency check directly:

```powershell
.\Tests\Invoke-IncludeArchitectureCheck.ps1
```

It runs fixture-based self-tests, resolves repository-local includes, detects missing targets and cycles, rejects include forms that cannot be analyzed statically, and enforces the reusable-library and Startup boundaries. It also runs as part of `Invoke-AllTests.ps1` and GitHub Actions.

When adding a module:

1. Include only what it directly references.
2. Keep the dependency direction one-way.
3. Put runtime construction and activation in the nearest executable composition root.
4. Add an injection seam for effects that should be tested without touching the real machine.
