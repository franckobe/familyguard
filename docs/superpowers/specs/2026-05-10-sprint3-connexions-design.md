# Sprint 3 — Connexions : Design Spec

**Date :** 2026-05-10  
**Statut :** Validé

---

## Contexte

Sprint 3 du projet FamilyGuard. Les sprints 1 (Auth) et 2 (Children) sont terminés. Ce sprint implémente le système de connexions de confiance entre parents et caregivers, ainsi qu'une refonte de la navigation vers un bottom nav bar persistant.

---

## Décisions clés

| Sujet | Décision |
|---|---|
| Deep link invite | URL web `https://familyguard.app/invite/{code}` — pas de Firebase Dynamic Links |
| Rôles | Double rôle possible : un user peut être parent ET caregiver |
| Navigation | Bottom nav bar (StatefulShellRoute) introduit dès ce sprint |
| Connexions UI | Deux onglets dans ConnectionsListScreen : "Mes babysitters" / "Mes familles" |
| Push notifications | Reportées au Sprint 5 — stub `onConnectionUpdated` présent |
| Invite flow | Route `/invite/:code` publique (accessible sans auth) |

---

## Section 1 — Architecture & Navigation

### Structure des routes (go_router)

```
StatefulShellRoute  (bottom nav — 3 branches)
├── /children                  → ChildrenListScreen
│   ├── /children/:id          → ChildDetailScreen
│   └── /children/:id/edit     → EditChildScreen
├── /connections               → ConnectionsListScreen
│   ├── /connections/invite    → InviteScreen
│   └── /connections/:id       → ConnectionDetailScreen
└── /guard-requests            → GuardRequestsPlaceholderScreen (vide, Sprint 4)

Routes hors ShellRoute (pas de bottom nav)
├── /splash          (public)
├── /login           (public)
├── /register        (public)
├── /forgot-password (public)
├── /invite/:code    (public) ← NOUVELLE — accessible sans auth
└── /profile/edit    (protégée)
```

### Comportement du guard auth

Le guard existant redirige tout utilisateur non authentifié vers `/login`, **sauf** pour la route `/invite/:code`. Cette route est publique : `InvitationReceivedScreen` gère lui-même l'état non authentifié (affiche le bouton "Se connecter" ou "Créer un compte" selon le contexte, le code restant dans l'URL).

### Bottom nav bar

Trois onglets persistants :
- **Enfants** (icône `baby`) — branche `/children`
- **Connexions** (icône `users`) — branche `/connections`
- **Gardes** (icône `calendar`) — branche `/guard-requests`, placeholder jusqu'au Sprint 4

Implémentation via `StatefulShellRoute` de go_router pour conserver l'état de chaque branche lors du changement d'onglet.

---

## Section 2 — Feature Connexions (Flutter)

### Structure des fichiers

```
lib/features/connections/
├── models/
│   └── connection.dart         (+ connection.freezed.dart)
├── repository/
│   └── connection_repository.dart
├── providers/
│   └── connection_providers.dart
└── screens/
    ├── connections_list_screen.dart
    ├── invite_screen.dart
    ├── connection_detail_screen.dart
    └── invitation_received_screen.dart
```

### Model — `Connection`

```dart
@freezed
class Connection with _$Connection {
  factory Connection({
    required String id,
    required String parentId,
    String? caregiverId,
    required ConnectionStatus status,
    required String inviteCode,
    required String inviteEmail,
    String? message,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Connection;

  factory Connection.fromFirestore(DocumentSnapshot doc) { ... }
  Map<String, dynamic> toFirestore() { ... }
}

enum ConnectionStatus { pending, active, declined, blocked }
```

### Repository — `ConnectionRepository`

| Méthode | Description |
|---|---|
| `streamAsParent(parentId)` | Stream des connexions où l'user est parent |
| `streamAsCaregiver(caregiverId)` | Stream des connexions où l'user est caregiver |
| `createInvite({email, message})` | Crée le doc Firestore — `inviteCode` généré par `onConnectionCreated` |

### Providers (Riverpod)

| Provider | Type | Description |
|---|---|---|
| `connectionsAsParentProvider` | `StreamProvider<List<Connection>>` | Connexions en tant que parent |
| `connectionsAsCaregiverProvider` | `StreamProvider<List<Connection>>` | Connexions en tant que caregiver |
| `acceptInviteProvider` | `AsyncNotifierProvider` | Appelle la callable `acceptInvite(inviteCode)` |

### Écrans

**`ConnectionsListScreen`**  
Deux onglets avec `GlassTabBar` (widget existant) :
- *Mes babysitters* — liste des connexions où `parentId == uid`, bouton FAB `+` → `InviteScreen`
- *Mes familles* — liste des connexions où `caregiverId == uid`, read-only

Chaque item : avatar initiales + nom (ou email si caregiver pas encore inscrit) + `StatusBadge`.

**`InviteScreen`**  
Formulaire simple : champ email (requis, validé) + champ message (optionnel). Bouton Envoyer → `ConnectionRepository.createInvite()` → retour sur la liste.

**`ConnectionDetailScreen`**  
Détail d'une connexion. Actions selon rôle :
- Parent : bouton Bloquer (`status → blocked`)
- Caregiver : bouton Quitter la connexion (`status → declined`)

**`InvitationReceivedScreen`**  
Route : `/invite/:code`. Accessible sans auth.
- Appelle la callable `getInviteDetails(inviteCode)` pour afficher le prénom du parent et l'email destinataire
- Si non authentifié : boutons "Se connecter" et "Créer un compte" → redirige vers `/login` ou `/register`, l'URL `/invite/:code` est préservée dans le navigateur web
- Si authentifié : bouton "Accepter" → appelle callable `acceptInvite(inviteCode)` → `status → active` → redirige vers `/connections`
- Pas de bouton "Refuser" — avant acceptation, `caregiverId` est null et les règles Firestore bloquent toute mise à jour client. Ignorer = ne pas agir (MVP)
- Gestion d'erreur : code invalide / déjà utilisé (invitation déjà acceptée)

---

## Section 3 — Cloud Functions

### `onConnectionCreated` (trigger Firestore onCreate)

**Déclencheur :** création d'un document dans `/connections`

**Logique :**
1. Génère un `inviteCode` (UUID v4)
2. Met à jour le document : `{ inviteCode, updatedAt }`
3. Récupère le profil du parent (`/users/{parentId}`) pour le prénom
4. Écrit dans `/mail/{id}` :
   ```json
   {
     "to": "inviteEmail",
     "message": {
       "subject": "{firstName} t'invite sur FamilyGuard",
       "html": "<a href='https://familyguard.app/invite/{inviteCode}'>Accepter l'invitation</a>"
     }
   }
   ```

### `getInviteDetails` (callable HTTPS — sans auth requise)

**Paramètre :** `{ inviteCode: string }`

**Logique :**
1. Query Firestore : `connections.where('inviteCode', '==', inviteCode).limit(1)`
2. Si non trouvé → erreur `not-found`
3. Si `status != 'pending'` → erreur `already-used`
4. Retourne uniquement `{ parentFirstName, inviteEmail, status }` — jamais le document complet

### `acceptInvite` (callable HTTPS — auth requise)

**Paramètre :** `{ inviteCode: string }`

**Logique :**
1. Vérifie que l'appelant est authentifié
2. Query : `connections.where('inviteCode', '==', inviteCode).limit(1)`
3. Si non trouvé → erreur `not-found`
4. Si `status != 'pending'` → erreur `already-used`
5. Si `caregiverId != null` → erreur `already-claimed`
6. Mise à jour atomique : `{ caregiverId: auth.uid, status: 'active', updatedAt: now() }`
7. Retourne `{ connectionId }`

**Note :** On ne valide pas que l'email de l'appelant correspond à `inviteEmail` — le code unique suffit comme preuve d'autorisation pour le MVP.

### `onConnectionUpdated` (trigger Firestore onUpdate — stub)

**Déclencheur :** mise à jour d'un document dans `/connections`

Vérifie si `status` passe de `pending` à `active`. Si oui : no-op pour l'instant (log uniquement). La push notification au parent sera ajoutée au Sprint 5.

---

## Section 4 — Firestore rules v3

Ajout des règles pour `/connections`. Les règles `users` et `children` restent inchangées.

```javascript
match /connections/{connectionId} {
  allow read: if isAuth() &&
    (request.auth.uid == resource.data.parentId ||
     request.auth.uid == resource.data.caregiverId);

  allow create: if isAuth() &&
    isOwner(request.resource.data.parentId);

  allow update: if isAuth() &&
    (request.auth.uid == resource.data.parentId ||
     request.auth.uid == resource.data.caregiverId);
}
```

**Note :** `acceptInvite` et `getInviteDetails` sont des callables Cloud Functions opérant avec les droits admin — les règles Firestore ne s'appliquent pas à ces opérations. La règle `update` côté client couvre uniquement les actions directes (bloquer, quitter).

---

## Index Firestore requis (firestore.indexes.json)

```json
{ "collectionGroup": "connections", "fields": [
    { "fieldPath": "parentId", "order": "ASCENDING" },
    { "fieldPath": "status", "order": "ASCENDING" },
    { "fieldPath": "createdAt", "order": "DESCENDING" }
]},
{ "collectionGroup": "connections", "fields": [
    { "fieldPath": "caregiverId", "order": "ASCENDING" },
    { "fieldPath": "status", "order": "ASCENDING" },
    { "fieldPath": "createdAt", "order": "DESCENDING" }
]}
```

---

## Hors scope Sprint 3

- Push notifications (Sprint 5)
- Blocage / gestion des connexions `blocked` dans l'UI (Sprint 5)
- Récapitulatif email "invitation acceptée" (Sprint 5)
- Deep link natif iOS/Android (hors MVP)
