const { onDocumentCreated } = require("firebase-functions/v2/firestore");
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
