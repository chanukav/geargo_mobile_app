'use strict';
const {initializeApp} = require('firebase-admin/app');
const {getFirestore} = require('firebase-admin/firestore');
const {getStorage} = require('firebase-admin/storage');
const {onCall, HttpsError} = require('firebase-functions/v2/https');
const d = require('./domain');
initializeApp();
const db = getFirestore();
async function platformAdmin(uid, tokenAdmin) {
  if (tokenAdmin === true) return true;
  const user = await db.doc(`users/${uid}`).get();
  return user.exists && user.data().role === 'admin';
}
function callable(handler) {
  return onCall({region: 'us-central1'}, async request => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Please sign in.');
    const actor = {uid: request.auth.uid, admin: request.auth.token.admin === true};
    if (!request.data || typeof request.data !== 'object' || Array.isArray(request.data)) throw new HttpsError('invalid-argument', 'Enter valid action details.');
    try { return await handler(request.data, actor); }
    catch (e) { if (e instanceof d.DomainError) throw new HttpsError(e.code, e.message); throw e; }
  });
}
async function rentalSnapshot(tx, ref) {
  const snapshot = await tx.get(ref);
  d.requireThat(snapshot.exists, 'not-found', 'Rental not found.');
  return snapshot.data();
}
async function verifyPhoto(path) {
  // CLI emulators infer an old appspot bucket when no login is configured.
  const bucket = process.env.MEMBER4_STORAGE_BUCKET || (process.env.FIREBASE_STORAGE_EMULATOR_HOST ? 'geargo-e0035.firebasestorage.app' : undefined);
  const file = getStorage().bucket(bucket).file(path);
  const [exists] = await file.exists();
  d.requireThat(exists, 'failed-precondition', 'A condition photo is missing. Upload it again.');
  const [metadata] = await file.getMetadata();
  d.requireThat(/^image\/(jpeg|png|webp)$/.test(metadata.contentType || '') && Number(metadata.size) > 0 && Number(metadata.size) < 8 * 1024 * 1024,
    'invalid-argument', 'Condition photos must be JPEG, PNG or WebP under 8 MB.');
}
exports.member4Handover = callable(async (command, actor) => {
  d.identifier(command.rentalId);
  const ref = db.doc(`rentals/${command.rentalId}`);
  await db.runTransaction(async tx => {
    const rental = await rentalSnapshot(tx, ref);
    const next = d.evolve(rental, actor, command, new Date().toISOString());
    if (command.action === 'photo') await verifyPhoto(command.path);
    if (command.action === 'submitCondition') await Promise.all(d.angles.map(a => verifyPhoto(next.conditions[command.phase].photos[a])));
    tx.set(ref, next);
  });
  return {saved: true};
});
exports.member4Message = callable(async (command, actor) => {
  const rentalId = d.identifier(command.rentalId);
  // A stable client ID makes retry after a lost response idempotent.
  const messageId = d.identifier(command.messageId);
  const ref = db.doc(`rentals/${rentalId}`);
  const message = ref.collection('messages').doc(messageId);
  await db.runTransaction(async tx => {
    const rental = await rentalSnapshot(tx, ref); d.participant(rental, actor);
    const previous = await tx.get(message);
    if (previous.exists) {
      d.requireThat(previous.data().senderId === actor.uid, 'permission-denied', 'Message ID belongs to another sender.'); return;
    }
    const kind = command.kind || 'text';
    d.requireThat(['text', 'location'].includes(kind), 'invalid-argument', 'Invalid message type.');
    tx.create(message, {senderId: actor.uid, kind, text: kind === 'text' ? d.text(command.text, 'Message') : 'Shared meetup point',
      location: kind === 'location' ? rental.meetup : null, createdAt: new Date().toISOString()});
  });
  return {saved: true};
});
exports.member4Admin = callable(async (command, actor) => {
  d.requireThat(await platformAdmin(actor.uid, actor.admin), 'permission-denied', 'Administrator access is required.');
  const adminActor = {...actor, admin: true};
  const now = new Date().toISOString();
  if (command.kind === 'deposit') {
    const rentalId = d.identifier(command.rentalId);
    const ref = db.doc(`rentals/${rentalId}`);
    const allowed = ['released', 'claimed'];
    d.requireThat(allowed.includes(command.status), 'invalid-argument', 'Invalid deposit decision.');
    await db.runTransaction(async tx => {
      const snapshot = await tx.get(ref);
      d.requireThat(snapshot.exists, 'not-found', 'Rental not found.');
      const rental = snapshot.data();
      d.requireThat(['reviewRequired', 'releasePending'].includes(rental.deposit?.status),
        'failed-precondition', 'Deposit is not awaiting administrator action.');
      rental.deposit.status = command.status;
      rental.deposit.adminNote = d.text(command.note, 'Decision note');
      rental.deposit.resolvedAt = now;
      rental.updatedAt = now;
      tx.set(ref, rental);
      tx.create(db.collection('audit').doc(), {
        recordId: ref.path, actorId: actor.uid, status: command.status,
        note: command.note.trim(), createdAt: now,
      });
    });
    return {saved: true};
  }
  const collection = command.kind === 'verification' ? 'verifications' : command.kind === 'dispute' ? 'disputes' : null;
  d.requireThat(collection, 'invalid-argument', 'Invalid review type.');
  const ref = db.doc(`${collection}/${d.identifier(command.id)}`);
  await db.runTransaction(async tx => {
    const snapshot = await tx.get(ref); d.requireThat(snapshot.exists, 'not-found', 'Review not found.');
    const next = d.adminUpdate(snapshot.data(), adminActor, command.kind, command.status, command.note, now);
    tx.set(ref, next);
    if (command.kind === 'verification') {
      const userId = snapshot.data().userId;
      if (userId) {
        tx.set(db.doc(`users/${userId}`), {
          verification_status: next.status,
          verification_reviewed_at: now,
        }, {merge: true});
        tx.set(db.doc(`owner_profile/${userId}`), {
          is_verified: next.status === 'approved',
          updated_at: now,
        }, {merge: true});
      }
    }
    tx.create(db.collection('audit').doc(), {recordId: ref.path, actorId: actor.uid, status: next.status, note: command.note.trim(), createdAt: next.updatedAt});
  });
  return {saved: true};
});
