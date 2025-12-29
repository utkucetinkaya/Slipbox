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
exports.processReceipt = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const db = admin.firestore();
/**
 * Process newly uploaded receipt images
 * Triggered when image is uploaded to Storage
 */
exports.processReceipt = functions.storage
    .object()
    .onFinalize(async (object) => {
    const filePath = object.name;
    if (!filePath || !filePath.startsWith("receipts/")) {
        return null; // Not a receipt image
    }
    // Extract uid and receiptId from path: receipts/{uid}/{receiptId}.jpg
    const pathParts = filePath.split("/");
    if (pathParts.length !== 3) {
        console.error("Invalid receipt path:", filePath);
        return null;
    }
    const uid = pathParts[1];
    const receiptId = pathParts[2].replace(/\.[^/.]+$/, ""); // Remove extension
    try {
        // 1. Verify Free tier limit
        const entitlements = await db.collection("entitlements").doc(uid).get();
        if (!entitlements.exists) {
            console.error("Entitlements not found for user:", uid);
            return null;
        }
        const entData = entitlements.data();
        const currentMonth = new Date().toISOString().substring(0, 7);
        // Reset counter if new month
        if (entData.monthKey !== currentMonth) {
            await entitlements.ref.update({
                receiptCount: 0,
                monthKey: currentMonth,
            });
            entData.receiptCount = 0;
        }
        // Check if user has exceeded free tier limit
        const FREE_LIMIT = 20;
        if (!entData.isPro && entData.receiptCount >= FREE_LIMIT) {
            // Mark receipt as error - exceeded limit
            await db
                .collection("users")
                .doc(uid)
                .collection("receipts")
                .doc(receiptId)
                .update({
                status: "error",
                error: "Free tier limit exceeded",
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            return null;
        }
        // 2. Get receipt document
        const receiptRef = db
            .collection("users")
            .doc(uid)
            .collection("receipts")
            .doc(receiptId);
        const receiptDoc = await receiptRef.get();
        if (!receiptDoc.exists) {
            console.error("Receipt document not found:", receiptId);
            return null;
        }
        const receiptData = receiptDoc.data();
        const rawText = receiptData.rawText || "";
        // 3. Parse and normalize receipt data
        // In a real implementation, this would use OCR and NLP
        // For now, we'll use the rawText if provided
        const normalized = normalizeReceipt(rawText);
        // 4. Check for existing rules
        const rulesSnapshot = await db
            .collection("users")
            .doc(uid)
            .collection("rules")
            .where("enabled", "==", true)
            .get();
        let categoryId = null;
        let confidence = 0;
        for (const ruleDoc of rulesSnapshot.docs) {
            const rule = ruleDoc.data();
            if (matchesRule(normalized.merchant, rule)) {
                categoryId = rule.categoryId;
                confidence = 1.0;
                break;
            }
        }
        // 5. If no rule match, use AI suggestion (placeholder)
        if (!categoryId) {
            // TODO: Integrate with OpenAI/Gemini for category suggestion
            // For now, default to "other"
            categoryId = "other";
            confidence = 0.5;
        }
        // 6. Update receipt document
        await receiptRef.update({
            merchant: normalized.merchant,
            date: normalized.date,
            total: normalized.total,
            currency: normalized.currency,
            categoryId: confidence >= 0.8 ? categoryId : null,
            categorySuggestedId: categoryId,
            confidence,
            status: confidence >= 0.8 ? "approved" : "needs_review",
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        // 7. Increment receipt count
        await entitlements.ref.update({
            receiptCount: admin.firestore.FieldValue.increment(1),
        });
        console.log(`Receipt processed successfully: ${receiptId}`);
        return null;
    }
    catch (error) {
        console.error("Error processing receipt:", error);
        // Mark receipt as error
        try {
            await db
                .collection("users")
                .doc(uid)
                .collection("receipts")
                .doc(receiptId)
                .update({
                status: "error",
                error: error instanceof Error ? error.message : "Unknown error",
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        }
        catch (updateError) {
            console.error("Error updating receipt status:", updateError);
        }
        return null;
    }
});
// Helper: Normalize receipt data from raw text
function normalizeReceipt(rawText) {
    // This is a placeholder - in production, use proper OCR + NLP
    return {
        merchant: "Bilinmiyor",
        date: new Date().toISOString().split("T")[0],
        total: 0,
        currency: "TRY",
    };
}
// Helper: Check if merchant matches rule
function matchesRule(merchant, rule) {
    const merchantLower = merchant.toLowerCase();
    const matchLower = rule.match.toLowerCase();
    if (rule.type === "merchant_equals") {
        return merchantLower === matchLower;
    }
    else if (rule.type === "merchant_contains") {
        return merchantLower.includes(matchLower);
    }
    return false;
}
//# sourceMappingURL=receiptProcessor.js.map