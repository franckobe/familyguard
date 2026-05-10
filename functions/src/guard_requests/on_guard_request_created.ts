import * as admin from 'firebase-admin';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';
import { sendPushToUser } from '../notifications/send_push_notification';

export const onGuardRequestCreated = onDocumentCreated(
  { document: 'guard_requests/{requestId}', region: 'europe-west1' },
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const data = snap.data();
    const recipientIds: string[] = data.recipientIds ?? [];
    const db = admin.firestore();

    const parentDoc = await db.collection('users').doc(data.parentId).get();
    const parentName = (parentDoc.data()?.firstName as string) || 'Un parent';
    const childName = (data.childSnapshots?.[0]?.firstName as string) || 'votre enfant';
    const typeLabel = data.type as string;

    for (const uid of recipientIds) {
      await db
        .collection('guard_requests')
        .doc(snap.id)
        .collection('recipients')
        .doc(uid)
        .set({
          caregiverId: uid,
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
          readAt: null,
        });

      await sendPushToUser(
        uid,
        'Nouvelle demande de garde',
        `${parentName} cherche quelqu'un pour garder ${childName} (${typeLabel})`,
      );
    }

    logger.info('Guard request notifications sent', {
      requestId: snap.id,
      recipientCount: recipientIds.length,
    });
  },
);
