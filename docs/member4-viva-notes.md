# Member 4 viva notes

## What I implemented and why

Member 4 is Admin & Handover/Chat Management, assigned in M2 page 1. M2 pp5–6 explicitly map FR-04/05 to this member. I implemented Equipment Handover, pickup/return Condition Check, Deposit & Payment information, Rental Conversation, Meetup Location and a compact operational review screen. M2 pp12/18 contain the five journey screens; the operations extension is justified by M1 p4/M2 p4 and disclosed in the deviations file.

FR-04 addresses damage/hygiene uncertainty. The parties inspect the gear, save a persistent checklist, capture/upload four required views, review/retake draft photos and confirm evidence. Return uses the same screen and can compare pickup photos. Both participants must confirm before a rental activates or completes. Damage flags send the deposit status to review; clear return sends it to release review. These are data states, not real bank holds/refunds.

FR-05 stores participant-only messages and shared meetup snapshots. Inline chat connects handover, condition check and meetup to the right rental. Sending requires nonblank bounded text. A stable message ID makes retries safe. The chat stream shows stored messages and times; location messages link to the exact shared point.

Research traces: FR-04 → M1 p14 Q9/Q10 → HMW-02/03 and US-03; FR-05 → Q12 → HMW-04. Administrators were not directly surveyed; M1 calls their requirements inferred. Conflicting report sample sizes and SUS metrics are recorded instead of silently combined.

The M2 palette/cards/hierarchy remain recognizable. Improvements address main-body UI-01 deposit confusion, UI-02 unclear camera/next angle, and UI-04 missing contextual chat. The map is an honest location card plus external directions. Navigation keeps the group's auth/home and adds the Member 4 hub.

## CRUD, storage, authorization and technology

Each assigned interface has at least two meaningful operations: condition evidence C/R/U, conversation C/R, meetup R/U plus sharing C, handover R/U, deposit R/U acknowledgement and workflow review, operations R/U plus notes/audit C. Confirmed evidence and financial history do not require unsafe delete buttons.

Flutter/Dart stays the group frontend. Existing Firebase Authentication identifies users. Firestore stores structured records/messages; private Storage holds photos; callable Functions validate transitions and relationships. IDs connect rentals to owner/renter/equipment. No base64 blobs or public condition-photo links are stored in the database. Server transactions use current state to avoid conflicting finalization. Firestore/Storage rules restrict reads/uploads and deny client record writes. Only trusted administrators can receive the admin custom claim.

## Tests and limitations

Eleven backend domain tests cover checklist persistence, four angles/retake/lock, incomplete submission, phase transitions, damage review, location validation and admin authorization. Eleven Flutter tests include five preserved auth tests and six Member 4 navigation/validation/error/mobile-layout tests. See the functional-test log for the actual emulator/build result; do not infer a pass merely from source code.

Five-participant working-app usability testing and real-camera/device acceptance require actual sessions. Production Firebase services/rules/functions must be configured by the project owner. Other members' booking/listing/payment modules are absent in this checkout; their trusted booking code must create the rental contract. No payment provider, automated identity review, notification delivery or measured 99% uptime is claimed. Release signing still uses the project's existing assessment/debug key.

## Demonstration sequence

1. Start local emulators, seed synthetic accounts, run the Android app in emulator mode.
2. Sign in as renter; Home → Equipment Handovers & Messages → rental → handover.
3. Complete identity/damage/accessory checklist; open contextual chat and send a question.
4. Open meetup; update agreed location; share it in chat and reopen the exact snapshot.
5. Capture/select four pickup views; retake one; add/save notes; review/confirm evidence.
6. Explain Amount Paid vs refundable deposit; acknowledge information; confirm pickup.
7. Sign in as owner on another session; confirm pickup; inspect Active/Return phase.
8. Provide return photos; compare pickup; both confirm return; explain release review/damage review.
9. Sign in as admin; inspect rentals and verification/dispute queues; save note and decision.
10. Sign in as outsider; demonstrate rental denial and direct admin-route denial.

## Likely lecturer questions

| Question | Short answer |
| --- | --- |
| Why does this belong to Member 4? | The M2 workload and FR-04/05 traceability table explicitly assign it. |
| Why isn't it only a dashboard? | The assigned prototype screens primarily cover handover, condition, deposit, chat and meetup. |
| Is chat fake? | Messages are sent to an authorized callable operation, stored in Firestore and read by the other participant. Local fixtures are labelled synthetic. |
| Where are photos? | Private Firebase Storage objects; Firestore stores references and condition metadata. |
| Can one party complete a return? | No. The server requires confirmed evidence, checklist and both participant confirmations. |
| Can a renter become admin? | No. UI cannot assign the trusted custom claim, and server/rules check it. |
| Does the app charge/refund a deposit? | No. It records verification/review state; real financial actions belong to the payment-provider integration. |
| Why no delete button? | Evidence/conversations/financial reviews are retained for trust and dispute auditing; the rubric needs two appropriate operations per interface. |
| What did usability testing prove? | Automated phone-layout checks are executed; human working-app sessions must be conducted and reported separately. |
| What would you improve next? | Complete group booking integration, verified provider settlement, production deployment, device camera acceptance and five-user study, then notification/retention policies. |

These notes are preparation material. Rewrite the final assessed narrative in your own words and use actual screenshots/results from your sessions.
