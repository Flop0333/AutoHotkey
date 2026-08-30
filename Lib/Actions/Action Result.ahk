#Requires AutoHotkey v2

/** Structured outcome returned for every registry invocation. */
class ActionResult {
    static STATUS_SUCCESS := "success"
    static STATUS_CANCELLED := "cancelled"
    static STATUS_UNAVAILABLE := "unavailable"
    static STATUS_VALIDATION_FAILED := "validation-failed"
    static STATUS_EXECUTION_FAILED := "execution-failed"

    __New(status, actionId := "", message := "", diagnostic := "", durationMs := 0, value := "") {
        this.status := status
        this.actionId := actionId
        this.message := message
        this.diagnostic := diagnostic
        this.durationMs := durationMs
        this.value := value
    }

    Succeeded {
        get => this.status = ActionResult.STATUS_SUCCESS
    }

    static Success(actionId, value := "", durationMs := 0) => ActionResult(ActionResult.STATUS_SUCCESS, actionId, "", "", durationMs, value)
    static Cancelled(actionId, message := "Action cancelled") => ActionResult(ActionResult.STATUS_CANCELLED, actionId, message)
    static Unavailable(actionId, message := "Action is unavailable") => ActionResult(ActionResult.STATUS_UNAVAILABLE, actionId, message)
    static ValidationFailed(actionId, message) => ActionResult(ActionResult.STATUS_VALIDATION_FAILED, actionId, message)
    static ExecutionFailed(actionId, message, diagnostic := "", durationMs := 0) => ActionResult(ActionResult.STATUS_EXECUTION_FAILED, actionId, message, diagnostic, durationMs)
}
