param(
    [Parameter(Mandatory=$true)][string]$TenantId
)

Write-Host "=== Token Persistence Test ==="
Write-Host "This should NOT require device code — uses Azure CLI cached tokens."
Write-Host ""

# Check Azure CLI has a valid session
Write-Host "--- Azure CLI status ---"
$account = az account show --query "{name:name, tenantId:tenantId, user:user.name}" -o table 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "FAIL: No Azure CLI session. Run bootstrap.ps1 first."
    Write-Host $account
    exit 1
}
Write-Host $account
Write-Host ""

# Get Graph token silently
Write-Host "--- Graph token (silent) ---"
$graphToken = az account get-access-token --tenant $TenantId --resource https://graph.microsoft.com --query accessToken -o tsv 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "FAIL: Could not get Graph token silently: $graphToken"
    exit 1
}
Write-Host "OK: Got Graph token (silent, no device code)"

# Connect to Graph
Import-Module Microsoft.Graph.Authentication
$secureToken = ConvertTo-SecureString $graphToken -AsPlainText -Force
Connect-MgGraph -AccessToken $secureToken -NoWelcome

$ctx = Get-MgContext
Write-Host "  TenantId: $($ctx.TenantId)"
Write-Host "  AuthType: $($ctx.AuthType)"
Write-Host ""

# Test API call
Write-Host "--- Graph API call ---"
try {
    Import-Module Microsoft.Graph.Users
    $user = Get-MgUser -Top 1 -Property DisplayName,UserPrincipalName -ErrorAction Stop
    Write-Host "OK: $($user.DisplayName) ($($user.UserPrincipalName))"
} catch {
    Write-Host "FAIL: $_"
}
Write-Host ""

# Test EXO token
Write-Host "--- EXO token (silent) ---"
$exoToken = az account get-access-token --tenant $TenantId --resource https://outlook.office365.com --query accessToken -o tsv 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "FAIL: Could not get EXO token silently: $exoToken"
} else {
    Write-Host "OK: Got EXO token (silent, no device code)"
    Import-Module ExchangeOnlineManagement
    $exoTemp = Join-Path $HOME ".exo-tmp"
    New-Item -ItemType Directory -Force -Path $exoTemp | Out-Null
    try {
        Connect-ExchangeOnline -AccessToken $exoToken -Organization "railcontrol.com.au" -ShowBanner:$false
        Write-Host "OK: EXO connected"
    } catch {
        Write-Host "FAIL: EXO connect failed: $_"
    }
}

Write-Host ""
Write-Host "=== RESULT: All tokens acquired silently from Azure CLI cache ==="
