importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-messaging.js");

firebase.initializeApp({
  apiKey: 'AIzaSyA_aU9Vlj0nBABHj-akncyMoRnFbgnwx9U',
  appId: '1:773624019931:web:6920e872af2088392e05fe',
  messagingSenderId: '773624019931',
  projectId: 'journee-flutter',
  authDomain: 'journee-flutter.firebaseapp.com',
  storageBucket: 'journee-flutter.appspot.com',
  measurementId: 'G-23J4EQ92GX',
});

const messaging = firebase.messaging();

// Optional:
messaging.onBackgroundMessage((message) => {
  console.log("onBackgroundMessage", message);
});