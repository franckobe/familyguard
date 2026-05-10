import * as admin from 'firebase-admin';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';
import { sendPushToUser } from '../notifications/send_push_notification';

export const onGuardResponseCreated = onDocumentCreated(
  {
    document: 'guard_requests/{requestId}/responses/{caregiverId}',
    region: 'europe-west1',
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const data = snap.data();
    const requestId = event.params.requestId;

    const requestDoc = await admin
      .firestore()
      .collection('guard_requests')
      .doc(requestId)
      .get();
    const parentId = requestDoc.data()?.parentId as string;
    if (!parentId) return;

    const caregiverName =
      (data.caregiverSnapshot?.firstName as string) || 'Un babysitter';
    const statusLabel =
      data.status === 'accepted' ? 'a accepté' : 'a refusé';

    await sendPushToUser(
      parentId,
      'Réponse reçue',
      `${caregiverName} ${statusLabel} votre demande de garde`,
    );

    logger.info('Response notification sent', { requestId, caregiverId: data.caregiverId });
  },
);
