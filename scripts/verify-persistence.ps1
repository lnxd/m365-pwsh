param(
    [Parameter(Mandatory=$true)][string]$TenantId
)

Write-Host "=== Token Persistence Test ==="
Write-Host "This should NOT require device code if tokens are cached."
Write-Host ""

Import-Module Microsoft.Graph.Authentication

# Attempt silent reconnect
Connect-MgGraph -TenantId $TenantId `
    -Scopes "User.Read.All" `
    -ContextScope CurrentUser `
    -NoWelcome

$ctx = Get-MgContext
if ($ctx -and $ctx.Account) {
    Write-Host "PASS: Silent reconnect succeeded"
    Write-Host "  Account: $($ctx.Account)"
    Write-Host "  TenantId: $($ctx.TenantId)"
    Write-Host "  ContextScope: $($ctx.ContextScope)"

    try {
        $user = Get-MgUser -Top 1 -Property DisplayName -ErrorAction Stop
        Write-Host "  API call OK: $($user.DisplayName)"
    } catch {
        Write-Host "  API call FAILED: $_"
    }
} else {
    Write-Host "FAIL: No cached context found - device code would be required"
}
