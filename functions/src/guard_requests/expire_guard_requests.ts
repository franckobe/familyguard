import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';

export const expireGuardRequests = functions
  .region('europe-west1')
  .pubsub.schedule('every day 06:00')
  .timeZone('Europe/Paris')
  .onRun(async () => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();

    const snap = await db
      .collection('guard_requests')
      .where('status', '==', 'open')
      .where('endAt', '<', now)
      .get();

    if (snap.empty) {
      functions.logger.info('No expired requests.');
      return;
    }

    const batch = db.batch();
    snap.docs.forEach((doc) => {
      batch.update(doc.ref, {
        status: 'expired',
        updatedAt: FieldValue.serverTimestamp(),
      });
    });
    await batch.commit();

    functions.logger.info(`Expired ${snap.size} guard requests.`);
  });
