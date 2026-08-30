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

class ProfileManager {
    static current := {displayName: "Default"}
}

RunTests() {
ActionRegistry.Reset()
ActionRegistry.SetProfileProvider((*) => ProfileManager.current)
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

FileAppend("Action Registry tests passed`n", "*")
}
