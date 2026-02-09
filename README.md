# Azure Virtual Desktop — Proof of Concept Deployment

An interactive, IaC-driven solution to deploy a **customer-ready Azure Virtual Desktop environment** using **Azure Bicep** and **PowerShell**. Supports both **greenfield** (net-new) and **brownfield** (existing infrastructure) flows.

---

## Features

- **Interactive deployment** — guided PowerShell experience with sensible defaults
- **Greenfield & Brownfield** — deploy everything from scratch or leverage existing VNet / Key Vault / Log Analytics
- **Modular Bicep templates** — clean, subscription-scoped infrastructure as code
- **Security-first** — Key Vault integration, Trusted Launch, RBAC authorization, no secrets in source
- **Image picker** — dynamically lists available Windows 11 offers and SKUs from your region

---

## Prerequisites

| Requirement | Minimum Version |
|---|---|
| Azure CLI | 2.50+ |
| Bicep CLI | 0.20+ (auto-installed if missing) |
| PowerShell | 7.x recommended; 5.1 supported |
| Azure Subscription | Contributor role at subscription scope |
| Azure AD | Permissions to register apps (if using AAD Kerberos for storage) |

---

## Quick Start

```powershell
# 1. Clone the repo and navigate to it
cd AVD-CustomerReady

# 2. Run the interactive deployment
.\Deploy-AVD.ps1

# 3. Follow the on-screen prompts
```

The script will:
1. Verify prerequisites (Azure CLI, Bicep, login status)
2. Ask you to choose **Greenfield** or **Brownfield**
3. Collect all parameters with sensible defaults
4. Let you pick a Windows 11 image from your region
5. Deploy via `az deployment sub create`
6. Display a summary with resource names, IPs, and portal links

---

## Project Structure

```
├── avdMain.bicep                  # Orchestrator — subscription scope
├── avdParams.bicepparam           # Default parameter values (reference only)
├── modules/
│   ├── networking.bicep           # VNet, Subnets, NSG
│   ├── keyvault.bicep             # Key Vault + secrets + RBAC
│   ├── avdcore.bicep              # Host pool, app group, workspace, storage, gallery, VM
│   ├── monitor.bicep              # Log Analytics + Data Collection Rule
│   ├── domain.bicep               # Domain controller (conditional)
│   ├── bastion.bicep              # Azure Bastion Developer SKU (conditional)
│   └── roleassignment.bicep       # AVD service principal role assignment
├── Deploy-AVD.ps1                 # Interactive PowerShell deployment wrapper
├── README.md                      # This file
├── Specifications/                # Design specifications & flow diagram
│   ├── SPECIFICATIONS.md
│   └── flow.png
└── Images/
```

---

## Deployment Paths

### Greenfield — Deploy Everything

All resources are created from scratch:

- 3 Resource Groups (core, networking, monitoring)
- Virtual Network, Subnet, NSG
- Key Vault with VM admin secret
- AVD Host Pool, Application Group, Workspace
- Storage Account with FSLogix profile share
- Azure Compute Gallery
- Template VM with Public IP
- Log Analytics Workspace + Data Collection Rule
- Role Assignment (Desktop Virtualization Power On Contributor)
- *(Optional)* Domain Controller VM
- *(Optional)* Azure Bastion

### Brownfield — Leverage Existing Infrastructure

You're prompted to select or enter existing:

| Existing Resource | Selection Method |
|---|---|
| Resource Groups | Pick from list or enter name |
| Virtual Network / Subnet | Pick from list |
| Key Vault | Pick from list |
| Log Analytics Workspace | Pick from list |

When existing resources are provided, the corresponding Bicep module is skipped.

---

## Resources Deployed

| Resource | Module | When Deployed |
|---|---|---|
| Resource Groups (3) | `avdMain.bicep` | Always (idempotent) |
| NSG, VNet, Subnet | `networking.bicep` | Greenfield only |
| Key Vault + Secret | `keyvault.bicep` | Greenfield only |
| Host Pool, App Group, Workspace | `avdcore.bicep` | Always |
| Storage Account (FSLogix) | `avdcore.bicep` | Always |
| Azure Compute Gallery | `avdcore.bicep` | Always |
| Template VM + PIP + NIC | `avdcore.bicep` | Always |
| Log Analytics Workspace | `monitor.bicep` | Greenfield only |
| Data Collection Rule | `monitor.bicep` | Optional |
| Domain Controller VM | `domain.bicep` | Optional |
| Azure Bastion | `bastion.bicep` | Optional |
| Role Assignment | `roleassignment.bicep` | Always |

---

## Security

| Practice | Detail |
|---|---|
| **No secrets in source** | Admin passwords collected via `Read-Host -AsSecureString` and passed as `@secure()` Bicep parameters |
| **Key Vault** | Stores VM admin password; RBAC authorization enabled; soft delete with 90-day retention |
| **Trusted Launch** | Secure Boot + vTPM enabled by default on all VMs |
| **NSG** | Default allows RDP from `*` — script warns operator to scope source IP |
| **RBAC** | Key Vault Secrets Officer assigned to deploying user; AVD Power On Contributor assigned to AVD service principal |

---

## Manual Deployment

If you prefer to deploy without the interactive wrapper:

```powershell
az deployment sub create `
  --location eastus2 `
  --template-file avdMain.bicep `
  --parameters vmAdminPassword='<your-password>' `
  --name "avd-poc-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
```

Override any default with `--parameters key=value`. See `avdParams.bicepparam` for the full parameter list.

---

## Naming Conventions

| Resource Type | Pattern | Example |
|---|---|---|
| Resource Group | `rg-avd-{function}-poc` | `rg-avd-core-poc` |
| Virtual Network | `vnet-avd-poc` | `vnet-avd-poc` |
| Subnet | `snet-avd-poc` | `snet-avd-poc` |
| NSG | `nsg-avd-poc` | `nsg-avd-poc` |
| Host Pool | `hp-avd-poc` | `hp-avd-poc` |
| Application Group | `ag-avd-poc` | `ag-avd-poc` |
| Workspace | `ws-avd-poc` | `ws-avd-poc` |
| Storage Account | `sa{uniqueString}` | `sa2hfx7...` |
| Key Vault | `kv{uniqueString}` | `kv2hfx7...` |
| Compute Gallery | `acgavdpoc` | `acgavdpoc` |
| VM | `avdtemplate01` | `avdtemplate01` |

Names requiring global uniqueness use `uniqueString()` to avoid collisions.

---

## Future Enhancements (Out of Scope for V1)

- Multi-region image replication via Azure Compute Gallery
- Automated session host provisioning from golden image
- Entra ID Join
- Private endpoints for Storage & Key Vault
- Azure Policy assignments
- CI/CD pipeline (GitHub Actions)
- Autoscale for pooled host pools
