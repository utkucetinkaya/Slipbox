import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const db = admin.firestore();

/**
 * Initialize a new user account
 * Called after successful authentication
 */
export const initializeUser = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
    // Verify authentication
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "User must be authenticated"
        );
    }

    const uid = context.auth.uid;

    try {
        // Check if user already initialized
        const userDoc = await db.collection("users").doc(uid).get();
        if (userDoc.exists) {
            return { success: true, message: "User already initialized" };
        }

        // Create user document
        await db.collection("users").doc(uid).set({
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            locale: "tr-TR",
            currencyDefault: "TRY",
        });

        // Create entitlements document
        const currentMonth = new Date().toISOString().substring(0, 7); // YYYY-MM
        await db.collection("entitlements").doc(uid).set({
            isPro: false,
            receiptCount: 0,
            monthKey: currentMonth,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Seed default categories
        const defaultCategories = [
            { id: "food_drink", name: "Yeme-İçme", icon: "fork.knife", order: 1 },
            { id: "transport", name: "Ulaşım", icon: "car.fill", order: 2 },
            { id: "equipment", name: "Ekipman", icon: "desktopcomputer", order: 3 },
            { id: "service", name: "Hizmet", icon: "wrench.fill", order: 4 },
            { id: "other", name: "Diğer", icon: "folder.fill", order: 5 },
        ];

        const batch = db.batch();
        for (const category of defaultCategories) {
            const categoryRef = db
                .collection("users")
                .doc(uid)
                .collection("categories")
                .doc(category.id);
            batch.set(categoryRef, {
                name: category.name,
                icon: category.icon,
                order: category.order,
                isDefault: true,
            });
        }
        await batch.commit();

        return { success: true, message: "User initialized successfully" };
    } catch (error) {
        console.error("Error initializing user:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Failed to initialize user"
        );
    }
});

/**
 * Delete all user data and account
 * Called from settings when user requests account deletion
 */
export const deleteUserData = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
    // Verify authentication
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "User must be authenticated"
        );
    }

    const uid = context.auth.uid;

    try {
        // Delete all receipts
        const receiptsSnapshot = await db
            .collection("users")
            .doc(uid)
            .collection("receipts")
            .get();

        const deletePromises: Promise<any>[] = [];

        // Delete receipt documents and images
        for (const doc of receiptsSnapshot.docs) {
            deletePromises.push(doc.ref.delete());

            // Delete receipt image from Storage
            const imagePath = doc.data().imagePath;
            if (imagePath) {
                try {
                    await admin.storage().bucket().file(imagePath).delete();
                } catch (error) {
                    console.error("Error deleting image:", error);
                }
            }
        }

        // Delete categories
        const categoriesSnapshot = await db
            .collection("users")
            .doc(uid)
            .collection("categories")
            .get();
        for (const doc of categoriesSnapshot.docs) {
            deletePromises.push(doc.ref.delete());
        }

        // Delete rules
        const rulesSnapshot = await db
            .collection("users")
            .doc(uid)
            .collection("rules")
            .get();
        for (const doc of rulesSnapshot.docs) {
            deletePromises.push(doc.ref.delete());
        }

        // Delete exports
        const exportsSnapshot = await db
            .collection("users")
            .doc(uid)
            .collection("exports")
            .get();
        for (const doc of exportsSnapshot.docs) {
            deletePromises.push(doc.ref.delete());

            // Delete export files from Storage
            const pdfPath = doc.data().pdfPath;
            const csvPath = doc.data().csvPath;
            if (pdfPath) {
                try {
                    await admin.storage().bucket().file(pdfPath).delete();
                } catch (error) {
                    console.error("Error deleting PDF:", error);
                }
            }
            if (csvPath) {
                try {
                    await admin.storage().bucket().file(csvPath).delete();
                } catch (error) {
                    console.error("Error deleting CSV:", error);
                }
            }
        }

        // Delete user document
        deletePromises.push(db.collection("users").doc(uid).delete());

        // Delete entitlements
        deletePromises.push(db.collection("entitlements").doc(uid).delete());

        // Wait for all deletions
        await Promise.all(deletePromises);

        // Delete auth account
        await admin.auth().deleteUser(uid);

        return { success: true, message: "User data deleted successfully" };
    } catch (error) {
        console.error("Error deleting user data:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Failed to delete user data"
        );
    }
});
