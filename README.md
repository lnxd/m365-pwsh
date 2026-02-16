# m365-pwsh

M365 admin PowerShell container for k3s with persistent MSAL token cache.

## Purpose

Runs PowerShell 7 with Microsoft.Graph 2.35.1, ExchangeOnlineManagement 3.9.2, and PnP.PowerShell 3.1.0 in a k3s pod. Mounts `$HOME` on a Longhorn PVC so device code authentication persists across `kubectl exec` sessions.

## Build

Via Tekton on k3s:
```bash
ssh lnxd@10.1.100.10 'sudo k3s kubectl create -f ~/k8s/build-system/taskrun-m365-pwsh.yaml'
```

## Deploy

```bash
ssh lnxd@10.1.100.10 'sudo k3s kubectl apply -f ~/k8s/m365-pwsh/'
```

## Usage

```bash
# Enter pod
ssh lnxd@10.1.100.10 'sudo k3s kubectl exec -it -n portal deploy/m365-pwsh -- pwsh'

# First time: bootstrap auth
./scripts/bootstrap.ps1 -TenantId "TENANT-ID" -Upn "admin@tenant.onmicrosoft.com"

# Subsequent sessions: verify persistence
./scripts/verify-persistence.ps1 -TenantId "TENANT-ID"
```

## Modules

- Microsoft.Graph 2.35.1
- ExchangeOnlineManagement 3.9.2
- PnP.PowerShell 3.1.0
