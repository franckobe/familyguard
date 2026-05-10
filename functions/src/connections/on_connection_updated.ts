import * as functions from 'firebase-functions';

export const onConnectionUpdated = functions.firestore
  .document('connections/{connectionId}')
  .onUpdate(async (change) => {
    const before = change.before.data();
    const after = change.after.data();

    if (before.status === 'pending' && after.status === 'active') {
      // TODO Sprint 5 : envoyer push notification au parent
      functions.logger.info('Connection activated', {
        connectionId: change.after.id,
        parentId: after.parentId,
        caregiverId: after.caregiverId,
      });
    }
  });
