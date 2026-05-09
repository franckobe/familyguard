# Sprint 1 — Fondations & Auth

**Date:** 2026-05-09  
**Projet:** FamilyGuard  
**Scope:** Initialisation Flutter + Firebase, écrans auth complets, Cloud Function `onUserCreated`, Firestore rules v1

---

## 1. Architecture & structure

Monorepo Flutter + Cloud Functions dans le même dossier. `flutter create` génère la racine (Android + iOS + Web). Les Cloud Functions sont dans `functions/` (Node.js 20 + TypeScript). `firebase.json` lie les deux.

```
familyguard/
├── lib/
│   ├── core/
│   │   ├── firebase/        ← firebase_options.dart (généré par flutterfire configure)
│   │   ├── router/          ← go_router + auth guard
│   │   └── theme/           ← couleurs, typographie
│   ├── features/
│   │   └── auth/
│   │       ├── models/      ← AppUser (freezed + fromFirestore/toFirestore)
│   │       ├── providers/   ← authStateProvider (StreamProvider<User?>)
│   │       │               ← currentUserProvider (StreamProvider<AppUser?>)
│   │       └── screens/     ← SplashScreen, LoginScreen, RegisterScreen,
│   │                           ForgotPasswordScreen, EditProfileScreen
│   └── main.dart
├── functions/
│   ├── src/
│   │   └── auth/
│   │       └── onUserCreated.ts
│   ├── package.json
│   ├── tsconfig.json
│   └── index.ts
├── firestore.rules
├── firestore.indexes.json
├── firebase.json
└── pubspec.yaml
```

---

## 2. Flux Auth Flutter

### State management

- `authStateProvider` : `StreamProvider<User?>` — écoute `FirebaseAuth.instance.authStateChanges()`
- `currentUserProvider` : `StreamProvider<AppUser?>` — écoute `/users/{uid}` dans Firestore (null si non authentifié)

### Navigation (go_router)

```
/splash          → SplashScreen (2s, redirect selon authState)
/login           → LoginScreen
/register        → RegisterScreen
/forgot-password → ForgotPasswordScreen
/home            → HomeScreen (placeholder Sprint 2)
/profile/edit    → EditProfileScreen
```

**Guard auth :** Si `authState == null` → redirect `/login`. Si authentifié et route `/login` ou `/register` → redirect `/home`.

### Flux inscription

1. Utilisateur remplit email + mot de passe → `FirebaseAuth.createUserWithEmailAndPassword`
2. Cloud Function `onUserCreated` crée `/users/{uid}` automatiquement
3. App redirige vers `/home`
4. Toast invite à compléter le profil (prénom, nom)

### Flux connexion

1. Email + mot de passe → `FirebaseAuth.signInWithEmailAndPassword`
2. App charge `/users/{uid}` via Firestore
3. Mise à jour du `fcmToken` dans `/users/{uid}` (Sprint 4)
4. Redirect `/home`

### EditProfileScreen

- Champs : prénom, nom, téléphone (optionnel), photo
- Upload photo : `image_picker` → Firebase Storage (`avatars/{uid}.jpg`) → màj `avatarUrl` dans `/users/{uid}`
- Pas de validation complexe : les champs vides sont autorisés (complétion progressive)

---

## 3. Cloud Function `onUserCreated`

**Trigger :** `functions.auth.user().onCreate`  
**Runtime :** Node.js 20

```typescript
// functions/src/auth/onUserCreated.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';

export const onUserCreated = functions.auth.user().onCreate(async (user) => {
  const firestore = admin.firestore();
  await firestore.collection('users').doc(user.uid).set({
    uid: user.uid,
    email: user.email ?? '',
    firstName: '',
    lastName: '',
    phone: null,
    avatarUrl: null,
    fcmToken: null,
    createdAt: FieldValue.serverTimestamp(),
  });
});
```

`firstName` et `lastName` sont vides à la création — l'utilisateur les renseigne dans `EditProfileScreen`. Pas de parsing du `displayName` Google pour le MVP.

---

## 4. Modèle `AppUser`

```dart
// lib/features/auth/models/app_user.dart
@freezed
class AppUser with _$AppUser {
  const factory AppUser({
    required String uid,
    required String email,
    required String firstName,
    required String lastName,
    String? phone,
    String? avatarUrl,
    String? fcmToken,
    required DateTime createdAt,
  }) = _AppUser;

  factory AppUser.fromFirestore(DocumentSnapshot doc) { ... }
  Map<String, dynamic> toFirestore() { ... }
}
```

---

## 5. Firestore rules v1

Seule la collection `/users` est active au Sprint 1.

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## 6. firebase.json

```json
{
  "hosting": {
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"]
  },
  "functions": [
    {
      "source": "functions",
      "codebase": "default",
      "runtime": "nodejs20"
    }
  ],
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  }
}
```

---

## 7. Thème

Palette neutre bleu-gris définie dans `lib/core/theme/` :

- Primary : `#4A6FA5` (bleu-gris)
- Surface : `#F8F9FA`
- Error : `#DC3545`
- Typographie : `TextTheme` Material 3 par défaut

---

## 8. Étapes de setup Firebase (manuelles)

À exécuter dans le terminal après génération du code :

```bash
# 1. Installer FlutterFire CLI
dart pub global activate flutterfire_cli

# 2. Créer le projet Firebase (Blaze plan requis pour les Functions)
firebase projects:create familyguard-app --display-name "FamilyGuard"

# 3. Activer les services dans la console Firebase :
#    - Authentication (email/password)
#    - Firestore (mode production)
#    - Storage
#    - Functions

# 4. Générer firebase_options.dart
flutterfire configure \
  --project=familyguard-app \
  --platforms=android,ios,web \
  --android-package-name=com.familyguard.app \
  --ios-bundle-id=com.familyguard.app
```

---

## 9. Hors scope Sprint 1

- FCM token update (Sprint 4)
- Google Sign-In (déféré à un sprint ultérieur — Sprint 1 couvre email/password uniquement)
- Deep links
- Push notifications
- Rôle parent/caregiver (Sprint 3)
