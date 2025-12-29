import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { v4 as uuidv4 } from "uuid";

const db = admin.firestore();

/**
 * Create a share link for an export
 */
export const createShareLink = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated"
    );
  }

  const uid = context.auth.uid;
  const { exportId } = data;

  if (!exportId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Export ID is required"
    );
  }

  try {
    // Check Pro status
    const entitlements = await db.collection("entitlements").doc(uid).get();
    if (!entitlements.exists || !entitlements.data()?.isPro) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Pro subscription required for share links"
      );
    }

    // Verify export exists
    const exportDoc = await db
      .collection("users")
      .doc(uid)
      .collection("exports")
      .doc(exportId)
      .get();

    if (!exportDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Export not found");
    }

    // Generate token
    const token = uuidv4();

    // Create share token document
    await db.collection("shareTokens").doc(token).set({
      uid,
      exportId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days
      revoked: false,
    });

    // Get the deployed function URL
    // In production, this should be your custom domain
    const baseUrl = functions.config().app?.url || "https://slipbox.web.app";

    return {
      url: `${baseUrl}/s/${token}`,
      token,
    };
  } catch (error) {
    console.error("Error creating share link:", error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError(
      "internal",
      "Failed to create share link"
    );
  }
});

/**
 * HTTP endpoint to view shared export
 * Route: /s/:token
 */
export const viewSharedExport = functions.https.onRequest(
  async (req: functions.https.Request, res: functions.Response) => {
    // Extract token from path
    const token = req.path.split("/").pop();

    if (!token) {
      res.status(400).send("Invalid token");
      return;
    }

    try {
      // Validate token
      const tokenDoc = await db.collection("shareTokens").doc(token).get();

      if (!tokenDoc.exists) {
        res.status(404).send("Link not found");
        return;
      }

      const tokenData = tokenDoc.data()!;

      // Check expiration
      if (tokenData.expiresAt.toDate() < new Date()) {
        res.status(410).send("Link expired");
        return;
      }

      // Check revoked
      if (tokenData.revoked) {
        res.status(403).send("Link revoked");
        return;
      }

      // Get export document
      const exportDoc = await db
        .collection("users")
        .doc(tokenData.uid)
        .collection("exports")
        .doc(tokenData.exportId)
        .get();

      if (!exportDoc.exists) {
        res.status(404).send("Export not found");
        return;
      }

      const exportData = exportDoc.data()!;

      // Generate signed URLs (15-minute expiry)
      const bucket = admin.storage().bucket();

      const [pdfUrl] = await bucket.file(exportData.pdfPath).getSignedUrl({
        action: "read",
        expires: Date.now() + 15 * 60 * 1000,
      });

      const [csvUrl] = await bucket.file(exportData.csvPath).getSignedUrl({
        action: "read",
        expires: Date.now() + 15 * 60 * 1000,
      });

      // Render HTML page
      const html = `
        <!DOCTYPE html>
        <html lang="tr">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>SlipBox - Shared Report</title>
          <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            body {
              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
              background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
              min-height: 100vh;
              display: flex;
              align-items: center;
              justify-content: center;
              padding: 20px;
            }
            .container {
              background: white;
              border-radius: 16px;
              padding: 40px;
              max-width: 500px;
              width: 100%;
              box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            }
            h1 {
              color: #667eea;
              margin-bottom: 10px;
              font-size: 24px;
            }
            p {
              color: #666;
              margin-bottom: 30px;
            }
            .info {
              background: #f7fafc;
              padding: 20px;
              border-radius: 8px;
              margin-bottom: 30px;
            }
            .info-row {
              display: flex;
              justify-content: space-between;
              margin-bottom: 10px;
            }
            .info-row:last-child { margin-bottom: 0; }
            .label { color: #718096; font-size: 14px; }
            .value { color: #2d3748; font-weight: 600; }
            .buttons {
              display: flex;
              gap: 10px;
              flex-direction: column;
            }
            a {
              display: block;
              text-align: center;
              padding: 14px;
              background: #667eea;
              color: white;
              text-decoration: none;
              border-radius: 8px;
              font-weight: 600;
              transition: background 0.2s;
            }
            a:hover {
              background: #5568d3;
            }
            a.secondary {
              background: #e2e8f0;
              color: #4a5568;
            }
            a.secondary:hover {
              background: #cbd5e0;
            }
          </style>
        </head>
        <body>
          <div class="container">
            <h1>📊 SlipBox</h1>
            <p>Gider Raporu - ${exportData.month}</p>
            
            <div class="info">
              <div class="info-row">
                <span class="label">Toplam Gider:</span>
                <span class="value">${exportData.totals.sum.toFixed(2)} ${exportData.totals.currency}</span>
              </div>
              <div class="info-row">
                <span class="label">Fiş Sayısı:</span>
                <span class="value">${exportData.totals.count}</span>
              </div>
              <div class="info-row">
                <span class="label">Oluşturulma:</span>
                <span class="value">${new Date(exportData.createdAt?.toDate()).toLocaleDateString("tr-TR")}</span>
              </div>
            </div>
            
            <div class="buttons">
              <a href="${pdfUrl}">📄 PDF İndir</a>
              <a href="${csvUrl}" class="secondary">📊 CSV İndir</a>
            </div>
            
            <p style="margin-top: 30px; font-size: 12px; text-align: center; color: #a0aec0;">
              Bu bağlantı 30 gün geçerlidir. İndirme linkleri 15 dakika süreyle aktiftir.
            </p>
          </div>
        </body>
        </html>
      `;

      res.status(200).send(html);

      // Track analytics (optional)
      console.log(`Share link viewed: ${token}`);
    } catch (error) {
      console.error("Error viewing shared export:", error);
      res.status(500).send("Internal server error");
    }
  }
);
