Param(
    [string]$TemplateFile = "../infra/main.bicep",
    [string]$ParamFile = "../infra/main.bicepparam"
)

# Normalize template paths relative to this script location
$TemplateFile = (Resolve-Path -Path (Join-Path $PSScriptRoot $TemplateFile)).ProviderPath
$ParamFile = (Resolve-Path -Path (Join-Path $PSScriptRoot $ParamFile) -ErrorAction SilentlyContinue)?.ProviderPath

Write-Host "=== Azure Bicep Deployment ===" -ForegroundColor Cyan

# Prompt inputs
$projectNameDefault = "iothost"
$projectName = Read-Host "Project name (default: $projectNameDefault)"
if ([string]::IsNullOrWhiteSpace($projectName)) { $projectName = $projectNameDefault }

$rgLocationDefault = "westus"
$rgLocation = Read-Host "Resource group location (default: $rgLocationDefault)"
if ([string]::IsNullOrWhiteSpace($rgLocation)) { $rgLocation = $rgLocationDefault }

function Resolve-PublicKeyPath {
    param([string]$InputPath)
    $candidates = @()

    $defaultEd = Join-Path $HOME ".ssh/id_ed25519.pub"
    $defaultRsa = Join-Path $HOME ".ssh/id_rsa.pub"

    if (-not [string]::IsNullOrWhiteSpace($InputPath)) {
        $candidates += $InputPath
    }
    $candidates += $defaultEd
    $candidates += $defaultRsa

    foreach ($path in $candidates) {
        $p = $path
        if ($p.StartsWith('~')) { $p = $p -replace '^~', $HOME }
        $resolved = Resolve-Path -Path $p -ErrorAction SilentlyContinue
        if ($resolved) { return $resolved.ProviderPath }
    }
    return $null
}

$defaultPubKeyPath = Join-Path $HOME ".ssh/id_ed25519.pub"
$sshKeyPathInput = Read-Host "Path to SSH public key (default tries: $defaultPubKeyPath, then id_rsa.pub)"
$sshKeyPath = Resolve-PublicKeyPath -InputPath $sshKeyPathInput
if (-not $sshKeyPath) { throw "SSH public key not found. Provide a valid .pub path." }

$sshKey = Get-Content $sshKeyPath -Raw
if ($sshKey -match "PRIVATE KEY") { throw "The file appears to be a PRIVATE key. Use the .pub public key file." }
$sshKey = $sshKey -replace '\r?\n','' -replace '\s+$',''

# Choose deployment location (control plane). Default to same as RG for simplicity.
$deploymentLocation = Read-Host "Deployment location for control plane (default: $rgLocation)"
if ([string]::IsNullOrWhiteSpace($deploymentLocation)) { $deploymentLocation = $rgLocation }

# Unique deployment name to avoid location conflicts with prior deployments
$deploymentName = "deploy-$($projectName)-$($rgLocation)-$(Get-Date -Format 'yyyyMMddHHmmss')"

Write-Host "Deploying with:" -ForegroundColor Yellow
Write-Host "  projectName = $projectName"
Write-Host "  rg location = $rgLocation"
Write-Host "  deployment location = $deploymentLocation"
Write-Host "  SSH key from = $sshKeyPath"
Write-Host "  deployment name = $deploymentName"

$confirm = Read-Host "Proceed? (y/n, default: y)"
if ([string]::IsNullOrWhiteSpace($confirm)) { $confirm = 'y' }
if ($confirm -ne 'y') { Write-Host "Aborted."; exit 1 }

$quotedKey = 'adminSshPublicKey=' + '"' + $sshKey + '"'

$cmd = @(
    "az", "deployment", "sub", "create",
    "--location", $deploymentLocation,
    "--name", $deploymentName,
    "--template-file", $TemplateFile,
    "--parameters",
        "projectName=$projectName",
        "location=$rgLocation",
        $quotedKey
)

Write-Host "Running: $($cmd -join ' ')" -ForegroundColor Cyan
$proc = Start-Process -FilePath $cmd[0] -ArgumentList $cmd[1..($cmd.Length-1)] -NoNewWindow -Wait -PassThru
if ($proc.ExitCode -ne 0) {
    throw "Deployment failed with exit code $($proc.ExitCode)"
}

Write-Host "Deployment completed." -ForegroundColor Green
