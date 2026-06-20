/**
 * Verify that the incoming request has a valid Firebase Auth token.
 * Throws HttpsError if unauthenticated.
 */
import { HttpsError, CallableRequest } from 'firebase-functions/v2/https';

export function requireAuth(request: CallableRequest): void {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Login required');
  }
}
