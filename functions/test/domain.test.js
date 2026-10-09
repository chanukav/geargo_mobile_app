'use strict';
const {test} = require('node:test');
const assert = require('node:assert/strict');
const {evolve, adminUpdate, text, identifier, participant} = require('../domain');
function rental() {
  return {participantIds: ['owner', 'renter'], status: 'pending',
    checklists: {pickup: {identity: false, damage: false, accessories: false}, return: {identity: false, damage: false, accessories: false}},
    conditions: {pickup: {status: 'draft', photos: {}, notes: '', damageReported: false}, return: {status: 'draft', photos: {}, notes: '', damageReported: false}},
    confirmations: {pickup: {}, return: {}}, deposit: {amount: 150, status: 'pending'}};
}
const actor = {uid: 'renter'}, now = '2026-10-07T10:00:00.000Z';
function action(r, action, fields = {}) { return evolve(r, actor, {rentalId: 'rent', phase: 'pickup', action, ...fields}, now); }
function ready(r, phase = 'pickup') {
  r.checklists[phase] = {identity: true, damage: true, accessories: true};
  r.conditions[phase].photos = {front: 'f', back: 'b', left: 'l', right: 'r'};
  r.conditions[phase].status = 'confirmed'; return r;
}
test('M4-TC-02 persists checklist without mutating the previous snapshot', () => {
  const original = rental(), next = action(original, 'checklist', {key: 'identity', value: true});
  assert.equal(next.checklists.pickup.identity, true); assert.equal(original.checklists.pickup.identity, false);
});
test('M4-TC-17 rejects an unrelated rental participant, including admin', () => {
  assert.throws(() => evolve(rental(), {uid: 'outsider', admin: true}, {action: 'acknowledgeDeposit'}, now), /another account/);
  assert.throws(() => participant(rental(), null), /another account/);
});
test('M4-TC-08/09/10 creates four-angle references and permits retake in draft only', () => {
  let r = rental();
  for (const angle of ['front', 'back', 'left', 'right']) r = action(r, 'photo', {angle, path: `condition/rent/pickup/renter/${angle}`});
  r = action(r, 'photo', {angle: 'front', path: 'condition/rent/pickup/renter/retake'});
  assert.equal(Object.keys(r.conditions.pickup.photos).length, 4);
  assert.equal(r.conditions.pickup.photos.front, 'condition/rent/pickup/renter/retake');
  r = action(r, 'submitCondition');
  assert.throws(() => action(r, 'photo', {angle: 'front', path: 'condition/rent/pickup/renter/x'}), /cannot be edited/);
});
test('M4-TC-19 prevents missing photo and wrong-phase confirmation', () => {
  assert.throws(() => action(rental(), 'submitCondition'), /four condition photos/);
  assert.throws(() => action(rental(), 'submitCondition', {phase: 'return'}), /not open/);
  assert.throws(() => action(rental(), 'confirmHandover'), /checklist/);
});
test('M4-TC-11 validates damage notes and locks confirmed evidence', () => {
  let r = rental(); assert.throws(() => action(r, 'notes', {notes: '', damageReported: true}), /Describe/);
  r = action(r, 'notes', {notes: 'Existing scratch', damageReported: true});
  assert.equal(r.conditions.pickup.notes, 'Existing scratch');
  r = ready(r); assert.throws(() => action(r, 'notes', {notes: 'erase', damageReported: false}), /cannot be edited/);
});
test('M4-TC-12 deposit acknowledgement is per participant and never charges funds', () => {
  const r = action(rental(), 'acknowledgeDeposit'); assert.equal(r.depositAcknowledgedBy.renter, now); assert.equal(r.deposit.status, 'pending');
});
test('M4-TC-13 requires both parties before activating the rental', () => {
  let r = action(ready(rental()), 'confirmHandover'); assert.equal(r.status, 'pending');
  r = evolve(r, {uid: 'owner'}, {action: 'confirmHandover', phase: 'pickup'}, now);
  assert.equal(r.status, 'active'); assert.equal(r.deposit.status, 'recorded');
  assert.throws(() => action(r, 'checklist', {key: 'identity', value: false}), /not open/);
});
test('M4-TC-14 return verification requires both parties and holds damage for review', () => {
  for (const damage of [false, true]) {
    let r = ready(rental(), 'return'); r.status = 'active'; r.conditions.return.damageReported = damage;
    r = action(r, 'confirmHandover', {phase: 'return'}); assert.equal(r.status, 'active');
    r = evolve(r, {uid: 'owner'}, {action: 'confirmHandover', phase: 'return'}, now);
    assert.equal(r.status, 'completed'); assert.equal(r.deposit.status, damage ? 'reviewRequired' : 'releasePending');
  }
});
test('M4-TC-06 validates meetup coordinates and persists agreed location', () => {
  const m = {name: 'Public park', address: 'North entrance', latitude: 6.9, longitude: 79.8};
  const r = action(rental(), 'meetup', {location: m}); assert.deepEqual(r.meetup, m);
  assert.throws(() => action(r, 'meetup', {location: {...m, latitude: 91}}), /coordinates/);
  assert.throws(() => action(r, 'meetup', {location: {...m, name: ''}}), /name/);
});
test('M4-TC-16/17 protects admin decisions, validates statuses and keeps notes', () => {
  assert.throws(() => adminUpdate({status: 'open'}, actor, 'dispute', 'resolved', 'Reviewed', now), /Administrator/);
  assert.throws(() => adminUpdate({status: 'open'}, {admin: true}, 'dispute', 'approved', 'Reviewed', now), /Invalid/);
  assert.throws(() => adminUpdate({status: 'open'}, {admin: true}, 'dispute', 'resolved', ' ', now), /required/);
  const r = adminUpdate({status: 'open', notes: []}, {uid: 'admin', admin: true}, 'dispute', 'resolved', 'No damage seen', now);
  assert.equal(r.status, 'resolved'); assert.equal(r.notes[0].authorId, 'admin');
  assert.throws(() => adminUpdate(r, {admin: true}, 'dispute', 'dismissed', 'Changed', now), /closed/);
});
test('M4-TC-18 rejects blank/oversize messages and path injection', () => {
  assert.throws(() => text(' ', 'Message'), /required/); assert.throws(() => text('x'.repeat(2001), 'Message'), /maximum/);
  assert.throws(() => identifier('../other'), /Invalid/);
  assert.throws(() => action(rental(), 'photo', {angle: 'front', path: 'condition/rent/pickup/owner/file'}), /ownership/);
});
