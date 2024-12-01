/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendNotification = functions.firestore
    .document('chatrooms/{roomId}/messages/{messageId}')
    .onCreate(async (snap, context) => {
        const message = snap.data();
        const roomId = context.params.roomId;
        const messageId = context.params.messageId;

        // Dapatkan token FCM pengguna
        const userToken = await admin.firestore().collection('users').doc(message.senderId).get();
        const fcmToken = userToken.data().fcmToken;

        // Kirim notifikasi
        const notification = {
            title: 'Pesan baru dari ' + message.senderId,
            body: message.messageContent,
        };

        await admin.messaging().sendToDevice(fcmToken, { notification });
    });