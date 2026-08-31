# Actions

The Actions folder gives every hotkey, dashboard, gesture, and menu the same way to describe and run reusable behavior.

## The flow

```text
ActionIds constant
    -> action factory describes the action
    -> an entry-point script supplies the implementation and registers it
    -> a consumer invokes the ID through ActionRegistry or ActionBinding
```

Each separately running `.ahk` script has its own in-memory registry. Including an action module creates no actions by itself: the script must construct and register the actions it needs.

## Main files

- `Action Ids.ahk`: stable IDs used by AHK code. JSON stores their string values.
- `Modules/* Actions.ahk`: inert factories containing shared titles, metadata, and policies.
- `Action.ahk`: the read-only-by-convention action definition.
- `Action Registry.ahk`: registration, lookup, policy checks, execution, and safe state reads.
- `Action Binding.ahk`: convenient callbacks for hotkeys, gestures, and menus.
- `Action Argument.ahk` and `Action Confirmation.ahk`: invocation policies.
- `Action Context.ahk`, `Action Result.ahk`, and `Action Log.ahk`: runtime context, structured outcomes, and bounded metadata-only history.

## Minimal example

```ahk
#Include Lib\Actions\Action Binding.ahk
#Include Lib\Actions\Modules\Window Actions.ahk

CloseWindowUnderMouse(*) {
    MouseGetPos(,, &windowId)
    WinClose(windowId)
}

ActionRegistry.Register(
    WindowActions.CloseUnderMouse(CloseWindowUnderMouse)
)

^!w::ActionBinding.Invoke(
    ActionIds.Window.CloseUnderMouse,
    unset,
    "example-hotkey"
)
```

The factory describes the action; `CloseWindowUnderMouse` implements it; the current script owns registration; and the hotkey knows only the stable ID.

## Rules of thumb

- Invoke through `ActionRegistry` or `ActionBinding`, not `Action.Execute`.
- Give each ID one registration owner per running process; duplicates are errors.
- Use `TryGetState()` in UIs so state-reader failures do not interrupt the interface.
- The registry's configured profile provider is authoritative; context profile data cannot override policy.
- Keep module files inert: no startup work, hotkeys, UI creation, or registration at include time.
- Inject implementations that depend on another app, service, script, or global object. Tiny dependency-free AHK operations may live inside a factory.
