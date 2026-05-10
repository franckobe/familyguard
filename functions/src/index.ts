import * as admin from 'firebase-admin';

admin.initializeApp();

export { onUserCreated } from './auth/on_user_created';
export { onConnectionCreated } from './connections/on_connection_created';
