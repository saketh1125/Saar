/**
 * Firestore client helper — provides typed access to common collections.
 */
import * as admin from 'firebase-admin';

if (admin.apps.length === 0) {
  admin.initializeApp();
}

export const db = admin.firestore();

/**
 * Get a document by ID from a collection.
 */
export async function getDoc(collection: string, id: string): Promise<any | null> {
  const doc = await db.collection(collection).doc(id).get();
  return doc.exists ? doc.data() : null;
}

/**
 * Set a document (merge mode).
 */
export async function setDoc(collection: string, id: string, data: any): Promise<void> {
  await db.collection(collection).doc(id).set(data, { merge: true });
}

/**
 * Query documents with simple filters.
 */
export async function queryDocs(
  collection: string,
  field: string,
  operator: FirebaseFirestore.WhereFilterOp,
  value: any,
  limit: number = 10
): Promise<any[]> {
  const snapshot = await db
    .collection(collection)
    .where(field, operator, value)
    .limit(limit)
    .get();

  return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

/**
 * Increment a counter field atomically.
 */
export async function incrementCounter(collection: string, id: string, field: string): Promise<void> {
  await db
    .collection(collection)
    .doc(id)
    .update({
      [field]: admin.firestore.FieldValue.increment(1),
    });
}
