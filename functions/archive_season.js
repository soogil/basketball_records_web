/**
 * 시즌 아카이브 스크립트 (GitHub Actions에서 매년 1월 1일 자동 실행)
 * - players / playerRecords → seasons/{previousYear}/ 로 백업
 * - 시즌 점수 초기화 (누적 점수, status, name 유지)
 */
const admin = require('firebase-admin');

const credentials = JSON.parse(process.env.FIREBASE_CREDENTIALS);
admin.initializeApp({ credential: admin.credential.cert(credentials) });
const db = admin.firestore();

async function run() {
  // 실행 시점은 KST 1월 1일이지만 UTC로는 12월 31일이므로 getFullYear()는 전년도
  const seasonName = new Date().getFullYear().toString();
  console.log(`[archiveSeason] 시즌 아카이브 시작: ${seasonName}`);

  const [playersSnapshot, recordsSnapshot] = await Promise.all([
    db.collection('players').get(),
    db.collection('playerRecords').get(),
  ]);

  // Firestore batch는 500건 제한이 있으므로 청크 단위로 처리
  const ops = [];

  for (const doc of playersSnapshot.docs) {
    ops.push({ type: 'set', ref: db.collection('seasons').doc(seasonName).collection('players').doc(doc.id), data: doc.data() });
    ops.push({ type: 'update', ref: db.collection('players').doc(doc.id), data: { totalScore: 0, attendanceScore: 0, winScore: 0, seasonTotalGames: 0, seasonTotalWins: 0.0, scoreAchieved: false } });
  }

  for (const doc of recordsSnapshot.docs) {
    ops.push({ type: 'set', ref: db.collection('seasons').doc(seasonName).collection('playerRecords').doc(doc.id), data: doc.data() });
    ops.push({ type: 'set', ref: db.collection('playerRecords').doc(doc.id), data: { records: [] } });
  }

  // 500건씩 나눠서 commit
  const CHUNK = 499;
  for (let i = 0; i < ops.length; i += CHUNK) {
    const batch = db.batch();
    for (const op of ops.slice(i, i + CHUNK)) {
      if (op.type === 'set') batch.set(op.ref, op.data);
      else batch.update(op.ref, op.data);
    }
    await batch.commit();
    console.log(`  배치 커밋 완료 (${Math.min(i + CHUNK, ops.length)}/${ops.length})`);
  }

  console.log(`[archiveSeason] 완료: ${seasonName} 시즌 아카이브 및 초기화`);
}

run().catch((e) => { console.error(e); process.exit(1); });
