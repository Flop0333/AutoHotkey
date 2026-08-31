# Action Registry Migration Notes

## Stable IDs

- Age of Efficiency app records now use `actionId` instead of callable-name strings.
- Macro Board buttons now use stable IDs instead of direct functions and separate state functions.
- Reusable hotkeys, gestures, Startup tray commands, Screen Snipper modes, Window Manager commands, and selected Desktop Manager launches now invoke action IDs.

Existing public command aliases such as `FW`, `A`, `SD`, `RE`, `SC`, `PBI`, `P`, `V`, `T`, and `Kill` remain unchanged.

## Intentional Behavior Changes

- Age of Efficiency resolves bookmark/search collisions by input shape: `y` or `Maps` opens the bookmark, while an argument selects search.
- Missing, unavailable, and profile-ineligible Age of Efficiency app actions are hidden without deleting their JSON records.
- Destructive actions use the same registry confirmation policy in every migrated consumer.
- Macro Board refreshes toggle state after execution and whenever it is shown or focused.
- Registry exception diagnostics omit exception messages because they can contain arguments or secret-backed values.

## Intentionally Local Behavior

Modal controls, raw input remaps, dynamic desktop layout keys, and Startup profile-menu construction remain owned by their consumers. Their reusable downstream actions may still use the registry.

## Cleanup Boundary

Behavior-free global wrappers used only to reach migrated actions were removed. Functions that still add behavior—such as user feedback, secret resolution, window management, or GUI construction—remain as implementation callables.

Age of Efficiency JSON retains command aliases and presentation overrides by design. Macro Board retains layout and optional per-button presentation overrides. These fields are consumer configuration, not competing ownership of execution, safety, availability, or toggle state.
