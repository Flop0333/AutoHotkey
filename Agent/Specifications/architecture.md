# Personal Agent Architecture

## Runtime

```text
WebView2 UI
   │ message + visible attachments
   ▼
AgentController
   ├─ AgentContextBuilder
   ├─ OpenAIResponsesClient
   ├─ AgentToolCatalogue
   ├─ AgentPolicy
   ├─ ConfirmationService
   ├─ AgentToolExecutor
   └─ AgentAuditLog
```

The model proposes typed calls. Local AHK validates, authorizes, confirms, and executes them. Model output is never executable.

## Boundaries

### AgentController

Owns one turn, cancellation, limits, API continuation, response-item routing, and UI events. It depends on interfaces, not tool-specific behavior.

### OpenAIResponsesClient

Owns HTTP transport and API DTOs. It retrieves the key at request time, redacts headers, applies timeouts, and returns structured transport results. Tests substitute `FakeResponsesClient`.

### AgentToolCatalogue

Owns explicit registration, definition validation, eligibility filtering, lookup, and OpenAI schema serialization. It never scans global functions.

### ToolArgumentValidator

Implements the version 1 JSON-schema subset, returns field-specific errors, and never coerces unexpected values.

### AgentPolicy

Evaluates validated calls against profile, availability, risk, permissions, limits, and confirmation. It never executes tools.

### AgentToolExecutor

Executes the exact registered callable once, catches exceptions, measures duration, and produces `AgentToolResult`.

### Context providers

Return typed attachments containing label, value, sensitivity, and permission requirement. The UI and API share the exact attachment collection, preventing hidden context transmission.

### UI

Uses the existing WebView bridge for conversation and operation cards. Normal operation never displays secrets or raw API JSON.

## Files

```text
Apps Standalone/Personal Agent/
├── Personal Agent.ahk
├── Agent Controller.ahk
├── Agent Configuration.ahk
├── Agent Instructions.ahk
├── API/
├── Context/
├── Safety/
├── Tools/
│   └── Definitions/
├── User Interface/
│   └── Web/
└── Tests/
```

## AgentTool contract

Required local fields:

```text
name, title, description, parameters, execute,
risk, availability, timeoutMs, redactedFields
```

Optional fields:

```text
profiles, resultSchema, confirmationBuilder,
rateLimit, parallelSafe, requiredContext
```

Only name, description, and parameter schema are sent to the model.

## Result contract

```json
{
  "status": "success",
  "summary": "Opened the AutoHotkey repository in VS Code",
  "data": {"application": "vscode"},
  "retryable": false
}
```

Diagnostics sent to the model are sanitized and minimal.

## Dependency direction

```text
UI → Controller → interfaces
API adapter → API DTOs
Catalogue/Policy/Executor → tool domain models
Tool definitions → existing app adapters
Context providers → Windows/profile helpers
```

Existing app adapters never depend on the Personal Agent.

