import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';

// Konfigurasi Web CampusLost dari Firebase project yang sama dengan aplikasi Flutter.
const firebaseConfig = {
  apiKey: 'AIzaSyCiDWWBM4Srzy0FZvkdtO1kkMlKqQ83mvw',
  authDomain: 'campuslost-bd070.firebaseapp.com',
  projectId: 'campuslost-bd070',
  storageBucket: 'campuslost-bd070.firebasestorage.app',
  messagingSenderId: '469768605032',
  appId: '1:469768605032:web:7a7ae6c5330533824f9add',
  measurementId: 'G-5YYG7VFCS1',
};

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app);
