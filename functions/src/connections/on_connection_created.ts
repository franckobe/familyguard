import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';
import { randomUUID } from 'crypto';

const APP_URL = process.env.APP_URL ?? 'https://familyguard.app';

export const onConnectionCreated = onDocumentCreated(
  { document: 'connections/{connectionId}', region: 'europe-west1' },
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const data = snap.data();

    if (data.inviteCode) return; // idempotent

    const inviteCode = randomUUID();
    const db = admin.firestore();

    await db.collection('connections').doc(snap.id).update({
      inviteCode,
      updatedAt: FieldValue.serverTimestamp(),
    });

    const parentDoc = await db.collection('users').doc(data.parentId).get();
    const parentFirstName = (parentDoc.data()?.firstName as string | undefined) ?? '';

    await db.collection('mail').add({
      to: data.inviteEmail,
      message: {
        subject: `${parentFirstName} vous invite sur FamilyGuard`,
        html: `
          <p>Bonjour,</p>
          <p><strong>${parentFirstName}</strong> vous invite à rejoindre son réseau FamilyGuard.</p>
          <p>
            <a href="${APP_URL}/invite/${inviteCode}" style="
              display:inline-block;padding:12px 24px;background:#7C3AED;
              color:#fff;border-radius:8px;text-decoration:none;font-weight:600;
            ">Accepter l'invitation</a>
          </p>
          <p style="color:#666;font-size:12px;">
            Si vous n'attendiez pas cette invitation, ignorez cet email.
          </p>
        `,
      },
    });

    logger.info('Invite email queued', {
      connectionId: snap.id,
      inviteEmail: data.inviteEmail,
    });
  }
);
