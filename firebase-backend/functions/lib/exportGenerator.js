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
exports.generateExport = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const db = admin.firestore();
/**
 * Generate PDF/CSV export for a given month
 */
exports.generateExport = functions.https.onCall(async (data, context) => {
    var _a;
    // Verify authentication
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
    }
    const uid = context.auth.uid;
    const { month } = data; // Format: YYYY-MM
    if (!month || !/^\d{4}-\d{2}$/.test(month)) {
        throw new functions.https.HttpsError("invalid-argument", "Invalid month format. Expected YYYY-MM");
    }
    try {
        // Check Pro status
        const entitlements = await db.collection("entitlements").doc(uid).get();
        if (!entitlements.exists || !((_a = entitlements.data()) === null || _a === void 0 ? void 0 : _a.isPro)) {
            throw new functions.https.HttpsError("permission-denied", "Pro subscription required for exports");
        }
        // Query receipts for the specified month
        const receiptsSnapshot = await db
            .collection("users")
            .doc(uid)
            .collection("receipts")
            .where("date", ">=", `${month}-01`)
            .where("date", "<=", `${month}-31`)
            .where("status", "==", "approved")
            .orderBy("date", "asc")
            .get();
        const receipts = receiptsSnapshot.docs.map((doc) => (Object.assign({ id: doc.id }, doc.data())));
        if (receipts.length === 0) {
            throw new functions.https.HttpsError("not-found", "No approved receipts found for this month");
        }
        // Generate export ID
        const exportId = `export_${Date.now()}`;
        // Generate CSV
        const csvContent = generateCSV(receipts);
        const csvPath = `exports/${uid}/${exportId}.csv`;
        const csvFile = admin.storage().bucket().file(csvPath);
        await csvFile.save(csvContent, {
            contentType: "text/csv",
            metadata: {
                metadata: {
                    uid,
                    month,
                },
            },
        });
        // Generate PDF (placeholder - would use pdfkit in production)
        const pdfContent = "PDF generation coming soon";
        const pdfPath = `exports/${uid}/${exportId}.pdf`;
        const pdfFile = admin.storage().bucket().file(pdfPath);
        await pdfFile.save(pdfContent, {
            contentType: "application/pdf",
            metadata: {
                metadata: {
                    uid,
                    month,
                },
            },
        });
        // Calculate totals
        const totals = calculateTotals(receipts);
        // Create export document
        await db
            .collection("users")
            .doc(uid)
            .collection("exports")
            .doc(exportId)
            .set({
            month,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            pdfPath,
            csvPath,
            totals,
        });
        // Generate signed URLs (15-minute expiry)
        const [pdfUrl] = await pdfFile.getSignedUrl({
            action: "read",
            expires: Date.now() + 15 * 60 * 1000,
        });
        const [csvUrl] = await csvFile.getSignedUrl({
            action: "read",
            expires: Date.now() + 15 * 60 * 1000,
        });
        return {
            exportId,
            pdfUrl,
            csvUrl,
        };
    }
    catch (error) {
        console.error("Error generating export:", error);
        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        throw new functions.https.HttpsError("internal", "Failed to generate export");
    }
});
// Helper: Generate CSV content
function generateCSV(receipts) {
    const headers = ["Tarih", "İşletme", "Kategori", "Tutar", "Para Birimi"];
    const rows = receipts.map((r) => [
        r.date,
        r.merchant || "",
        r.categoryId || "",
        r.total || 0,
        r.currency || "TRY",
    ]);
    const csvLines = [
        headers.join(","),
        ...rows.map((row) => row.join(",")),
    ];
    return csvLines.join("\n");
}
// Helper: Calculate totals
function calculateTotals(receipts) {
    var _a;
    const sum = receipts.reduce((acc, r) => acc + (r.total || 0), 0);
    return {
        sum,
        currency: ((_a = receipts[0]) === null || _a === void 0 ? void 0 : _a.currency) || "TRY",
        count: receipts.length,
    };
}
//# sourceMappingURL=exportGenerator.js.map