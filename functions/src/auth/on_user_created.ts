import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';

export const onUserCreated = functions.auth.user().onCreate(async (user) => {
  await admin.firestore().collection('users').doc(user.uid).set({
    uid: user.uid,
    email: user.email ?? '',
    firstName: '',
    lastName: '',
    phone: null,
    avatarUrl: null,
    fcmToken: null,
    createdAt: FieldValue.serverTimestamp(),
  });
});
