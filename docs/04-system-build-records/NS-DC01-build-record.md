# NS-DC01 System Build Record

## Document Control

| Field | Value |
| --- | --- |
| System | NS-DC01 |
| Project | Nord Systems Virtual IT Lab |
| Role | Domain controller, DNS server, DHCP server, backup server |
| Operating system | Windows Server 2022 Standard Evaluation, Desktop Experience |
| Domain | `corp.nordsystems.com` |
| NetBIOS name | `NORDSYSTEMS` |
| Status | Build in progress |

This record tracks implementation work, validation results, evidence, snapshots, and deviations from the approved design. Passwords, recovery secrets, activation information, and other credentials must never be recorded here.

## Virtual Machine Configuration

| Component | Configuration | Status |
| --- | --- | --- |
| Hypervisor | VMware Workstation Pro | Complete |
| VM name | `NS-DC01` | Complete |
| Firmware | UEFI with Secure Boot | Complete |
| vCPU | 2 | Complete |
| Memory | 4 GB | Complete |
| Virtual disk | 80 GB, NVMe, thin provisioned | Complete |
| Network adapter | Custom `VMnet2` only | Complete |
| VMware Tools | Typical installation | Complete |

VM files are stored outside the Git repository at:

```text
C:\Users\ajekkula\Virtual_Machines\NS-DC01
```

## Network Configuration

| Setting | Value | Status |
| --- | --- | --- |
| IPv4 address | `10.10.10.10` | Complete |
| Subnet mask | `255.255.255.0` (`/24`) | Complete |
| Default gateway | `10.10.10.1` | Complete |
| Preferred DNS | `10.10.10.10` | Complete |
| Alternate DNS | None | Complete |
| IPv6 | Enabled | Complete |

Validation completed:

- Ping to pfSense LAN interface `10.10.10.1`: passed with 0% packet loss.
- Ping to public IP `1.1.1.1`: passed, confirming routing and outbound NAT through NS-FW01.
- External DNS resolution through `NS-DC01 → NS-FW01 → VMnet8 DNS` was validated with `Resolve-DnsName www.github.com` after clearing the server and client DNS caches.

## Active Directory Domain Services

| Item | Configuration | Status |
| --- | --- | --- |
| Forest root domain | `corp.nordsystems.com` | Complete |
| NetBIOS domain | `NORDSYSTEMS` | Complete |
| Forest functional level | Windows Server 2016 | Complete |
| Domain functional level | Windows Server 2016 | Complete |
| Global Catalog | Enabled | Complete |
| DNS role | Installed | Complete |
| Alternate UPN suffix | `nordsystems.com` | Complete |

Validation completed:

- `Get-ADDomain` returned the correct DNS root, NetBIOS name, and domain mode.
- `Get-ADForest` returned `corp.nordsystems.com` and `Windows2016Forest`.
- NTDS and DNS services were running.
- `dcdiag /test:Advertising /test:SysVolCheck` passed Connectivity, Advertising, and SysVolCheck.
- DFS Replication service was running.

## DNS Configuration

| Item | Configuration | Status |
| --- | --- | --- |
| Forward lookup zone | `corp.nordsystems.com` | Complete |
| Reverse lookup zone | `10.10.10.0/24` | Complete |
| NS-DC01 PTR record | `10.10.10.10` to `NS-DC01.corp.nordsystems.com` | Complete |
| Forwarder | `10.10.10.1`, NS-FW01 | Complete |
| Root hints | Disabled | Complete |
| External resolution path | NS-DC01 to NS-FW01 to the VMnet8-supplied resolver | Validated |
| Dynamic updates | Secure only | Complete |

## DHCP Configuration

| Item | Configuration | Status |
| --- | --- | --- |
| DHCP server | `NS-DC01.corp.nordsystems.com` | Complete |
| AD authorization | Authorized | Complete |
| Scope name | Nord Systems LAN | Complete |
| Scope network | `10.10.10.0/24` | Complete |
| Lease range | `10.10.10.100` to `10.10.10.199` | Complete |
| Lease duration | 8 days | Complete |
| Option 003 Router | `10.10.10.1` | Complete |
| Option 006 DNS Servers | `10.10.10.10` | Complete |
| Option 015 DNS Domain Name | `corp.nordsystems.com` | Complete |

Validation completed:

- DHCP service was running.
- `Get-DhcpServerInDC` listed NS-DC01 at `10.10.10.10`.
- DHCP Users and DHCP Administrators domain-local groups exist.
- Scope is active and the configured range and options were verified with PowerShell.

## Organizational Unit Structure

```text
OU=NordSystems
├── OU=AdminAccounts
├── OU=Departments
│   ├── OU=Administration
│   ├── OU=Finance
│   ├── OU=HumanResources
│   ├── OU=IT
│   └── OU=Marketing
├── OU=Groups
├── OU=Servers
├── OU=ServiceAccounts
└── OU=Workstations
```

All approved OUs are protected from accidental deletion.

## Security Groups

| Group category | Count | Status |
| --- | ---: | --- |
| Global security groups | 17 | Complete |
| Domain Local security groups | 17 | Complete |
| Total security groups created | 34 | Complete |
| Approved AGDLP nesting mappings | 22 | Complete |

The group structure implements Accounts to Global groups to Domain Local groups to Permissions. Resource ACLs will be applied when NS-FS01 is built.

## Snapshots

| VM | Snapshot | Purpose |
| --- | --- | --- |
| NS-FW01 | `01-pfsense-installed` | pfSense CE installed with WAN on VMnet8 and LAN `10.10.10.1/24` on VMnet2 |
| NS-DC01 | `01-server-baseline` | Windows Server installed, VMware Tools installed, hostname and static networking configured |
| NS-DC01 | `02-ad-dns-dhcp-configured` | AD DS, DNS, reverse DNS, forwarding, and authorized DHCP scope configured and validated |

## Evidence Index

| Evidence file | What it proves | Status |
| --- | --- | --- |
| `evidence/phase-01-network-foundation/vmnet2-isolated-lan.png` | VMnet2 subnet, host-adapter isolation, and VMware DHCP disabled | Captured |
| `evidence/phase-01-network-foundation/pfsense-interface-assignment.png` | pfSense WAN/LAN assignment and LAN address | Captured |
| `evidence/phase-01-network-foundation/ns-dc01-network-connectivity.png` | NS-DC01 static address, gateway reachability, and internet reachability by IP | Captured |
| `evidence/phase-02-domain-services/ad-ds-dhcp-health-check.png` | AD DS advertising, SYSVOL, DFSR, DHCP service, and DHCP groups | Captured |

## Issues and Resolutions

| Issue | Cause | Resolution | Current state |
| --- | --- | --- | --- |
| VMware library could not open NS-FW01 after files were moved | VMware library entry retained the old path | Removed the broken library entry and reopened the `.vmx` file from the new local path using **I Moved It** | Resolved |
| VMware VM files were initially stored under a OneDrive-managed path | School Windows profile redirected common folders into OneDrive | Moved the VM folders to `C:\Users\ajekkula\Virtual_Machines` | Resolved |
| DHCP Option 003 initially showed `0.0.0.0` | Empty router value was added | Removed the invalid value and added `10.10.10.1` | Resolved |
| Initial DHCP and DFSR events caused `dcdiag /q` warnings | Events were generated during role installation and before DHCP authorization completed | Verified current services, groups, authorization, Advertising, and SYSVOL health without clearing historical logs | Resolved |
| OU creation script appeared to fail | AD Users and Computers had not refreshed, and duplicate-object errors occurred on retry | Refreshed the console and confirmed the scripted structure existed | Resolved |
| HR OU name did not match the approved specification | OU was initially created as `HR` | Renamed it to `HumanResources` and re-enabled accidental-deletion protection | Resolved |
| NS-DC01 was configured with direct public DNS forwarders `1.1.1.1` and `8.8.8.8` | Implementation guidance did not follow D-02 Section 5.2 | Enabled forwarding mode on the NS-FW01 DNS Resolver, confirmed use of VMnet8-supplied DNS, replaced both public forwarders with `10.10.10.1`, disabled root hints on NS-DC01, cleared caches, and repeated external-resolution validation | Resolved |

## Current Build Status

Completed:

- Windows Server installation and VMware Tools
- Static network configuration and routing validation
- AD DS forest deployment
- DNS authoritative, reverse, and external forwarding through the approved NS-FW01 path
- DHCP authorization, scope, and options
- Approved OU structure
- Alternate UPN suffix
- Global and Domain Local security groups
- AGDLP group nesting

Next planned work:

1. Provision 10 standard employee accounts.
2. Provision 2 privileged accounts and 4 service accounts.
3. Assign approved Global group memberships.
4. Configure account-specific security controls.
5. Validate identities and group membership against the Identity and Access Register.
6. Capture evidence and take a post-provisioning snapshot.

## Update Procedure

After each build milestone:

1. Add the implemented setting to the appropriate section.
2. Record the validation command and outcome, not just the configuration action.
3. Add the evidence filename to the Evidence Index.
4. Record mistakes and corrections in Issues and Resolutions.
5. Add the snapshot name when a recovery checkpoint is taken.
6. Commit the updated build record and evidence to GitHub after the milestone is validated.

Do not record passwords, private keys, recovery secrets, tokens, or unredacted sensitive values.
