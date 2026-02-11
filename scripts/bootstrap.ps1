param(
    [Parameter(Mandatory=$true)][string]$TenantId,
    [Parameter(Mandatory=$true)][string]$Upn,
    [string[]]$GraphScopes = @(
        "User.ReadWrite.All",
        "Group.ReadWrite.All",
        "GroupMember.ReadWrite.All",
        "Directory.ReadWrite.All",
        "Organization.Read.All",
        "RoleManagement.Read.All",
        "DeviceManagementManagedDevices.ReadWrite.All",
        "DeviceManagementConfiguration.ReadWrite.All",
        "DeviceManagementServiceConfig.ReadWrite.All",
        "Mail.ReadWrite",
        "MailboxSettings.ReadWrite",
        "Sites.ReadWrite.All",
        "Files.ReadWrite.All",
        "TeamSettings.ReadWrite.All",
        "Channel.ReadBasic.All",
        "AuditLog.Read.All",
        "Reports.Read.All",
        "Policy.Read.All",
        "Policy.ReadWrite.ConditionalAccess",
        "IdentityRiskyUser.Read.All",
        "SecurityEvents.Read.All",
        "UserAuthenticationMethod.ReadWrite.All"
    )
)

Write-Host "PowerShell: $($PSVersionTable.PSVersion)"
Write-Host "Tenant: $TenantId"
Write-Host ""

# Step 1: Azure CLI login (device code - tokens persist on disk in ~/.azure/)
Write-Host "=== Azure CLI Login (device code - tokens persist to disk) ==="
Write-Host "This is the ONLY device code you need. Tokens persist across sessions."
Write-Host ""

$azResult = az login --tenant $TenantId --allow-no-subscriptions --use-device-code 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Azure CLI login failed: $azResult"
    exit 1
}
Write-Host "Azure CLI login successful"
Write-Host ""

# Step 2: Get Graph token from Azure CLI and connect
Write-Host "=== Graph Authentication (via Azure CLI token) ==="
Import-Module Microsoft.Graph.Authentication

$graphToken = az account get-access-token --tenant $TenantId --resource https://graph.microsoft.com --query accessToken -o tsv 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to get Graph token: $graphToken"
    Write-Host ""
    Write-Host "Falling back to direct device code..."
    Connect-MgGraph -TenantId $TenantId -Scopes $GraphScopes -ContextScope Process -UseDeviceCode
} else {
    $secureToken = ConvertTo-SecureString $graphToken -AsPlainText -Force
    Connect-MgGraph -AccessToken $secureToken -NoWelcome
}

$ctx = Get-MgContext
$ctx | Format-List TenantId, Account, ContextScope, ClientId, AuthType
Write-Host ""

# Verify Graph
Write-Host "=== Graph Validation ==="
try {
    Import-Module Microsoft.Graph.Users
    $user = Get-MgUser -Top 1 -Property DisplayName,UserPrincipalName -ErrorAction Stop
    Write-Host "OK: $($user.DisplayName) ($($user.UserPrincipalName))"
} catch {
    Write-Host "FAIL: $_"
}
Write-Host ""

# Step 3: Get EXO token from Azure CLI and connect
Write-Host "=== Exchange Online Authentication (via Azure CLI token) ==="
Import-Module ExchangeOnlineManagement
$exoTemp = Join-Path $HOME ".exo-tmp"
New-Item -ItemType Directory -Force -Path $exoTemp | Out-Null

$exoToken = az account get-access-token --tenant $TenantId --resource https://outlook.office365.com --query accessToken -o tsv 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to get EXO token: $exoToken"
    Write-Host ""
    Write-Host "Falling back to direct device code..."
    Connect-ExchangeOnline -Device -UserPrincipalName $Upn -EXOModuleBasePath $exoTemp -ShowBanner:$false
} else {
    Connect-ExchangeOnline -AccessToken $exoToken -Organization "railcontrol.com.au" -ShowBanner:$false
}
Write-Host ""

# Show cache status
Write-Host "=== Azure CLI Token Cache ==="
$azDir = Join-Path $HOME ".azure"
if (Test-Path $azDir) {
    Get-ChildItem $azDir | Format-Table Name, Length, LastWriteTime -Auto
} else {
    Write-Host "No .azure directory found"
}

Write-Host ""
Write-Host "Bootstrap complete. Azure CLI tokens persist in ~/.azure/ on PVC."
Write-Host "Subsequent sessions will use 'az account get-access-token' silently."
