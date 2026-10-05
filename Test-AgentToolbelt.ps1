param(
    [switch]$Explain
)

# Test-AgentToolbelt.ps1
#
# Read-only verification of command-line capabilities useful to coding agents.
# This script does not install software or modify system configuration.

$tools = @(
    @{ Name = "Git"; Command = "git"; Args = @("--version"); Category = "Core"; Capability = "source-control"; Reason = "Provides source control operations and repository inspection. Git is broadly assumed by coding agents when working with source repositories." },
    @{ Name = "ripgrep"; Command = "rg"; Args = @("--version"); Category = "Core"; Capability = "text-search"; Reason = "Provides fast recursive text and code search with predictable CLI behavior. Coding agents commonly use it to navigate repositories efficiently." },
    @{ Name = "PowerShell 7"; Command = "pwsh"; Args = @("--version"); Category = "Core"; Capability = "shell"; Reason = "Provides a modern, scriptable shell with structured object handling and consistent behavior across supported Windows environments." },
    @{ Name = "jq"; Command = "jq"; Args = @("--version"); Category = "Core"; Capability = "json-query"; Reason = "Provides deterministic querying and transformation of JSON from APIs, CLI tools, configuration files, and build output." },
    @{ Name = "curl"; Command = "curl.exe"; Args = @("--version"); Category = "Core"; Capability = "http-client"; Reason = "Provides a widely understood, non-interactive HTTP client for testing APIs, downloading resources, and inspecting HTTP behavior." },

    @{ Name = "fd"; Command = "fd"; Args = @("--version"); Category = "Recommended"; Capability = "file-discovery"; Reason = "Provides fast and convenient filesystem discovery. It complements ripgrep when agents need to locate files by name or path." },
    @{ Name = "yq"; Command = "yq"; Args = @("--version"); Category = "Recommended"; Capability = "yaml-query"; Reason = "Provides deterministic querying and transformation of YAML, useful for pipelines, configuration files, manifests, and automation." },
    @{ Name = "Python"; Command = "python"; Args = @("--version"); Category = "Recommended"; Capability = "python-runtime"; Reason = "Provides a broadly available scripting runtime for data transformation, automation, and tasks that are awkward in shell scripts." },
    @{ Name = "uv"; Command = "uv"; Args = @("--version"); Category = "Recommended"; Capability = "python-tooling"; Reason = "Provides fast and reproducible Python package, tool, and virtual-environment management without requiring agents to manipulate global Python installations." },

    @{ Name = ".NET SDK"; Command = "dotnet"; Args = @("--version"); Category = ".NET"; Capability = "dotnet-sdk"; Reason = "Provides build, test, restore, formatting, package, and project operations for .NET repositories." },

    @{ Name = "Node.js"; Command = "node"; Args = @("--version"); Category = "Web"; Capability = "javascript-runtime"; Reason = "Provides the JavaScript runtime required by modern frontend build systems, development tools, and many CLI utilities." },
    @{ Name = "npm"; Command = "npm"; Args = @("--version"); Category = "Web"; Capability = "npm-package-manager"; Reason = "Provides the standard Node.js package-management workflow used by many JavaScript and frontend repositories." },
    @{ Name = "pnpm"; Command = "pnpm"; Args = @("--version"); Category = "Web"; Capability = "pnpm-package-manager"; Reason = "Provides efficient dependency management for repositories that use pnpm, including many modern monorepos." },

    @{ Name = "Azure CLI"; Command = "az"; Args = @("version", "--output", "json"); VersionProperty = "azure-cli"; Category = "Azure"; Capability = "azure-cli"; Reason = "Provides scriptable access to Azure resources and services using documented CLI commands." },

    @{ Name = "GitLab CLI"; Command = "glab"; Args = @("--version"); Category = "GitLab"; Capability = "gitlab-cli"; Reason = "Provides scriptable access to GitLab-specific operations such as merge requests, issues, pipelines, and repository metadata." },
    @{ Name = "GitHub CLI"; Command = "gh"; Args = @("--version"); Category = "GitHub / Optional"; Capability = "github-cli"; Reason = "Provides scriptable access to GitHub-specific operations such as pull requests, issues, workflows, releases, and repository metadata." },

    @{ Name = "WinGet"; Command = "winget"; Args = @("--version"); Category = "Package manager"; Capability = "package-manager-winget"; Reason = "Potential future installation adapter on supported Windows environments. Its presence is not required for agent readiness." },
    @{ Name = "Scoop"; Command = "scoop"; Args = @("--version"); Category = "Package manager"; Capability = "package-manager-scoop"; Reason = "Potential future per-user installation adapter, particularly useful where administrator privileges are unavailable." },
    @{ Name = "Chocolatey"; Command = "choco"; Args = @("--version"); Category = "Package manager"; Capability = "package-manager-chocolatey"; Reason = "Potential future installation adapter, including for some older Windows and Windows Server environments." }
)

function Test-Tool {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Tool
    )

    $command = Get-Command $Tool.Command -ErrorAction SilentlyContinue | Select-Object -First 1

    if (-not $command) {
        return [PSCustomObject]@{
            Category = $Tool.Category; Tool = $Tool.Name; Command = $Tool.Command
            Capability = $Tool.Capability; Status = "MISSING"; Version = ""
            Path = ""; Reason = $Tool.Reason; Error = ""
        }
    }

    try {
        $global:LASTEXITCODE = 0
        $output = @(& $Tool.Command @($Tool.Args) 2>&1)
        $exitCode = $LASTEXITCODE

        if ($null -ne $exitCode -and $exitCode -ne 0) {
            throw "Command exited with code $exitCode. $($output -join ' ')"
        }

        $version = ($output | Select-Object -First 1 | Out-String).Trim()

        if ($Tool.VersionProperty) {
            $parsed = ($output -join [Environment]::NewLine) | ConvertFrom-Json
            $version = [string]$parsed.($Tool.VersionProperty)
        }

        return [PSCustomObject]@{
            Category = $Tool.Category; Tool = $Tool.Name; Command = $Tool.Command
            Capability = $Tool.Capability; Status = "PASS"; Version = $version
            Path = $command.Source; Reason = $Tool.Reason; Error = ""
        }
    }
    catch {
        return [PSCustomObject]@{
            Category = $Tool.Category; Tool = $Tool.Name; Command = $Tool.Command
            Capability = $Tool.Capability; Status = "BROKEN"; Version = ""
            Path = $command.Source; Reason = $Tool.Reason; Error = $_.Exception.Message
        }
    }
}

$results = foreach ($tool in $tools) {
    Test-Tool -Tool $tool
}

$results |
    Sort-Object Category, Tool |
    Format-Table Category, Tool, Capability, Status, Version -AutoSize

if ($Explain) {
    Write-Host ""
    Write-Host "Tool explanations"
    Write-Host "================="

    foreach ($result in ($results | Sort-Object Category, Tool)) {
        Write-Host ""
        Write-Host "$($result.Tool) [$($result.Status)]"
        Write-Host "Category:   $($result.Category)"
        Write-Host "Capability: $($result.Capability)"
        Write-Host "Command:    $($result.Command)"

        if ($result.Path) { Write-Host "Path:       $($result.Path)" }
        if ($result.Version) { Write-Host "Version:    $($result.Version)" }

        Write-Host ""
        Write-Host "Why:"
        Write-Host $result.Reason

        if ($result.Status -eq "BROKEN") {
            Write-Host ""
            Write-Host "Error:"
            Write-Host $result.Error
        }
    }
}

$coreFailures = @($results | Where-Object {
    $_.Category -eq "Core" -and $_.Status -ne "PASS"
})
$otherIssues = @($results | Where-Object {
    $_.Category -ne "Core" -and
    $_.Category -ne "Package manager" -and
    $_.Status -eq "BROKEN"
})

Write-Host ""
Write-Host "=========================="

if ($coreFailures.Count -gt 0) {
    Write-Host "Agent CLI Baseline: FAIL"
}
else {
    Write-Host "Agent CLI Baseline: PASS"
}

Write-Host ""
Write-Host "Core:"
if ($coreFailures.Count -eq 0) {
    Write-Host "  All core capabilities are ready."
}
else {
    foreach ($failure in $coreFailures) {
        Write-Host ("  {0,-8} {1,-10} {2}" -f $failure.Status, $failure.Command, $failure.Capability)
    }
}

if ($otherIssues.Count -gt 0) {
    Write-Host ""
    Write-Host "Other issues:"
    foreach ($issue in $otherIssues) {
        Write-Host ("  {0,-8} {1,-10} {2}" -f $issue.Status, $issue.Command, $issue.Capability)
    }
}

Write-Host ""
Write-Host "Inventory:"
$results |
    Where-Object { $_.Category -ne "Package manager" } |
    Group-Object Category |
    Sort-Object Name |
    ForEach-Object {
        $ready = @($_.Group | Where-Object Status -eq "PASS").Count
        $total = $_.Count
        Write-Host ("  {0,-18} {1}/{2} ready" -f $_.Name, $ready, $total)
    }

if ($coreFailures.Count -gt 0) {
    exit 1
}

exit 0
