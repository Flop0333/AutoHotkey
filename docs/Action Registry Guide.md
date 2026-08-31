# Action Registry Guide

The Action Registry gives dashboards, hotkeys, gestures, tray menus, and future adapters one stable way to discover and invoke reusable behavior. An action ID is the contract. Labels, icons, bindings, and layouts may change without changing that ID.

## Add an Action

1. Choose a stable namespaced ID such as `productivity.timer.start` and add it once to `ActionIds` in `Lib/Actions/Action Ids.ahk`.
2. Add a factory to the appropriate file in `Lib/Actions/Modules`. A factory describes behavior but does not execute or register it.
3. In the consumer that owns the real callable, include the module and register the returned `Action`.
4. Use the `ActionIds` constant from buttons, hotkeys, gestures, and menu items. Serialized JSON keeps the string value because it cannot contain AHK constants.
5. Add the reference to the validation coverage and run the tests.

```ahk
; Lib/Actions/Modules/Productivity Actions.ahk
static FocusMode(execute, getState) => Action(ActionIds.Productivity.FocusModeToggle, "Focus Mode", execute, {
    description: "Toggle distraction-free mode",
    category: "Productivity",
    getState: getState
})

; The consumer supplies its existing implementation.
ActionRegistry.Register(
    ProductivityActions.FocusMode(ToggleFocusMode, GetFocusModeState)
)
```

Module files must stay inert: including one must not launch an app, create a UI, bind a key, or register an action.

## Expose It to a Consumer

- Hotkey, gesture, or tray: use `ActionBinding.Callback(ActionIds.Productivity.FocusModeToggle, "my-consumer")`.
- Macro Board: add `Button(ActionIds.Productivity.FocusModeToggle)`; layout-only label or image overrides may remain on the button.
- Age of Efficiency: store the stable `actionId` and command alias in `Apps.json`. Its adapter filters unavailable and profile-ineligible actions.
- Another UI: use the adapter pattern below. Do not call `definition.Execute` directly.

## Minimal Consumer-Neutral Adapter

```ahk
class ExampleActionAdapter {
    static List(query := "") {
        context := ActionContext("example-adapter", ProfileManager.current)
        actions := query = ""
            ? ActionRegistry.GetDiscoverable(context)
            : ActionRegistry.Search(query, {profile: context.profile, available: true})

        result := []
        for definition in actions
            result.Push({
                id: definition.Id,
                title: definition.Title,
                category: definition.Category,
                isToggle: definition.IsToggle,
                state: definition.IsToggle ? ActionRegistry.GetState(definition.Id) : ""
            })
        return result
    }

    static Invoke(actionId, argument := unset) {
        context := ActionContext("example-adapter", ProfileManager.current)
        return IsSet(argument)
            ? ActionRegistry.Invoke(actionId, argument, context)
            : ActionRegistry.Invoke(actionId, unset, context)
    }
}
```

The adapter owns presentation only. The registry continues to enforce arguments, profile eligibility, availability, confirmation, exception handling, and structured results.

## Remote, Voice, and AI Safety

Use `GetDiscoverable()` for any consumer that should begin with a conservative capability list. Its default result excludes unavailable, wrong-profile, sensitive-tagged, sensitive-confirmation, and destructive actions. Opting an action into enumeration does not bypass invocation checks: `Invoke()` still applies confirmation and all other registry policies.

Do not serialize callables, arguments, result values, exception messages, Secrets objects, or private URLs. The bounded action log intentionally stores only timestamp, action ID, consumer, status, and duration.

## Validation

- Run `Tests/RunRegistryTests.ahk` for registry behavior.
- Run `Tests/ValidateActionReferences.ps1` to detect duplicate canonical IDs, invalid persisted references, and action ID strings used instead of `ActionIds` in production AHK files.
- Compile the relevant `Tests/Compile*.ahk` harness after changing a consumer.
- Perform manual interaction checks when changing hotkeys, confirmations, profiles, or external applications.
