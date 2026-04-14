const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
admin.initializeApp();

// ─────────────────────────────────────────────
// YARDIMCI: Geçersiz tokenları Firestore'dan sil
// ─────────────────────────────────────────────
async function cleanupInvalidTokens(responses, tokenDocs) {
  const deletePromises = [];
  responses.forEach((resp, index) => {
    if (!resp.success) {
      const errorCode = resp.error?.code;
      if (
        errorCode === "messaging/invalid-registration-token" ||
        errorCode === "messaging/registration-token-not-registered"
      ) {
        deletePromises.push(
          admin.firestore().collection("fcm_tokens").doc(tokenDocs[index].id).delete()
        );
      }
    }
  });
  if (deletePromises.length > 0) {
    await Promise.all(deletePromises);
  }
}

// ─────────────────────────────────────────────
// YARDIMCI: Mesaj yapısı oluştur
// ─────────────────────────────────────────────
function buildMessage(title, body, tokens) {
  return {
    tokens,
    notification: { title, body },
    android: { priority: "high", notification: { channelId: "high_importance_channel", sound: "default" } },
    apns: { payload: { aps: { sound: "default", badge: 1 } } },
  };
}

// 0. ESKİ TOKEN TEMİZLİĞİ (Her gece 03:00)
exports.cleanupOldTokens = onSchedule(
  { schedule: "0 3 * * *", timeZone: "Europe/Istanbul" },
  async (event) => {
    const tenDaysAgo = new Date();
    tenDaysAgo.setDate(tenDaysAgo.getDate() - 10);
    const oldTokensSnapshot = await admin.firestore().collection("fcm_tokens")
      .where("lastUpdate", "<", admin.firestore.Timestamp.fromDate(tenDaysAgo)).get();
    if (oldTokensSnapshot.empty) return;
    const batch = admin.firestore().batch();
    oldTokensSnapshot.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
  }
);

// 1. GENEL HATIRLATICI (Her gün 14:00)
exports.dailyGeneralReminder = onSchedule(
  { schedule: "0 14 * * *", timeZone: "Europe/Istanbul" },
  async (event) => {
    const snapshot = await admin.firestore().collection("fcm_tokens").get();
    if (snapshot.empty) return;
    const activeTokenDocs = [];
    await Promise.all(snapshot.docs.map(async (tokenDoc) => {
      const userDoc = await admin.firestore().collection("users").doc(tokenDoc.id).get();
      if (userDoc.exists && (userDoc.data().notifications_active ?? true)) {
        activeTokenDocs.push({ id: tokenDoc.id, token: tokenDoc.data().token });
      }
    }));
    if (activeTokenDocs.length === 0) return;
    const message = buildMessage("Güne Almanca ile Başla! 🇩🇪", "Bugünkü kelime testini çöz, serini koru!", activeTokenDocs.map(t => t.token));
    const response = await admin.messaging().sendEachForMulticast(message);
    await cleanupInvalidTokens(response.responses, activeTokenDocs);
  }
);

// 2. İNAKTİF KULLANICI (Her gün 19:00)
exports.inactiveUserCheck = onSchedule(
  { schedule: "0 19 * * *", timeZone: "Europe/Istanbul" },
  async (event) => {
    const twoDaysAgo = new Date();
    twoDaysAgo.setDate(twoDaysAgo.getDate() - 2);
    const usersSnapshot = await admin.firestore().collection("users")
      .where("last_quiz_date", "<", admin.firestore.Timestamp.fromDate(twoDaysAgo)).get();
    const promises = usersSnapshot.docs.map(async (userDoc) => {
      if (!(userDoc.data().notifications_active ?? true)) return;
      const tokenDoc = await admin.firestore().collection("fcm_tokens").doc(userDoc.id).get();
      if (!tokenDoc.exists || !tokenDoc.data().token) return;
      const message = buildMessage("Seni Özledik! 👋", "Geri dön ve serini kurtar!", [tokenDoc.data().token]);
      const resp = await admin.messaging().sendEachForMulticast(message);
      await cleanupInvalidTokens(resp.responses, [{ id: userDoc.id }]);
    });
    await Promise.all(promises);
  }
);

// 3. GÜNLÜK HEDEF (Her gün 20:00)
exports.dailyGoalReminder = onSchedule(
  { schedule: "0 20 * * *", timeZone: "Europe/Istanbul" },
  async (event) => {
    const now = new Date();
    const dateId = `${now.getFullYear()}-${(now.getMonth() + 1).toString().padStart(2, "0")}-${now.getDate().toString().padStart(2, "0")}`;
    const usersSnapshot = await admin.firestore().collection("users").get();
    const promises = usersSnapshot.docs.map(async (userDoc) => {
      const userData = userDoc.data();
      if (!(userData.notifications_active ?? true) || !userData.daily_goal) return;
      const dailyRef = await admin.firestore().collection("users").doc(userDoc.id).collection("daily_series").doc(dateId).get();
      const remaining = userData.daily_goal - (dailyRef.exists ? (dailyRef.data().correct_answers || 0) : 0);
      if (remaining <= 0) return;
      const tokenDoc = await admin.firestore().collection("fcm_tokens").doc(userDoc.id).get();
      if (!tokenDoc.exists || !tokenDoc.data().token) return;
      const message = buildMessage("Hedefine Az Kaldı! 🔥", `${remaining} kelime daha öğren, hedefe ulaş!`, [tokenDoc.data().token]);
      const resp = await admin.messaging().sendEachForMulticast(message);
      await cleanupInvalidTokens(resp.responses, [{ id: userDoc.id }]);
    });
    await Promise.all(promises);
  }
);

// 4. HAFTALIK SKOR SIFIRLAMA + ŞAMPİYON KAYDI (Her Pazar 23:59)
// ✅ İNGİLİZCE PROJESİNDEKİ TAM SÜRÜM AKTARILDI
exports.resetWeeklyScores = onSchedule(
  { schedule: "59 23 * * 0", timeZone: "Europe/Istanbul" },
  async (event) => {
    const db = admin.firestore();
    try {
      // A) ŞAMPİYONLARI KAYDET
      const topSnapshot = await db.collection("weekly_leaderboard").orderBy("weeklyScore", "desc").limit(3).get();
      if (!topSnapshot.empty) {
        const cBatch = db.batch();
        const cRef = db.collection("last_week_champions");
        const oldC = await cRef.get();
        oldC.docs.forEach(d => cBatch.delete(d.ref));
        topSnapshot.docs.forEach((d, i) => {
          cBatch.set(cRef.doc(d.id), {
            uid: d.id, username: d.data().username,
            avatar: d.data().avatar || "assets/avatars/boy-avatar-1.png",
            score: d.data().weeklyScore, rank: i + 1,
            savedAt: admin.firestore.FieldValue.serverTimestamp()
          });
        });
        await cBatch.commit();
      }

      // B) TÜM SKORLARI SIFIRLA (Users + Weekly Leaderboard)
      const uSnap = await db.collection("users").where("weekly_score", ">", 0).get();
      const lSnap = await db.collection("weekly_leaderboard").where("weeklyScore", ">", 0).get();

      let batch = db.batch();
      let count = 0;
      const promises = [];

      uSnap.docs.forEach(d => {
        batch.update(d.ref, { weekly_score: 0 });
        count++; if (count === 500) { promises.push(batch.commit()); batch = db.batch(); count = 0; }
      });
      lSnap.docs.forEach(d => {
        batch.update(d.ref, { weeklyScore: 0 });
        count++; if (count === 500) { promises.push(batch.commit()); batch = db.batch(); count = 0; }
      });

      if (count > 0) promises.push(batch.commit());
      await Promise.all(promises);
    } catch (e) { console.error("Sıfırlama hatası:", e); }
  }
);

// 5. VERİ TAŞIMA SCRIPT'İ (GEÇİCİ - SADECE BİR KEZ)
// Mevcut users verilerini weekly_leaderboard'a aktarır
// ─────────────────────────────────────────────
exports.migrateWeeklyScores = onSchedule(
  {
    schedule: "*/5 * * * *", // Her 5 dakikada bir tetiklenir (Manuel tetikleme sonrası silinmelidir)
    timeZone: "Europe/Istanbul"
  },
  async (event) => {
    console.log("--- VERİ TAŞIMA (MIGRATION) BAŞLADI ---");

    try {
      const usersRef = admin.firestore().collection("users");
      const weeklyRef = admin.firestore().collection("weekly_leaderboard");
      const snapshot = await usersRef.get();

      if (snapshot.empty) {
        console.log("Taşınacak veri bulunamadı.");
        return;
      }

      let batch = admin.firestore().batch();
      let count = 0;
      let totalProcessed = 0;

      for (const doc of snapshot.docs) {
        const data = doc.data();

        batch.set(weeklyRef.doc(doc.id), {
          uid: doc.id,
          username: data.username || "Öğrenci",
          avatar: data.avatarPath || "assets/avatars/boy-avatar-1.png",
          weeklyScore: data.weekly_score || 0,
          totalScore: data.total_xp || 0,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });

        count++;
        totalProcessed++;

        if (count === 500) {
          await batch.commit();
          console.log(`${totalProcessed} kayıt başarıyla taşındı...`);
          batch = admin.firestore().batch();
          count = 0;
        }
      }

      if (count > 0) {
        await batch.commit();
      }

      console.log(`İŞLEM TAMAMLANDI: Toplam ${totalProcessed} kullanıcı haftalık tabloya aktarıldı.`);
    } catch (error) {
      console.error("Taşıma hatası:", error);
    }
  }
);
