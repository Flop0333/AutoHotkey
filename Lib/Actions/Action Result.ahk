#Requires AutoHotkey v2

/** Structured outcome returned for every registry invocation. */
class ActionResult {
    /** The implementation completed successfully. */
    static STATUS_SUCCESS := "success"
    /** The user declined required confirmation. */
    static STATUS_CANCELLED := "cancelled"
    /** Profile or runtime availability prevented execution. */
    static STATUS_UNAVAILABLE := "unavailable"
    /** The ID or supplied argument did not satisfy the action contract. */
    static STATUS_VALIDATION_FAILED := "validation-failed"
    /** The implementation or state reader threw an exception. */
    static STATUS_EXECUTION_FAILED := "execution-failed"

    /** Stores a consumer-safe outcome plus a non-secret developer diagnostic. */
    __New(status, actionId := "", message := "", diagnostic := "", durationMs := 0, value := "") {
        this.status := status
        this.actionId := actionId
        this.message := message
        this.diagnostic := diagnostic
        this.durationMs := durationMs
        this.value := value
    }

    /** Convenience check used before reading value. */
    Succeeded {
        get => this.status = ActionResult.STATUS_SUCCESS
    }

    /** Successful result; value may contain the implementation's return value. */
    static Success(actionId, value := "", durationMs := 0) => ActionResult(ActionResult.STATUS_SUCCESS, actionId, "", "", durationMs, value)
    /** Result returned when confirmation is declined. */
    static Cancelled(actionId, message := "Action cancelled") => ActionResult(ActionResult.STATUS_CANCELLED, actionId, message)
    /** Result returned when current runtime policy blocks the action. */
    static Unavailable(actionId, message := "Action is unavailable") => ActionResult(ActionResult.STATUS_UNAVAILABLE, actionId, message)
    /** Result returned before execution when the request is invalid. */
    static ValidationFailed(actionId, message) => ActionResult(ActionResult.STATUS_VALIDATION_FAILED, actionId, message)
    /** Result returned when trusted action code fails. */
    static ExecutionFailed(actionId, message, diagnostic := "", durationMs := 0) => ActionResult(ActionResult.STATUS_EXECUTION_FAILED, actionId, message, diagnostic, durationMs)
}
