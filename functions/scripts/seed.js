'use strict';
// Refuse to seed production or replace existing group data.
if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) throw new Error('Run only inside Firebase emulators.');
const {initializeApp} = require('firebase-admin/app');
const {getAuth} = require('firebase-admin/auth');
const {getFirestore} = require('firebase-admin/firestore');
initializeApp({projectId: process.env.GCLOUD_PROJECT || 'geargo-e0035'});
const db = getFirestore(), auth = getAuth();
const password = 'GearGo-demo-2026';
async function user(uid, email, displayName, admin = false) {
  try { await auth.getUser(uid); } catch (e) { if (e.code !== 'auth/user-not-found') throw e; await auth.createUser({uid, email, displayName, password}); }
  if (admin) await auth.setCustomUserClaims(uid, {admin: true});
}
function blankCondition() { return {photos: {}, notes: '', damageReported: false, status: 'draft'}; }
async function create(path, data) { const ref = db.doc(path); if (!(await ref.get()).exists) await ref.create(data); }
async function main() {
  await user('demo-renter', 'renter@geargo.test', 'Nadeesha');
  await user('demo-owner', 'owner@geargo.test', 'Marcus V.');
  await user('demo-admin', 'admin@geargo.test', 'Platform Operations', true);
  await user('demo-outsider', 'outsider@geargo.test', 'Unrelated User');
  await create('rentals/demo-rental', {
    ownerId: 'demo-owner', renterId: 'demo-renter', participantIds: ['demo-owner', 'demo-renter'],
    equipmentId: 'demo-bike', equipmentName: 'Specialized Rockhopper Comp', ownerName: 'Marcus V.', renterName: 'Nadeesha', equipmentImageUrl: '',
    startDate: '2026-10-15', endDate: '2026-10-19', dailyRate: 32, currency: 'USD', rentalCharge: 128, serviceFee: 12.8,
    amountPaid: 140.8, paymentStatus: 'Emulator fixture — no payment collected', status: 'pending',
    meetup: {name: 'Lincoln Park — North Entrance', address: 'Public north entrance, Lincoln Park, Chicago', latitude: 41.9214, longitude: -87.6336},
    checklists: {pickup: {identity: false, damage: false, accessories: false}, return: {identity: false, damage: false, accessories: false}},
    conditions: {pickup: blankCondition(), return: blankCondition()}, confirmations: {pickup: {}, return: {}},
    deposit: {amount: 150, status: 'pending'}, depositAcknowledgedBy: {}, updatedAt: new Date().toISOString(),
  });
  await create('verifications/demo-verification', {userId: 'demo-owner', summary: 'Demo owner identity review (synthetic evidence)', status: 'pending', notes: []});
  await create('disputes/demo-dispute', {rentalId: 'demo-rental', summary: 'Demo accessory disagreement (synthetic)', status: 'open', notes: []});
  console.log('Emulator fixtures ready. renter/owner/admin/outsider@geargo.test; password: ' + password);
}
main().catch(e => { console.error(e); process.exitCode = 1; });
