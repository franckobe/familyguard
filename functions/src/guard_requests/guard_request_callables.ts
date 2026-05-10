import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';

export const confirmCaregiver = functions
  .region('europe-west1')
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Authentification requise.');
    }

    const { requestId, caregiverId } = data as { requestId: string; caregiverId: string };
    const db = admin.firestore();
    const ref = db.collection('guard_requests').doc(requestId);

    await db.runTransaction(async (tx) => {
      const doc = await tx.get(ref);
      if (!doc.exists) {
        throw new functions.https.HttpsError('not-found', 'Demande introuvable.');
      }
      const d = doc.data()!;
      if (d.parentId !== context.auth!.uid) {
        throw new functions.https.HttpsError('permission-denied', 'Non autorisé.');
      }
      if (d.status !== 'open') {
        throw new functions.https.HttpsError('failed-precondition', 'Demande déjà traitée.');
      }
      tx.update(ref, {
        status: 'accepted',
        confirmedId: caregiverId,
        updatedAt: FieldValue.serverTimestamp(),
      });
    });

    return { ok: true };
  });

export const cancelRequest = functions
  .region('europe-west1')
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Authentification requise.');
    }

    const { requestId } = data as { requestId: string };
    const db = admin.firestore();
    const ref = db.collection('guard_requests').doc(requestId);
    const doc = await ref.get();

    if (!doc.exists) {
      throw new functions.https.HttpsError('not-found', 'Demande introuvable.');
    }
    if (doc.data()!.parentId !== context.auth.uid) {
      throw new functions.https.HttpsError('permission-denied', 'Non autorisé.');
    }

    await ref.update({
      status: 'cancelled',
      updatedAt: FieldValue.serverTimestamp(),
    });

    return { ok: true };
  });
