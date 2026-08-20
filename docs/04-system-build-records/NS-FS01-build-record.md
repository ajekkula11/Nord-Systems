# NS-FS01 System Build Record

## Document Control

| Field | Value |
| --- | --- |
| System | NS-FS01 |
| Project | Nord Systems Virtual IT Lab |
| Role | Samba file server and GLPI service-desk server |
| Operating system | Ubuntu Server 22.04.5 LTS |
| Domain | `corp.nordsystems.com` |
| NetBIOS domain | `NORDSYSTEMS` |
| Status | Core file service configured; role testing and GLPI pending |

This record tracks implementation work, validation, evidence, snapshots, and deviations from the approved design. Passwords, Kerberos tickets, private keys, database secrets, and recovery credentials must never be recorded here.

## Virtual Machine Configuration

| Component | Configuration | Status |
| --- | --- | --- |
| Hypervisor | VMware Workstation Pro | Complete |
| VM name | `NS-FS01` | Complete |
| Firmware | Not recorded during installation; verify in VMware settings | Verification required |
| vCPU | 2 | Complete |
| Memory | 3 GB | Complete |
| Virtual disk | 40 GB, SCSI, single virtual-disk file | Complete |
| Network adapter | Custom `VMnet2` only | Complete |
| VMware guest tools | `open-vm-tools` | Complete |

VM files are stored outside the Git repository at:

```text
C:\Users\ajekkula\Virtual_Machines\NS-FS01
```

## Operating System Baseline

| Item | Configuration | Status |
| --- | --- | --- |
| Distribution | Ubuntu Server 22.04.5 LTS | Complete |
| Installation type | Standard Ubuntu Server | Complete |
| Local administrator | `nsadmin` | Complete |
| Root SSH logon | Disabled | Complete |
| OpenSSH Server | Installed and active | Complete |
| System packages | Updated after installation | Complete |
| VMware tools | Installed and active | Complete |
| Hostname | `ns-fs01` | Complete |
| FQDN | `ns-fs01.corp.nordsystems.com` | Complete |

## Network Configuration

| Setting | Value | Status |
| --- | --- | --- |
| IPv4 address | `10.10.10.20/24` | Complete |
| Default gateway | `10.10.10.1` | Complete |
| DNS server | `10.10.10.10` | Complete |
| DNS search domain | `corp.nordsystems.com` | Complete |
| VMware network | `VMnet2` | Complete |
| Time source | `10.10.10.10`, NS-DC01 | Complete |

Validation completed:

- Ping to NS-FW01 at `10.10.10.1`: passed.
- Ping to NS-DC01 at `10.10.10.10`: passed.
- Ping to public IP `1.1.1.1`: passed.
- External DNS resolution through NS-DC01: passed.
- Forward lookup for NS-FS01 returned `10.10.10.20`.
- Reverse lookup for `10.10.10.20` returned `NS-FS01.corp.nordsystems.com`.
- `timedatectl timesync-status` identified NS-DC01 as the time server.

## Installed File-Service and Domain Packages

| Package | Purpose | Status |
| --- | --- | --- |
| `samba` | SMB file services | Installed |
| `winbind` | Active Directory identity and group resolution | Installed |
| `libnss-winbind` | NSS integration | Installed |
| `libpam-winbind` | PAM integration | Installed |
| `krb5-user` | Kerberos authentication tools | Installed |
| `smbclient` | Local SMB validation | Installed |
| `dnsutils` | DNS diagnostics | Installed |
| `acl` | POSIX ACL management | Installed |
| `attr` | Extended-attribute tools | Installed |

## Active Directory Integration

| Item | Configuration | Status |
| --- | --- | --- |
| Samba security mode | ADS member server | Complete |
| Workgroup | `NORDSYSTEMS` | Complete |
| Kerberos realm | `CORP.NORDSYSTEMS.COM` | Complete |
| Computer-account OU | `OU=Servers,OU=NordSystems` | Complete |
| Join account | Delegated `adm-mhalvorsen` account | Complete |
| Join delegation | `GG_Admin_Infrastructure` manages computer objects in Servers OU | Complete |
| Identity mapping | TDB default range plus RID mapping for NORDSYSTEMS | Complete |
| NSS integration | Winbind added to `passwd` and `group` lookups | Complete |
| Legacy NetBIOS browsing | `nmbd` disabled | Complete |

Validation completed:

- `kinit` and `klist` validated Kerberos authentication.
- `net ads testjoin` returned `Join is OK`.
- `sudo wbinfo -t` validated the machine trust secret.
- `wbinfo --ping-dc` connected to NS-DC01 successfully.
- `wbinfo --own-domain` returned `NORDSYSTEMS`.
- `getent passwd arao` resolved the AD user.
- `getent group GG_Dept_Finance` resolved the AD group.
- NS-DC01 confirmed the NS-FS01 computer object in the approved Servers OU.
- The Kerberos keytab contains NS-FS01 principals.

## Samba Protocol and Global Security

| Setting | Value | Status |
| --- | --- | --- |
| Minimum server protocol | SMB2 | Complete |
| Minimum client protocol | SMB2 | Complete |
| SMB1 | Disabled | Validated |
| Guest mapping | Never | Complete |
| Guest access | Disabled on every share | Complete |
| ACL module | `acl_xattr` | Complete |
| DOS attributes | Stored in extended attributes | Complete |
| Printer services | Disabled | Complete |

Kerberos-authenticated share enumeration reported that SMB1 is disabled.

## Share Inventory

| Share | Path | Published state | Intended authorization |
| --- | --- | --- | --- |
| `Company` | `/srv/samba/company` | Browsable, writable subject to ACL | `DL_ShareCompany_RW` |
| `Administration` | `/srv/samba/administration` | Browsable, writable subject to ACL | Administration RW and FC groups |
| `Finance` | `/srv/samba/finance` | Browsable, RO/RW/FC subject to ACL and share controls | Finance RW, FC, and RO groups |
| `HR` | `/srv/samba/hr` | Browsable, RO/RW/FC subject to ACL and share controls | HR RW, FC, and RO groups |
| `IT` | `/srv/samba/it` | Browsable, writable subject to ACL | IT RW and FC groups |
| `Marketing` | `/srv/samba/marketing` | Browsable, writable subject to ACL | Marketing RW and FC groups |
| `Home$` | `/srv/samba/home` | Hidden | Each employee's own subfolder only |

All 13 Domain Local groups required by the file-access matrix resolved successfully on NS-FS01 before ACL deployment.

## File-System Access Controls

- `/srv/samba` is owned by `root:root`.
- Business-share directories use setgid directory permissions and deny access to `other`.
- Approved Domain Local groups receive named POSIX ACL entries.
- Default ACL entries propagate the approved access to newly created files and directories.
- Finance and HR read-only groups receive `r-x` rather than write permission.
- Full-control resource groups receive `rwx` and are assigned as Samba `admin users` only on their own departmental share.
- Each home folder is owned by its employee account and denies group and other access.
- The `Home$` root permits traversal without allowing directory listing; GPO mapping will target the user's named subfolder.

Validated ACL example:

- Finance RW: `rwx`
- Finance FC: `rwx`
- Finance RO: `r-x`
- Other: `---`
- Equivalent default ACLs were present for inheritance.

## Samba Auditing

| Item | Configuration | Status |
| --- | --- | --- |
| VFS audit module | `full_audit` | Complete |
| Audit prefix | User, client IP, and share | Complete |
| Successful operations | Connection and common file operations | Complete |
| Failed operations | All | Complete |
| Syslog facility | `LOCAL5` | Complete |
| Audit log | `/var/log/samba/audit.log` | Complete |
| Log permissions | `syslog:adm`, mode `0640` | Complete |

Validation completed:

- A `logger` test reached the dedicated Samba audit log.
- A Kerberos-authenticated privileged account was denied access to Finance.
- Samba produced audit records for the denied operation.

## Host Firewall

| Rule | Source | Destination | Status |
| --- | --- | --- | --- |
| Default incoming | Any | Deny | Complete |
| Default outgoing | Any | Allow | Complete |
| SSH | `10.10.10.0/24` | TCP 22 | Complete |
| SMB | `10.10.10.0/24` | TCP 445 | Complete |
| GLPI HTTP/HTTPS | Not yet configured | TCP 80/443 | Pending GLPI installation |

UFW is enabled. No NS-FS01 service is exposed through the pfSense WAN interface.

## SSH Hardening

| Setting | Value | Status |
| --- | --- | --- |
| Root login | Disabled | Complete |
| Empty passwords | Disabled | Complete |
| Maximum authentication attempts | 3 | Complete |
| X11 forwarding | Disabled | Complete |
| TCP forwarding | Disabled | Complete |
| Public-key authentication | Enabled | Complete |
| Password authentication | Temporarily enabled | Pending key-based validation |
| Keyboard-interactive authentication | Disabled | Complete |
| Idle-client checks | 300-second interval, count 2 | Complete |

Password authentication remains enabled until key-based access is configured and tested from an approved management workstation.

## Updates and System Auditing

| Control | Configuration | Status |
| --- | --- | --- |
| Automatic package-list updates | Daily | Complete |
| Unattended security upgrades | Enabled | Complete |
| Audit service | `auditd` active | Complete |
| Samba configuration watch | Write and attribute changes | Complete |
| SSH configuration watch | Write and attribute changes | Complete |
| Netplan configuration watch | Write and attribute changes | Complete |
| Kerberos configuration watch | Write and attribute changes | Complete |
| NSS configuration watch | Write and attribute changes | Complete |

Samba file operations are audited through `full_audit`; `auditd` monitors changes to critical system configuration.

## Current Validation Matrix

| Test | Result | Status |
| --- | --- | --- |
| Static address, gateway, DNS, and internet reachability | Passed | Complete |
| Forward and reverse DNS | Passed | Complete |
| Time synchronization with NS-DC01 | Passed | Complete |
| AD join and trust | Passed | Complete |
| AD user and group resolution | Passed | Complete |
| Kerberos-authenticated share enumeration | Passed | Complete |
| Hidden `Home$` share | Not displayed during enumeration | Complete |
| SMB1 disabled | Reported by `smbclient` | Complete |
| Privileged account denied Finance access | `NT_STATUS_ACCESS_DENIED` | Complete |
| Denied access recorded in Samba audit log | Audit lines generated | Complete |
| Standard user Company and department write access | Requires employee session | Pending |
| Cross-department denial | Requires employee session | Pending |
| Executive Finance and HR read-only access | Requires employee session | Pending |
| Department owner full control | Requires employee session | Pending |
| Home-folder isolation | Requires employee session | Pending |
| Inherited permissions on new content | Requires positive write test | Pending |

## Snapshots

| Snapshot | Purpose | Record status |
| --- | --- | --- |
| `01-ubuntu-baseline` | Updated Ubuntu, static network, DNS, SSH, and VMware tools | Confirmed |
| `02-ad-member-server` | Domain join, Winbind, NSS, Kerberos, and trust | Verify in Snapshot Manager |
| `03-samba-shares-configured` | Shares, resource ACLs, and home directories | Verify in Snapshot Manager |
| `04-samba-auditing-enabled` | Dedicated Samba audit logging and denied-access evidence | Verify in Snapshot Manager |
| `05-linux-hardening-complete` | UFW, SSH hardening, unattended upgrades, and auditd | Verify in Snapshot Manager |

## Evidence Index

| Evidence file | What it proves | Status |
| --- | --- | --- |
| `evidence/file-services/ns-fs01-domain-join-validation.png` | AD join, trust, services, and Kerberos integration | Capture/verify |
| `evidence/active-directory/ns-fs01-computer-object-placement.png` | Computer object is in the Servers OU | Capture/verify |
| `evidence/file-services/ns-fs01-finance-acl.png` | Finance RW, FC, RO, and inherited ACL entries | Capture/verify |
| `evidence/file-services/ns-fs01-share-enumeration.png` | Expected shares, hidden Home$, SMB1 disabled | Capture/verify |
| `evidence/file-services/privileged-account-finance-denied.png` | Infrastructure administrator denied departmental access | Capture/verify |
| `evidence/file-services/samba-privileged-denial-audit.png` | Denied access written to the Samba audit log | Capture/verify |
| `evidence/file-services/ns-fs01-hardening-validation.png` | UFW, service health, trust, and audit rules | Capture/verify |

## Issues and Resolutions

| Issue | Cause | Resolution | Current state |
| --- | --- | --- | --- |
| Linux `sed` command produced a PowerShell parser error | Command was accidentally run on NS-DC01 instead of NS-FS01 | Reran the command on Ubuntu; no change had occurred on NS-DC01 | Resolved |
| Package manager could not locate `ac1` | The ACL package name was typed with the number `1` instead of lowercase `l` | Reran the installation with package name `acl` | Resolved |
| Initial `wbinfo -t` check failed | The trust-secret check was run without root access | Reran as `sudo wbinfo -t` | Resolved |
| SMB session attempted `nsadmin@CORP.NORDSYSTEMS.COM` | The intended privileged Kerberos ticket was absent, so the local Ubuntu username was selected | Acquired a ticket for `adm-mhalvorsen@CORP.NORDSYSTEMS.COM` and targeted the server FQDN | Resolved |
| `rsyslog` briefly appeared inactive | Status was checked during or immediately after service restart | Confirmed `rsyslog` was active and validated the LOCAL5 logging route | Resolved |

## Current Build Status

Completed:

- Ubuntu baseline, networking, DNS, and time synchronization
- Active Directory member-server integration
- Winbind, NSS, Kerberos, and trust validation
- Company, departmental, and private home directory structure
- AGDLP-based ACL deployment
- Samba share publication and SMB2 minimum
- Privileged-account isolation test
- Samba operation auditing
- UFW, SSH hardening, unattended updates, and system auditing

Pending:

1. Verify snapshot and evidence filenames.
2. Configure and validate SSH key-based access before disabling password authentication.
3. Build NS-WS01.
4. Complete positive and negative role-based share tests from Windows.
5. Configure drive-mapping GPOs and validate H:, P:, S:, F:, and R: behavior.
6. Install, secure, and validate GLPI.
7. Add UFW rules for GLPI only when the web service is installed.
8. Install the backup agent and complete backup and restoration testing.

## Update Procedure

After each milestone:

1. Record the implemented setting and validation result.
2. Add the evidence filename.
3. Record mistakes and corrections without including credentials.
4. Confirm the snapshot in VMware Snapshot Manager.
5. Commit the build record and evidence to GitHub.

Do not record passwords, private keys, Kerberos tickets, database secrets, recovery media secrets, or tokens.
