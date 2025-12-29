import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

/**
 * Create a receipt upload session
 * Checks Free tier limits BEFORE allowing upload
 * Enforces App Check
 */
export const createReceiptUploadSession = functions.https.onCall(
    async (data: any, context: functions.https.CallableContext) => {
        // Enforce App Check
        if (!context.app) {
            throw new functions.https.HttpsError(
                "failed-precondition",
                "App Check verification failed"
            );
        }

        // Verify authentication
        if (!context.auth) {
            throw new functions.https.HttpsError(
                "unauthenticated",
                "User must be authenticated"
            );
        }

        const uid = context.auth.uid;

        try {
            // Check Free tier limit
            const entitlements = await admin
                .firestore()
                .collection("entitlements")
                .doc(uid)
                .get();

            if (!entitlements.exists) {
                throw new functions.https.HttpsError(
                    "not-found",
                    "User entitlements not found"
                );
            }

            const entData = entitlements.data()!;
            const currentMonth = new Date().toISOString().substring(0, 7);

            // Reset counter if new month
            if (entData.monthKey !== currentMonth) {
                await entitlements.ref.update({
                    receiptCount: 0,
                    monthKey: currentMonth,
                });
                entData.receiptCount = 0;
            }

            const FREE_LIMIT = 20;
            if (!entData.isPro && entData.receiptCount >= FREE_LIMIT) {
                throw new functions.https.HttpsError(
                    "resource-exhausted",
                    "Free tier limit exceeded. Upgrade to Pro for unlimited receipts."
                );
            }

            // Grant permission
            return {
                allowed: true,
                receiptCount: entData.receiptCount,
                limit: FREE_LIMIT,
                isPro: entData.isPro,
            };
        } catch (error) {
            console.error("Error creating upload session:", error);
            if (error instanceof functions.https.HttpsError) {
                throw error;
            }
            throw new functions.https.HttpsError(
                "internal",
                "Failed to create upload session"
            );
        }
    }
);
