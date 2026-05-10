import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';

export const onConnectionUpdated = onDocumentUpdated(
  { document: 'connections/{connectionId}', region: 'europe-west1' },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    if (before.status === 'pending' && after.status === 'active') {
      // TODO Sprint 5 : envoyer push notification au parent
      logger.info('Connection activated', {
        connectionId: event.params.connectionId,
        parentId: after.parentId,
        caregiverId: after.caregiverId,
      });
    }
  }
);
