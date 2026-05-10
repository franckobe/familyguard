import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions/v2';

export async function sendPushToUser(
  uid: string,
  title: string,
  body: string,
): Promise<void> {
  const userDoc = await admin.firestore().collection('users').doc(uid).get();
  const fcmToken = userDoc.data()?.fcmToken as string | undefined;
  if (!fcmToken) {
    logger.info('No FCM token for user', { uid });
    return;
  }
  await admin.messaging().send({
    token: fcmToken,
    notification: { title, body },
    apns: { payload: { aps: { sound: 'default' } } },
    android: { notification: { sound: 'default' } },
  });
}
