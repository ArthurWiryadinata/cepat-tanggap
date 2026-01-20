const {
  onDocumentCreated,
  onDocumentUpdated,
  onDocumentDeleted,
} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

// ===== HELPER FUNCTION: Calculate Distance =====
function calculateDistance(lat1, lon1, lat2, lon2) {
  const earthRadius = 6371; // km
  const dLat = toRadians(lat2 - lat1);
  const dLon = toRadians(lon2 - lon1);

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRadians(lat1)) *
      Math.cos(toRadians(lat2)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return earthRadius * c;
}

function toRadians(degrees) {
  return degrees * (Math.PI / 180);
}

// ===== HELPER: Get IoT Status (support multiple structures) =====
function getIoTStatus(data) {
  // Priority 1: Root level IOTStatus
  if (data.IOTStatus) {
    return data.IOTStatus;
  }

  // Priority 2: Nested in disasterStatus
  if (data.disasterStatus && data.disasterStatus.IOTStatus) {
    return data.disasterStatus.IOTStatus;
  }

  // Priority 3: Old structure
  if (data.status) {
    return data.status;
  }

  return "is safe";
}

// ===== HELPER: Check if IoT has disaster =====
function hasDisaster(iotStatus) {
  if (!iotStatus) return false;

  const status = iotStatus.toLowerCase().trim();

  // Safe status
  if (status === "is safe" || status === "safe" || status === "") {
    return false;
  }

  // Check disaster keywords
  return (
    status.includes("gempa") ||
    status.includes("banjir") ||
    status.includes("kebakaran") ||
    status.includes("api")
  );
}

// ===== TRIGGER 1: Monitor IOT Status Changes =====
exports.monitorIoTStatusChange = onDocumentUpdated(
  "IOT/{deviceId}",
  async (event) => {
    console.log("\n🔍 ═══ IOT STATUS CHANGED ═══");
    console.log("Device ID:", event.params.deviceId);

    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();

    // ✅ Get status dengan support untuk nested structure
    const beforeStatus = getIoTStatus(beforeData);
    const afterStatus = getIoTStatus(afterData);

    console.log("Before status:", beforeStatus);
    console.log("After status:", afterStatus);
    console.log("After data structure:", JSON.stringify(afterData, null, 2));

    const hadDisaster = hasDisaster(beforeStatus);
    const hasDisasterNow = hasDisaster(afterStatus);

    console.log("Had disaster before:", hadDisaster);
    console.log("Has disaster now:", hasDisasterNow);

    // ✅ Status berubah dari SAFE → DISASTER
    if (!hadDisaster && hasDisasterNow) {
      console.log("🚨 NEW DISASTER DETECTED!");

      try {
        // Get semua user locations dari Firestore
        const usersSnapshot = await admin.firestore().collection("users").get();
        console.log(`📊 Total users in database: ${usersSnapshot.size}`);

        // Get IoT device location
        const iotLocation = afterData.location;
        if (!iotLocation) {
          console.log("⚠️ IoT device has no location");
          return null;
        }

        const iotLat = iotLocation._latitude || iotLocation.latitude;
        const iotLng = iotLocation._longitude || iotLocation.longitude;

        console.log(`📍 IoT Location: ${iotLat}, ${iotLng}`);

        // Check jika ada user dalam radius 5km
        let affectedUsersCount = 0;
        const affectedUsersList = [];

        for (const userDoc of usersSnapshot.docs) {
          const userData = userDoc.data();
          const userLocation = userData.userLocation;

          if (!userLocation) {
            console.log(`   ⚠️ User ${userDoc.id}: No location data`);
            continue;
          }

          const userLat = userLocation._latitude || userLocation.latitude;
          const userLng = userLocation._longitude || userLocation.longitude;

          const distance = calculateDistance(iotLat, iotLng, userLat, userLng);

          console.log(`   📍 User ${userDoc.id}: ${distance.toFixed(2)} km`);

          if (distance <= 5.0) {
            affectedUsersCount++;
            affectedUsersList.push(userDoc.id);
            console.log(
              `   ✅ User ${userDoc.id} is AFFECTED (${distance.toFixed(2)} km)`
            );
          }
        }

        console.log(`\n📊 Summary:`);
        console.log(`   Total affected users: ${affectedUsersCount}`);
        console.log(`   Affected user IDs: ${affectedUsersList.join(", ")}`);

        // ✅ ALWAYS CREATE ALERT (untuk testing), nanti bisa uncomment kondisi di bawah
        // if (affectedUsersCount > 0) {

        console.log(`✅ Creating alert document...`);

        // Get disaster type untuk message yang lebih spesifik
        let disasterType = "Bencana";
        if (afterStatus.toLowerCase().includes("gempa")) {
          disasterType = "Gempa";
        } else if (afterStatus.toLowerCase().includes("banjir")) {
          disasterType = "Banjir";
        } else if (afterStatus.toLowerCase().includes("kebakaran")) {
          disasterType = "Kebakaran";
        }

        // Create alert document
        const alertData = {
          type: "emergency", // ✅ INI HARUS "emergency" bukan "is safe"
          title: `🚨 ${disasterType.toUpperCase()} TERDETEKSI!`,
          message: `${disasterType} terdeteksi di ${event.params.deviceId}. ${affectedUsersCount} pengguna dalam radius 5km. Segera evakuasi ke tempat aman!`,
          disasterCount: 1,
          deviceIds: [event.params.deviceId],
          iotLat: iotLat,
          iotLng: iotLng,
          affectedUsersCount: affectedUsersCount,
          affectedUsersList: affectedUsersList,
          iotStatus: afterStatus, // Simpan status asli
          disasterType: disasterType,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          createdBy: "cloud_function_iot_monitor",
        };

        console.log(
          "Alert data to be created:",
          JSON.stringify(alertData, null, 2)
        );

        const alertRef = await admin
          .firestore()
          .collection("alerts")
          .add(alertData);
        console.log(`✅ Alert document created with ID: ${alertRef.id}`);
        console.log(`   Type: ${alertData.type}`);
        console.log(`   Title: ${alertData.title}`);

        // } else {
        //   console.log("ℹ️ No users within 5km, skip alert");
        // }

        console.log("═══ IOT MONITOR END ═══\n");
        return null;
      } catch (error) {
        console.error("❌ Error creating alert:", error);
        console.error("Error stack:", error.stack);
        return null;
      }
    }
    // ✅ Status berubah dari DISASTER → SAFE
    else if (hadDisaster && !hasDisasterNow) {
      console.log("✅ Disaster cleared - status back to safe");

      // Delete existing alerts for this device
      try {
        const alertsSnapshot = await admin
          .firestore()
          .collection("alerts")
          .where("deviceIds", "array-contains", event.params.deviceId)
          .get();

        console.log(`Found ${alertsSnapshot.size} alerts to delete`);

        for (const doc of alertsSnapshot.docs) {
          await doc.ref.delete();
          console.log(`🗑️ Deleted alert: ${doc.id}`);
        }
      } catch (error) {
        console.error("❌ Error deleting alerts:", error);
      }
    } else {
      console.log("ℹ️ No significant status change");
      console.log(`   Before: ${beforeStatus} (disaster: ${hadDisaster})`);
      console.log(`   After: ${afterStatus} (disaster: ${hasDisasterNow})`);
    }

    console.log("═══ IOT MONITOR END ═══\n");
    return null;
  }
);

// ===== TRIGGER 2: Send FCM when alert is CREATED =====
exports.sendEmergencyAlert = onDocumentCreated(
  "alerts/{docId}",
  async (event) => {
    console.log("\n🔥 ═══ NEW ALERT CREATED ═══");
    console.log("Document ID:", event.params.docId);

    const data = event.data.data();
    console.log("Alert data:", JSON.stringify(data, null, 2));

    if (!data) {
      console.error("❌ No data found in document");
      return null;
    }

    console.log("Alert type:", data.type);

    if (data.type === "emergency") {
      console.log("✅ Type is EMERGENCY - sending FCM");

      const message = {
        topic: "all_users",
        data: {
          type: "emergency",
          title: data.title || "🚨 BENCANA TERDETEKSI!",
          message: data.message || "Segera lakukan tindakan evakuasi!",
          disasterCount: String(data.disasterCount || 0),
          iotStatus: data.iotStatus || "",
          disasterType: data.disasterType || "",
          deviceIds: JSON.stringify(data.deviceIds || []),
          timestamp: String(Date.now()),
        },
        android: {
          priority: "high",
          ttl: 0,
        },
        apns: {
          payload: {
            aps: {
              contentAvailable: true,
              sound: "default",
              badge: 1,
            },
          },
          headers: {
            "apns-priority": "10",
          },
        },
      };

      try {
        console.log("📡 Sending FCM message to topic: all_users");
        console.log("Message payload:", JSON.stringify(message, null, 2));

        const response = await admin.messaging().send(message);

        console.log("✅ FCM sent successfully!");
        console.log("Message ID:", response);
        console.log("═══ SEND COMPLETE ═══\n");

        return { success: true, messageId: response };
      } catch (error) {
        console.error("❌ Error sending FCM:");
        console.error("Error message:", error.message);
        console.error("Error code:", error.code);
        console.error("Error stack:", error.stack);
        console.log("═══ SEND FAILED ═══\n");
        return { success: false, error: error.message };
      }
    } else {
      console.log(`⚠️ Alert type is "${data.type}" - NOT emergency, skip FCM`);
      console.log("═══ SKIPPED ═══\n");
      return null;
    }
  }
);

// ===== TRIGGER 3: Log when alert is DELETED =====
exports.onAlertDeleted = onDocumentDeleted("alerts/{docId}", async (event) => {
  console.log("\n🗑️ ═══ ALERT DELETED ═══");
  console.log("Document ID:", event.params.docId);

  const data = event.data.data();
  console.log("Deleted alert type:", data?.type);
  console.log("═══ DELETE END ═══\n");

  return null;
});

// ===== TEST FUNCTION: Manual notification test =====
exports.testEmergencyNotification =
  require("firebase-functions/v2/https").onRequest(async (req, res) => {
    console.log("\n🧪 ═══ TEST NOTIFICATION TRIGGERED ═══");

    const message = {
      topic: "all_users",
      data: {
        type: "emergency",
        title: "🧪 TEST Emergency Alert",
        message: "This is a test notification from Cloud Functions",
        disasterCount: "1",
        iotStatus: "banjir",
        disasterType: "Banjir",
        timestamp: String(Date.now()),
      },
      android: {
        priority: "high",
      },
    };

    try {
      console.log("Sending test message:", JSON.stringify(message, null, 2));
      const response = await admin.messaging().send(message);
      console.log("✅ Test notification sent:", response);
      console.log("═══ TEST COMPLETE ═══\n");

      res.json({
        success: true,
        message: "Test notification sent successfully",
        messageId: response,
      });
    } catch (error) {
      console.error("❌ Test failed:", error);
      console.log("═══ TEST FAILED ═══\n");

      res.status(500).json({
        success: false,
        error: error.message,
      });
    }
  });

// ===== DEBUG FUNCTION: Check current IoT status =====
exports.debugIoTStatus = require("firebase-functions/v2/https").onRequest(
  async (req, res) => {
    console.log("\n🔍 ═══ DEBUG IOT STATUS ═══");

    try {
      const iotSnapshot = await admin.firestore().collection("IOT").get();

      const results = [];

      for (const doc of iotSnapshot.docs) {
        const data = doc.data();
        const status = getIoTStatus(data);
        const hasDisasterNow = hasDisaster(status);

        results.push({
          id: doc.id,
          status: status,
          hasDisaster: hasDisasterNow,
          location: data.location,
          fullData: data,
        });
      }

      console.log("IoT devices:", JSON.stringify(results, null, 2));
      console.log("═══ DEBUG END ═══\n");

      res.json({
        success: true,
        devices: results,
      });
    } catch (error) {
      console.error("❌ Debug failed:", error);
      res.status(500).json({
        success: false,
        error: error.message,
      });
    }
  }
);
