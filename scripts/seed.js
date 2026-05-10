#!/usr/bin/env node
/**
 * Seed Firestore with realistic test data.
 * Run from the project root:
 *
 *   node scripts/seed.js <your-firebase-uid> [--clean]
 *
 * --clean  deletes previously seeded documents before inserting new ones.
 */

const path = require('path');
// Resolve firebase-admin from functions/node_modules regardless of cwd
const admin = require(path.resolve(__dirname, '../functions/node_modules/firebase-admin'));
const { randomUUID } = require('crypto');

const MY_UID = process.argv[2];
const CLEAN = process.argv.includes('--clean');

if (!MY_UID) {
  console.error('Usage: node scripts/seed.js <your-firebase-uid> [--clean]');
  process.exit(1);
}

admin.initializeApp({ projectId: 'familyguard-app-e2b30' });
const db = admin.firestore();
const TS = admin.firestore.Timestamp;

const daysAgo = (n) =>
  TS.fromDate(new Date(Date.now() - n * 24 * 60 * 60 * 1000));

const SEED_TAG = '__seed__';

// ---------------------------------------------------------------------------
// Fake user profiles (no real Auth account needed — just Firestore docs)
// ---------------------------------------------------------------------------
const CAREGIVER_1_ID = randomUUID();
const CAREGIVER_2_ID = randomUUID();
const FAKE_PARENT_ID  = randomUUID();

const fakeUsers = [
  {
    id: CAREGIVER_1_ID,
    data: {
      uid: CAREGIVER_1_ID,
      email: 'marie.leblanc@example.com',
      firstName: 'Marie',
      lastName: 'Leblanc',
      phone: '+33 6 12 34 56 78',
      avatarUrl: null,
      fcmToken: null,
      createdAt: daysAgo(30),
      [SEED_TAG]: true,
    },
  },
  {
    id: CAREGIVER_2_ID,
    data: {
      uid: CAREGIVER_2_ID,
      email: 'thomas.petit@example.com',
      firstName: 'Thomas',
      lastName: 'Petit',
      phone: null,
      avatarUrl: null,
      fcmToken: null,
      createdAt: daysAgo(12),
      [SEED_TAG]: true,
    },
  },
  {
    id: FAKE_PARENT_ID,
    data: {
      uid: FAKE_PARENT_ID,
      email: 'isabelle.moreau@example.com',
      firstName: 'Isabelle',
      lastName: 'Moreau',
      phone: '+33 6 98 76 54 32',
      avatarUrl: null,
      fcmToken: null,
      createdAt: daysAgo(60),
      [SEED_TAG]: true,
    },
  },
];

// ---------------------------------------------------------------------------
// Children
// ---------------------------------------------------------------------------
const children = [
  {
    parentId: MY_UID,
    firstName: 'Emma',
    lastName: '',
    birthDate: TS.fromDate(new Date('2019-03-15')),
    avatarUrl: null,
    allergies: 'Arachides',
    medicalInfo: null,
    notes: 'Aime les dinosaures et la peinture',
    archived: false,
    createdAt: daysAgo(60),
    updatedAt: daysAgo(60),
    [SEED_TAG]: true,
  },
  {
    parentId: MY_UID,
    firstName: 'Lucas',
    lastName: '',
    birthDate: TS.fromDate(new Date('2021-07-22')),
    avatarUrl: null,
    allergies: null,
    medicalInfo: 'Asthme léger — spray Ventoline dans le sac',
    notes: null,
    archived: false,
    createdAt: daysAgo(40),
    updatedAt: daysAgo(40),
    [SEED_TAG]: true,
  },
];

// ---------------------------------------------------------------------------
// Connections
// ---------------------------------------------------------------------------
const connections = [
  // Mes babysitters — active
  {
    parentId: MY_UID,
    caregiverId: CAREGIVER_1_ID,
    status: 'active',
    inviteCode: randomUUID(),
    inviteEmail: 'marie.leblanc@example.com',
    message: "Bonjour Marie, j'aimerais t'ajouter à mon réseau FamilyGuard !",
    createdAt: daysAgo(20),
    updatedAt: daysAgo(15),
    [SEED_TAG]: true,
  },
  // Mes babysitters — pending
  {
    parentId: MY_UID,
    caregiverId: null,
    status: 'pending',
    inviteCode: randomUUID(),
    inviteEmail: 'thomas.petit@example.com',
    message: null,
    createdAt: daysAgo(3),
    updatedAt: daysAgo(3),
    [SEED_TAG]: true,
  },
  // Mes babysitters — declined
  {
    parentId: MY_UID,
    caregiverId: null,
    status: 'declined',
    inviteCode: randomUUID(),
    inviteEmail: 'sophie.bernard@example.com',
    message: null,
    createdAt: daysAgo(10),
    updatedAt: daysAgo(7),
    [SEED_TAG]: true,
  },
  // Mes familles — active (current user is the caregiver)
  {
    parentId: FAKE_PARENT_ID,
    caregiverId: MY_UID,
    status: 'active',
    inviteCode: randomUUID(),
    inviteEmail: 'me@seed.local',
    message: 'Bonjour, je cherche un babysitter de confiance pour mes enfants.',
    createdAt: daysAgo(45),
    updatedAt: daysAgo(40),
    [SEED_TAG]: true,
  },
];

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
async function deleteSeeded(collection) {
  const snap = await db.collection(collection).where(SEED_TAG, '==', true).get();
  if (snap.empty) return;
  const batch = db.batch();
  snap.docs.forEach((d) => batch.delete(d.ref));
  await batch.commit();
  console.log(`  🗑  Deleted ${snap.size} seeded docs from /${collection}`);
}

async function insertBatch(collection, docs) {
  const batch = db.batch();
  docs.forEach(({ id, data }) => {
    const ref = id ? db.collection(collection).doc(id) : db.collection(collection).doc();
    batch.set(ref, data ?? id);
  });
  await batch.commit();
  console.log(`  ✅  Inserted ${docs.length} docs into /${collection}`);
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------
async function seed() {
  console.log(`\n🌱 Seeding Firestore for UID: ${MY_UID}\n`);

  if (CLEAN) {
    console.log('🧹 Cleaning previous seed data…');
    await deleteSeeded('users');
    await deleteSeeded('children');
    await deleteSeeded('connections');
    console.log();
  }

  console.log('👤 Fake user profiles…');
  await insertBatch('users', fakeUsers);

  console.log('👶 Children…');
  await insertBatch(
    'children',
    children.map((data) => ({ data })),
  );

  console.log('🔗 Connections…');
  await insertBatch(
    'connections',
    connections.map((data) => ({ data })),
  );

  console.log('\n🎉 Done! Reload the app to see the data.\n');
  process.exit(0);
}

seed().catch((e) => {
  console.error(e);
  process.exit(1);
});
