import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';
import { sendPushToUser } from '../notifications/send_push_notification';

export const onGuardRequestUpdated = onDocumentUpdated(
  { document: 'guard_requests/{requestId}', region: 'europe-west1' },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    if (
      before.confirmedId == null &&
      after.confirmedId != null &&
      after.status === 'accepted'
    ) {
      await sendPushToUser(
        after.confirmedId as string,
        'Garde confirmée !',
        'Vous avez été sélectionné pour cette garde.',
      );
      logger.info('Confirmation notification sent', {
        requestId: event.params.requestId,
        confirmedId: after.confirmedId,
      });
    }

    if (before.status !== 'cancelled' && after.status === 'cancelled') {
      const recipientIds: string[] = after.recipientIds ?? [];
      for (const uid of recipientIds) {
        await sendPushToUser(uid, 'Demande annulée', 'Une demande de garde a été annulée.');
      }
    }
  },
);
