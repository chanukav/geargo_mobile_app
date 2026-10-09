'use strict';
const angles = ['front', 'back', 'left', 'right'];
const checklist = ['identity', 'damage', 'accessories'];
class DomainError extends Error {
  constructor(code, message) { super(message); this.code = code; }
}
function requireThat(value, code, message) { if (!value) throw new DomainError(code, message); }
function text(value, name, max = 2000) {
  requireThat(typeof value === 'string' && value.trim().length > 0 && value.trim().length <= max,
    'invalid-argument', `${name} is required (maximum ${max} characters).`);
  return value.trim();
}
function identifier(value) {
  requireThat(typeof value === 'string' && /^[A-Za-z0-9_-]{1,128}$/.test(value), 'invalid-argument', 'Invalid record ID.');
  return value;
}
function participant(rental, actor) {
  requireThat(actor && rental.participantIds.includes(actor.uid), 'permission-denied', 'This rental belongs to another account.');
}
function phaseOpen(rental, phase) {
  requireThat(angles && ['pickup', 'return'].includes(phase), 'invalid-argument', 'Choose pickup or return.');
  requireThat(rental.status === (phase === 'pickup' ? 'pending' : 'active'), 'failed-precondition', 'This condition phase is not open.');
}
function evolve(rental, actor, command, now) {
  participant(rental, actor);
  const next = structuredClone(rental);
  const phase = command.phase;
  if (command.action === 'acknowledgeDeposit') {
    next.depositAcknowledgedBy = {...(next.depositAcknowledgedBy || {}), [actor.uid]: now};
  } else if (command.action === 'checklist') {
    phaseOpen(next, phase);
    requireThat(Object.keys(next.confirmations[phase]).length === 0, 'failed-precondition', 'Checklist is locked after a participant confirms.');
    requireThat(checklist.includes(command.key) && typeof command.value === 'boolean', 'invalid-argument', 'Invalid checklist item.');
    next.checklists[phase][command.key] = command.value;
  } else if (command.action === 'meetup') {
    requireThat(next.status !== 'completed', 'failed-precondition', 'Completed rentals cannot change meetup details.');
    const m = command.location;
    requireThat(m && Number.isFinite(m.latitude) && Math.abs(m.latitude) <= 90 && Number.isFinite(m.longitude) && Math.abs(m.longitude) <= 180,
      'invalid-argument', 'Enter valid coordinates.');
    next.meetup = {name: text(m.name, 'Meetup name', 120), address: text(m.address, 'Address', 300), latitude: m.latitude, longitude: m.longitude};
  } else if (['photo', 'notes', 'submitCondition'].includes(command.action)) {
    phaseOpen(next, phase);
    const check = next.conditions[phase];
    requireThat(check.status !== 'confirmed', 'failed-precondition', 'Confirmed evidence cannot be edited.');
    if (command.action === 'photo') {
      requireThat(angles.includes(command.angle), 'invalid-argument', 'Invalid photo angle.');
      requireThat(typeof command.path === 'string' && command.path.startsWith(`condition/${command.rentalId}/${phase}/${actor.uid}/`) && !command.path.includes('..'),
        'permission-denied', 'Invalid photo ownership.');
      check.photos[command.angle] = command.path;
    } else if (command.action === 'notes') {
      requireThat(typeof command.notes === 'string' && command.notes.length <= 2000 && typeof command.damageReported === 'boolean', 'invalid-argument', 'Invalid condition notes.');
      requireThat(!command.damageReported || command.notes.trim().length > 0, 'invalid-argument', 'Describe the visible damage.');
      check.notes = command.notes.trim(); check.damageReported = command.damageReported;
    } else {
      requireThat(angles.every(a => check.photos[a]), 'failed-precondition', 'All four condition photos are required.');
      requireThat(!check.damageReported || check.notes.length > 0, 'failed-precondition', 'Describe the visible damage.');
      check.status = 'confirmed'; check.confirmedAt = now; check.confirmedBy = actor.uid;
    }
  } else if (command.action === 'confirmHandover') {
    phaseOpen(next, phase);
    requireThat(checklist.every(k => next.checklists[phase][k]) && next.conditions[phase].status === 'confirmed',
      'failed-precondition', 'Complete the checklist and confirm all four photos first.');
    // Both parties independently confirm. One participant cannot release another's deposit.
    next.confirmations[phase][actor.uid] = now;
    if (next.participantIds.every(uid => next.confirmations[phase][uid])) {
      next.status = phase === 'pickup' ? 'active' : 'completed';
      next.deposit.status = phase === 'pickup' ? 'recorded' : next.conditions.return.damageReported ? 'reviewRequired' : 'releasePending';
    }
  } else throw new DomainError('invalid-argument', 'Unknown handover action.');
  next.updatedAt = now;
  return next;
}
function adminUpdate(record, actor, kind, status, note, now) {
  requireThat(actor?.admin === true, 'permission-denied', 'Administrator access is required.');
  const states = kind === 'verification' ? ['approved', 'rejected'] : kind === 'dispute' ? ['investigating', 'resolved', 'dismissed'] : [];
  requireThat(states.includes(status), 'invalid-argument', 'Invalid operational status.');
  requireThat(!['approved', 'rejected', 'resolved', 'dismissed'].includes(record.status), 'failed-precondition', 'This review is already closed.');
  return {...record, status, notes: [...(record.notes || []), {text: text(note, 'Review note'), authorId: actor.uid, createdAt: now}], updatedAt: now};
}
module.exports = {angles, checklist, DomainError, requireThat, text, identifier, participant, evolve, adminUpdate};
