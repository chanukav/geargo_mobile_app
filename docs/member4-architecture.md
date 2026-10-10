# Member 4 architecture and integration

## Stack and rationale

Keep the group's Flutter/Dart and Firebase Authentication architecture. Flutter 3.47.6/Dart 3.13.5 were found in the SDK version metadata. Flutter supports native Android camera/gallery, touch layouts and an installable APK. Firestore supports persistent rental/conversation streams; Storage keeps photo bytes outside document records; callable Functions centralize authorized state transitions. These are additive Firebase services because no existing domain backend/database/photo service was present.

The Member 4 screens share a repository interface to test UI without Firebase and keep fetch logic out of widgets. `FirebaseMember4Repository` supplies real streams and callable writes. A local theme follows the report without modifying the existing auth theme. Existing authentication, wrapper, models, validators and other members' modules remain intact. Home gets one new shortcut. Generated platform plugin registration changes are produced by Flutter dependencies.

Firebase callable functions include validated authentication context ([official documentation](https://firebase.google.com/docs/functions/callable)); this implementation additionally checks rental participation/admin claims on every operation. Firestore transactions validate the latest record before atomic changes ([transaction documentation](https://firebase.google.com/docs/firestore/manage-data/transactions)). Android image activity recovery follows the [image_picker guidance](https://pub.dev/packages/image_picker); recovered files require the user to select an angle before retrying.

## Collections and relationships

`rentals/{id}` is the Member 3 → Member 4 integration contract. Trusted booking code must create it after its own booking/payment checks. No client can fabricate bookings through Member 4. Existing owner/renter/equipment IDs are references; names/image/date/payment fields are display snapshots for booked terms, not replacement account/listing entities.

Required fields:

```text
ownerId, renterId, participantIds: [ownerId, renterId] (two distinct Firebase UIDs)
equipmentId, equipmentName, equipmentImageUrl (optional), ownerName, renterName
startDate, endDate (ISO calendar dates); dailyRate, currency
rentalCharge, serviceFee, amountPaid, paymentStatus (booking-owned records)
status: pending | active | completed
meetup: {name, address, latitude, longitude}
checklists: {pickup: {identity, damage, accessories}, return: {identity, damage, accessories}}
conditions: {pickup: condition, return: condition}
condition: {photos: {front?, back?, left?, right?}, notes, damageReported, status: draft|confirmed,
            confirmedAt?, confirmedBy?}
confirmations: {pickup: {uid?: ISO timestamp}, return: {uid?: ISO timestamp}}
deposit: {amount, status: pending|recorded|reviewRequired|releasePending}
depositAcknowledgedBy: {uid?: ISO timestamp}; updatedAt
```

Photos store private object paths such as `condition/{rentalId}/{phase}/{uploaderUid}/{randomObjectId}`. Storage objects are immutable. Retakes replace a draft reference with a new object; old objects are retained, not overwritten. Confirmed evidence is immutable. No permanent public download URLs or base64 image data are placed in Firestore/components. The UI loads bytes using authenticated Storage reads; the backend verifies object existence, supported content type and size before saving/submitting references. Retention/cleanup of unused draft objects remains a future operational policy.

`rentals/{id}/messages/{clientGeneratedId}` contains senderId, kind, text, optional immutable location snapshot and server-created timestamp. Stable IDs prevent duplicate retry submissions after a lost response. Server authorization checks the rental each time. The location snapshot is preserved even if the agreed rental meetup later changes.

`verifications/{id}` contains userId, summary, status and notes. `disputes/{id}` contains rentalId, summary, status and notes. These are trusted operational queues, not client-created identity approvals. `audit/{id}` records reviewer UID, target path, status, note and timestamp. No real ID images or card numbers are stored by this module. A verification decision updates the operational request; Member 2's future profile badge must consume this trusted status rather than Firebase's email-verification flag.

## Callable API (region us-central1)

These are Firebase callable endpoints, not a parallel REST family:

| Function | Payload / operations | Authorization |
| --- | --- | --- |
| `member4Handover` | rentalId, action; checklist phase/key/value; photo phase/angle/path; notes phase/notes/damageReported; submitCondition phase; confirmHandover phase; meetup location; acknowledgeDeposit | Authenticated rental participant |
| `member4Message` | rentalId, messageId, kind text/location, text | Authenticated rental participant |
| `member4Admin` | kind verification/dispute, id, status, note | Trusted admin custom claim |

No hardcoded rental ID is used in application screens. IDs come from the signed-in user's rental query and contextual navigation. Emulator seed IDs are explicitly synthetic.

## State and security

Pickup evidence/checklist opens only for pending rentals. Every four-angle condition submission locks evidence. Renter and owner independently confirm; the second confirmation activates the rental. Return opens only for active rentals and reuses the condition screen with pickup comparison. Both return confirmations complete the rental and set damage review or release-review-pending. **No transaction here creates a financial authorization or releases money.** Member 3/payment-provider integration must verify actual holds/refunds. No unsupported release deadline is promised.

Firestore rules allow participant rental/message reads and trusted admin operational reads. Client document writes are denied; server commands validate IDs, bounded text, valid coordinates, photo ownership, open phases, required evidence/checklists and allowed review statuses. Storage reads require participant/admin authorization, creates require participant/uploader/open phase, valid type and <8MB size, and updates/deletes are denied. Checklists lock once a participant confirms. Users cannot set their own admin claim. Cloud Functions run under the Admin SDK and perform their own authorization; hiding UI is not treated as protection.

## Reliability and limits

Loading/empty/error screens are explicit. Failed chat/notes/photo operations retain input in the current screen, and messages have idempotent retry IDs. Notes/checklists/photos acknowledged by the backend survive navigation and reload. Unsaved text is retained while opening a contextual route but is not guaranteed after force-closing the app; tap Save notes before leaving. Android's recovered picker file can be retried. Callable mutations require connectivity; no false offline success is displayed. Emulator integration checks real persistence and access rules. No deployed uptime, production payment, human identity verification or human usability result is claimed.

Production deployment is separate from source implementation. Firebase project-owner access and service activation are required; emulator mode supports local execution without cloud credentials. The existing non-Android Firebase configuration limitation remains documented in the original README. Android release signing remains the group's existing debug key configuration, suitable for assessment installs, not store distribution.
