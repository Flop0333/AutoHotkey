# Action Registry Implementation Plan

## Purpose

Create one authoritative registry for executable actions in the AutoHotkey suite. An action is registered once and can then be discovered and invoked consistently from Age of Efficiency, Macro Board, hotkeys, mouse gestures, tray menus, and future interfaces.

The registry should remove duplicated action definitions without turning interface-specific layout or interaction settings into global concerns. Age of Efficiency remains responsible for command input and search presentation, Macro Board remains responsible for button layout, and hotkey/gesture scripts remain responsible for bindings. They should all reference the same registered actions.

This file is intended to keep a multi-step implementation focused. A task is complete only when its code, migration, and relevant verification are complete.

## Guiding Decisions

- The implementation targets AutoHotkey v2 only.
- Existing user-visible behavior must continue working during and after migration unless a change is explicitly documented.
- Action IDs are stable, unique, case-insensitive machine-readable strings such as `system.reload-startup` or `spotify.good-morning-jazz`.
- An action owns behavior and shared metadata. A consumer owns presentation and bindings specific to that consumer.
- Direct AHK callables are preferred over function-name strings and dynamic `%name%()` invocation.
- The initial implementation is local and synchronous. Remote execution, voice control, AI interpretation, and a visual action editor are outside the first version.
- Existing bookmarks and internet search engines remain separate data types in the first version. They may be exposed through a common discovery interface later, but are not silently converted into executable actions.
- Profile restrictions and availability checks affect discovery and execution; hiding an unavailable action in one UI must not alter the registry itself.
- Destructive actions require explicit confirmation metadata and must not become easier to trigger accidentally.

## Target Architecture

The registry consists of:

1. `Action` — an immutable definition containing identity, behavior, and shared metadata.
2. `ActionRegistry` — registration, validation, lookup, discovery, and invocation.
3. Consumer adapters — small integrations for Age of Efficiency, Macro Board, hotkeys, gestures, and tray menus.
4. Action modules — registrations grouped by domain, such as system, windows, Spotify, Notion, and development.

Conceptual flow:

```text
Action modules -> ActionRegistry -> consumer adapter -> user interface/binding
                         |
                         +-> centralized validation, availability, confirmation,
                             invocation, result reporting, and usage metadata
```

## Action Contract

Every registered action must support the following core fields:

| Field | Required | Meaning |
|---|---:|---|
| `id` | Yes | Stable unique identifier, independent of labels and bindings |
| `title` | Yes | Human-readable display name |
| `execute` | Yes | AHK callable invoked by the registry |
| `description` | No | Short explanation for discovery interfaces and tooltips |
| `category` | No | Shared grouping such as System, Window, Media, or Development |
| `icon` | No | Consumer-neutral icon key or asset reference |
| `aliases` | No | Alternative discovery terms; not global hotkeys |
| `argument` | No | Argument specification, including whether input is required |
| `profiles` | No | Profiles where the action is allowed; empty means all profiles |
| `isAvailable` | No | Callable that determines runtime availability |
| `getState` | No | Callable for toggle/state-aware consumers |
| `confirmation` | No | Confirmation policy and message for risky actions |
| `tags` | No | Additional discovery and filtering terms |

Consumer-specific information must not be placed in the core action unless it is genuinely shared. Examples that stay with consumers include Macro Board page and position, hotkey combinations, gesture patterns, and tray-menu ordering.

## Execution Semantics

- Registry invocation is by action ID, with an optional argument and invocation context.
- The registry validates existence, profile eligibility, availability, argument requirements, and confirmation before calling the action.
- Invocation returns a structured result rather than relying only on `true`, `false`, or a message box.
- A result distinguishes at least: success, cancelled, unavailable, validation failure, and execution failure.
- Expected user cancellation is not reported as an error.
- Exceptions from action code are caught at the registry boundary, enriched with the action ID, logged, and returned as a failed result.
- Consumers may decide how to display a result, but they may not bypass registry safety checks.
- Toggle actions use `getState` to report state; executing the action is still handled by `execute`.

## Implementation Tasks

### 1. Inventory and Baseline

- [x] Catalogue every current executable action exposed through Age of Efficiency, Macro Board, global/app hotkeys, mouse gestures, and startup tray menus.
- [x] Record each action's current callable, arguments, profile rules, state getter, icon, category, confirmation behavior, and consumers.
- [x] Identify duplicate actions that currently have different names or wrappers and decide on one canonical action ID for each behavior.
- [x] Record current user-visible behavior for every migrated consumer so regression checks have a baseline.
- [x] Resolve existing command collisions such as `Y`/`y` and `Maps`, or explicitly document their intended precedence before migrating Age of Efficiency.
- [x] Decide whether usage history is included in version one; if included, define its storage location, privacy rules, and retention limit before implementation.

### 2. Core Models

- [x] Add an `Action` model with validated construction and documented defaults for every optional field.
- [x] Add an argument specification model supporting no argument, optional argument, and required argument.
- [x] Add an invocation-context model that can identify the consumer, active profile, active window, and whether confirmation has already been obtained.
- [x] Add an action-result model with stable status values and optional user-facing and diagnostic messages.
- [x] Ensure mutable arrays or objects supplied as metadata cannot unexpectedly change a registered action after registration.
- [x] Document the public model APIs with short examples in the source.

### 3. Registry Foundation

- [x] Add `ActionRegistry.Register(action)` with duplicate-ID rejection and useful validation errors.
- [x] Add exact lookup by stable action ID.
- [x] Add case-insensitive discovery by title, aliases, category, and tags without treating discovery text as an ID.
- [x] Add filtered enumeration for profile, availability, category, tag, and state capability.
- [x] Add one registry invocation path that performs all eligibility, argument, confirmation, exception, and result handling.
- [x] Make registry initialization deterministic and independent of consumer startup order.
- [ ] Detect and report invalid registrations at startup with enough information to locate the offending action module.
- [x] Prevent one invalid optional action module from silently corrupting or partially overwriting valid registrations.

### 4. Safety and Observability

- [x] Define confirmation levels for normal, sensitive, and destructive actions.
- [x] Mark current destructive actions, including PC shutdown, closing all browsers, and killing all AHK processes, with an appropriate confirmation policy.
- [x] Add a central error-reporting path that does not expose secret values or argument contents by default.
- [ ] Add lightweight invocation logging containing timestamp, action ID, consumer, status, and duration.
- [ ] Make logging optional and bounded so it cannot grow indefinitely.
- [ ] Add a development-only registry diagnostic that lists duplicate IDs, missing callables, invalid profiles, broken state getters, and unavailable icon references where practical.

### 5. Define Action Modules

- [x] Create a clear folder and naming convention for action-registration modules.
- [ ] Register system actions such as reload startup, shutdown, Caps Lock off, and kill AHK processes.
- [ ] Register productivity actions such as timer, fake work mode, screen/OCR-related actions, and picture-in-picture.
- [ ] Register application actions for Notion, Spotify, browsers, KeePass, VS Code, Teams, WhatsApp, and other existing app adapters that are currently exposed to users.
- [ ] Register development actions such as PBI reformat, status-code memes, remote desktop, and command-storage access.
- [x] Register window and virtual-desktop actions that are appropriate for reuse across multiple consumers.
- [x] Keep private URLs, credentials, email addresses, and machine-specific values in the Secrets/Profile/Paths layers rather than action metadata.
- [x] Ensure action modules do not create UIs, bind hotkeys, or execute actions merely because they were included.

### 6. Age of Efficiency Migration

- [ ] Add an Age of Efficiency adapter that converts eligible registered actions into its command-preview representation.
- [x] Replace dynamic `%app.action%()` execution with registry invocation by stable action ID.
- [x] Migrate existing app records to action IDs while preserving user-facing commands, titles, categories, icons, and argument prompts.
- [x] Decide whether Age of Efficiency action presentation remains JSON-configurable or is generated entirely from registry metadata; document and implement the chosen ownership boundary.
- [x] Preserve bookmark and internet-search execution while making collision handling deterministic and visible to the user.
- [ ] Show unavailable or profile-ineligible actions consistently, either filtered out or visibly disabled according to a documented rule.
- [x] Surface registry validation and execution failures through the existing UI without raw exception dialogs.
- [ ] Remove obsolete action-name strings and wrappers only after every existing command has a registry equivalent.

### 7. Macro Board Migration

- [x] Add a Macro Board button definition that references an action ID instead of storing a direct function and separate state function.
- [x] Obtain shared title, description, icon, availability, and toggle state from the registry while allowing per-button label/icon overrides.
- [x] Preserve profile-specific button sets, ordering, layout, and saved window settings.
- [x] Route all button execution through registry invocation.
- [x] Display unavailable and failed actions consistently without freezing or closing the WebView.
- [ ] Refresh toggle state after execution and when the board is shown.
- [x] Remove the old direct-function button path after all current buttons have migrated and passed regression checks.

### 8. Hotkey and Gesture Migration

- [x] Add a small binding helper that invokes an action ID through the registry.
- [x] Migrate reusable global hotkeys from direct callables to registered action IDs.
- [x] Migrate appropriate app-specific hotkeys while keeping application-context conditions in the hotkey consumer.
- [x] Migrate mouse gestures to action IDs while keeping gesture-pattern ownership in the gesture consumer.
- [x] Preserve hotkeys whose behavior is too local or low-level to benefit from registry exposure, and document the rule used to make that distinction.
- [x] Add startup diagnostics for bindings that reference missing or profile-ineligible action IDs.
- [x] Verify that migration introduces no duplicate or shadowed hotkey definitions.

### 9. Tray and Other Consumers

- [x] Route reusable Startup tray actions through the registry while retaining profile-switch menu construction in the tray consumer.
- [ ] Provide a documented adapter pattern that future consumers can follow without depending on Age of Efficiency or Macro Board internals.
- [ ] Add one minimal example consumer in documentation showing lookup, discovery, state reading, and invocation.
- [ ] Confirm that future voice, phone, or AI consumers can enumerate safe actions without automatically gaining permission to invoke sensitive or destructive actions.

### 10. Compatibility and Cleanup

- [ ] Remove duplicated action metadata only after the final consumer using it has migrated.
- [ ] Remove obsolete wrapper functions that add no behavior beyond forwarding to the canonical callable.
- [x] Remove string-based dynamic function invocation from migrated paths.
- [x] Update includes so action modules and registry initialization cannot cause circular dependencies.
- [ ] Confirm startup still works for Work, Dev Box, Woonkamer Laptops, and Default profiles when optional applications or secrets are absent.
- [ ] Update README architecture and customization sections to explain how to add an action and expose it in each consumer.
- [ ] Add a migration note explaining renamed IDs, changed command aliases, and intentional behavior changes.

### 11. Verification

- [x] Add automated or scriptable checks for action construction, duplicate registration, lookup, filtering, required arguments, profile eligibility, availability, confirmation, cancellation, state reading, exception handling, and structured results.
- [x] Add a registry validation command that can run without launching all dashboards or executing registered actions.
- [ ] Verify every action ID referenced by a consumer exists.
- [ ] Verify every existing Age of Efficiency app command still invokes the intended behavior or has a documented replacement.
- [ ] Verify every existing Macro Board button still renders and invokes the intended behavior for each profile.
- [ ] Verify migrated hotkeys and gestures invoke exactly once and honor their original context conditions.
- [ ] Verify destructive actions cannot run from any consumer without satisfying their confirmation policy.
- [ ] Verify secrets and sensitive arguments are absent from logs, diagnostics, and registry enumeration.
- [ ] Perform a clean-start test on every available profile and record any profile that could not be tested locally.
- [ ] Perform an extended normal-use test covering startup, profile switching, dashboard reopening, script reloads, and action failures.

## Acceptance Specification

The implementation is fully complete only when all statements below are true.

### Registration and Identity

- [x] Given two actions with the same ID in any letter casing, when initialization runs, then registration fails with a diagnostic naming the duplicate ID and both registration locations where available.
- [ ] Given a valid registered action, when its label, icon, or consumer binding changes, then its stable ID and callers do not need to change.
- [x] Given an invalid action definition, when the registry validates it, then the error identifies the action and invalid field before the action can be invoked.

### Discovery and Profiles

- [x] Given an action with a title, aliases, category, and tags, when a consumer searches using any configured discovery term, then that action can be found.
- [x] Given an action restricted to the Work profile, when the active profile is not Work, then normal consumers cannot invoke it through the registry.
- [x] Given an action whose runtime dependency is unavailable, when consumers enumerate available actions, then the action is filtered or marked unavailable according to the documented consumer rule.
- [ ] Given a profile switch followed by suite restart, when consumers initialize, then each consumer reflects the new profile's eligible actions.

### Arguments and Execution

- [x] Given an action with no argument, when invoked with no argument, then its callable executes exactly once.
- [x] Given an action requiring an argument, when invoked without one, then the registry returns a validation result and does not execute the callable.
- [x] Given an optional argument, when it is omitted or supplied, then the callable receives the documented value in both cases.
- [x] Given an action callable that throws, when invoked from any consumer, then the suite remains running and the consumer receives a structured failure result.
- [ ] Given a user-cancelled prompt or confirmation, when invocation ends, then the action does not execute and the result is `cancelled`, not `failed`.

### State and Safety

- [x] Given a toggle action, when its state changes, then Macro Board can retrieve and display the new state without owning a duplicate state function.
- [ ] Given a destructive action, when invoked from Age of Efficiency, Macro Board, a hotkey, a gesture, or a future adapter, then the same registry confirmation policy applies.
- [ ] Given a sensitive argument or secret-backed action, when it executes or fails, then logs and diagnostics do not contain the secret value.
- [ ] Given a consumer attempts to bypass profile, availability, or confirmation checks, when it invokes through the public registry API, then the registry still enforces those checks.

### Consumer Consistency

- [x] Given one action exposed in multiple consumers, when its shared title, description, category, icon, availability, or safety policy changes, then all non-overridden consumers reflect the change from the single definition.
- [x] Given an action ID referenced by a consumer does not exist, when validation runs, then the missing reference is reported before normal use.
- [ ] Given the same action is invoked from Age of Efficiency and Macro Board, when provided the same argument and context, then it reaches the same callable and applies the same validation and safety rules.
- [x] Given an interface-specific override such as a shorter Macro Board label, when applied, then it affects only that interface and does not mutate the registered action.

### Backward Behavior

- [ ] Given the suite starts under each configured profile, when initialization completes, then existing dashboards, hotkeys, gestures, tray controls, bookmarks, and searches remain usable unless a replacement is documented.
- [ ] Given current Age of Efficiency command collisions, when migration is complete, then each intended bookmark and search action has a unique or explicitly namespaced invocation path.
- [ ] Given an optional application is not installed, when the registry initializes, then unrelated actions and consumers continue to work.
- [ ] Given the registry or one action module contains an error, when startup reports it, then the diagnostic is actionable and does not expose secrets.

## Definition of Done

- [ ] Every implementation task in this file is checked or explicitly moved to a documented later scope with a reason.
- [ ] Every acceptance statement passes, with manual-only checks identified as such.
- [ ] All current action consumers use stable action IDs for migrated behavior.
- [ ] No migrated consumer directly invokes an action callable or dynamically invokes a function-name string.
- [ ] Registry validation completes without duplicate IDs, missing consumer references, or invalid metadata.
- [ ] Documentation contains one clear path for adding a new action and exposing it through each supported consumer.
- [ ] The repository contains no newly introduced secrets, personal values, or machine-specific absolute paths.
- [ ] The implementation has completed a clean-start and normal-use regression test without critical failures.

## Current Implementation Checkpoint (2026-08-30)

Work is intentionally paused here in a runnable, reviewable state. The checkboxes above remain the authoritative record of overall completion.

### Completed in This Implementation Pass

- [x] Built the registry foundation: stable IDs, metadata, discovery, arguments, profile and availability checks, confirmation, toggle state, structured results, validation, and binding diagnostics.
- [x] Migrated Age of Efficiency execution to action IDs, including deterministic bookmark/search collision handling.
- [x] Migrated Macro Board buttons and shared presentation/state metadata to action IDs.
- [x] Migrated reusable global and app-specific hotkeys, mouse gestures, Window Manager commands, reusable Desktop Manager commands, and Startup tray reload/exit commands.
- [x] Added registry tests and isolated compile checks for every migrated entry point.
- [x] Confirmed all registry tests and all eight affected compile checks pass at this checkpoint.

### Intentionally Left Local

These bindings are not unfinished migrations unless their reuse requirements change:

- Text Speaker modal keys and Mouse Toys raw remaps, because they are tightly coupled to local interaction state.
- Dynamically generated per-desktop shortcuts, because the Desktop Manager owns their runtime lifecycle.
- Startup profile-menu construction, because it is navigation/configuration rather than a reusable action.
- Low-level Caps Lock service internals, because exposing implementation details would not improve consumers.

### Recommended Resume Point

Resume with the unchecked tasks in sections 5 through 11, in this order:

1. Add bounded, secret-safe logging and a user-facing registry diagnostics command.
2. Finish the Age of Efficiency adapter and its unavailable/profile-ineligible presentation rule.
3. Refresh Macro Board toggle state whenever the board is shown.
4. Register the remaining genuinely reusable system, productivity, application, and development actions.
5. Add the documented adapter example and update README/migration documentation.
6. Run manual clean-start and normal-use regression checks for every available profile.

### How to Validate Before Continuing

- Run `Tests/RunRegistryTests.ahk` for the registry behavior suite.
- Compile the eight `Tests/Compile*.ahk` harnesses for Age of Efficiency, Macro Board, Hotkeys, App Hotkeys, Mouse Gestures, Window Manager, Desktop Manager, and Startup.
- A local `Secrets/Secrets.ahk` may be required for full-suite compilation. Create it from the repository's example according to the normal installation process and never commit it.
- The compile checks contain pre-existing warning output; at this checkpoint they exit successfully and no warnings originate from the new registry/binding layer.

### Handoff Notes

- The live AutoHotkey suite was not restarted or replaced, so manual interaction and profile regression testing still need to be performed.
- Temporary smoke-test files and the temporary test Secrets file have been removed.
- The unrelated untracked `error-improve-plan.md` file was deliberately left untouched.
- No commit was created; review the working-tree changes before committing.

## Explicitly Deferred Ideas

These are intentionally excluded from the initial Action Registry implementation and should not expand the project scope unless separately approved:

- [ ] Natural-language or AI selection of actions.
- [ ] Voice-controlled invocation.
- [ ] Remote or phone-triggered invocation.
- [ ] A no-code visual action editor.
- [ ] Arbitrary user-authored multi-step automation recipes.
- [ ] Cross-computer registry synchronization.
- [ ] Plugin discovery or dynamic loading of untrusted action modules.
- [ ] Converting every bookmark and search engine into a core executable action.
