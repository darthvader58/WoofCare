// Keep this version aligned with firebase_core_web's supported Firebase JS SDK.
importScripts('https://www.gstatic.com/firebasejs/12.15.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/12.15.0/firebase-messaging-compat.js');

// Firebase web configuration is public client configuration, not a secret.
firebase.initializeApp({
  apiKey: 'AIzaSyCvzQDGbU8ndDGJ3mGCeWA0mSsCNRhsbt0',
  appId: '1:506976961145:web:551d2afd7dc9f0e8240aa8',
  authDomain: 'woofcare-a9fac.firebaseapp.com',
  measurementId: 'G-FJDV4K81CK',
  messagingSenderId: '506976961145',
  projectId: 'woofcare-a9fac',
  storageBucket: 'woofcare-a9fac.firebasestorage.app',
});

// firebase_messaging uses this worker for notifications received in the
// background. Firebase displays notification payloads automatically.
const messaging = firebase.messaging();
