// Import the functions you need from the SDKs you need
import { getApp, getApps, initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";

// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
  apiKey: "AIzaSyDH6V1XK8fS19oJZmzcDWuumEXLpWSOPkY",
  authDomain: "champions-ring-app.firebaseapp.com",
  projectId: "champions-ring-app",
  storageBucket: "champions-ring-app.firebasestorage.app",
  messagingSenderId: "1084769880827",
  appId: "1:1084769880827:web:e05c807de7f0fcf3fc7e5e",
  measurementId: "G-6RZZKBEP6G"
};

// Reuse the app during Next.js hot reloads. Analytics is not needed for login.
export const app = getApps().length ? getApp() : initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app, "default");
