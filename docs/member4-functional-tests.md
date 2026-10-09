# Member 4 functional tests

Test date: 7 October 2026. All IDs below have prefix `M4-TC-`. Use actual results from the executed suites; manual camera/device and human sessions are explicitly pending. Emulator fixtures are synthetic and do not claim live customer evidence.

Evidence sources:

- `test/member4_widget_test.dart`: seven Member 4 widget tests at 360×800 and 390×844; all passed. Existing five auth tests also passed (12 total).
- `functions/test/domain.test.js`: eleven workflow/security/validation tests; all passed.
- `functions/test/emulator/workflows.test.js`: full Auth/Firestore/Functions/Storage integration workflow **passed** (one end-to-end test with multiple persistence/security/storage/transition assertions; 11.1 seconds).
- Tool logs are in ignored `.tooling/` to avoid committing verbose environment output. Tests themselves are reproducible evidence.

| ID | Requirement | Preconditions | Steps | Expected | Actual result | Status | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 01 | FR-04 | Signed-in participant; pending rental | Open hub and handover | Correct rental and checklist progress | Phone widget shows rental and 0/4 progress | Automated pass | Widget navigation test |
| 02 | FR-04 | Pending rental, no participant confirmed | Check identity/accessories/damage; navigate/reload | Saved checklist persists; snapshot not mutated | Domain update preserves previous snapshot | Domain pass; persistence integration pending | Domain checklist test |
| 03 | FR-05/UI-04 | Handover loaded | Tap Message Owner | Correct rental chat opens | Phone widget opens Rental Conversation | Automated pass | Widget contextual navigation |
| 04 | FR-05 | Participant conversation | Enter and send a message | Message stored and visible to participants | Widget repository receives text; real backend integration pending | Widget pass; integration pending | Widget send/retry; emulator test |
| 05 | FR-05 | Stored message | Reopen with owner; retry same message ID | Original message persists; no duplicate | Awaiting emulator integration result | Pending integration | Emulator separate owner client/query |
| 06 | FR-05 | Participant rental | Read/update coordinates; share location; open directions | Valid location persists; exact snapshot accessible | Domain accepts valid coordinates and rejects invalid values | Domain pass; platform directions manual pending | Domain meetup; emulator location snapshot |
| 07 | FR-04 | Pending rental | Open pickup condition screen | Four angles and capture guidance | 360px phone widget shows explicit Front prompt | Automated pass | Condition widget test |
| 08 | FR-04 | Camera/gallery permission; pending pickup | Capture/select Front | Private object/reference and preview | Domain saves front reference; real Storage integration pending | Device camera pending | Domain photo test; emulator PNG upload |
| 09 | FR-04/UI-02 | First photo saved | Add Back/Left/Right | Four saved views and clear progression | Domain stores four angle references; phone validation checks incomplete state | Domain pass; camera progression manual pending | Domain four-angle test |
| 10 | FR-04 | Draft photo exists | Retake Front; reopen preview | Draft reference replaced; confirmed evidence cannot change | Domain validates retake and lock | Domain pass; real upload pending | Domain retake; emulator immutable objects |
| 11 | FR-04 | Four photos saved; optional damage described | Review, save notes, confirm | Valid evidence confirmed/locked; existing objects required | Domain validates notes and immutability | Domain pass; server object verification pending | Domain notes/submit; emulator missing object |
| 12 | FR-04/UI-01 | Rental payment/deposit record | View breakdown; acknowledge | Paid amount separate from refundable deposit | Widget shows USD140.80 vs USD150.00; domain stores per-user acknowledgement | Automated pass | Deposit widget/domain tests |
| 13 | FR-04 | Checklist and pickup evidence confirmed | Renter confirms; owner confirms | First waits; second makes Active | Domain validates both-party transition | Domain pass; integration pending | Domain pickup |
| 14 | FR-04 | Active rental | Return photos/notes, compare pickup, both confirm | Completed; damage review or release review pending | Domain validates clean/damaged return outcomes | Domain pass; live camera pending | Domain return; emulator round trip |
| 15 | ADMIN | Trusted admin claim | Open operations | Real rental counts and records; no invented analytics | Direct nonadmin screen guarded; live admin integration pending | Pending integration | Admin UI; emulator admin reads |
| 16 | ADMIN | Pending review and admin | Enter note, confirm status | Status/notes/audit persist; invalid/closed transitions rejected | Domain verifies allowed status, required notes and terminal locks | Domain pass; integration pending | Admin domain/emulator |
| 17 | Security | Unrelated user or renter | Direct admin route; request another rental/admin command | Denied before sensitive data/action | Widget denies admin before query; domain denies unrelated/admin mutation | Automated pass; rules integration pending | Admin widget/domain; emulator denial |
| 18 | FR-05 | Conversation open | Send whitespace/oversize message | Rejected; no stored message | Widget/domain reject blank/oversize | Automated pass | Chat widget/domain |
| 19 | FR-04 | Fewer than four photos/incomplete checklist | Try submitting/confirming/wrong phase | Disabled UI and server rejection | Widget disables confirmation; domain rejects incomplete/wrong phase | Automated pass | Condition widget/domain |
| 20 | Reliability | Failed/offline mutation | Enter message, fail send, retry; select image then retry upload | Retain input; no false success or duplicate messages | Widget retains and retries text successfully | Automated text pass; physical offline photo test pending | Widget failure; emulator idempotency |

## Build and run record

- Flutter dependency download succeeded; `flutter pub add` reported Windows desktop symlink support needs Developer Mode.
- `flutter analyze --no-pub`: **No issues found** after applying localized Dart brace fixes.
- `flutter test --no-pub`: **12 passed**, including unchanged auth tests and the additional direct administrator-evidence route test.
- `node --test functions/test/domain.test.js`: **11 passed**.
- Initial backend dependency install failed because C: had no free space; workspace-local npm cache install succeeded.
- `npm audit --omit=dev`: zero production dependency vulnerabilities at the time checked. The development tool installation reported vulnerabilities; no breaking force upgrade was applied.
- Initial release APK attempt failed due to incomplete system NDK 28.2 (missing source.properties). A complete matching NDK was downloaded under ignored `.tooling/android-ndk`; the machine-specific `geargo.ndkPath` fallback in untracked Android local.properties resolved this. Release APK built successfully (52.4 MB).
- Debug APK with local Firebase host 10.0.2.2 built successfully using direct Gradle, Android x64, a 2GB heap and two workers. An earlier concurrent Flutter/emulator attempt exhausted Windows thread resources; the successful build stopped test services during compilation. Output: `build/app/outputs/apk/debug/app-debug.apk`. This build compiles the current administrator-evidence navigation revision.
- Android run check subsequently passed: the D:-backed GearGo_Acceptance emulator (emulator-5554) booted with Vulkan disabled and 1536MB RAM; debug APK installation returned Success; `com.example.geargo/.MainActivity` launched, its rendered GearGo screen was verified through UI hierarchy/screenshot, and its emulator window was brought into view. Local Firebase was started and seeded. Evidence: `docs/evidence/android-login.png` (the capture shows the authenticated guest home, despite the initial filename). Physical camera/permission and full on-device workflow tests remain pending.
- Firebase emulator end-to-end workflow: **passed**, exit 0. Verified actual message persistence across separate renter/owner clients, retry deduplication, shared location snapshots, authenticated private PNG object upload/read, unrelated-account denial, immutable object deletion denial, retake, missing-object rejection, confirmed evidence lock, both-party pickup/return, verification/dispute decisions and two audit records. The legacy Storage emulator emitted a shutdown-time Java null-input exception after the successful suite; no test assertion failed.
- Working-app five-participant usability sessions: **not conducted**; see the preparation plan.

## Manual device acceptance still needed

Run the emulator-backed APK on Android; grant/deny camera/photo permissions, capture all angles, retake, cancel picker, rotate/background, recover interrupted capture, reopen saved photos/chat, test keyboard and back navigation, both-party pickup/return, offline retry and directions launch. Repeat relevant tasks at representative Android phone sizes. Save screenshots and actual logs. UI tests with a test repository are not evidence of physical camera operation.
