/**
 * Creates project creator accounts in Firebase Auth + Firestore.
 *
 * Run from project root:
 *   node seed/create_project_users.js
 *
 * Requirements:
 *   - Node.js (any recent version)
 *   - Internet connection to Firebase project online-learning-app-e8b52
 *
 * How it works:
 *   1. Signs up (or signs in) each user via Firebase Auth REST API
 *   2. Uses the user's own ID token to write their Firestore profile
 *      (Firestore rules allow any authenticated user to read/write)
 *   3. If a user's password is unknown, falls back to email-based Firestore lookup
 *      using the admin account's token to set the correct role
 */

'use strict';

const https = require('https');

const PROJECT_ID = 'online-learning-app-e8b52';
// Web API key — public (already in firebase_options.dart)
const WEB_API_KEY = 'AIzaSyB6Djei1qapoEawNzHwNYrSrbmWMn4IEbY';

// ── Project creator accounts ───────────────────────────────────────────────

const PROJECT_USERS = [
  {
    email: 'hparvat610@rku.ac.in',
    password: 'Student@123',
    name: 'H Parvat',
    role: 'student',
  },
  {
    email: 'rishigoswami91@gmail.com',
    password: 'Mentor@123',
    name: 'Rishi Goswami',
    role: 'mentor',
  },
  {
    email: 'hetvikakkad1508@gmail.com',
    password: 'Admin@123',
    name: 'Hetvi Kakkad',
    role: 'admin',
  },
];

// ── HTTP helper ─────────────────────────────────────────────────────────────

function request(hostname, path, method, extraHeaders, bodyObj) {
  const body = bodyObj !== undefined ? JSON.stringify(bodyObj) : undefined;
  const opts = {
    hostname,
    path,
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(body ? { 'Content-Length': Buffer.byteLength(body) } : {}),
      ...extraHeaders,
    },
  };
  return new Promise((resolve, reject) => {
    const req = https.request(opts, (res) => {
      let data = '';
      res.on('data', (c) => { data += c; });
      res.on('end', () => {
        try { resolve({ status: res.statusCode, data: JSON.parse(data) }); }
        catch { resolve({ status: res.statusCode, data }); }
      });
    });
    req.on('error', reject);
    if (body) req.write(body);
    req.end();
  });
}

// ── Firebase Auth REST ──────────────────────────────────────────────────────

async function signUp(email, password) {
  const { data } = await request(
    'identitytoolkit.googleapis.com',
    `/v1/accounts:signUp?key=${WEB_API_KEY}`,
    'POST', {},
    { email, password, returnSecureToken: true },
  );
  if (data.localId && data.idToken) return data;
  const err = new Error(data.error?.message ?? 'signUp failed');
  err.code = data.error?.message;
  throw err;
}

async function signIn(email, password) {
  const { data } = await request(
    'identitytoolkit.googleapis.com',
    `/v1/accounts:signInWithPassword?key=${WEB_API_KEY}`,
    'POST', {},
    { email, password, returnSecureToken: true },
  );
  if (data.localId && data.idToken) return data;
  const err = new Error(data.error?.message ?? 'signIn failed');
  err.code = data.error?.message;
  throw err;
}

async function updateDisplayName(idToken, displayName) {
  await request(
    'identitytoolkit.googleapis.com',
    `/v1/accounts:update?key=${WEB_API_KEY}`,
    'POST', {},
    { idToken, displayName },
  );
}

async function sendPasswordReset(email) {
  await request(
    'identitytoolkit.googleapis.com',
    `/v1/accounts:sendOobCode?key=${WEB_API_KEY}`,
    'POST', {},
    { requestType: 'PASSWORD_RESET', email },
  );
}

// ── Firestore helpers ───────────────────────────────────────────────────────

function toFsVal(v) {
  if (v === null || v === undefined) return { nullValue: null };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'string') return { stringValue: v };
  if (typeof v === 'number') {
    return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  }
  if (v instanceof Date) return { timestampValue: v.toISOString() };
  return { stringValue: String(v) };
}

async function writeUserDoc(idToken, uid, user) {
  const doc = {
    fields: {
      uid: toFsVal(uid),
      email: toFsVal(user.email),
      name: toFsVal(user.name),
      role: toFsVal(user.role),
      isVerified: toFsVal(true),
      status: toFsVal('active'),
      isBlocked: toFsVal(false),
      profileImage: toFsVal(''),
      createdAt: toFsVal(new Date().toISOString()),
    },
  };
  const { status, data } = await request(
    'firestore.googleapis.com',
    `/v1/projects/${PROJECT_ID}/databases/(default)/documents/users/${uid}`,
    'PATCH',
    { Authorization: `Bearer ${idToken}` },
    doc,
  );
  if (status !== 200) {
    throw new Error(
      `Firestore write failed (${status}): ${data.error?.message ?? JSON.stringify(data)}`,
    );
  }
}

// Find a user doc by email using Firestore structured query
async function findUidByEmail(idToken, email) {
  const query = {
    structuredQuery: {
      from: [{ collectionId: 'users' }],
      where: {
        fieldFilter: {
          field: { fieldPath: 'email' },
          op: 'EQUAL',
          value: { stringValue: email.toLowerCase() },
        },
      },
      limit: 1,
    },
  };
  const { data } = await request(
    'firestore.googleapis.com',
    `/v1/projects/${PROJECT_ID}/databases/(default)/documents:runQuery`,
    'POST',
    { Authorization: `Bearer ${idToken}` },
    query,
  );
  // Response is an array of { document: {...} }
  const rows = Array.isArray(data) ? data : [];
  const doc = rows.find((r) => r.document);
  if (!doc?.document?.name) return null;
  // name format: projects/.../documents/users/{uid}
  return doc.document.name.split('/').pop();
}

// Update just the role field on an existing doc
async function updateUserRole(idToken, uid, user) {
  const doc = {
    fields: {
      role: toFsVal(user.role),
      name: toFsVal(user.name),
      isVerified: toFsVal(true),
      status: toFsVal('active'),
      isBlocked: toFsVal(false),
    },
  };
  const mask = 'role,name,isVerified,status,isBlocked';
  const { status, data } = await request(
    'firestore.googleapis.com',
    `/v1/projects/${PROJECT_ID}/databases/(default)/documents/users/${uid}?updateMask.fieldPaths=role&updateMask.fieldPaths=name&updateMask.fieldPaths=isVerified&updateMask.fieldPaths=status&updateMask.fieldPaths=isBlocked`,
    'PATCH',
    { Authorization: `Bearer ${idToken}` },
    doc,
  );
  if (status !== 200) {
    throw new Error(
      `Firestore role update failed (${status}): ${data.error?.message ?? JSON.stringify(data)}`,
    );
  }
}

// ── Main ────────────────────────────────────────────────────────────────────

async function processUser(user, adminToken) {
  let authData;
  let created = true;

  try {
    authData = await signUp(user.email, user.password);
  } catch (signUpErr) {
    if (signUpErr.code === 'EMAIL_EXISTS') {
      created = false;
      try {
        authData = await signIn(user.email, user.password);
      } catch (_signInErr) {
        // Account exists with a different password.
        // Try to find and update their Firestore doc via admin token
        if (!adminToken) throw new Error('Account exists with unknown password and no admin token available');

        const uid = await findUidByEmail(adminToken, user.email);
        if (uid) {
          await updateUserRole(adminToken, uid, user);
          // Send password reset so they can access with their own password
          try { await sendPasswordReset(user.email); } catch (_) {}
          return { uid, created: false, note: 'role updated via admin; password reset email sent' };
        }
        // No Firestore doc found — create a pre_registered_roles entry
        throw new Error(
          `Account exists but could not locate Firestore doc. ` +
          `Have admin manually change their role in Firebase Console.`,
        );
      }
    } else {
      throw signUpErr;
    }
  }

  const { localId: uid, idToken } = authData;
  await updateDisplayName(idToken, user.name);
  await writeUserDoc(idToken, uid, user);

  return { uid, created };
}

async function main() {
  console.log('\n🚀 Creating project creator accounts...\n');

  // We'll collect admin token after admin is processed
  let adminToken = null;
  const results = [];

  for (const user of PROJECT_USERS) {
    process.stdout.write(`  [${user.role.toUpperCase()}] ${user.email} ... `);
    try {
      const { uid, created, note } = await processUser(user, adminToken);

      // If this is the admin, save their token for fallback lookups
      if (user.role === 'admin') {
        try {
          const sd = await signIn(user.email, user.password);
          adminToken = sd.idToken;
        } catch (_) {}
      }

      const label = note ?? (created ? 'created' : 'already existed — Firestore updated');
      console.log(`✅ ${label} (uid: ${uid})`);
      results.push({ ...user, uid, ok: true, note });
    } catch (e) {
      console.log(`❌ ${e.message}`);
      results.push({ ...user, uid: null, ok: false });
    }
  }

  // Second pass: retry failed users that now have adminToken available
  for (const r of results.filter((r) => !r.ok)) {
    if (!adminToken) continue;
    const user = PROJECT_USERS.find((u) => u.email === r.email);
    if (!user) continue;
    process.stdout.write(`  [RETRY] ${user.email} ... `);
    try {
      const uid = await findUidByEmail(adminToken, user.email);
      if (uid) {
        await updateUserRole(adminToken, uid, user);
        try { await sendPasswordReset(user.email); } catch (_) {}
        console.log(`✅ role updated to '${user.role}' via admin; password reset email sent to ${user.email}`);
        r.ok = true;
        r.uid = uid;
        r.note = 'password reset email sent';
      } else {
        console.log('❌ User not found in Firestore');
      }
    } catch (e) {
      console.log(`❌ ${e.message}`);
    }
  }

  const ok = results.filter((r) => r.ok);
  const failed = results.filter((r) => !r.ok);

  console.log('\n────────────────────────────────────────────────────────────');
  console.log('  Results:');
  console.log('────────────────────────────────────────────────────────────');
  for (const r of results) {
    const symbol = r.ok ? '✅' : '❌';
    const note = r.note ? ` (${r.note})` : '';
    console.log(`  ${symbol} ${r.role.padEnd(8)}  ${r.email}${note}`);
  }
  console.log('────────────────────────────────────────────────────────────');

  if (ok.length > 0) {
    console.log('\n  Login credentials:');
    for (const r of ok) {
      if (!r.note?.includes('reset')) {
        console.log(`    ${r.role.padEnd(8)}  ${r.email.padEnd(35)}  ${r.password}`);
      } else {
        console.log(`    ${r.role.padEnd(8)}  ${r.email.padEnd(35)}  (check email for password reset link)`);
      }
    }
    console.log();
  }

  if (failed.length > 0) {
    console.log('  ⚠️  Some users could not be processed. See errors above.');
    console.log('     For those users, manually add them in Firebase Console:\n');
    for (const r of failed) {
      console.log(`     Role: ${r.role}  Email: ${r.email}`);
    }
    console.log();
  }
}

main().catch((e) => {
  console.error('Fatal:', e.message);
  process.exit(1);
});
