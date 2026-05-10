import * as admin from 'firebase-admin';

admin.initializeApp();

export { onUserCreated } from './auth/on_user_created';
export { onConnectionCreated } from './connections/on_connection_created';
export { onConnectionUpdated } from './connections/on_connection_updated';
export { getInviteDetails, acceptInvite } from './connections/accept_invite';
export { onGuardRequestCreated } from './guard_requests/on_guard_request_created';
export { onGuardResponseCreated } from './guard_requests/on_guard_response_created';
export { onGuardRequestUpdated } from './guard_requests/on_guard_request_updated';
export { confirmCaregiver, cancelRequest } from './guard_requests/guard_request_callables';
export { expireGuardRequests } from './guard_requests/expire_guard_requests';
