# agent-toolbelt

A small, opinionated CLI baseline for coding agents — define, explain, and verify the tools agents can rely on.

## Why

Coding agents work better when common command-line capabilities are predictable. Instead of making an agent repeatedly discover which search, JSON, shell, or runtime tools happen to be available, agent-toolbelt defines a small capability baseline and verifies that the commands actually work.

The project is deliberately **agent-neutral**, **editor-neutral**, and **package-manager-neutral**. GitHub Copilot, Codex, Claude Code, Gemini CLI, IDE agents, and other coding agents can all benefit from the same underlying toolbelt.

## v0.1 scope

The first version focuses on three things:

1. **Define** useful command-line capabilities.
2. **Explain** why each capability is useful to coding agents.
3. **Verify** that the corresponding command is present and executable.

Installation and workstation provisioning are intentionally out of scope for v0.1. A tool may have been installed with WinGet, Scoop, Chocolatey, a corporate software portal, or manually; verification only cares whether the capability works.

## Baseline

### Core

| Capability | Command | Purpose |
| --- | --- | --- |
| Source control | `git` | Repository inspection and source-control operations |
| Text search | `rg` | Fast recursive code and text search |
| Shell | `pwsh` | Modern scriptable PowerShell environment |
| JSON query | `jq` | Deterministic JSON querying and transformation |
| HTTP client | `curl.exe` | Non-interactive HTTP and API operations |

A missing or broken Core capability makes the baseline fail.

### Recommended

`fd`, `yq`, Python, and `uv` provide useful general-purpose capabilities but do not currently determine the Core pass/fail result.

### Workload profiles

The initial inventory also checks common .NET, web, Azure, GitLab, and GitHub tooling. These are workload-specific rather than universal Core requirements.

## Usage

Run the read-only verifier:

```powershell
./Test-AgentToolbelt.ps1
```

Include the rationale for every tool:

```powershell
./Test-AgentToolbelt.ps1 -Explain
```

The verifier reports:

- `PASS` — command was found and its verification command succeeded.
- `MISSING` — command was not found.
- `BROKEN` — command was found but could not be executed successfully.

The script makes no system changes and requires no installation privileges.

## Design principles

- **Capabilities before packages.** Define what an agent needs before deciding how software is installed.
- **Executable beats installed.** A package being present is irrelevant if the command does not actually work.
- **Small baseline.** Core should contain only broadly useful capabilities with clear agent value.
- **Read-only by default.** Assessment must be safe on managed and locked-down machines.
- **No vendor assumption.** Git is fundamental; GitHub, GitLab, and Azure DevOps integrations are profiles.
- **Installation is an adapter.** Future installers may support WinGet, Scoop, Chocolatey, corporate deployment, or other mechanisms without changing the capability model.

## Status

Early v0.1 experiment. The baseline and profile boundaries are expected to evolve as they are tested across different Windows environments.
