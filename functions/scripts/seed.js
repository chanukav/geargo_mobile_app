'use strict';
// Refuse to seed production or replace existing group data.
if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) throw new Error('Run only inside Firebase emulators.');
const {initializeApp} = require('firebase-admin/app');
const {getAuth} = require('firebase-admin/auth');
const {getFirestore} = require('firebase-admin/firestore');
initializeApp({projectId: process.env.GCLOUD_PROJECT || 'geargo-e0035'});
const db = getFirestore(), auth = getAuth();
const password = 'GearGo-demo-2026';
async function user(uid, email, displayName, userPassword = password, admin = false) {
  try { await auth.getUser(uid); } catch (e) { if (e.code !== 'auth/user-not-found') throw e; await auth.createUser({uid, email, displayName, password: userPassword}); }
  if (admin) await auth.setCustomUserClaims(uid, {admin: true});
}
function blankCondition() { return {photos: {}, notes: '', damageReported: false, status: 'draft'}; }
async function create(path, data) { const ref = db.doc(path); if (!(await ref.get()).exists) await ref.create(data); }
async function main() {
  await user('demo-renter', 'renter@geargo.test', 'Nadeesha');
  await user('demo-owner', 'owner@geargo.test', 'Marcus V.');
  await user('demo-admin', 'admin@geargo.test', 'Platform Operations', password, true);
  await user('demo-outsider', 'outsider@geargo.test', 'Unrelated User');

  // Official Owner and Renter credentials
  await user('official-owner', 'owner@geargo.com', 'Marcus Vance (Owner)', 'GearGoOwner2026!');
  await user('official-renter', 'user@geargo.com', 'Sam Wilson (Renter)', 'GearGoRenter2026!');

  // Seed user persona roles in Firestore
  await create('users/official-owner', { uid: 'official-owner', email: 'owner@geargo.com', display_name: 'Marcus Vance (Owner)', role: 'owner', created_at: new Date().toISOString() });
  await create('users/official-renter', { uid: 'official-renter', email: 'user@geargo.com', display_name: 'Sam Wilson (Renter)', role: 'renter', created_at: new Date().toISOString() });
  await create('users/demo-owner', { uid: 'demo-owner', email: 'owner@geargo.test', display_name: 'Marcus V.', role: 'owner', created_at: new Date().toISOString() });
  await create('users/demo-renter', { uid: 'demo-renter', email: 'renter@geargo.test', display_name: 'Nadeesha', role: 'renter', created_at: new Date().toISOString() });

  // Seed Owner Profile
  await create('owner_profile/official-owner', {
    id: 'official-owner',
    user_id: 'official-owner',
    name: 'Marcus Vance (Owner)',
    phone: '+1 (555) 234-5678',
    address: 'Denver, Colorado',
    business_name: 'Alpine Gear Rentals',
    profile_image: '',
    bio: 'Professional outdoor enthusiast offering premium mountain and winter sports gear.',
    website: 'https://geargo.com',
    is_verified: true,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  });
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
