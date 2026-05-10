# CLAUDE.md — FamilyGuard

Document de référence pour Claude Code. À relire au début de chaque session de travail.

---

## Design du projet
Voir DESIGN.md 

---

## Vision du projet

FamilyGuard est une application mobile et web permettant à des parents d'organiser la garde de leurs enfants avec leurs proches ou babysitters de confiance. Le parent invite des gardes dans son réseau privé ; les gardes peuvent accepter ou refuser les demandes. Tout reste dans un cercle fermé — pas de mise en relation publique.

---

## Stack technique

| Couche | Technologie |
|---|---|
| Frontend / Mobile / Web | Flutter (Dart) |
| Auth | Firebase Auth (email/password + Google) |
| Base de données | Cloud Firestore |
| Stockage fichiers | Firebase Storage (avatars) |
| Logique métier & crons | Cloud Functions (Node.js 20) |
| Notifications push | Firebase Cloud Messaging (FCM) |
| Emails transactionnels | Firebase Extension "Trigger Email" + Resend |
| Hosting web | Firebase Hosting |

Pas de backend custom. Toute la logique métier sensible (validation, notifications, expiration des demandes) passe par des Cloud Functions déclenchées par Firestore ou par HTTP callable.

---

## Structure du projet

```
familyguard/
├── functions/                  ← Cloud Functions (Node.js 20 + TypeScript)
│   ├── src/
│   │   ├── auth/               ← onUserCreated
│   │   ├── connections/        ← onInviteAccepted, sendInviteEmail
│   │   ├── guard_requests/     ← onRequestCreated, expireRequests (cron)
│   │   └── notifications/      ← sendPushNotification helper
│   ├── package.json
│   └── tsconfig.json
├── lib/                        ← Flutter app
│   ├── core/
│   │   ├── firebase/           ← initialisation Firebase, instances
│   │   ├── router/             ← go_router, guards auth
│   │   └── theme/              ← couleurs, typographie
│   ├── features/
│   │   ├── auth/
│   │   ├── children/
│   │   ├── connections/
│   │   └── guard_requests/
│   └── main.dart
├── firebase.json
├── firestore.rules
├── firestore.indexes.json
└── pubspec.yaml
```

Chaque feature suit la structure :
```
features/guard_requests/
├── models/          ← classes Dart + fromFirestore / toFirestore
├── providers/       ← Riverpod (AsyncNotifier, StreamProvider)
├── screens/
└── widgets/
```

---

## Modèle de données Firestore

### `/users/{userId}`

Créé automatiquement par la Cloud Function `onUserCreated` (Auth trigger).

```
{
  uid:        string,        // = Firebase Auth UID
  email:      string,
  firstName:  string,
  lastName:   string,
  phone:      string | null,
  avatarUrl:  string | null,
  fcmToken:   string | null, // mis à jour au login depuis Flutter
  createdAt:  Timestamp
}
```

---

### `/children/{childId}`

```
{
  parentId:    string,
  firstName:   string,
  lastName:    string,
  birthDate:   Timestamp,
  avatarUrl:   string | null,
  allergies:   string | null,
  medicalInfo: string | null,
  notes:       string | null,
  archived:    boolean,       // true si supprimé mais gardes passées existantes
  createdAt:   Timestamp,
  updatedAt:   Timestamp
}
```

Règle : lecture/écriture uniquement si `request.auth.uid == resource.data.parentId`.

---

### `/connections/{connectionId}`

Lien de confiance entre un parent et un caregiver.

```
{
  parentId:    string,
  caregiverId: string | null, // null jusqu'à ce que l'invité crée son compte
  status:      'pending' | 'active' | 'declined' | 'blocked',
  inviteCode:  string,        // code unique généré à la création
  inviteEmail: string,
  message:     string | null,
  createdAt:   Timestamp,
  updatedAt:   Timestamp
}
```

Index composites requis :
- `parentId ASC + status ASC + createdAt DESC`
- `caregiverId ASC + status ASC + createdAt DESC`

---

### `/guard_requests/{requestId}`

```
{
  parentId:       string,
  childId:        string,
  childSnapshot:  {            // copie dénormalisée pour les listes
    firstName:  string,
    lastName:   string,
    avatarUrl:  string | null,
    birthDate:  Timestamp
  },
  type:           'hourly' | 'half_day' | 'daily' | 'night' | 'weekend',
  startAt:        Timestamp,
  endAt:          Timestamp,
  location:       string | null,
  notes:          string | null,
  status:         'open' | 'accepted' | 'done' | 'cancelled' | 'expired',
  recurrenceType: 'none' | 'custom',
  recipientIds:   string[],    // UIDs des caregivers destinataires
  confirmedId:    string | null,
  createdAt:      Timestamp,
  updatedAt:      Timestamp
}
```

Index composites requis :
- `parentId ASC + status ASC + startAt ASC`
- `recipientIds array-contains + status ASC + startAt ASC`

---

### `/guard_requests/{requestId}/occurrences/{occurrenceId}`

Sous-collection — chaque occurrence d'une garde récurrente.

```
{
  startAt:   Timestamp,
  endAt:     Timestamp,
  status:    'planned' | 'done' | 'cancelled',
  notes:     string | null,
  createdAt: Timestamp
}
```

---

### `/guard_requests/{requestId}/responses/{caregiverId}`

L'ID du document = UID du caregiver (un seul document par caregiver par demande).

```
{
  caregiverId: string,
  caregiverSnapshot: {
    firstName: string,
    lastName:  string,
    avatarUrl: string | null
  },
  status:      'accepted' | 'declined',
  message:     string | null,
  respondedAt: Timestamp
}
```

---

### `/guard_requests/{requestId}/recipients/{caregiverId}`

Tracking : à qui la demande a été envoyée et si elle a été lue.

```
{
  caregiverId: string,
  sentAt:      Timestamp,
  readAt:      Timestamp | null
}
```

Écrit uniquement par Cloud Functions, jamais depuis le client.

---

### `/mail/{mailId}`

Collection spéciale lue par l'extension "Trigger Email" pour l'envoi des emails. Écrite par les Cloud Functions uniquement.

```
{
  to:      string,
  message: { subject: string, html: string }
}
```

---

## Cloud Functions

### Triggers Auth / Firestore

| Fonction | Déclencheur | Rôle |
|---|---|---|
| `onUserCreated` | Auth onCreate | Crée `/users/{uid}` |
| `onConnectionCreated` | connections onCreate | Envoie l'email d'invitation |
| `onConnectionUpdated` | connections onUpdate | Notifie le parent quand accepté |
| `onGuardRequestCreated` | guard_requests onCreate | Push notif à chaque recipientId |
| `onGuardResponseCreated` | responses onCreate | Push notif au parent |
| `onGuardRequestUpdated` | guard_requests onUpdate | Push notif au caregiver confirmé |

### Callable Functions (appelées depuis Flutter)

| Fonction | Rôle |
|---|---|
| `acceptInvite(inviteCode)` | Lie le caregiver à la connexion → active |
| `confirmCaregiver(requestId, caregiverId)` | Parent confirme → request accepted |
| `cancelRequest(requestId)` | Annule + notifie les caregivers |

### Scheduled (crons)

| Fonction | Fréquence | Rôle |
|---|---|---|
| `expireGuardRequests` | Tous les jours à 6h | Passe à `expired` les demandes `open` dépassées |

---

## Règles de sécurité Firestore (firestore.rules)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function isAuth() {
      return request.auth != null;
    }
    function isOwner(uid) {
      return request.auth.uid == uid;
    }

    match /users/{userId} {
      allow read: if isAuth();
      allow write: if isOwner(userId);
    }

    match /children/{childId} {
      allow read, write: if isAuth() && isOwner(resource.data.parentId);
      allow create: if isAuth() && isOwner(request.resource.data.parentId);
    }

    match /connections/{connectionId} {
      allow read: if isAuth() &&
        (request.auth.uid == resource.data.parentId ||
         request.auth.uid == resource.data.caregiverId);
      allow create: if isAuth() && isOwner(request.resource.data.parentId);
      allow update: if isAuth() &&
        (request.auth.uid == resource.data.parentId ||
         request.auth.uid == resource.data.caregiverId);
    }

    match /guard_requests/{requestId} {
      allow read: if isAuth() &&
        (request.auth.uid == resource.data.parentId ||
         request.auth.uid in resource.data.recipientIds);
      allow create: if isAuth() && isOwner(request.resource.data.parentId);
      allow update: if isAuth() && isOwner(resource.data.parentId);

      match /occurrences/{occurrenceId} {
        allow read, write: if isAuth() &&
          isOwner(get(/databases/$(database)/documents/guard_requests/$(requestId)).data.parentId);
      }

      match /responses/{caregiverId} {
        allow read: if isAuth() &&
          (request.auth.uid == get(/databases/$(database)/documents/guard_requests/$(requestId)).data.parentId ||
           request.auth.uid == caregiverId);
        allow create, update: if isAuth() && isOwner(caregiverId);
      }

      match /recipients/{caregiverId} {
        allow read: if isAuth() &&
          (request.auth.uid == get(/databases/$(database)/documents/guard_requests/$(requestId)).data.parentId ||
           request.auth.uid == caregiverId);
        allow write: if false; // Cloud Functions uniquement
      }
    }

    match /mail/{mailId} {
      allow read, write: if false; // Cloud Functions uniquement
    }
  }
}
```

---

## Plan des features MVP

### Feature 1 — Auth

Écrans : `SplashScreen`, `LoginScreen`, `RegisterScreen`, `ForgotPasswordScreen`, `EditProfileScreen`

- Inscription email/password → Cloud Function crée `/users/{uid}`
- Login → récupère le profil Firestore + met à jour fcmToken
- Redirection auto selon état auth (go_router redirect)

---

### Feature 2 — Enfants

Écrans : `ChildrenListScreen`, `AddChildScreen`, `EditChildScreen`, `ChildDetailScreen`

- CRUD Firestore sur `/children`
- Upload photo → Firebase Storage → avatarUrl dans le document
- Suppression : si gardes existantes → `archived: true`, sinon delete physique

---

### Feature 3 — Connexions

Écrans : `ConnectionsListScreen`, `InviteScreen`, `InvitationReceivedScreen`, `ConnectionDetailScreen`

Flux d'invitation :
```
Parent → crée Connection (status: pending, inviteCode généré)
       → Cloud Function envoie email avec lien deep link
Caregiver → clique app://invite/{inviteCode}
          → s'inscrit ou se connecte
          → appelle callable acceptInvite(inviteCode)
          → Connection passe pending → active
Parent    → reçoit push notif "Dupont a rejoint ton réseau"
```

---

### Feature 4 — Demandes de garde

**Côté parent**

Écrans : `GuardRequestsListScreen`, `CreateGuardRequestScreen` (stepper 3 étapes), `GuardRequestDetailScreen`

Stepper création :
1. Enfant + type + dates/heures
2. Si récurrent : ajouter des occurrences (dates/heures libres)
3. Choisir les destinataires (parmi connexions `active`)

Détail : voir les réponses (accepté/refusé/pas encore répondu), bouton confirmer un caregiver.

**Côté caregiver**

Écrans : `IncomingRequestsScreen`, `IncomingRequestDetailScreen`, `MyScheduleScreen`

- Stream Firestore en temps réel (`recipientIds array-contains uid`)
- Boutons accepter / refuser avec message optionnel
- Vue agenda des gardes confirmées

---

## Règles métier

1. **Connexion obligatoire** : `recipientIds` ne peut contenir que des UIDs dont la connexion est `active`. Vérifié côté Flutter ET dans `onGuardRequestCreated`.
2. **Un seul confirmé** : `confirmCaregiver` vérifie atomiquement que `status == 'open'` avant de confirmer.
3. **Occurrences indépendantes** : annuler une occurrence ne change pas les autres ni le statut de la demande parente.
4. **Soft delete enfants** : `archived: true` si des gardes passées existent.
5. **Visibilité stricte** : les règles Firestore garantissent qu'un caregiver ne voit que les demandes où il est dans `recipientIds`.
6. **Dénormalisation** : `childSnapshot` et `caregiverSnapshot` sont mis à jour par Cloud Function si le profil source change.

---

## Dépendances Flutter (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^3.0.0
  firebase_auth: ^5.0.0
  cloud_firestore: ^5.0.0
  cloud_functions: ^5.0.0
  firebase_storage: ^12.0.0
  firebase_messaging: ^15.0.0
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0
  go_router: ^14.0.0
  freezed_annotation: ^2.4.0
  json_annotation: ^4.9.0
  cached_network_image: ^3.3.0
  image_picker: ^1.1.0
  intl: ^0.19.0

dev_dependencies:
  build_runner: ^2.4.0
  freezed: ^2.5.0
  json_serializable: ^6.8.0
  riverpod_generator: ^2.4.0
  flutter_lints: ^4.0.0
```

---

## Conventions Flutter

- Streams Firestore → `StreamProvider` Riverpod (temps réel natif, pas de polling)
- Modèles : `freezed` + `fromFirestore` / `toFirestore` manuels
- Navigation : `go_router` avec `ShellRoute` pour la bottom nav
- Nommage Firestore : `snake_case` pour les collections et champs
- Un fichier par écran/widget, pas de fichiers fourre-tout

---

## Variables d'environnement Cloud Functions

Stockées dans Firebase Secret Manager, accédées via `defineSecret()` :

```
RESEND_API_KEY
APP_URL           # https://familyguard.app (liens dans les emails)
```

La config Firebase client (`google-services.json`, `GoogleService-Info.plist`, `firebase_options.dart`) est générée par la FlutterFire CLI — ne pas commiter les fichiers sensibles.

---

## Ordre de développement recommandé

```
Sprint 1 — Fondations
  ✦ Création projet Firebase (Auth, Firestore, Storage, Functions, Hosting)
  ✦ FlutterFire CLI : firebase_options.dart
  ✦ go_router + thème + structure features
  ✦ Cloud Function onUserCreated
  ✦ Écrans auth complets
  ✦ firestore.rules v1

Sprint 2 — Enfants
  ✦ CRUD /children + upload avatar Storage
  ✦ Écrans children Flutter
  ✦ firestore.rules v2

Sprint 3 — Connexions
  ✦ Callable acceptInvite + email invitation
  ✦ Deep link app://invite/{code}
  ✦ Écrans connexions Flutter
  ✦ firestore.rules v3

Sprint 4 — Demandes de garde
  ✦ Création demande (stepper) + occurrences
  ✦ Vue caregiver (incoming + répondre)
  ✦ Vue parent (suivi + confirmer)
  ✦ Cloud Functions push notifs
  ✦ firestore.rules v4

Sprint 5 — Polish MVP
  ✦ Cron expiration demandes
  ✦ Emails recap (invitation acceptée, garde confirmée)
  ✦ Build iOS + Android + Firebase Hosting (web)
```

---

## Hors scope MVP

À ne pas implémenter en phase 1 (le modèle de données ne les bloque pas) :

- Chat temps réel
- Évaluations post-garde
- Paiement intégré
- Notifications SMS
- Mode hors-ligne étendu

---

*Ce fichier est la source de vérité du projet. En cas de doute sur une règle métier, une structure Firestore ou une Cloud Function, se référer à ce document avant de coder.*
