param(
    [Parameter(Mandatory=$true)][string]$TenantId,
    [Parameter(Mandatory=$true)][string]$Upn,
    [string[]]$Scopes = @(
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
Write-Host "Scopes: $($Scopes.Count)"
Write-Host ""

# Graph: device code + CurrentUser cache
Import-Module Microsoft.Graph.Authentication
Write-Host "=== Graph Authentication ==="
Connect-MgGraph -TenantId $TenantId `
    -Scopes $Scopes `
    -ContextScope CurrentUser `
    -UseDeviceCode

$ctx = Get-MgContext
$ctx | Format-List TenantId, Account, ContextScope, ClientId, AuthType
Write-Host "Granted scopes: $($ctx.Scopes.Count)"
Write-Host ""

# Verify Graph works
Write-Host "=== Graph Validation ==="
try {
    $user = Get-MgUser -Top 1 -Property DisplayName,UserPrincipalName -ErrorAction Stop
    Write-Host "OK: $($user.DisplayName) ($($user.UserPrincipalName))"
} catch {
    Write-Host "FAIL: $_"
}

Write-Host ""

# EXO: device code
Write-Host "=== Exchange Online Authentication ==="
Import-Module ExchangeOnlineManagement
$exoTemp = Join-Path $HOME ".exo-tmp"
New-Item -ItemType Directory -Force -Path $exoTemp | Out-Null
Connect-ExchangeOnline -Device -UserPrincipalName $Upn -EXOModuleBasePath $exoTemp -ShowBanner:$false

Write-Host ""
Write-Host "=== Token Cache ==="
$mg = Join-Path $HOME ".mg"
if (Test-Path $mg) {
    Get-ChildItem -Force $mg | Format-Table Name, Length, LastWriteTime -Auto
} else {
    Write-Host "No .mg cache directory found"
}

Write-Host ""
Write-Host "Bootstrap complete. Exit and re-enter to test token persistence."
