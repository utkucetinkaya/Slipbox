import { Request, Response } from "express";
import * as admin from "firebase-admin";

/**
 * Middleware to verify App Check token for HTTP functions
 * Use this for public HTTP endpoints like viewSharedExport
 */
export const verifyAppCheck = async (
    req: Request,
    res: Response,
    next: Function
) => {
    const appCheckToken = req.header("X-Firebase-AppCheck");

    if (!appCheckToken) {
        res.status(401).send("Missing App Check token");
        return;
    }

    try {
        await admin.appCheck().verifyToken(appCheckToken);
        next();
    } catch (error) {
        console.error("App Check verification failed:", error);
        res.status(401).send("Invalid App Check token");
    }
};

/**
 * Helper function to enforce App Check in Callable functions
 * Throws HttpsError if App Check verification fails
 */
export const enforceAppCheck = (context: any) => {
    if (!context.app) {
        const functions = require("firebase-functions");
        throw new functions.https.HttpsError(
            "failed-precondition",
            "App Check verification failed"
        );
    }
};
