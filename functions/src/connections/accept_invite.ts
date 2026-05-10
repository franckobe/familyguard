import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';

export const getInviteDetails = functions.https.onCall(async (data) => {
  const { inviteCode } = data as { inviteCode: string };
  const db = admin.firestore();

  const snap = await db
    .collection('connections')
    .where('inviteCode', '==', inviteCode)
    .limit(1)
    .get();

  if (snap.empty) {
    throw new functions.https.HttpsError('not-found', 'Invitation introuvable.');
  }

  const conn = snap.docs[0].data();

  if (conn.status !== 'pending') {
    throw new functions.https.HttpsError('failed-precondition', 'already-used');
  }

  const parentDoc = await db.collection('users').doc(conn.parentId).get();
  const parentFirstName = (parentDoc.data()?.firstName as string | undefined) ?? '';

  return {
    parentFirstName,
    inviteEmail: conn.inviteEmail as string,
    status: conn.status as string,
  };
});

export const acceptInvite = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentification requise.');
  }

  const { inviteCode } = data as { inviteCode: string };
  const db = admin.firestore();

  const snap = await db
    .collection('connections')
    .where('inviteCode', '==', inviteCode)
    .limit(1)
    .get();

  if (snap.empty) {
    throw new functions.https.HttpsError('not-found', 'Invitation introuvable.');
  }

  const doc = snap.docs[0];
  const conn = doc.data();

  if (conn.status !== 'pending') {
    throw new functions.https.HttpsError('failed-precondition', 'already-used');
  }

  if (conn.caregiverId != null) {
    throw new functions.https.HttpsError('failed-precondition', 'already-claimed');
  }

  await db.collection('connections').doc(doc.id).update({
    caregiverId: context.auth.uid,
    status: 'active',
    updatedAt: FieldValue.serverTimestamp(),
  });

  return { connectionId: doc.id };
});
