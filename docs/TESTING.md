# Testing

The repository uses lightweight AutoHotkey v2 tests driven by PowerShell. No external test framework or package installation is required locally beyond AutoHotkey v2.

## Run the tests

From the repository root in PowerShell:

```powershell
# Everything: syntax, unit, then integration
./Tests/Invoke-AllTests.ps1

# Individual suites
./Tests/Invoke-SyntaxCheck.ps1
./Tests/Invoke-UnitTests.ps1
./Tests/Invoke-IntegrationTests.ps1
```

The runners find `AutoHotkey.exe` or `AutoHotkey64.exe` on `PATH`, then try the normal AutoHotkey v2 installation directories under Program Files. Each command exits `0` on success and `1` on failure, so the same runners work locally and in CI.

Optional timeout parameters are available when diagnosing a slow machine:

```powershell
./Tests/Invoke-AllTests.ps1 -TimeoutSeconds 240
./Tests/Invoke-SyntaxCheck.ps1 -TimeoutSeconds 30
./Tests/Invoke-UnitTests.ps1 -TimeoutSeconds 40
./Tests/Invoke-IntegrationTests.ps1 -TimeoutSeconds 120
```

## What each suite checks

### Syntax check

`Invoke-SyntaxCheck.ps1` parses each active AutoHotkey v2 entry point without running its hotkeys, GUIs, or startup actions. It creates a temporary wrapper that exits before including the target; AutoHotkey still parses the complete include tree first.

Targets are discovered from the `Run(...)` calls in `Startup/Startup.ahk`, plus the logging hosts, Test Dashboard host, logging facade, and manual `Tests/Run-Tests.ahk` entry point. A missing file, non-zero exit, or blocked load-error dialog fails the suite. Optional scripts not in that target set, including the AutoHotkey v1 Bluetooth script, are not covered.

### Unit tests

`Invoke-UnitTests.ps1` discovers every `Tests/Unit/*.Tests.ahk` file alphabetically and runs each as a separate process. Current coverage includes array, database/state behavior, structured logging, number conversion, and secrets-file behavior.

`Tests/Support/Assert.ahk` provides the dependency-free `Assert` methods and `TestKit` runner. Each test file prints `PASS`/`FAIL` lines and reports through its process exit code.

### Integration tests

`Invoke-IntegrationTests.ps1` runs `Tests/Integration/Logging.Integration.Tests.ahk`. It exercises real logger/dashboard processes and shared logging behavior while redirecting `AUTOHOTKEY_LOG_DIR` to a temporary directory. The runner restores the caller's environment and removes temporary files afterward.

## Test Dashboard and results

Double-click `Tests/Run-Tests.ahk`, choose **Test Dashboard** from the startup tray, or run the `Test` command in Age of Efficiency. The launcher opens the dashboard and runs `Invoke-AllTests.ps1` in a hidden PowerShell process.

The combined runner writes git-ignored runtime data:

- `Logs/test-run-status.json` — current state and most recent result, polled by the dashboard;
- `Logs/test-run-history.log` — one compact JSON object per completed run, oldest first.

Direct individual-suite runs print results to the terminal but do not update dashboard history. Delete the two result files only when intentionally resetting the local dashboard history.

## Add or change tests

For a unit test:

1. Create or update a `Tests/Unit/<Area>.Tests.ahk` file.
2. Add `#Requires AutoHotkey v2`, include `Tests/Support/Assert.ahk`, and include the code under test.
3. Register cases with `TestKit.Run("description", testFunction)`.
4. Call `TestKit.Report()` exactly once at the end.
5. Keep tests deterministic and redirect file operations to a unique temporary directory with cleanup.

For cross-process or UI behavior, add focused coverage under `Tests/Integration/` and update `Invoke-IntegrationTests.ps1` if introducing another integration entry point. Use bounded waits instead of fixed long sleeps, isolate logs through `AUTOHOTKEY_LOG_DIR`, and always close processes and remove temporary data.

When adding an application to `RunStartup()`, the syntax runner normally discovers it automatically. Update the explicit target list only for an important entry point that is not started there.

## CI

`.github/workflows/ahk-tests.yml` runs all three suites on `windows-latest` for pushes and pull requests targeting `main`. It downloads the latest official AutoHotkey v2 release from `AutoHotkey/AutoHotkey` on GitHub and adds it to `PATH`.

After a PR test run completes, `.github/workflows/ci-failure-summary.yml` maintains one readable failure-summary comment on that PR. See [Startup and GitHub automation](AUTOMATION.md) for the complete connection map.

Before submitting a change, run the most focused relevant suite and then `Invoke-AllTests.ps1` when the change affects shared code, startup, includes, logging, or test infrastructure.
