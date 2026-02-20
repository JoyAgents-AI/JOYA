# joy-adapter-openclaw.ps1 — Connect/disconnect OpenClaw workspace to JOYA (Windows)
#
# Usage:
#   .\joy-adapter-openclaw.ps1 install <agent-name> [-JoyRoot <path>] [-Workspace <path>] [-Force]
#   .\joy-adapter-openclaw.ps1 uninstall <agent-name> [-JoyRoot <path>] [-Workspace <path>]
#   .\joy-adapter-openclaw.ps1 status <agent-name> [-JoyRoot <path>] [-Workspace <path>]
#
# Windows adaptation: uses pointer files instead of symlinks (symlinks don't work over NFS).

param(
    [Parameter(Position=0, Mandatory=$true)]
    [ValidateSet("install","uninstall","status")]
    [string]$Action,

    [Parameter(Position=1, Mandatory=$true)]
    [string]$AgentName,

    [string]$JoyRoot = "",
    [string]$Workspace = "",
    [switch]$Force
)

$BackupSuffix = ".bak.pre-joy"
$OcConfig = "$env:USERPROFILE\.openclaw\openclaw.json"

# --- Resolve JoyRoot ---
if (-not $JoyRoot) {
    # Try common locations
    $candidates = @(
        "$env:USERPROFILE\Code\joy-agents",
        "C:\joy-agents"
    )
    foreach ($c in $candidates) {
        if (Test-Path "$c\AGENT_INIT.md") {
            $JoyRoot = $c
            break
        }
    }
    if (-not $JoyRoot) {
        Write-Error "Cannot find joy-agents root. Use -JoyRoot to specify."
        exit 1
    }
}

# --- Resolve Workspace ---
if (-not $Workspace) {
    if (Test-Path $OcConfig) {
        $cfg = Get-Content $OcConfig -Raw | ConvertFrom-Json
        $ws = $cfg.agents.defaults.workspace
        if ($ws -and (Test-Path $ws)) {
            $Workspace = $ws
        }
    }
    if (-not $Workspace) {
        $Workspace = "$env:USERPROFILE\.openclaw\workspace"
    }
}

$AgentDir = "$JoyRoot\instance\agents\$AgentName"
$ConfigDir = "$JoyRoot\instance\shared\config"
$Marker = "$Workspace\.joy-adapter-openclaw"

# --- Helper: Write pointer file ---
function Write-Pointer {
    param([string]$Path, [string]$Content)
    if (Test-Path $Path) { Remove-Item $Path -Force }
    Set-Content -Path $Path -Value $Content -Encoding UTF8
}

# --- Helper: Backup file ---
function Backup-File {
    param([string]$Path)
    if (Test-Path $Path) {
        $backup = "${Path}${BackupSuffix}"
        Copy-Item $Path $backup -Force
        Write-Host "      > $(Split-Path $Path -Leaf) backed up"
    }
}

# =============================================================
# INSTALL
# =============================================================
function Do-Install {
    Write-Host ""
    Write-Host "=== Installing JOYA adapter for OpenClaw (Windows) ==="
    Write-Host "   Agent:     $AgentName"
    Write-Host "   JoyRoot:   $JoyRoot"
    Write-Host "   AgentDir:  $AgentDir"
    Write-Host "   Workspace: $Workspace"
    Write-Host ""

    if (-not (Test-Path $AgentDir)) {
        Write-Error "Agent directory not found: $AgentDir"
        exit 1
    }
    if (-not (Test-Path $Workspace)) {
        Write-Error "Workspace not found: $Workspace"
        exit 1
    }
    if ((Test-Path $Marker) -and -not $Force) {
        Write-Host "Already installed. Use -Force to reinstall."
        return
    }

    # Ensure memory dir exists
    $memDir = "$AgentDir\memory"
    if (-not (Test-Path $memDir)) { New-Item -ItemType Directory -Path $memDir -Force | Out-Null }

    # --- Phase 1: Import ---
    Write-Host "Phase 1: Import existing workspace data"

    # MEMORY.md
    $wsMemory = "$Workspace\MEMORY.md"
    $joyMemory = "$AgentDir\MEMORY.md"
    if ((Test-Path $wsMemory) -and -not (Get-Content $wsMemory -Raw -ErrorAction SilentlyContinue | Select-String "JOYA")) {
        $wsLines = (Get-Content $wsMemory).Count
        $joyLines = 0
        if (Test-Path $joyMemory) { $joyLines = (Get-Content $joyMemory).Count }
        if ($joyLines -lt 5 -and $wsLines -gt 5) {
            Copy-Item $wsMemory $joyMemory -Force
            Write-Host "   MEMORY.md ($wsLines lines) imported"
        }
    }

    # SOUL.md → append to IDENTITY.md
    $wsSoul = "$Workspace\SOUL.md"
    if ((Test-Path $wsSoul) -and -not (Get-Content $wsSoul -Raw -ErrorAction SilentlyContinue | Select-String "JOYA")) {
        $soulContent = Get-Content $wsSoul -Raw
        $identityFile = "$AgentDir\IDENTITY.md"
        if ((Test-Path $identityFile) -and -not (Get-Content $identityFile -Raw | Select-String "Imported from OpenClaw SOUL.md")) {
            $append = "`n---`n## Imported from OpenClaw SOUL.md`n`n$soulContent"
            Add-Content -Path $identityFile -Value $append
            Write-Host "   SOUL.md appended to IDENTITY.md"
        }
    }

    # IDENTITY.md (OpenClaw format)
    $wsIdentity = "$Workspace\IDENTITY.md"
    if ((Test-Path $wsIdentity) -and -not (Get-Content $wsIdentity -Raw -ErrorAction SilentlyContinue | Select-String "JOYA")) {
        $idContent = Get-Content $wsIdentity -Raw
        $identityFile = "$AgentDir\IDENTITY.md"
        if ((Test-Path $identityFile) -and -not (Get-Content $identityFile -Raw | Select-String "Imported from OpenClaw IDENTITY.md")) {
            $append = "`n---`n## Imported from OpenClaw IDENTITY.md`n`n$idContent"
            Add-Content -Path $identityFile -Value $append
            Write-Host "   IDENTITY.md appended"
        }
    }

    # TOOLS.md
    if ((Test-Path "$Workspace\TOOLS.md") -and -not (Test-Path "$AgentDir\TOOLS.md")) {
        Copy-Item "$Workspace\TOOLS.md" "$AgentDir\TOOLS.md"
        Write-Host "   TOOLS.md imported"
    }

    # --- Phase 2: Link (pointer files, no symlinks) ---
    Write-Host ""
    Write-Host "Phase 2: Create pointer files (Windows — no symlinks over NFS)"

    # Backup existing files
    foreach ($f in @("SOUL.md","USER.md","AGENTS.md","IDENTITY.md","MEMORY.md","TOOLS.md","HEARTBEAT.md")) {
        Backup-File "$Workspace\$f"
    }

    # AGENTS.md — the key file that tells the agent where everything is
    Write-Pointer "$Workspace\AGENTS.md" @"
# Agents — JOYA Governed

This workspace is governed by the JOYA protocol.

## On every session start (and after compaction)

1. Read ``$JoyRoot/AGENT_INIT.md`` — JOYA entry point
2. Read ``$AgentDir/IDENTITY.md`` — who you are
3. Read ``$AgentDir/MEMORY.md`` and ``memory/`` — your memories (WRITE here too)
4. Read ``$ConfigDir/PRINCIPAL.md`` — who you serve
5. Read ``$ConfigDir/PLAYBOOK.md`` — how this instance operates
6. Read ``$ConfigDir/INFRASTRUCTURE.md`` — comms tokens, services, endpoints

## Key paths

- JOYA root: ``$JoyRoot/``
- Your agent dir: ``$AgentDir/``
- Framework core: ``$JoyRoot/framework/core/``
- Framework guides: ``$JoyRoot/framework/guides/``
- Framework toolkit: ``$JoyRoot/framework/toolkit/``
- Team roster: ``$JoyRoot/instance/agents/ROSTER.md``
- Team directory: ``$JoyRoot/instance/agents/DIRECTORY.json``
- Infrastructure: ``$ConfigDir/INFRASTRUCTURE.md``

## Your private tools

- Scripts: ``$AgentDir/scripts/``
- Skills: ``$AgentDir/skills/``

## Key rules (from framework)

- **A2**: Confirm receipt before acting
- **A3**: Don't waste context — summarize, reference, don't duplicate
- **R4**: Never write secrets to memory or messages
- **R11**: All project artifacts go in ``.joy/`` directory
- **Memory**: Always write MEMORY.md to your agent dir (path above), NOT local workspace
- Update MEMORY.md with important learnings after each session
"@
    Write-Host "      AGENTS.md created"

    # SOUL.md pointer
    Write-Pointer "$Workspace\SOUL.md" @"
# Soul — JOYA Bridge

This agent's identity is managed by JOYA.

Read and embody the personality defined in ``$AgentDir/IDENTITY.md``.

For team info, read ``$JoyRoot/instance/agents/ROSTER.md``.
"@
    Write-Host "      SOUL.md pointer created"

    # USER.md pointer
    Write-Pointer "$Workspace\USER.md" @"
# User — JOYA Bridge

Read ``$ConfigDir/PRINCIPAL.md`` for information about your Principal.
"@
    Write-Host "      USER.md pointer created"

    # IDENTITY.md pointer
    Write-Pointer "$Workspace\IDENTITY.md" @"
# Identity — JOYA Bridge

Read ``$AgentDir/IDENTITY.md`` for your full identity definition.
"@
    Write-Host "      IDENTITY.md pointer created"

    # MEMORY.md pointer (tells agent to read/write from NFS)
    Write-Pointer "$Workspace\MEMORY.md" @"
# Memory — JOYA Bridge

Your authoritative memory is at: ``$AgentDir/MEMORY.md``
Daily notes: ``$AgentDir/memory/``

Always read and write memory at the paths above (NFS), not this local file.
"@
    Write-Host "      MEMORY.md pointer created"

    # TOOLS.md pointer
    Write-Pointer "$Workspace\TOOLS.md" @"
# Tools — JOYA Bridge

Your tools config is at: ``$AgentDir/TOOLS.md``
"@
    Write-Host "      TOOLS.md pointer created"

    # Write marker
    @"
agent=$AgentName
joy_root=$JoyRoot
workspace=$Workspace
installed=$(Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
"@ | Set-Content -Path $Marker -Encoding UTF8

    Write-Host ""
    Write-Host "=========================================="
    Write-Host "Done! OpenClaw workspace connected to JOYA."
    Write-Host ""
    Write-Host "  Agent '$AgentName' identity: $AgentDir\IDENTITY.md"
    Write-Host "  Memory (NFS):               $AgentDir\MEMORY.md"
    Write-Host "  Memory archive (NFS):       $AgentDir\memory\"
    Write-Host ""
    Write-Host "  To undo: .\joy-adapter-openclaw.ps1 uninstall $AgentName"
    Write-Host "=========================================="
}

# =============================================================
# UNINSTALL
# =============================================================
function Do-Uninstall {
    Write-Host "Uninstalling JOYA adapter for '$AgentName'"

    if (-not (Test-Path $Marker)) {
        Write-Host "No JOYA adapter found in workspace: $Workspace"
        return
    }

    # Export latest memory
    if (Test-Path "$AgentDir\MEMORY.md") {
        Copy-Item "$AgentDir\MEMORY.md" "$Workspace\MEMORY.md.joy-export" -Force
        Write-Host "   Latest memory exported to MEMORY.md.joy-export"
    }

    # Restore backups
    foreach ($f in @("SOUL.md","USER.md","AGENTS.md","IDENTITY.md","MEMORY.md","TOOLS.md","HEARTBEAT.md")) {
        $backup = "$Workspace\${f}${BackupSuffix}"
        $target = "$Workspace\$f"
        if (Test-Path $backup) {
            if (Test-Path $target) { Remove-Item $target -Force }
            Move-Item $backup $target
            Write-Host "   Restored: $f"
        }
    }

    Remove-Item $Marker -Force
    Write-Host ""
    Write-Host "Done! Workspace restored."
}

# =============================================================
# STATUS
# =============================================================
function Do-Status {
    Write-Host "JOYA Adapter Status ($AgentName)"
    Write-Host "   Workspace: $Workspace"
    Write-Host ""

    if (Test-Path $Marker) {
        Write-Host "   Status: INSTALLED"
        Get-Content $Marker | ForEach-Object { Write-Host "   $_" }
        Write-Host ""

        Write-Host "   Pointer files:"
        foreach ($f in @("AGENTS.md","SOUL.md","USER.md","IDENTITY.md","MEMORY.md","TOOLS.md")) {
            $path = "$Workspace\$f"
            if (Test-Path $path) {
                $content = Get-Content $path -Raw -ErrorAction SilentlyContinue
                if ($content -match "JOYA") {
                    Write-Host "      OK  $f"
                } else {
                    Write-Host "      ??  $f (no JOYA reference)"
                }
            } else {
                Write-Host "      --  $f (missing)"
            }
        }

        Write-Host ""
        Write-Host "   NFS access:"
        if (Test-Path "$AgentDir\IDENTITY.md") {
            Write-Host "      OK  Agent dir readable"
        } else {
            Write-Host "      FAIL  Cannot read $AgentDir"
        }
        if (Test-Path "$JoyRoot\framework\VERSION") {
            $ver = (Get-Content "$JoyRoot\framework\VERSION" -Raw).Trim()
            Write-Host "      OK  Framework v$ver"
        } else {
            Write-Host "      FAIL  Cannot read framework/VERSION"
        }
    } else {
        Write-Host "   Status: NOT INSTALLED"
    }
}

# =============================================================
# DISPATCH
# =============================================================
switch ($Action) {
    "install"   { Do-Install }
    "uninstall" { Do-Uninstall }
    "status"    { Do-Status }
}
