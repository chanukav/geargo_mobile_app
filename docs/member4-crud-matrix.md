# Member 4 CRUD matrix

Assignment 3 p2 requires **at least two working CRUD operations per interface**, not all four operations on every record. Evidence retention makes deletion inappropriate for confirmed photos, financial review records and conversations.

| Screen | Requirement | Create | Read | Update | Delete | Implemented? | Test case |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Equipment Handover | FR-04 | Participant confirmation record | Rental/checklist/progress | Checklist; guarded pickup/return status | No: retain rental history | Yes, R/U plus confirmation C | 01,02,13,14,19 |
| Condition Check / Camera | FR-04 | Photo objects and evidence references | Saved previews; pickup/return comparison | Draft retake and notes; submit | No: immutable objects/evidence | Yes, C/R/U | 07–11,14,19 |
| Deposit & Payment | FR-04; FR-03 integration | Per-user acknowledgement | Rental payment and refundable deposit review | Acknowledgement; return transition updates review state | No: financial audit | Yes, R/U; no payment processing | 12–14 |
| Rental Conversation | FR-05 | Text/location messages | Participant conversation | No: message immutability | No: preserve dispute evidence | Yes, C/R | 03–05,18,20 |
| Meetup Location | FR-05 | Shared location message | Agreed location; shared snapshot | Name/address/coordinates | No: retain shared snapshots | Yes, C/R/U | 06 |
| Platform Operations | M1 p4; M2 p4 | Review notes and audit records | Rental activity, verifications/disputes | Review status | No: safe decisions | Yes, C/R/U | 15–17 |

The hub is an integration entry point, not a separately assigned prototype interface. Test IDs have prefix `M4-TC-`. Backend paths and validation are documented in [architecture](member4-architecture.md). Executed results and unexecuted device tasks are distinguished in [functional tests](member4-functional-tests.md).
