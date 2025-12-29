"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.appleServerNotification = exports.validatePurchase = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const crypto = __importStar(require("crypto"));
const db = admin.firestore();
/**
 * Validate StoreKit purchase and update entitlements
 */
exports.validatePurchase = functions.https.onCall(async (data, context) => {
    // Verify authentication
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
    }
    const uid = context.auth.uid;
    const { transactionJWS } = data;
    if (!transactionJWS) {
        throw new functions.https.HttpsError("invalid-argument", "Transaction JWS is required");
    }
    try {
        // TODO: Validate JWS with Apple's App Store Server API
        // This is a placeholder - in production, verify signature and decode
        // For now, we'll mock the validation
        const mockTransactionInfo = {
            productId: "fiskutusu_pro_monthly",
            expirationDate: Date.now() + 30 * 24 * 60 * 60 * 1000, // 30 days
            originalTransactionId: crypto.randomBytes(16).toString("hex"),
        };
        // Update entitlements
        await db
            .collection("entitlements")
            .doc(uid)
            .update({
            isPro: true,
            expiresAt: new Date(mockTransactionInfo.expirationDate),
            productId: mockTransactionInfo.productId,
            originalTransactionId: mockTransactionInfo.originalTransactionId,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        // Create transaction mapping for server notifications
        await db
            .collection("transactionMapping")
            .doc(mockTransactionInfo.originalTransactionId)
            .set({
            uid,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return {
            success: true,
            isPro: true,
        };
    }
    catch (error) {
        console.error("Error validating purchase:", error);
        throw new functions.https.HttpsError("internal", "Failed to validate purchase");
    }
});
/**
 * Handle Apple Server Notifications
 * Webhook for subscription lifecycle events
 */
exports.appleServerNotification = functions.https.onRequest(async (req, res) => {
    // Verify Apple signature (JWS validation)
    // TODO: Implement proper signature verification
    var _a;
    try {
        const notification = req.body;
        // Extract notification type and transaction ID
        const notificationType = notification.notificationType;
        const originalTransactionId = (_a = notification.data) === null || _a === void 0 ? void 0 : _a.originalTransactionId;
        if (!originalTransactionId) {
            res.status(400).send("Missing transaction ID");
            return;
        }
        // Lookup user by transaction ID
        const mappingDoc = await db
            .collection("transactionMapping")
            .doc(originalTransactionId)
            .get();
        if (!mappingDoc.exists) {
            console.log(`Unknown transaction ID: ${originalTransactionId}`);
            res.status(200).send("OK"); // Still return 200 to acknowledge
            return;
        }
        const uid = mappingDoc.data().uid;
        // Handle different notification types
        switch (notificationType) {
            case "SUBSCRIBED":
            case "DID_RENEW":
                await db.collection("entitlements").doc(uid).update({
                    isPro: true,
                    expiresAt: new Date(notification.data.expirationDate),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
                break;
            case "DID_FAIL_TO_RENEW":
            case "EXPIRED":
            case "DID_CHANGE_RENEWAL_STATUS":
                // Check if subscription is still active
                const expirationDate = new Date(notification.data.expirationDate);
                const isStillActive = expirationDate > new Date();
                await db.collection("entitlements").doc(uid).update({
                    isPro: isStillActive,
                    expiresAt: expirationDate,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
                break;
            case "REFUND":
                await db.collection("entitlements").doc(uid).update({
                    isPro: false,
                    expiresAt: null,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
                break;
            default:
                console.log(`Unknown notification type: ${notificationType}`);
        }
        res.status(200).send("OK");
    }
    catch (error) {
        console.error("Error processing Apple notification:", error);
        res.status(500).send("Error");
    }
});
//# sourceMappingURL=subscriptions.js.map