'use strict';
const {test, before, after} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const {initializeTestEnvironment, assertFails, assertSucceeds} = require('@firebase/rules-unit-testing');
const {initializeApp, deleteApp} = require('firebase/app');
const {getAuth, connectAuthEmulator, signInWithEmailAndPassword} = require('firebase/auth');
const {getFunctions, connectFunctionsEmulator, httpsCallable} = require('firebase/functions');
const {getFirestore, connectFirestoreEmulator, doc, getDoc, setDoc, collection, getDocs} = require('firebase/firestore');
const {getStorage, connectStorageEmulator, ref, uploadBytes, getBytes, deleteObject} = require('firebase/storage');
let rules;
const clients = [];
before(async () => {
  if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) throw new Error('Use firebase emulators:exec; never run against production.');
  rules = await initializeTestEnvironment({projectId: 'geargo-e0035', firestore: {host: '127.0.0.1', port: 8085, rules: fs.readFileSync('../firestore.rules', 'utf8')}});
});
after(async () => { await Promise.all(clients.map(c => deleteApp(c.app))); await rules?.cleanup(); });
async function client(role) {
  const app = initializeApp({projectId: 'geargo-e0035', apiKey: 'emulator-only', storageBucket: 'geargo-e0035.firebasestorage.app'}, role + Date.now());
  const auth = getAuth(app); connectAuthEmulator(auth, 'http://127.0.0.1:9099', {disableWarnings: true});
  await signInWithEmailAndPassword(auth, `${role}@geargo.test`, 'GearGo-demo-2026');
  const db = getFirestore(app); connectFirestoreEmulator(db, '127.0.0.1', 8085);
  const functions = getFunctions(app); connectFunctionsEmulator(functions, '127.0.0.1', 5001);
  const storage = getStorage(app); connectStorageEmulator(storage, '127.0.0.1', 9199);
  const c = {app, auth, db, storage, call: (name, data) => httpsCallable(functions, name)(data)}; clients.push(c); return c;
}
test('M4 full workflow: real messages, private images, server transitions, admin and unrelated-account denial', async () => {
  const renter = await client('renter'), owner = await client('owner'), outsider = await client('outsider'), admin = await client('admin');
  const rentalId = 'demo-rental';
  const rental = () => getDoc(doc(renter.db, 'rentals', rentalId));
  assert.equal((await rental()).data().status, 'pending');
  await assertFails(getDoc(doc(outsider.db, 'rentals', rentalId)));
  await assertFails(setDoc(doc(renter.db, 'rentals', rentalId), {status: 'completed'}));
  await assertFails(getDocs(collection(renter.db, 'verifications')));
  await assert.rejects(renter.call('member4Admin', {kind: 'dispute', id: 'demo-dispute', status: 'resolved', note: 'Invalid access'}), {code: 'functions/permission-denied'});
  const message = {rentalId, messageId: 'retry-message', text: 'Meet at the north entrance?'};
  await renter.call('member4Message', message); await renter.call('member4Message', message);
  const messages = await getDocs(collection(owner.db, 'rentals', rentalId, 'messages'));
  assert.equal(messages.docs.filter(d => d.id === 'retry-message').length, 1);
  assert.equal(messages.docs[0].data().text, message.text);
  await assert.rejects(renter.call('member4Message', {...message, messageId: 'blank', text: ' '}), {code: 'functions/invalid-argument'});
  await assert.rejects(outsider.call('member4Message', {...message, messageId: 'intrusion'}), {code: 'functions/permission-denied'});
  await renter.call('member4Handover', {rentalId, action: 'meetup', location: {name: 'Public park entrance', address: 'North gate', latitude: 41.92, longitude: -87.63}});
  await renter.call('member4Message', {rentalId, messageId: 'shared-location', kind: 'location'});
  assert.equal((await getDoc(doc(owner.db, 'rentals', rentalId, 'messages', 'shared-location'))).data().location.name, 'Public park entrance');
  await renter.call('member4Handover', {rentalId, action: 'acknowledgeDeposit'});
  assert.ok((await rental()).data().depositAcknowledgedBy['demo-renter']);
  // A real, tiny PNG image, uploaded to emulator Storage (not a fake URI).
  const png = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jZ1kAAAAASUVORK5CYII=', 'base64');
  for (const phase of ['pickup', 'return']) {
    await assert.rejects(renter.call('member4Handover', {rentalId, phase, action: 'submitCondition'}), {code: 'functions/failed-precondition'});
    for (const key of ['identity', 'damage', 'accessories']) await renter.call('member4Handover', {rentalId, phase, action: 'checklist', key, value: true});
    for (const angle of ['front', 'back', 'left', 'right']) {
      const path = `condition/${rentalId}/${phase}/demo-renter/${angle}`;
      await uploadBytes(ref(renter.storage, path), png, {contentType: 'image/png'});
      await renter.call('member4Handover', {rentalId, phase, action: 'photo', angle, path});
      await assert.rejects(getBytes(ref(outsider.storage, path)), {code: 'storage/unauthorized'});
      await assertSucceeds(getBytes(ref(owner.storage, path)));
      await assert.rejects(deleteObject(ref(renter.storage, path)), {code: 'storage/unauthorized'});
    }
    const path = `condition/${rentalId}/${phase}/demo-renter/retake-front`;
    await uploadBytes(ref(renter.storage, path), png, {contentType: 'image/png'});
    await renter.call('member4Handover', {rentalId, phase, action: 'photo', angle: 'front', path});
    await assert.rejects(renter.call('member4Handover', {rentalId, phase, action: 'photo', angle: 'front', path: `condition/${rentalId}/${phase}/demo-renter/nonexistent`}), {code: 'functions/failed-precondition'});
    await renter.call('member4Handover', {rentalId, phase, action: 'notes', notes: 'No new damage', damageReported: false});
    await renter.call('member4Handover', {rentalId, phase, action: 'submitCondition'});
    await assert.rejects(renter.call('member4Handover', {rentalId, phase, action: 'notes', notes: 'tamper', damageReported: false}), {code: 'functions/failed-precondition'});
    await renter.call('member4Handover', {rentalId, phase, action: 'confirmHandover'});
    assert.equal((await rental()).data().status, phase === 'pickup' ? 'pending' : 'active');
    await owner.call('member4Handover', {rentalId, phase, action: 'confirmHandover'});
    assert.equal((await rental()).data().status, phase === 'pickup' ? 'active' : 'completed');
  }
  assert.equal((await rental()).data().deposit.status, 'releasePending');
  await admin.call('member4Admin', {kind: 'verification', id: 'demo-verification', status: 'approved', note: 'Synthetic identity evidence reviewed'});
  await admin.call('member4Admin', {kind: 'dispute', id: 'demo-dispute', status: 'resolved', note: 'Condition evidence reviewed; no damage'});
  assert.equal((await getDoc(doc(admin.db, 'verifications', 'demo-verification'))).data().status, 'approved');
  assert.equal((await getDoc(doc(admin.db, 'disputes', 'demo-dispute'))).data().notes.length, 1);
  assert.equal((await getDocs(collection(admin.db, 'audit'))).size, 2);
});
