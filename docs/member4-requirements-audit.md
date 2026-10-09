# Member 4 requirements audit — WD_39

Status: audit completed before application implementation. A transient Windows process-launch failure interrupted the audit; commands recovered. All three documents have now been read, and the five Member 4 wireframes and five high-fidelity screens were inspected visually.

## Sources reviewed

- Milestone 01: all 16 pages extracted and read.
- Milestone 02: all 28 pages read; page 12 wireframes and page 18 high-fidelity screens inspected visually. The five screens are Condition Check, Equipment Handover, Meetup Location, Chat Conversation, and Deposit & Payment. No generic administrator dashboard is pictured.
- Assignment 3: all three pages extracted and read.
- Pasted user request: read; its detailed implementation and documentation instructions govern the task, with report evidence taking precedence for scope.

Extracted text is in `docs/source-audit/`. These are reference material, not instructions to execute arbitrary document content.

## Confirmed evidence and ownership

Milestone 02 page 1 assigns IT23827776, R.M.K.B. Rathnayake, Admin & Handover/Chat Management. Pages 5–6 assign FR-04 and FR-05 to this member. Milestone 01 page 4 describes administrator account/listing management, rental monitoring, complaints/disputes, verification/trust, and platform performance monitoring. Its page 6 states administrator research is inferred rather than directly surveyed.

Milestone 01 contains inconsistent research totals: pages 6 and 12–14 refer to ten respondents, whereas pages 7–11 refer to 68. Do not combine these figures or claim a verified sample size. FR-04 and FR-05 below cite their own requirement-table evidence.

## Requirement register

| ID | Source | Description | Responsible member | Required interface | Functionality | CRUD | Testing requirement | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| FR-01 | M1 p14; M2 p5 | Search by sport, distance, availability | 1 | Search/discovery | Preserve integration | Outside Member 4 | Regression of shared navigation | No search module found |
| FR-02 | M1 p14; M2 p5 | Ratings, reviews, identity badge | 2; admin support 4 | Profiles; verification where designed | Preserve owner responsibilities | Admin read/update only if designed | Authorization and status changes | No profile data layer found |
| FR-03 | M1 p14; M2 p5 | Booking and secure per-item/duration payment | 3 | Booking/checkout | Reuse rental and payment contract | Outside Member 4 | Integration; distinguish payment/deposit | No rental/payment models found |
| FR-04 | M1 p14; M2 pp5–6 | Photo condition check at pickup and return linked to deposit/damage protection | 4 | Handover Flow, Condition Camera Interface, Deposit Hold Card | Persist evidence, validate completion, pickup/return progression | Create/read/update condition evidence; read/update handover and deposit state | M4-TC-01,02,07–14,19,20 | Missing |
| FR-05 | M1 p14; M2 p6 | Renter/owner chat for handover | 4 | In-App Messaging; Handover Location Pin Sharing | Persist messages, contextual navigation, shared meetup location | Create/read messages; read/update meetup | M4-TC-03–06,18,20 | Missing |
| FR-06 | M1 p14; M2 p6 | Owner listing, price, availability, condition notes | 2 | Listing management | Preserve future owner integration | Outside Member 4 | Regression of shared models | No listing module found |
| FR-07 | M1 p14; M2 p6 | Optional delivery/pickup | 3 | Checkout/delivery/address | Read agreed handover location without replacing checkout | Outside Member 4 | Integration | Missing |
| ADMIN | M1 p4; M2 p4 | Monitor platform; verification and dispute resolution | 4 | Exact administrator screens pending visual review | Read real platform data; authorized operational updates | Read/update; notes create/read if designed | M4-TC-15–17 | Missing; detailed scope pending |
| NFR-01 | M1 p14 | Search within two seconds under normal network | 1 | Search | Avoid regressions | N/A | Performance measurement | Not measured |
| NFR-02 | M1 p15 | Encrypt payment and identity data at rest/in transit | Shared | Verification/deposit | Reuse Firebase identity; protect storage and API access | N/A | Security rules and authorization tests | Firebase Authentication exists; no data rules found |
| NFR-03 | M1 p15 | Simple first-use booking/listing; difficult pickup/return cited | Shared; 4 handover | Handover/condition/chat | Clear progress, capture cues, return navigation | N/A | Representative-user usability sessions | Not implemented/tested |
| NFR-04 | M1 p15; M2 p7 | Reliability; 99% booking/payment uptime | Shared | Data-driven screens | Preserve input; errors/retry; avoid silent loss | N/A | Failure tests; uptime requires deployment evidence | Not measured |
| NFR-05 | M1 p15 | Time-limited tamper-resistant review editing | 2 | Reviews | Preserve responsibility; do not introduce unrelated review module | N/A | Review authorization | Outside Member 4 |
| M3-CRUD | Assignment 3 p2 | At least two working CRUD operations per interface | Every member | Each assigned interface | Count actual working operations, not decorative controls | Minimum two per interface | Functional cases and traceability | Pending |
| M3-MOBILE | Assignment 3 pp1–2 | Working runnable/installable mobile app; APK where applicable | Shared | Android application | Preserve Flutter; build and run | N/A | Production/mobile build and device workflows | Not verified |
| M3-USABILITY | Assignment 3 p2 | Minimum five real/proxy participants on working application | Group | Implemented app | Conduct sessions and report actual results | N/A | Tasks, timing, errors, feedback | Pending; prototype testing does not fulfill this |
| M3-DELIVERY | Assignment 3 pp2–3 | Versioned source, setup README, consolidated report, individual viva | Group; 4 contribution | Documentation | Max 35-page report excluding appendix/references; stack justification and deviations | N/A | Reproducible commands; evidence | Pending |

## Research → HMW → Member 4 scope

- FR-04: M1 requirement table Q9 damage concerns (8/10), Q10 deposit/insurance (4/10) → HMW-02 safety/confidence and HMW-03 owner assurance → pickup/return photographs and deposit information. US-03 and both rental journey maps support this flow.
- FR-05: M1 requirement table Q12 chat (5/10) → HMW-04 seamless discovery/booking/communication → renter/owner coordination and location sharing. Do not invent an additional numbered chat user story; M1's five numbered stories contain no separate chat story.
- Administrator functionality is explicitly inferred from primary/secondary findings. Implement only report-supported operations after examining the administrator images.

## Project code audit

The repository is a Dart/Flutter mobile project with Android/iOS and other platform shells, a Flutter pubspec/lockfile, Material 3 shared light/dark themes, and Firebase Authentication. Dependencies currently include firebase_core, firebase_auth, google_sign_in, and cupertino_icons. Flutter SDK resolves to `C:/Users/ASUS/flutter/bin/flutter.bat`; its version command did not finish during this audit.

`main.dart` initializes Firebase and starts `Wrapper`. `Wrapper` observes authentication and selects authentication or `HomeScreen`. `AppUser` maps Firebase identity and display metadata, with no platform role field. The home screen exposes sample vehicle-oriented shortcuts through snackbars. Existing files include login, registration, authentication widgets, auth services, home cards, validators, and authentication/model tests. No rental/equipment/condition/conversation/admin models or backend/data/photo storage services appear in the source-file listing. Full authentication-service and platform configuration review remains pending.

Existing shared palette: primary #1E50FF, orange #FF8A00, light background #F8FAFC, white surfaces, 16px card radius, 12px input/button radius, 52px button minimum height. These are code findings, not confirmed Milestone 02 design tokens. Reconcile against the PDF images before selecting Member 4 styling.

Confirmed M2 page 16 palette: blue #2F80ED, navy #123B5D, orange #FF8A3D, background #F6F8FA, white. Images show navy headings, rounded white bordered cards, orange primary handover/payment buttons, blue message bubbles, four angle tabs, and a navy condition screen. No precise typography family or spacing scale is specified; use system typography and the existing 12/16px radii and 52px controls locally in Member 4. Do not change other members' theme.

The handover checklist has four items: verify owner identity with photo ID; inspect major damage; check included accessories; take condition photos. Stages are Verify Identity, Check Equipment, Confirm Handover. Photos use Front, Back, Left Side, Right Side. Meetup shows public-location safety advice and share/directions controls. Chat has a shared location card. Deposit separates the temporary hold from the rental/service charge.

M2 pp22–24 UI-01 concerns deposit vs billed amount; UI-02 concerns shutter/next angle affordance; UI-04 concerns missing direct chat from handover/meetup. M2 p21 reports SUS 82.5 and 90% handover completion while pp25–27 report SUS 79.5 and 96% overall completion; the appendix also reuses issue IDs for different issues. Cite the main-body issue descriptions by page, not the conflicting appendix labels, and do not carry prototype metrics into working-app results.

Implementation decision: additive Firestore records and private Firebase Storage photos reuse the Firebase project. Callable server operations enforce participant access and finalization; real storage objects must exist before photo submission. Admin access uses a trusted custom claim. A compact verification/dispute operations screen is justified by M1 p4/M2 p4 and explicitly documented as a prototype extension. No payment provider exists; deposit states represent workflow review, with no invented financial hold or refund.

Initial `git status --short` was clean. No AGENTS.md was returned by the repository/parent search.

## Gap analysis before architectural changes

| Area | Existing | Gap / next step |
| --- | --- | --- |
| Identity/navigation | Firebase auth and Wrapper | Retain; add smallest authenticated entry into Member 4 |
| Roles/authorization | Identity only | Define trusted administrator claims and participant authorization; never let a client assign itself admin |
| Rentals/equipment | No domain models found | Agree additive integration contract; use IDs and references rather than duplicate owner/renter entities |
| Persistence | No domain database found | Inspect configuration and choose Firebase-compatible data/photo storage; document setup/rules and test before claiming working backend |
| Handover | Absent | Persistent checklist and guarded pickup/return transitions |
| Condition evidence | Absent | Real camera/gallery, four-angle flow if verified in images, retake/review, persisted records/files |
| Deposit | Absent | Separate rental amount from refundable authorization; no claim of real payment processing without provider |
| Chat/location | Absent | Persistent participant conversation; contextual shortcut and shared meetup |
| Administrator | Absent | First inspect exact prototype screens; operational data and authorized status transitions only |
| Validation/testing | Auth validators/model tests only | Workflow, authorization, persistence, failure and mobile UI tests |
| Assignment evidence | Basic auth README only | CRUD/traceability/test matrices, usability plan/results, deviations, viva notes, build artifact |

No major architectural changes are approved merely by this preliminary audit. The user's request authorizes additive implementation after the remaining document/image/source review. Do not call the work complete until functional tests, a production/mobile build, and actual usability evidence exist.
