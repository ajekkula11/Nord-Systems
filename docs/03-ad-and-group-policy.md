# Nord Systems Active Directory and Group Policy Specification

Organizational unit, group placement, and Group Policy baseline for the simulated Nord Systems environment.

| Field | Value |
|---|---|
| Document ID | NS-DOC-003 |
| Deliverable | D-03 |
| Version | 1.0 |
| Status | Baseline |
| Owner | Infrastructure Engagement Lead |
| Governing document | NS-DOC-001 Engagement Charter v1.2 |

## 1. Purpose and Scope

This document specifies the Active Directory logical structure for Nord Systems: the organizational unit hierarchy, placement of directory objects, and Group Policy Objects applied to each container.

The Identity and Access Register remains authoritative for accounts, groups, nesting, and share access. This document defines where those objects are placed and how policy is scoped.

| Document | Relationship |
|---|---|
| NS-DOC-001 Engagement Charter | Defines naming, namespace, addressing, systems, access tiers, and security requirements |
| Identity and Access Register | Defines accounts, groups, nesting, and the access matrix |
| D-04 System Build Records | Records actual host configurations, including Linux-side controls |
| D-09 Automation Scripts | Creates the OUs, accounts, and groups specified here |

## 2. Organizational Unit Structure

### 2.1 Design Principles

- Users and computers are separated so user-side and computer-side policy can be scoped independently.
- Departmental OUs support departmental drive mapping and possible future software deployment.
- Permissions are determined by group membership, not OU placement.
- Privileged and service accounts are separated from staff accounts so logon restrictions can be scoped cleanly.
- NS-DC01 remains in the default Domain Controllers OU.
- Built-in policies are not modified except for domain account policy in the Default Domain Policy.

### 2.2 OU Tree

```text
corp.nordsystems.com
|
+-- OU=NordSystems
|   +-- OU=Departments
|   |   +-- OU=Administration
|   |   +-- OU=Finance
|   |   +-- OU=HumanResources
|   |   +-- OU=IT
|   |   +-- OU=Marketing
|   +-- OU=Groups
|   +-- OU=Workstations
|   +-- OU=Servers
|   +-- OU=AdminAccounts
|   +-- OU=ServiceAccounts
|
+-- OU=Domain Controllers
```

### 2.3 Container Contents

| Container | Distinguished name | Contents |
|---|---|---|
| Administration | `OU=Administration,OU=Departments,OU=NordSystems,DC=corp,DC=nordsystems,DC=com` | `arao`, `jpatel` |
| Finance | `OU=Finance,OU=Departments,OU=NordSystems,DC=corp,DC=nordsystems,DC=com` | `swhitfield`, `jbrennan` |
| Human Resources | `OU=HumanResources,OU=Departments,OU=NordSystems,DC=corp,DC=nordsystems,DC=com` | `alindqvist`, `esorensen` |
| IT | `OU=IT,OU=Departments,OU=NordSystems,DC=corp,DC=nordsystems,DC=com` | `mhalvorsen`, `amenon`, daily accounts only |
| Marketing | `OU=Marketing,OU=Departments,OU=NordSystems,DC=corp,DC=nordsystems,DC=com` | `rcastellanos`, `lnovak` |
| Groups | `OU=Groups,OU=NordSystems,DC=corp,DC=nordsystems,DC=com` | Role groups and resource groups defined in the Identity and Access Register |
| Workstations | `OU=Workstations,OU=NordSystems,DC=corp,DC=nordsystems,DC=com` | NS-WS01 and NS-WS02 |
| Servers | `OU=Servers,OU=NordSystems,DC=corp,DC=nordsystems,DC=com` | NS-FS01 |
| AdminAccounts | `OU=AdminAccounts,OU=NordSystems,DC=corp,DC=nordsystems,DC=com` | `adm-mhalvorsen`, `adm-amenon` |
| ServiceAccounts | `OU=ServiceAccounts,OU=NordSystems,DC=corp,DC=nordsystems,DC=com` | `svc-backup`, `svc-dhcp`, `svc-glpi`, `svc-samba` |
| Domain Controllers | `OU=Domain Controllers,DC=corp,DC=nordsystems,DC=com` | NS-DC01 |

## 3. Group Placement

All role and resource groups are stored flat in `OU=Groups`. Group scope and membership define access. OU placement does not convey permissions.

The Identity and Access Register is authoritative for the complete group catalog, nesting, and resulting access matrix.

## 4. Group Policy Inventory

| Policy object | Linked to | Configuration side | Purpose |
|---|---|---|---|
| Default Domain Policy | Domain root | Computer | Password and lockout policy |
| NS_Baseline_DomainControllers | Domain Controllers | Computer | Domain controller security baseline |
| NS_Baseline_Workstations | Workstations | Computer | Workstation security baseline |
| NS_Baseline_Servers | Servers | Computer | Dormant Windows server baseline |
| NS_DriveMapping_Home | Departments | User | User home-drive mapping |
| NS_DriveMapping_Departments | Departments | User | Company and departmental drive mappings |
| NS_RestrictedGroups_Workstations | Workstations | Computer | Workstation local group membership |
| NS_RestrictedGroups_Servers | Servers | Computer | Dormant Windows server local group policy |
| NS_LogonRestrictions_Privileged | Workstations | Computer | Privileged-account tier separation |
| NS_LogonRestrictions_Service | Workstations, Servers, Domain Controllers | Computer | Service-account interactive-logon restrictions |
| NS_Audit_Authentication | Domain Controllers, Workstations | Computer | Authentication and account-management auditing |

## 5. Policy Specifications

### 5.1 Default Domain Policy

**Link:** Domain root  
**Scope:** Authenticated Users  
**Side:** Computer Configuration

| Setting | Value | Path |
|---|---|---|
| Enforce password history | 24 passwords | Account Policies > Password Policy |
| Maximum password age | 365 days | Account Policies > Password Policy |
| Minimum password age | 1 day | Account Policies > Password Policy |
| Minimum password length | 14 characters | Account Policies > Password Policy |
| Password complexity | Enabled | Account Policies > Password Policy |
| Account lockout threshold | 10 invalid attempts | Account Policies > Account Lockout Policy |
| Account lockout duration | 15 minutes | Account Policies > Account Lockout Policy |
| Reset lockout counter after | 15 minutes | Account Policies > Account Lockout Policy |

Domain account policy is linked at the domain root so it affects domain accounts.

### 5.2 NS_Baseline_DomainControllers

**Link:** `OU=Domain Controllers`  
**Side:** Computer Configuration

| Setting | Value | Path |
|---|---|---|
| Digitally sign communications, SMB server | Enabled | Security Options |
| Do not display last signed-in user | Enabled | Security Options |
| Machine inactivity limit | 900 seconds | Security Options |
| Allow log on through Remote Desktop Services | `DL_Server_Admins` | User Rights Assignment |
| Windows Defender Firewall | Enabled on all profiles, inbound default block | Windows Defender Firewall |
| Configure SMBv1 client driver | Disabled | Administrative Templates > MS Security Guide |

This baseline is separate from the Default Domain Controllers Policy so it can be unlinked independently if a setting causes a fault.

### 5.3 NS_Baseline_Workstations

**Link:** `OU=Workstations`  
**Applies to:** NS-WS01 and NS-WS02  
**Side:** Computer Configuration

| Setting | Value | Path |
|---|---|---|
| Configure SMBv1 client driver | Disabled | Administrative Templates > MS Security Guide |
| SMBv1 server | Disabled | Administrative Templates > MS Security Guide |
| Turn off multicast name resolution, LLMNR | Enabled | Administrative Templates > Network > DNS Client |
| Machine inactivity limit | 900 seconds | Security Options |
| Do not display last signed-in user | Enabled | Security Options |
| UAC admin approval mode | Enabled, prompt for consent on secure desktop | Security Options |
| Windows Defender Firewall | Enabled on all profiles, inbound default block | Windows Defender Firewall |
| Configure Automatic Updates | Auto download and scheduled installation | Administrative Templates > Windows Update |
| Interactive logon message | Nord Systems authorized-use notice | Security Options |

Disabling LLMNR removes multicast fallback and forces workstation name resolution through NS-DC01.

### 5.4 Dormant Server Policies

**Policies:** `NS_Baseline_Servers`, `NS_RestrictedGroups_Servers`  
**Link:** `OU=Servers`  
**Current members:** NS-FS01 only

These policies are created and linked but do not currently apply because NS-FS01 is a Linux server and does not process Windows Group Policy. Equivalent Linux hardening, including SSH restrictions, host firewall rules, Samba configuration, and audit logging, belongs in the NS-FS01 build record.

Their dormant state must be recorded as expected, not treated as evidence that the settings applied successfully.

### 5.5 NS_DriveMapping_Home

**Link:** `OU=Departments`  
**Side:** User Configuration > Preferences > Windows Settings > Drive Maps

| Letter | Path | Action | Targeting |
|---|---|---|---|
| H: | `\\NS-FS01\Home$\%LogonUser%` | Update and reconnect | All users in scope |

The home-drive mapping is kept separate from conditional departmental mappings so either policy can be diagnosed or unlinked independently.

### 5.6 NS_DriveMapping_Departments

**Link:** `OU=Departments`  
**Side:** User Configuration > Preferences > Drive Maps

| Letter | Path | Item-level target |
|---|---|---|
| P: | `\\NS-FS01\Company` | Member of `GG_Org_AllStaff` |
| S: | `\\NS-FS01\Administration` | Member of `GG_Dept_Administration` |
| S: | `\\NS-FS01\Finance` | Member of `GG_Dept_Finance` |
| S: | `\\NS-FS01\HR` | Member of `GG_Dept_HR` |
| S: | `\\NS-FS01\IT` | Member of `GG_Dept_IT` |
| S: | `\\NS-FS01\Marketing` | Member of `GG_Dept_Marketing` |
| F: | `\\NS-FS01\Finance` | Member of `GG_Tier_Executive` |
| R: | `\\NS-FS01\HR` | Member of `GG_Tier_Executive` |

Design rules:

- The S: drive always represents the signed-in user's department.
- Departmental groups are mutually exclusive, so only one S: mapping should evaluate true.
- Group membership, not account location, determines mappings.
- Executive users receive F: and R: in addition to their departmental S: drive.
- Item-level targeting controls mapping convenience, not authorization. Samba ACLs remain the security control.

### 5.7 NS_RestrictedGroups_Workstations

**Link:** `OU=Workstations`  
**Side:** Computer Configuration > Preferences > Local Users and Groups

| Local group | Members, replacing existing membership |
|---|---|
| Administrators | `DL_Workstation_Admins` and the built-in local Administrator account |
| Remote Desktop Users | `DL_Workstation_Admins` |

Replacing membership removes unauthorized locally added administrators during policy refresh. `DL_Workstation_Admins` contains `GG_Admin_Infrastructure`, which contains only the two `adm-` accounts.

### 5.8 NS_LogonRestrictions_Privileged

**Link:** `OU=Workstations`  
**Side:** Computer Configuration > User Rights Assignment

| Right | Assigned to |
|---|---|
| Deny log on locally | `GG_Admin_Infrastructure` |
| Deny log on through Remote Desktop Services | `GG_Admin_Infrastructure` |

Privileged accounts remain local administrators for approved remote-management mechanisms but cannot be used for interactive workstation sign-in.

### 5.9 NS_LogonRestrictions_Service

**Links:** `OU=Workstations`, `OU=Servers`, and `OU=Domain Controllers`  
**Side:** Computer Configuration > User Rights Assignment

| Right | Assigned to |
|---|---|
| Deny log on locally | `GG_Svc_Application`, `GG_Svc_Backup` |
| Deny log on through Remote Desktop Services | `GG_Svc_Application`, `GG_Svc_Backup` |

Service accounts are denied interactive and Remote Desktop logon. `Deny log on locally` controls interactive logon and does not prevent an account from running a Windows service. If `svc-backup` is configured as a custom Veeam service identity, `Log on as a service` is granted separately. Veeam otherwise uses LocalSystem by default.

### 5.10 NS_Audit_Authentication

**Links:** `OU=Domain Controllers` and `OU=Workstations`  
**Side:** Computer Configuration > Advanced Audit Policy Configuration

| Subcategory | Setting | Category |
|---|---|---|
| Audit Credential Validation | Success and Failure | Account Logon |
| Audit Kerberos Authentication Service | Success and Failure | Account Logon |
| Audit Logon | Success and Failure | Logon/Logoff |
| Audit Account Lockout | Success and Failure | Logon/Logoff |
| Audit User Account Management | Success and Failure | Account Management |
| Audit Security Group Management | Success and Failure | Account Management |

Authentication, lockout, account-management, and group-management events provide evidence for troubleshooting and access changes. File-level access auditing for NS-FS01 is configured through Samba rather than Group Policy.

## 6. Link Order and Precedence

Policy applies in local, site, domain, and OU order. The container closest to the object applies last. Within one container, link order 1 has the highest precedence.

| Container | Link order | Policy object |
|---|---:|---|
| Domain root | 1 | Default Domain Policy |
| Domain Controllers | 1 | NS_LogonRestrictions_Service |
| Domain Controllers | 2 | NS_Baseline_DomainControllers |
| Domain Controllers | 3 | NS_Audit_Authentication |
| Domain Controllers | 4 | Default Domain Controllers Policy |
| Workstations | 1 | NS_LogonRestrictions_Privileged |
| Workstations | 2 | NS_LogonRestrictions_Service |
| Workstations | 3 | NS_RestrictedGroups_Workstations |
| Workstations | 4 | NS_Baseline_Workstations |
| Workstations | 5 | NS_Audit_Authentication |
| Servers | 1 | NS_LogonRestrictions_Service |
| Servers | 2 | NS_RestrictedGroups_Servers |
| Servers | 3 | NS_Baseline_Servers |
| Departments | 1 | NS_DriveMapping_Departments |
| Departments | 2 | NS_DriveMapping_Home |

No GPO uses Enforced, Block Inheritance, or security filtering. Scoping is handled through link location and drive-map item-level targeting.

## 7. Verification

| ID | Test | Expected result |
|---|---|---|
| V-01 | Sign in as `jbrennan` on NS-WS01 and list mapped drives | H:, P:, and Finance S: are present; F: and R: are absent |
| V-02 | Sign in as `arao` on NS-WS01 | H:, P:, Administration S:, Finance F:, and HR R: are present |
| V-03 | As `jbrennan`, open the HR share directly by UNC path | Access denied, confirming the ACL rather than targeting is the control |
| V-04 | Run `gpresult /h` as a standard user | Drive mapping policies and workstation baseline apply without errors |
| V-05 | Attempt interactive sign-in as `adm-amenon` on NS-WS01 | Sign-in denied by User Rights Assignment |
| V-06 | Add a local account to Administrators, then force policy refresh | Account removed and approved membership restored |
| V-07 | Move a test account between departmental groups and sign in again | S: maps to the new department without a policy change |
| V-08 | Lock out a test account and inspect the DC security log | Event 4740 identifies the source workstation |
| V-09 | Confirm NS_Baseline_Servers has no applicable Windows systems | Dormant state matches Section 5.4 |

## 8. Change Control

- OU changes require a document version update because automation uses the literal distinguished names.
- New GPOs must be added to the inventory and fully specified before creation.
- Any future use of Enforced, Block Inheritance, or security filtering must be documented with its reason.

