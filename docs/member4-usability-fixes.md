# Member 4 usability fixes

Use M2 main-body findings pp22–24. Appendix E reuses the issue IDs for other problems, and its metrics conflict with the main body; do not merge those datasets.

| Issue | Original problem / evidence | Requirement | Implementation fix | Files | How tested | Result |
| --- | --- | --- | --- | --- | --- | --- |
| UI-01 | M2 p22: P2/P3 interpreted the deposit as nonrefundable; p24 recommends separate sections | FR-03/04 | Separate Amount Paid from Refundable Security Deposit. Explain return review and provider limitation; per-user acknowledgement | `deposit_screen.dart`, `widgets.dart`, `domain.js` | Widget deposit amounts; domain acknowledgement/return states; emulator workflow | Automated UI/domain tests passed; human comprehension testing pending |
| UI-02 | M2 p22: P3/P5 tapped the viewfinder and lacked next-angle cues; p24 recommends sequence/checkmarks | FR-04 | Labelled capture/upload buttons, 0–4 saved progress, angle chips/checkmarks, saved cue, next missing-angle selection, retake, review, disabled incomplete submission | `condition_screen.dart`, `repository.dart` | Phone layout/incomplete validation; domain four angles/retake/lock; emulator real objects | Automated UI/domain tests passed; real-camera and five-user test pending |
| UI-04 | M2 p22: users left Handover to reach Messages; p24 recommends inline Message Owner / Navigate to Meetup | FR-05 | Direct rental conversation from handover, meetup and condition screen; shared location message opens its exact snapshot | `handover_screen.dart`, `meetup_screen.dart`, `chat_screen.dart` | Widget taps handover chat shortcut; emulator stores location message | Contextual navigation widget test passed; human timing pending |

UI-03 search/filter changes belong to Member 1 and were not modified. No claim is made that prototype SUS scores measure the working Flutter app.
