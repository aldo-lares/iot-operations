#!/usr/bin/env pwsh
# ============================================================================
# PowerShell deployment script for Ubuntu VM with Resource Group creation
# ============================================================================
# This script deploys the Ubuntu VM using subscription-level deployment
# which automatically creates the resource group
# 
# Usage:
#   .\deploy.ps1 [-ResourceGroupName <name>] [-SshKeyPath <path>] [-Location <location>]
#
# Example:
#   .\deploy.ps1 -ResourceGroupName "rg-iot-operations" -SshKeyPath "$HOME\.ssh\id_rsa.pub"
# ============================================================================

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "rg-iot-operations",
    
    [Parameter(Mandatory=$false)]
    [string]$SshKeyPath = "$HOME\.ssh\id_rsa.pub",
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "westus2"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Green
Write-Host "Ubuntu VM Deployment Script (PowerShell)" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Check if Azure CLI is installed
Write-Host "Checking prerequisites..." -ForegroundColor Yellow
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Azure CLI is not installed" -ForegroundColor Red
    Write-Host "Please install it from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
}

# Check if Bicep is installed
try {
    az bicep version 2>&1 | Out-Null
} catch {
    Write-Host "Warning: Bicep CLI is not installed" -ForegroundColor Yellow
    Write-Host "Installing Bicep CLI..." -ForegroundColor Yellow
    az bicep install
}

# Check if SSH key exists
if (-not (Test-Path $SshKeyPath)) {
    Write-Host "Error: SSH public key not found at $SshKeyPath" -ForegroundColor Red
    Write-Host ""
    Write-Host "Generate a new SSH key with:"
    Write-Host "  ssh-keygen -t rsa -b 4096 -f $HOME\.ssh\azure_vm_key" -ForegroundColor Cyan
    exit 1
}

Write-Host "✓ Prerequisites checked" -ForegroundColor Green
Write-Host ""

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  Resource Group: $ResourceGroupName"
Write-Host "  Location: $Location"
Write-Host "  SSH Key: $SshKeyPath"
Write-Host ""

# Check if logged in to Azure
Write-Host "Checking Azure login status..." -ForegroundColor Yellow
try {
    $account = az account show | ConvertFrom-Json
    Write-Host "✓ Logged in to Azure" -ForegroundColor Green
    Write-Host "  Subscription: $($account.name)" -ForegroundColor Gray
    Write-Host ""
} catch {
    Write-Host "Not logged in to Azure" -ForegroundColor Red
    Write-Host "Please run: az login" -ForegroundColor Cyan
    exit 1
}

# Read SSH public key
Write-Host "Reading SSH public key..." -ForegroundColor Yellow
$sshPublicKey = Get-Content $SshKeyPath -Raw
$sshPublicKey = $sshPublicKey.Trim()

if ([string]::IsNullOrWhiteSpace($sshPublicKey)) {
    Write-Host "Error: SSH public key is empty" -ForegroundColor Red
    exit 1
}

Write-Host "✓ SSH key loaded successfully" -ForegroundColor Green
Write-Host ""

# Set environment variable for SSH key (used by bicepparam file)
$env:SSH_PUBLIC_KEY = $sshPublicKey

# Deploy using subscription-level deployment
Write-Host "Deploying infrastructure (this may take several minutes)..." -ForegroundColor Yellow
Write-Host ""

try {
    $deploymentName = "iot-ops-deployment-$(Get-Date -Format 'yyyyMMddHHmmss')"
    
    $outputs = az deployment sub create `
        --name $deploymentName `
        --location $Location `
        --template-file main.sub.bicep `
        --parameters main.sub.bicepparam `
        --parameters resourceGroupName=$ResourceGroupName `
        --query properties.outputs `
        -o json | ConvertFrom-Json
    
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "✓ Deployment completed successfully!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "Deployment Details:" -ForegroundColor Cyan
    Write-Host "  Resource Group: $($outputs.resourceGroupName.value)" -ForegroundColor Gray
    Write-Host "  Public IP: $($outputs.publicIpAddress.value)" -ForegroundColor Gray
    Write-Host "  FQDN: $($outputs.fqdn.value)" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "Connect to your VM:" -ForegroundColor Cyan
    Write-Host "  $($outputs.sshCommand.value)" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "VM Resource ID:" -ForegroundColor Cyan
    Write-Host "  $($outputs.vmId.value)" -ForegroundColor Gray
    Write-Host ""
    
} catch {
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "✗ Deployment failed!" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host "Deployment completed at $(Get-Date)" -ForegroundColor Green
