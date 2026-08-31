#Requires AutoHotkey v2
#SingleInstance Force
#Include ..\Lib\Actions\Action Registry.ahk

testLogPath := A_Temp "\action-registry-tests.log"
try FileDelete(testLogPath)
OnError(TestFailure)
RunTests()
ExitApp(0)

TestFailure(error, mode) {
    global testLogPath
    FileAppend("FAILED: " error.Message " | " error.What " | " error.File ":" error.Line "`n", testLogPath)
    ExitApp(1)
    return true
}

Checkpoint(message) {
    global testLogPath
    FileAppend(message "`n", testLogPath)
}

Assert(condition, message) {
    if !condition
        throw Error("Assertion failed: " message)
}

ThrowTestSecret(value) {
    throw Error(value)
}

class ProfileManager {
    static current := {displayName: "Default"}
}

RunTests() {
ActionRegistry.Reset()
ActionRegistry.SetProfileProvider((*) => ProfileManager.current)
ActionLog.Clear()
ActionLog.Configure(true, 3)
Checkpoint("registry reset")

aliases := ["clock"]
callCount := 0
basicAction := Action("Test.Run", "Run Test", (*) => ++callCount, {
    description: "A registry test action",
    category: "Tests",
    aliases: aliases,
    tags: ["fast"]
})
ActionRegistry.Register(basicAction)

aliases.Push("mutated")
returnedAliases := basicAction.Aliases
returnedAliases.Push("also-mutated")
Assert(basicAction.Id = "test.run", "IDs are normalized")
Assert(basicAction.Aliases.Length = 1, "Action metadata is isolated from mutation")
Assert(ActionRegistry.Get("TEST.RUN") = basicAction, "Lookup is case-insensitive")
Assert(ActionRegistry.Search("clock").Length = 1, "Aliases are searchable")
Assert(ActionRegistry.GetAll({category: "tests", tag: "FAST"}).Length = 1, "Filters are case-insensitive")
Checkpoint("definition and discovery passed")

result := ActionRegistry.Invoke("test.run", unset, ActionContext("tests", "Default"))
Assert(result.Succeeded, "Normal action succeeds")
Assert(callCount = 1, "Action callable executes exactly once")
Checkpoint("basic invocation passed")

secretValue := "DO-NOT-LOG-THIS"
secretFailure := Action("test.secret", "Secret Failure", ThrowTestSecret, {
    argument: ActionArgument.Optional("Sensitive value")
})
ActionRegistry.Register(secretFailure)
secretResult := ActionRegistry.Invoke("test.secret", secretValue, ActionContext("secret-test"))
Assert(!InStr(secretResult.diagnostic, secretValue), "Exception diagnostics omit secret values")
logEntry := ActionLog.GetEntries()[ActionLog.GetEntries().Length]
serializedLogEntry := logEntry.timestamp "|" logEntry.actionId "|" logEntry.consumer "|" logEntry.status "|" logEntry.durationMs
Assert(!InStr(serializedLogEntry, secretValue), "Invocation logs omit arguments and secret values")
Assert(logEntry.consumer = "secret-test", "Invocation logs identify the consumer")
Checkpoint("secret-safe logging passed")

requiredAction := Action("test.echo", "Echo", (value) => value, {
    argument: ActionArgument.Required("Enter a value")
})
ActionRegistry.Register(requiredAction)
Assert(ActionRegistry.Invoke("test.echo", unset, ActionContext("tests")).status = ActionResult.STATUS_VALIDATION_FAILED, "Required arguments are enforced")
Assert(ActionRegistry.Invoke("test.echo", "hello", ActionContext("tests")).value = "hello", "Arguments reach the callable")

optionalAction := Action("test.optional", "Optional", (value := "default") => value, {
    argument: ActionArgument.Optional("Optional value")
})
ActionRegistry.Register(optionalAction)
Assert(ActionRegistry.Invoke("test.optional", unset, ActionContext("tests")).value = "default", "Optional arguments may be omitted")
Assert(ActionRegistry.Invoke("test.optional", "supplied", ActionContext("tests")).value = "supplied", "Optional arguments may be supplied")
Checkpoint("arguments passed")

profileAction := Action("test.work", "Work only", (*) => true, {profiles: ["Work"]})
ActionRegistry.Register(profileAction)
Assert(!ActionRegistry.Invoke("test.work", unset, ActionContext("tests", "Default")).Succeeded, "Profile restrictions are enforced")
Assert(!ActionRegistry.Invoke("test.work", unset, ActionContext("tests")).Succeeded, "The current profile is enforced when consumers omit it")
Assert(ActionRegistry.Invoke("test.work", unset, ActionContext("tests", "Work")).Succeeded, "Eligible profiles can invoke")
Checkpoint("profiles passed")

unavailableAction := Action("test.unavailable", "Unavailable", (*) => true, {isAvailable: (*) => false})
ActionRegistry.Register(unavailableAction)
Assert(ActionRegistry.Invoke("test.unavailable", unset, ActionContext("tests")).status = ActionResult.STATUS_UNAVAILABLE, "Availability is enforced")
Checkpoint("availability passed")

state := false
toggleAction := Action("test.toggle", "Toggle", (*) => state := !state, {getState: (*) => state})
ActionRegistry.Register(toggleAction)
ActionRegistry.Invoke("test.toggle", unset, ActionContext("tests"))
Assert(ActionRegistry.GetState("test.toggle"), "Toggle state is read centrally")
Checkpoint("state passed")

failureAction := Action("test.failure", "Failure", (*) => ({}).missing)
ActionRegistry.Register(failureAction)
Assert(ActionRegistry.Invoke("test.failure", unset, ActionContext("tests")).status = ActionResult.STATUS_EXECUTION_FAILED, "Exceptions become structured failures")
Checkpoint("failure handling passed")

destructiveAction := Action("test.destructive", "Destructive", (*) => true, {
    confirmation: ActionConfirmation.Destructive("Confirm test")
})
ActionRegistry.Register(destructiveAction)
Assert(ActionRegistry.Invoke("test.destructive", unset, ActionContext("tests", "", 0, true)).Succeeded, "Pre-confirmed destructive action succeeds")
Assert(ActionRegistry.GetDiscoverable(ActionContext("future-adapter", "Default")).Length > 0, "Safe actions are discoverable")
Assert(!ArrayContainsAction(ActionRegistry.GetDiscoverable(ActionContext("future-adapter", "Default")), "test.destructive"), "Destructive actions are excluded from default discovery")
Assert(ArrayContainsAction(ActionRegistry.GetDiscoverable(ActionContext("future-adapter", "Default"), {allowDestructive: true}), "test.destructive"), "Destructive discovery requires explicit opt-in")
Checkpoint("confirmation passed")

duplicateRejected := false
try ActionRegistry.Register(Action("TEST.RUN", "Duplicate", (*) => true))
catch
    duplicateRejected := true
Assert(duplicateRejected, "Duplicate IDs are rejected case-insensitively")
Checkpoint("duplicates passed")

countBeforeBatch := ActionRegistry.Count
try ActionRegistry.RegisterAll([
    Action("test.batch", "Batch", (*) => true),
    Action("test.run", "Duplicate in batch", (*) => true)
])
Assert(ActionRegistry.Count = countBeforeBatch, "Failed registration batches are rolled back")
Assert(!ActionRegistry.Has("test.batch"), "Rolled-back actions are removed")
Checkpoint("batch rollback passed")

missing := ActionRegistry.ValidateReferences(["test.run", "test.missing"])
Assert(missing.Length = 1, "Missing consumer references are reported")
Checkpoint("references passed")

ActionRegistry.Invoke("test.run", unset, ActionContext("log-bound-test"))
ActionRegistry.Invoke("test.run", unset, ActionContext("log-bound-test"))
ActionRegistry.Invoke("test.run", unset, ActionContext("log-bound-test"))
ActionRegistry.Invoke("test.run", unset, ActionContext("log-bound-test"))
Assert(ActionLog.GetEntries().Length = 3, "Invocation logging remains bounded")
Assert(!InStr(ActionRegistry.FormatDiagnostics(), secretValue), "Registry diagnostics omit secret values")
Checkpoint("bounded logging and diagnostics passed")

FileAppend("Action Registry tests passed`n", "*")
}

ArrayContainsAction(actions, actionId) {
    for definition in actions
        if definition.Id = actionId
            return true
    return false
}
