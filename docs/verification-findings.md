# Verification findings

## Windows Python App Execution Alias (October 2026)

**Observed on:** a Windows home laptop during the v0.1 machine-only verifier trial.

**Initial result:** Python was reported as `BROKEN`, not `MISSING`.

Evidence:

```powershell
Get-Command python -All
# C:\Users\marku\AppData\Local\Microsoft\WindowsApps\python.exe

where.exe python
# C:\Users\marku\AppData\Local\Microsoft\WindowsApps\python.exe

python --version
# Python was not found; Windows offered installation from Microsoft Store

py --list
# py: command not recognized
```

**Diagnosis:** Windows exposed a `python.exe` App Execution Alias on `PATH`, but no working Python runtime was accessible through that command. Command discovery alone was therefore insufficient. The verifier correctly marked it `BROKEN` because the version check failed.

**Resolution:** After installing Python 3.13, the verifier reported `PASS` with `Python 3.13.15`.

**Lessons:**

- Keep `MISSING` (no command found) distinct from `BROKEN` (command found, verification fails).
- A WindowsApps alias is not proof that the underlying runtime is installed.
- For future diagnostics, consider surfacing the resolved command path, exit code, and a *possible App Execution Alias* hint when applicable. Do not automatically repair, disable aliases, or install software.
- This is a machine-state observation, not a workspace dependency or version-compatibility check; workspace requirements remain outside v0.1 scope.

**Related cross-machine observation:** A work laptop exposed a `pnpm` command whose shim failed to run; that was also correctly classified as `BROKEN`. Different causes, same status semantics.
