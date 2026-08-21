# NS-WS01 System Build Record

**Document ID:** NS-DOC-004-WS01  
**System:** NS-WS01  
**Role:** Primary staff workstation  
**Status:** Operational baseline complete  
**Domain:** `corp.nordsystems.com`  
**NetBIOS domain:** `NORDSYSTEMS`  

## 1. Purpose

NS-WS01 is the primary Windows workstation used to validate Nord Systems domain authentication, DHCP and DNS services, workstation security policy, role-based drive mappings, Samba permissions, administrative separation, and simulated support scenarios.

The workstation is not an infrastructure server and does not host shared services. Routine work is performed with a standard domain account. Local administrative elevation uses a dedicated local recovery account.

## 2. Virtual Machine Configuration

| Component | Configuration |
|---|---|
| Hypervisor | VMware Workstation Pro |
| Guest operating system | Windows 11 Pro x64 |
| Firmware | UEFI with Secure Boot |
| Trusted Platform Module | Virtual TPM installed |
| Processors | 2 cores |
| Memory | 4 GB |
| Virtual disk | 64 GB NVMe |
| Network adapter | Custom VMnet2 |
| VMware Tools | Installed |
| Computer name | `NS-WS01` |

## 3. Network Configuration

NS-WS01 uses DHCP and does not have a manually assigned IPv4 address.

| Setting | Effective value |
|---|---|
| IPv4 allocation | NS-DC01 DHCP scope `10.10.10.100-10.10.10.199` |
| Subnet mask | `255.255.255.0` |
| Default gateway | `10.10.10.1` (NS-FW01) |
| DNS server | `10.10.10.10` (NS-DC01) |
| DNS suffix | `corp.nordsystems.com` |
| LAN | VMnet2, `10.10.10.0/24` |

Validated network paths:

- NS-WS01 to NS-FW01 LAN interface
- NS-WS01 to NS-DC01
- NS-WS01 to NS-FS01 when the file-service operating profile is active
- NS-WS01 to the internet through NS-FW01
- External name resolution through `NS-WS01 -> NS-DC01 -> NS-FW01 -> upstream DNS`

## 4. Installation and Domain Join

1. Created the VM with UEFI, Secure Boot, TPM, VMnet2, and the approved resource allocation.
2. Installed Windows 11 Pro from ISO.
3. Created the local `wsadmin` account during initial setup.
4. Installed VMware Tools.
5. Renamed the computer to `NS-WS01`.
6. Validated DHCP, gateway, DNS, and domain discovery.
7. Joined `corp.nordsystems.com` using delegated administrative credentials.
8. Placed the computer object directly in:

```text
CN=NS-WS01,OU=Workstations,OU=NordSystems,DC=corp,DC=nordsystems,DC=com
```

9. Restarted and validated domain sign-in with `NORDSYSTEMS\jpatel`.

## 5. Administrative Account Model

| Account | Purpose | Status |
|---|---|---|
| `NORDSYSTEMS\jpatel` | Routine staff use and access testing | Standard domain user |
| `NS-WS01\wsadmin` | Local UAC elevation and recovery | Enabled and password verified |
| `NS-WS01\Administrator` | Built-in local Administrator | Disabled |
| `NORDSYSTEMS\Administrator` | Domain-wide emergency administration | Not permitted for workstation administration |
| `NORDSYSTEMS\adm-mhalvorsen` | Delegated infrastructure administration | Interactive workstation logon denied |

`NORDSYSTEMS\Domain Admins` was removed from the workstation's local Administrators group. This prevents routine workstation administration from exposing domain-wide Administrator credentials.

## 6. Applied Computer Group Policy

The following objects were verified using `gpresult /r /scope computer` from an elevated PowerShell session:

- `NS_Baseline_Workstations`
- `NS_RestrictedGroups_Workstations`
- `NS_LogonRestrictions_Privileged`
- `NS_LogonRestrictions_Service`
- `NS_Audit_Authentication`
- `Default Domain Policy`

### Workstation baseline controls

| Control | Effective configuration |
|---|---|
| SMBv1 client | Disabled |
| SMBv1 server | Disabled |
| LLMNR | Disabled |
| Inactivity limit | 900 seconds |
| Display last signed-in user | Disabled |
| UAC | Admin approval with consent prompt on secure desktop |
| Windows Firewall | Enabled for all profiles; inbound default block |
| Windows Update | Automatic download and scheduled installation |
| Sign-in notice | Nord Systems authorized-use notice displayed |

### Local group enforcement

Local **Administrators** membership:

- `NORDSYSTEMS\DL_Workstation_Admins`
- `NS-WS01\Administrator`
- `NS-WS01\wsadmin`

Local **Remote Desktop Users** membership:

- `NORDSYSTEMS\DL_Workstation_Admins`

## 7. Applied User Group Policy

The following objects were verified for `NORDSYSTEMS\jpatel` using `gpresult /r`:

- `NS_DriveMapping_Home`
- `NS_DriveMapping_Departments`

### Effective drive mappings for jpatel

| Drive | Target | Reason |
|---|---|---|
| `H:` | `\\NS-FS01\Home$\jpatel` | Personal home folder |
| `P:` | `\\NS-FS01\Company` | Membership in `GG_Org_AllStaff` |
| `S:` | `\\NS-FS01\Administration` | Membership in `GG_Dept_Administration` |

The executive-only `F:` and `R:` drives were not mapped, which is correct because `jpatel` belongs to `GG_Tier_Staff` rather than `GG_Tier_Executive`.

## 8. Validation Results

| Test | Method | Expected result | Result |
|---|---|---|---|
| WS-01 | Confirm hostname | `NS-WS01` | Pass |
| WS-02 | Confirm domain membership | `corp.nordsystems.com` | Pass |
| WS-03 | Confirm DHCP configuration | Address in `.100-.199`, gateway `.1`, DNS `.10` | Pass |
| WS-04 | Ping NS-FW01 | Reply from `10.10.10.1` | Pass |
| WS-05 | Ping NS-DC01 | Reply from `10.10.10.10` | Pass |
| WS-06 | Resolve an external FQDN | Answer returned through approved DNS chain | Pass |
| WS-07 | Review computer GPO results | All required workstation GPOs applied | Pass |
| WS-08 | Review user GPO results | Both drive-mapping GPOs applied | Pass |
| WS-09 | Review local Administrators | Only approved domain group and local recovery accounts | Pass |
| WS-10 | Review mapped drives as jpatel | `H:`, `P:`, and `S:` present | Pass |
| WS-11 | Write to authorized locations | Home, Company, and Administration writes succeed | Pass |
| WS-12 | Open Finance as jpatel | Access denied | Pass |
| WS-13 | Open another employee's home folder | Access denied | Pass |
| WS-14 | Sign in as adm-mhalvorsen | Sign-in method not allowed | Pass after correction |
| WS-15 | Display authorized-use notice | Notice appears before sign-in | Pass |
| WS-16 | Check Windows Update | Update check completes after DNS repair | Pass |

## 9. Problems Encountered and Corrections

### 9.1 Windows setup reported no internet

The VM received the domain DHCP suffix, proving the VMnet2 adapter and DHCP path were functioning. Windows setup was completed with a local account, and networking was validated after installation.

### 9.2 External DNS returned server failure

Direct queries to NS-DC01 and NS-FW01 returned `RCODE_SERVER_FAILURE`. The fault was isolated to pfSense DNS forwarding. Explicit upstream DNS servers `1.1.1.1` and `8.8.8.8` were configured on NS-FW01, WAN DHCP DNS override was disabled, and forwarding mode remained enabled. Resolution was then validated from NS-DC01 and NS-WS01.

### 9.3 Domain Administrator was used for workstation elevation

The account used for elevation was identified as `NORDSYSTEMS\Administrator`, not a local account. The local `wsadmin` password was reset and verified. Domain Admins was removed from local Administrators, and future UAC elevation uses `.\wsadmin`.

### 9.4 Privileged interactive logon was initially allowed

`adm-mhalvorsen` correctly belonged to `GG_Admin_Infrastructure`, but the workstation still allowed sign-in. Two GPOs configured the same user-right assignments, so the effective policy did not contain the privileged group.

The highest-precedence workstation restriction was corrected to include:

- `GG_Admin_Infrastructure`
- `GG_Svc_Application`
- `GG_Svc_Backup`

The GPO was placed at link order 1, policy was refreshed, the workstation was restarted, and the privileged sign-in attempt was denied as expected.

### 9.5 Drive policies applied but no drives appeared

The drive-mapping GPOs were applied, but NS-FS01 was powered off under the active low-memory profile. After NS-FS01 was started, policy was refreshed and the user signed in again. The expected `H:`, `P:`, and `S:` drives appeared.

## 10. Evidence Checklist

Save sanitized evidence under:

```text
evidence/ns-ws01/
```

Recommended files:

- `01-vm-hardware-settings.png`
- `02-dhcp-and-dns-configuration.png`
- `03-domain-membership.png`
- `04-computer-gpo-results.png`
- `05-user-gpo-results.png`
- `06-local-group-enforcement.png`
- `07-drive-mappings-jpatel.png`
- `08-authorized-share-access.png`
- `09-unauthorized-share-denied.png`
- `10-privileged-logon-denied.png`
- `11-external-dns-resolution.png`
- `12-windows-update-status.png`
- `13-snapshot-manager.png`

Evidence must not display passwords, password prompts containing typed values, recovery secrets, private keys, or unredacted firewall configuration exports.

## 11. Snapshot Checkpoint

Verify the exact snapshot names in VMware Snapshot Manager. Intended checkpoints include:

- `01-domain-joined-gpo-and-drive-mappings`
- `02-workstation-security-and-access-baseline`

If the actual names differ, record the real names rather than renaming history only to match this document.

## 12. Current Operational State

NS-WS01 is ready for:

- Standard-user authentication testing
- Department and home-drive testing
- Group Policy validation
- DNS, DHCP, authentication, permissions, and software support scenarios
- GLPI ticket submission after the service desk is installed
- Multi-client validation after NS-WS02 is built

The NS-WS01 build is functionally complete. Remaining work for this system is evidence capture, GitHub publication, and use in later ticket and recovery scenarios.
