# Nord Systems Access Control Matrix

| Field | Value |
| --- | --- |
| Document ID | D-05 |
| Environment | Simulated Nord Systems virtual IT lab |
| AD domain | `corp.nordsystems.com` |
| File server | `NS-FS01` |
| Access model | AGDLP |
| Source | Nord Systems Identity and Access Register |

## Purpose

This document summarizes the access-control design for Nord Systems shared resources. The design follows least privilege, separation of standard and privileged accounts, role-based group membership, and deny-by-default access.

The full Identity and Access Register is maintained separately as the detailed source for accounts, groups, memberships, systems, and operating profiles.

## Access Model

Nord Systems uses AGDLP:

1. User and service **accounts** are assigned to **global groups** that represent business or administrative roles.
2. Global groups are nested into **domain local groups** associated with a resource and permission level.
3. Domain local groups receive the actual permission on the resource.

Accounts are not placed directly on shared-resource ACLs. The documented exception is each user's private `Home$` folder, where the individual account requires a direct ACL entry.

## Role Rules

| Role | Effective access |
| --- | --- |
| Executive | Full control of the executive's own department, read-only access to Finance and HR, and modify access to Company |
| Department manager | Full control of the manager's own departmental share through an owner group; the manager tier itself grants no resource access |
| Staff | Modify access to the employee's departmental share and Company |
| Infrastructure administrator | No standing access to departmental or user shares; administrative access uses separate `adm-` accounts and documented procedures |
| Service account | Only the rights required by its assigned service; interactive logon is denied |

## Shared-Resource Access Matrix

`Modify` permits normal working access. `Full` is assigned only to the department owner. `Read` is read-only. `Own` means access only to the user's own folder. `None` means no standing access.

| Share | Administration | Finance | HR | IT | Marketing | Executive | Infrastructure admins |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `\\NS-FS01\Company` | Modify | Modify | Modify | Modify | Modify | Modify | None |
| `\\NS-FS01\Administration` | Modify | None | None | None | None | Full | None |
| `\\NS-FS01\Finance` | None | Modify | None | None | None | Read | None |
| `\\NS-FS01\HR` | None | None | Modify | None | None | Read | None |
| `\\NS-FS01\IT` | None | None | None | Modify | None | None | None |
| `\\NS-FS01\Marketing` | None | None | None | None | Modify | None | None |
| `\\NS-FS01\Home$` | Own | Own | Own | Own | Own | Own | None |

The executive is also the Administration data owner in this simulated organization. This is why the executive receives Full control of the Administration share.

## AGDLP Group Mapping

| Business role or scope | Global group | Domain local group | Effective permission |
| --- | --- | --- | --- |
| All standard users | `GG_Org_AllStaff` | `DL_ShareCompany_RW` | Modify Company |
| Administration staff | `GG_Dept_Administration` | `DL_ShareAdministration_RW` | Modify Administration |
| Administration owner | `GG_Owner_Administration` | `DL_ShareAdministration_FC` | Full control Administration |
| Finance staff | `GG_Dept_Finance` | `DL_ShareFinance_RW` | Modify Finance |
| Finance owner | `GG_Owner_Finance` | `DL_ShareFinance_FC` | Full control Finance |
| Executive tier | `GG_Tier_Executive` | `DL_ShareFinance_RO` | Read Finance |
| HR staff | `GG_Dept_HR` | `DL_ShareHR_RW` | Modify HR |
| HR owner | `GG_Owner_HR` | `DL_ShareHR_FC` | Full control HR |
| Executive tier | `GG_Tier_Executive` | `DL_ShareHR_RO` | Read HR |
| IT staff | `GG_Dept_IT` | `DL_ShareIT_RW` | Modify IT |
| IT owner | `GG_Owner_IT` | `DL_ShareIT_FC` | Full control IT |
| Marketing staff | `GG_Dept_Marketing` | `DL_ShareMarketing_RW` | Modify Marketing |
| Marketing owner | `GG_Owner_Marketing` | `DL_ShareMarketing_FC` | Full control Marketing |
| Infrastructure administrators | `GG_Admin_Infrastructure` | `DL_GLPI_Admins` | GLPI super-administrator profile |
| IT staff | `GG_Dept_IT` | `DL_GLPI_Technicians` | GLPI technician profile |
| Infrastructure administrators | `GG_Admin_Infrastructure` | `DL_Workstation_Admins` | Local administrator on workstations through GPO |
| Infrastructure administrators | `GG_Admin_Infrastructure` | `DL_Server_Admins` | Local administrator on member servers through GPO |

## Administrative and Emergency Access

Infrastructure administrators have no standing network-share access to departmental data. A legitimate business need must be recorded in GLPI, approved by the owning department manager, and implemented through the appropriate group membership. The membership change is captured by security-group-management auditing.

Restore operations do not require departmental share membership because the backup agent operates with local privilege on `NS-FS01`.

## Validation Tests

| Test | Action | Expected result |
| --- | --- | --- |
| Department isolation 1 | Sign in with a Finance staff account and open `\\NS-FS01\HR` | Access denied |
| Department isolation 2 | Sign in with an HR staff account and open `\\NS-FS01\Finance` | Access denied |
| Privileged-account isolation | Sign in with an `adm-` infrastructure account and open `\\NS-FS01\Finance` | Access denied |
| Executive read-only access | Sign in with the executive account and attempt to create or modify a file in Finance and HR | Read succeeds; write is denied |
| Department working access | Sign in with a standard department account and create, edit, and delete a test file in that department's share | Operations succeed |
| Home-folder isolation | Sign in as one user and attempt to open another user's folder under `Home$` | Access denied |

Evidence for each validation test is captured during implementation and stored in the repository's `evidence/` directory with sensitive values redacted.

## Security Notes

- Samba share permission is set broadly, while the resource ACL is the authoritative access gate.
- Cross-department access is denied unless explicitly approved and assigned through the appropriate groups.
- Privileged accounts are separate from daily user accounts.
- Service accounts are limited to service use and are denied interactive logon.
- All users, departments, and organizational data in this project are fictional.
