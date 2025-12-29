const {
  onDocumentCreated,
  onDocumentUpdated,
} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendEmergencyAlert = onDocumentCreated(
  "alerts/{docId}",
  async (event) => {
    console.log("🔥 Trigger masuk! Dokumen baru dibuat.");
    const data = event.data.data();
    console.log("Data dokumen:", data);

    if (!data) {
      console.error("❌ No data found in snapshot.");
      return null;
    }

    if (data.type === "emergency") {
      const message = {
        topic: "all_users",
        data: {
          type: "emergency",
          title: data.title || "🚨 Emergency Alert",
          message: data.message || "Emergency Alert",
        },
        android: {
          priority: "high",
        },
        apns: {
          payload: {
            aps: {
              contentAvailable: true,
            },
          },
          headers: {
            "apns-priority": "10",
          },
        },
      };

      try {
        console.log(
          "📡 Sending message to topic all_users:",
          JSON.stringify(message, null, 2)
        );

        const response = await admin.messaging().send(message);

        console.log("✅ Sent FCM to topic all_users:", response);
        console.log("Message payload:", JSON.stringify(message, null, 2));
      } catch (error) {
        console.error("❌ Error sending message:", error);
      }
    } else {
      console.log("ℹ️ Alert type is not emergency:", data.type);
    }

    return null;
  }
);

exports.sendEmergencyOnUpdate = onDocumentUpdated(
  "alerts/{docId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    // Trigger hanya ketika status berubah
    if (before.type !== after.type) {
      console.log(`🔄 Status berubah: ${before.type} ➡ ${after.type}`);

      // Jika status baru adalah EMERGENCY → kirim notif sama seperti onCreate
      if (after.type === "emergency") {
        console.log("🚨 EMERGENCY DETECTED via UPDATE — sending FCM...");

        const message = {
          topic: "all_users",
          data: {
            type: "emergency",
            title: after.title || "🚨 Emergency Alert",
            message: after.message || "Emergency Alert",
          },
          android: { priority: "high" },
          apns: {
            payload: { aps: { contentAvailable: true } },
            headers: { "apns-priority": "10" },
          },
        };

        try {
          const response = await admin.messaging().send(message);
          console.log("✅ Emergency alert sent via UPDATE:", response);
        } catch (error) {
          console.error("❌ Error sending emergency alert:", error);
        }
      } else {
        console.log(
          "ℹ Status berubah tetapi bukan emergency, tidak kirim notif."
        );
      }
    } else {
      console.log("ℹ Dokumen update tapi status tidak berubah → dilewat.");
    }
  }
);
