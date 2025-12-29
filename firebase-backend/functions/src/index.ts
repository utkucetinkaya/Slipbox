import * as admin from "firebase-admin";

// Initialize Firebase Admin
admin.initializeApp();

// Import all function modules
import { initializeUser, deleteUserData } from "./userManagement";
import { processReceipt } from "./receiptProcessor";
import { generateExport } from "./exportGenerator";
import { createShareLink, viewSharedExport } from "./shareLinks";
import { validatePurchase, appleServerNotification } from "./subscriptions";
import { createReceiptUploadSession } from "./uploadSession";

// Export all callable functions
export {
    initializeUser,
    deleteUserData,
    generateExport,
    createShareLink,
    validatePurchase,
    createReceiptUploadSession,
};

// Export HTTP functions
export {
    viewSharedExport,
    appleServerNotification,
};

// Export storage triggers
export { processReceipt };
