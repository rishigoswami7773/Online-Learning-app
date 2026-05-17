"use strict";

const {onCall, HttpsError} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const Razorpay = require("razorpay");
const crypto = require("crypto");

admin.initializeApp();

const getRazorpay = () => new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID,
  key_secret: process.env.RAZORPAY_KEY_SECRET,
});

exports.createRazorpayOrder = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Login required");
  }
  const {amount, courseId, courseName} = request.data;
  const razorpay = getRazorpay();
  const order = await razorpay.orders.create({
    amount: Math.round(amount * 100),
    currency: "INR",
    receipt: `rcpt_${courseId}_${Date.now()}`,
    notes: {courseId, courseName, userId: request.auth.uid},
  });
  return {orderId: order.id, amount: order.amount, currency: order.currency};
});

exports.addUserByAdmin = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Login required");
  }

  const callerDoc = await admin.firestore()
      .collection("users")
      .doc(request.auth.uid)
      .get();

  if (!callerDoc.exists || callerDoc.data()?.role !== "admin") {
    throw new HttpsError("permission-denied", "Admin access required");
  }

  const {email, name, role, password} = request.data;

  if (!email || !name || !role) {
    throw new HttpsError(
        "invalid-argument", "email, name, and role are required");
  }

  const validRoles = ["student", "mentor", "admin"];
  if (!validRoles.includes(role)) {
    throw new HttpsError(
        "invalid-argument", "role must be student, mentor, or admin");
  }

  const db = admin.firestore();
  const now = admin.firestore.FieldValue.serverTimestamp();

  // If user already exists in Auth, just update Firestore role
  try {
    const existing = await admin.auth().getUserByEmail(email);
    await db.collection("users").doc(existing.uid).set({
      uid: existing.uid,
      email,
      name,
      role,
      isVerified: true,
      status: "active",
      isBlocked: false,
    }, {merge: true});
    return {success: true, uid: existing.uid, existed: true};
  } catch (e) {
    if (e.code !== "auth/user-not-found") throw e;
  }

  // Generate password if not provided
  const suffix = Math.floor(1000 + Math.random() * 9000);
  const roleCapital = role.charAt(0).toUpperCase() + role.slice(1);
  const finalPassword = (password && password.length >= 6) ?
    password :
    `${roleCapital}@${suffix}`;

  const newUser = await admin.auth().createUser({
    email,
    password: finalPassword,
    displayName: name,
    emailVerified: true,
  });

  await db.collection("users").doc(newUser.uid).set({
    uid: newUser.uid,
    email,
    name,
    role,
    isVerified: true,
    status: "active",
    isBlocked: false,
    profileImage: "",
    createdAt: now,
  });

  return {
    success: true,
    uid: newUser.uid,
    generatedPassword: finalPassword,
    existed: false,
  };
});

exports.verifyPaymentAndEnroll = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Login required");
  }
  const {
    razorpayOrderId,
    razorpayPaymentId,
    razorpaySignature,
    courseId,
    courseName,
    amount,
  } = request.data;

  const secret = process.env.RAZORPAY_KEY_SECRET;
  const expected = crypto
      .createHmac("sha256", secret)
      .update(`${razorpayOrderId}|${razorpayPaymentId}`)
      .digest("hex");

  if (expected !== razorpaySignature) {
    throw new HttpsError("permission-denied", "Invalid payment signature");
  }

  const db = admin.firestore();
  const uid = request.auth.uid;
  const now = admin.firestore.FieldValue.serverTimestamp();

  await db.collection("payments").add({
    userId: uid,
    courseId,
    courseName,
    amount,
    currency: "INR",
    orderId: razorpayOrderId,
    paymentId: razorpayPaymentId,
    status: "success",
    paidAt: now,
  });

  await db.collection("enrollments").doc(`${uid}_${courseId}`).set({
    studentId: uid,
    courseId,
    courseTitle: courseName,
    status: "active",
    enrolledAt: now,
    paymentId: razorpayPaymentId,
    paid: true,
  });

  await db.collection("activityLogs").add({
    userId: uid,
    action: "course_purchased",
    courseId,
    courseName,
    amount,
    timestamp: now,
  });

  return {success: true};
});
