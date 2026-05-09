# Sprint 1 — Fondations & Auth Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Initialiser le projet Flutter + Firebase et implémenter l'authentification complète (email/password) avec la Cloud Function `onUserCreated`.

**Architecture:** Monorepo Flutter + Cloud Functions. Firebase Auth gère l'identité ; Firestore stocke les profils utilisateurs créés automatiquement par une Cloud Function Auth `onCreate`. Riverpod (`StreamProvider`) expose l'état auth en temps réel. `go_router` gère la navigation avec un guard auth basé sur `refreshListenable`.

**Tech Stack:** Flutter 3.38.5 / Dart 3.10.4, Firebase Auth 5.x, Cloud Firestore 5.x, Firebase Storage 12.x, Riverpod 2.5, go_router 14, freezed 2.5, Cloud Functions Node.js 20 + TypeScript 5, Jest 29.

---

## File Map

```
familyguard/
├── lib/
│   ├── main.dart                                            ← MODIFY (overwrite default)
│   ├── core/
│   │   ├── firebase/
│   │   │   └── firebase_options.dart                       ← CREATE (placeholder, remplacé par flutterfire)
│   │   ├── theme/
│   │   │   └── app_theme.dart                              ← CREATE
│   │   └── router/
│   │       ├── app_router.dart                             ← CREATE
│   │       └── home_placeholder_screen.dart                ← CREATE
│   └── features/
│       └── auth/
│           ├── models/
│           │   └── app_user.dart                           ← CREATE (+ app_user.freezed.dart généré)
│           ├── providers/
│           │   └── auth_providers.dart                     ← CREATE
│           └── screens/
│               ├── splash_screen.dart                      ← CREATE
│               ├── login_screen.dart                       ← CREATE
│               ├── register_screen.dart                    ← CREATE
│               ├── forgot_password_screen.dart             ← CREATE
│               └── edit_profile_screen.dart                ← CREATE
├── test/
│   └── features/
│       └── auth/
│           └── models/
│               └── app_user_test.dart                      ← CREATE
├── functions/
│   ├── src/
│   │   ├── index.ts                                        ← CREATE
│   │   └── auth/
│   │       ├── on_user_created.ts                          ← CREATE
│   │       └── __tests__/
│   │           └── on_user_created.test.ts                 ← CREATE
│   ├── package.json                                        ← CREATE
│   └── tsconfig.json                                       ← CREATE
├── pubspec.yaml                                            ← MODIFY
├── firebase.json                                           ← CREATE
├── firestore.rules                                         ← CREATE
└── firestore.indexes.json                                  ← CREATE
```

---

## Task 1: Initialize Flutter project

**Files:**
- Generate: tout le scaffold Flutter dans le répertoire courant

- [ ] **Step 1: Run flutter create**

```bash
flutter create \
  --project-name familyguard \
  --org com.familyguard \
  --platforms android,ios,web \
  --force \
  .
```

Expected: "All done!" avec la liste des fichiers créés. Ignore les warnings sur les fichiers existants (CLAUDE.md, README.md).

- [ ] **Step 2: Create feature directory structure**

```bash
mkdir -p \
  lib/core/firebase \
  lib/core/theme \
  lib/core/router \
  lib/features/auth/models \
  lib/features/auth/providers \
  lib/features/auth/screens \
  lib/features/children/models \
  lib/features/children/providers \
  lib/features/children/screens \
  lib/features/connections/models \
  lib/features/connections/providers \
  lib/features/connections/screens \
  lib/features/guard_requests/models \
  lib/features/guard_requests/providers \
  lib/features/guard_requests/screens \
  test/features/auth/models
```

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "chore: initialize Flutter project (Android, iOS, Web)"
```

---

## Task 2: Configure pubspec.yaml

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Replace pubspec.yaml**

```yaml
name: familyguard
description: Application de gestion de garde d'enfants en cercle privé.
version: 1.0.0+1
publish_to: 'none'

environment:
  sdk: '>=3.0.0 <4.0.0'

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
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.0
  freezed: ^2.5.0
  json_serializable: ^6.8.0
  riverpod_generator: ^2.4.0
  flutter_lints: ^4.0.0
  mocktail: ^0.3.0
  fake_cloud_firestore: ^3.0.0

flutter:
  uses-material-design: true
```

- [ ] **Step 2: Install dependencies**

```bash
flutter pub get
```

Expected: "Got dependencies!" sans erreurs.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: configure pubspec.yaml with all Sprint 1 dependencies"
```

---

## Task 3: Initialize Cloud Functions

**Files:**
- Create: `functions/package.json`
- Create: `functions/tsconfig.json`
- Create: `functions/src/index.ts`

- [ ] **Step 1: Create functions/package.json**

```json
{
  "name": "familyguard-functions",
  "version": "1.0.0",
  "engines": { "node": "20" },
  "main": "lib/index.js",
  "scripts": {
    "build": "tsc",
    "build:watch": "tsc --watch",
    "test": "jest"
  },
  "dependencies": {
    "firebase-admin": "^12.0.0",
    "firebase-functions": "^5.0.0"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "firebase-functions-test": "^3.3.0",
    "jest": "^29.0.0",
    "ts-jest": "^29.0.0",
    "typescript": "^5.0.0"
  },
  "jest": {
    "preset": "ts-jest",
    "testEnvironment": "node",
    "testMatch": ["**/__tests__/**/*.test.ts"]
  }
}
```

- [ ] **Step 2: Create functions/tsconfig.json**

```json
{
  "compilerOptions": {
    "module": "commonjs",
    "noImplicitReturns": true,
    "noUnusedLocals": true,
    "outDir": "lib",
    "sourceMap": true,
    "strict": true,
    "target": "es2020",
    "skipLibCheck": true
  },
  "compileOnSave": true,
  "include": ["src"]
}
```

- [ ] **Step 3: Create functions/src/index.ts**

```typescript
import * as admin from 'firebase-admin';

admin.initializeApp();

export { onUserCreated } from './auth/on_user_created';
```

- [ ] **Step 4: Install dependencies**

```bash
cd functions && npm install && cd ..
```

Expected: `node_modules/` créé, aucune erreur.

- [ ] **Step 5: Commit**

```bash
git add functions/
git commit -m "chore: initialize Cloud Functions (Node.js 20 + TypeScript)"
```

---

## Task 4: Setup Firebase config files

**Files:**
- Create: `firebase.json`
- Create: `firestore.rules`
- Create: `firestore.indexes.json`

- [ ] **Step 1: Create firebase.json**

```json
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ]
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

- [ ] **Step 2: Create firestore.rules**

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

- [ ] **Step 3: Create firestore.indexes.json**

```json
{
  "indexes": [],
  "fieldOverrides": []
}
```

- [ ] **Step 4: Commit**

```bash
git add firebase.json firestore.rules firestore.indexes.json
git commit -m "chore: add Firebase config (rules v1, indexes placeholder)"
```

---

## Task 5: Setup core theme

**Files:**
- Create: `lib/core/theme/app_theme.dart`

- [ ] **Step 1: Create app_theme.dart**

```dart
import 'package:flutter/material.dart';

class AppTheme {
  static const _primary = Color(0xFF4A6FA5);
  static const _surface = Color(0xFFF8F9FA);
  static const _error = Color(0xFFDC3545);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primary,
          surface: _surface,
          error: _error,
        ),
      );
}
```

- [ ] **Step 2: Verify**

```bash
dart analyze lib/core/theme/app_theme.dart
```

Expected: "No issues found!"

- [ ] **Step 3: Commit**

```bash
git add lib/core/theme/app_theme.dart
git commit -m "feat: add AppTheme (Material 3, palette bleu-gris)"
```

---

## Task 6: AppUser model + tests

**Files:**
- Create: `lib/features/auth/models/app_user.dart`
- Create: `test/features/auth/models/app_user_test.dart`

- [ ] **Step 1: Write the failing test**

Créer `test/features/auth/models/app_user_test.dart` :

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:familyguard/features/auth/models/app_user.dart';

void main() {
  group('AppUser', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('fromFirestore parses a Firestore document correctly', () async {
      final now = DateTime(2026, 1, 1, 12, 0, 0);
      await fakeFirestore.collection('users').doc('uid123').set({
        'uid': 'uid123',
        'email': 'test@example.com',
        'firstName': 'Alice',
        'lastName': 'Dupont',
        'phone': '+33612345678',
        'avatarUrl': null,
        'fcmToken': null,
        'createdAt': Timestamp.fromDate(now),
      });

      final doc = await fakeFirestore.collection('users').doc('uid123').get();
      final user = AppUser.fromFirestore(doc);

      expect(user.uid, 'uid123');
      expect(user.email, 'test@example.com');
      expect(user.firstName, 'Alice');
      expect(user.lastName, 'Dupont');
      expect(user.phone, '+33612345678');
      expect(user.avatarUrl, isNull);
      expect(user.createdAt, now);
    });

    test('toFirestore produces correct map', () {
      final now = DateTime(2026, 1, 1, 12, 0, 0);
      final user = AppUser(
        uid: 'uid123',
        email: 'test@example.com',
        firstName: 'Alice',
        lastName: 'Dupont',
        phone: null,
        avatarUrl: null,
        fcmToken: null,
        createdAt: now,
      );

      final map = user.toFirestore();

      expect(map['uid'], 'uid123');
      expect(map['email'], 'test@example.com');
      expect(map['firstName'], 'Alice');
      expect(map['phone'], isNull);
      expect(map['createdAt'], Timestamp.fromDate(now));
    });

    test('equality: two AppUsers with same data are equal', () {
      final now = DateTime(2026, 1, 1);
      final a = AppUser(
        uid: 'u1',
        email: 'a@b.com',
        firstName: 'A',
        lastName: 'B',
        createdAt: now,
      );
      final b = AppUser(
        uid: 'u1',
        email: 'a@b.com',
        firstName: 'A',
        lastName: 'B',
        createdAt: now,
      );
      expect(a, equals(b));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/features/auth/models/app_user_test.dart
```

Expected: FAIL — `AppUser` non défini.

- [ ] **Step 3: Create app_user.dart**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_user.freezed.dart';

@freezed
class AppUser with _$AppUser {
  const AppUser._();

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

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return AppUser(
      uid: data['uid'] as String,
      email: data['email'] as String,
      firstName: data['firstName'] as String,
      lastName: data['lastName'] as String,
      phone: data['phone'] as String?,
      avatarUrl: data['avatarUrl'] as String?,
      fcmToken: data['fcmToken'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'uid': uid,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'avatarUrl': avatarUrl,
        'fcmToken': fcmToken,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
```

- [ ] **Step 4: Run code generation**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Expected: `lib/features/auth/models/app_user.freezed.dart` généré sans erreurs.

- [ ] **Step 5: Run test to verify it passes**

```bash
flutter test test/features/auth/models/app_user_test.dart
```

Expected: PASS — les 3 tests passent.

- [ ] **Step 6: Commit**

```bash
git add lib/features/auth/models/ test/features/auth/models/
git commit -m "feat: add AppUser model with fromFirestore/toFirestore (tested)"
```

---

## Task 7: Auth providers

**Files:**
- Create: `lib/features/auth/providers/auth_providers.dart`

- [ ] **Step 1: Create auth_providers.dart**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) => doc.exists ? AppUser.fromFirestore(doc) : null);
});
```

- [ ] **Step 2: Verify**

```bash
dart analyze lib/features/auth/providers/auth_providers.dart
```

Expected: "No issues found!"

- [ ] **Step 3: Commit**

```bash
git add lib/features/auth/providers/auth_providers.dart
git commit -m "feat: add authStateProvider and currentUserProvider (Riverpod)"
```

---

## Task 8: SplashScreen

**Files:**
- Create: `lib/features/auth/screens/splash_screen.dart`

- [ ] **Step 1: Create splash_screen.dart**

```dart
import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shield,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'FamilyGuard',
              style: Theme.of(context)
                  .textTheme
                  .headlineLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
```

Note : le go_router redirige automatiquement depuis `/splash` dès que l'état auth est résolu — pas besoin de timer.

- [ ] **Step 2: Commit**

```bash
git add lib/features/auth/screens/splash_screen.dart
git commit -m "feat: add SplashScreen"
```

---

## Task 9: LoginScreen

**Files:**
- Create: `lib/features/auth/screens/login_screen.dart`

- [ ] **Step 1: Create login_screen.dart**

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage(e.code))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _errorMessage(String code) => switch (code) {
        'user-not-found' => 'Aucun compte avec cet email.',
        'wrong-password' => 'Mot de passe incorrect.',
        'invalid-credential' => 'Email ou mot de passe incorrect.',
        'too-many-requests' => 'Trop de tentatives. Réessayez plus tard.',
        _ => 'Erreur de connexion. Réessayez.',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                Icon(Icons.shield,
                    size: 60, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  'Connexion',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'Email invalide' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Min. 6 caractères'
                      : null,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: const Text('Mot de passe oublié ?'),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loading ? null : _signIn,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Se connecter'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.push('/register'),
                  child: const Text("Pas encore de compte ? S'inscrire"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/auth/screens/login_screen.dart
git commit -m "feat: add LoginScreen"
```

---

## Task 10: RegisterScreen

**Files:**
- Create: `lib/features/auth/screens/register_screen.dart`

- [ ] **Step 1: Create register_screen.dart**

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // go_router refreshListenable détecte le changement d'auth et redirige vers /home
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage(e.code))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _errorMessage(String code) => switch (code) {
        'email-already-in-use' => 'Cet email est déjà utilisé.',
        'weak-password' => 'Mot de passe trop faible.',
        'invalid-email' => 'Email invalide.',
        _ => "Erreur lors de l'inscription. Réessayez.",
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'Email invalide' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Min. 6 caractères'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v != _passwordController.text
                      ? 'Les mots de passe ne correspondent pas'
                      : null,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _register,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("S'inscrire"),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Déjà un compte ? Se connecter'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/auth/screens/register_screen.dart
git commit -m "feat: add RegisterScreen"
```

---

## Task 11: ForgotPasswordScreen

**Files:**
- Create: `lib/features/auth/screens/forgot_password_screen.dart`

- [ ] **Step 1: Create forgot_password_screen.dart**

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      if (mounted) setState(() => _sent = true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'user-not-found'
                ? 'Aucun compte avec cet email.'
                : 'Erreur. Réessayez.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mot de passe oublié')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _sent
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 16),
                    const Text(
                      'Email envoyé ! Vérifiez votre boîte mail pour réinitialiser votre mot de passe.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Entrez votre email pour recevoir un lien de réinitialisation.',
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || !v.contains('@'))
                            ? 'Email invalide'
                            : null,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _loading ? null : _sendReset,
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Envoyer le lien'),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/auth/screens/forgot_password_screen.dart
git commit -m "feat: add ForgotPasswordScreen"
```

---

## Task 12: EditProfileScreen

**Files:**
- Create: `lib/features/auth/screens/edit_profile_screen.dart`

- [ ] **Step 1: Create edit_profile_screen.dart**

```dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _loading = false;
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user != null) {
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
      _phoneController.text = user.phone ?? '';
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked != null) setState(() => _pickedImage = File(picked.path));
  }

  Future<String?> _uploadAvatar(String uid) async {
    if (_pickedImage == null) return null;
    final ref = FirebaseStorage.instance.ref('avatars/$uid.jpg');
    await ref.putFile(_pickedImage!);
    return ref.getDownloadURL();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final avatarUrl = await _uploadAvatar(uid);
      final update = <String, dynamic>{
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      };
      if (avatarUrl != null) update['avatarUrl'] = avatarUrl;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update(update);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour')),
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la sauvegarde')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 48,
                      backgroundImage: _pickedImage != null
                          ? FileImage(_pickedImage!) as ImageProvider
                          : (user?.avatarUrl != null
                              ? NetworkImage(user!.avatarUrl!)
                              : null),
                      child:
                          (_pickedImage == null && (user?.avatarUrl == null))
                              ? const Icon(Icons.person, size: 48)
                              : null,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                    child: Text('Appuyer pour changer la photo')),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'Prénom',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone (optionnel)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Enregistrer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/auth/screens/edit_profile_screen.dart
git commit -m "feat: add EditProfileScreen (profil + upload avatar)"
```

---

## Task 13: HomePlaceholderScreen + go_router

**Files:**
- Create: `lib/core/router/home_placeholder_screen.dart`
- Create: `lib/core/router/app_router.dart`

Toutes les screens existent à ce stade — le routeur peut les importer sans erreur.

- [ ] **Step 1: Create home_placeholder_screen.dart**

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_providers.dart';

class HomePlaceholderScreen extends ConsumerWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final greeting = (user != null && user.firstName.isNotEmpty)
        ? 'Bonjour ${user.firstName} !'
        : 'Bonjour !';
    return Scaffold(
      appBar: AppBar(
        title: const Text('FamilyGuard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(greeting,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            const Text('Sprint 2 à venir — Gestion des enfants'),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Create app_router.dart**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/edit_profile_screen.dart';
import 'home_placeholder_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthChangeNotifier(ref);
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authAsync = ref.read(authStateProvider);
      if (authAsync.isLoading) return '/splash';

      final isAuthenticated = authAsync.valueOrNull != null;
      const authRoutes = ['/login', '/register', '/forgot-password', '/splash'];
      final isAuthRoute = authRoutes.contains(state.matchedLocation);

      if (!isAuthenticated && !isAuthRoute) return '/login';
      if (isAuthenticated && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(path: '/home', builder: (_, __) => const HomePlaceholderScreen()),
      GoRoute(
        path: '/profile/edit',
        builder: (_, __) => const EditProfileScreen(),
      ),
    ],
  );
});

class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}
```

- [ ] **Step 3: Analyze**

```bash
dart analyze lib/core/router/
```

Expected: "No issues found!"

- [ ] **Step 4: Commit**

```bash
git add lib/core/router/
git commit -m "feat: add go_router with auth guard + HomePlaceholderScreen"
```

---

## Task 14: Cloud Function onUserCreated + tests

**Files:**
- Create: `functions/src/auth/on_user_created.ts`
- Create: `functions/src/auth/__tests__/on_user_created.test.ts`

- [ ] **Step 1: Write the failing test**

Créer `functions/src/auth/__tests__/on_user_created.test.ts` :

```typescript
import * as admin from 'firebase-admin';

const testEnv = require('firebase-functions-test')();

jest.mock('firebase-admin', () => ({
  initializeApp: jest.fn(),
  firestore: jest.fn(),
}));

describe('onUserCreated', () => {
  let mockSet: jest.Mock;
  let mockDoc: jest.Mock;
  let mockCollection: jest.Mock;

  beforeEach(() => {
    jest.resetModules();
    mockSet = jest.fn().mockResolvedValue(undefined);
    mockDoc = jest.fn().mockReturnValue({ set: mockSet });
    mockCollection = jest.fn().mockReturnValue({ doc: mockDoc });
    (admin.firestore as jest.Mock).mockReturnValue({ collection: mockCollection });
  });

  afterAll(() => testEnv.cleanup());

  it('creates /users/{uid} document on new user', async () => {
    const { onUserCreated } = await import('../on_user_created');
    const wrapped = testEnv.wrap(onUserCreated);

    await wrapped({ uid: 'uid-abc', email: 'alice@example.com' });

    expect(mockCollection).toHaveBeenCalledWith('users');
    expect(mockDoc).toHaveBeenCalledWith('uid-abc');
    expect(mockSet).toHaveBeenCalledWith(
      expect.objectContaining({
        uid: 'uid-abc',
        email: 'alice@example.com',
        firstName: '',
        lastName: '',
        phone: null,
        avatarUrl: null,
        fcmToken: null,
      }),
    );
  });

  it('uses empty string when email is undefined', async () => {
    const { onUserCreated } = await import('../on_user_created');
    const wrapped = testEnv.wrap(onUserCreated);

    await wrapped({ uid: 'uid-no-email' });

    expect(mockSet).toHaveBeenCalledWith(
      expect.objectContaining({ email: '' }),
    );
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd functions && npm test && cd ..
```

Expected: FAIL — module `../on_user_created` introuvable.

- [ ] **Step 3: Create functions/src/auth/on_user_created.ts**

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';

export const onUserCreated = functions.auth.user().onCreate(async (user) => {
  await admin.firestore().collection('users').doc(user.uid).set({
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

- [ ] **Step 4: Run test to verify it passes**

```bash
cd functions && npm test && cd ..
```

Expected: PASS — les 2 tests passent.

- [ ] **Step 5: Build TypeScript**

```bash
cd functions && npm run build && cd ..
```

Expected: Pas d'erreurs TypeScript. Répertoire `functions/lib/` créé.

- [ ] **Step 6: Commit**

```bash
git add functions/src/auth/
git commit -m "feat: add onUserCreated Cloud Function (tested)"
```

---

## Task 15: Wire main.dart + firebase_options placeholder

**Files:**
- Create: `lib/core/firebase/firebase_options.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: Create firebase_options.dart placeholder**

```dart
// Généré par `flutterfire configure` — ce fichier sera remplacé lors du setup Firebase.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'Exécuter "flutterfire configure" pour générer ce fichier avec les vraies options Firebase.',
    );
  }
}
```

- [ ] **Step 2: Replace lib/main.dart**

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/firebase/firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: FamilyGuardApp()));
}

class FamilyGuardApp extends ConsumerWidget {
  const FamilyGuardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'FamilyGuard',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

- [ ] **Step 3: Analyze the full lib/ directory**

```bash
dart analyze lib/
```

Expected: "No issues found!" (le placeholder firebase_options lance une exception au runtime mais analyse proprement).

- [ ] **Step 4: Run all Flutter tests**

```bash
flutter test
```

Expected: PASS — les 3 tests AppUser passent.

- [ ] **Step 5: Commit**

```bash
git add lib/main.dart lib/core/firebase/firebase_options.dart
git commit -m "feat: wire main.dart (Firebase init, ProviderScope, go_router)"
```

---

## Task 16: Firebase setup (commandes manuelles)

Ces commandes s'exécutent avec le préfixe `! ` dans Claude Code pour un retour en direct.

- [ ] **Step 1: Installer FlutterFire CLI**

```bash
dart pub global activate flutterfire_cli
```

Expected: "Activated flutterfire_cli x.x.x."

- [ ] **Step 2: Créer le projet Firebase**

```bash
firebase projects:create familyguard-app --display-name "FamilyGuard"
```

Expected: "✔ Creating Google Cloud Platform project ... [OK]"

- [ ] **Step 3: Activer les services dans la console Firebase**

Aller sur [console.firebase.google.com](https://console.firebase.google.com) → projet `familyguard-app` :
- **Authentication** → Sign-in method → activer Email/Password
- **Firestore** → Create database → production mode → région `europe-west1`
- **Storage** → Get started
- **Functions** → upgrade vers le Blaze plan (requis)

- [ ] **Step 4: Générer firebase_options.dart**

```bash
flutterfire configure \
  --project=familyguard-app \
  --platforms=android,ios,web \
  --android-package-name=com.familyguard.app \
  --ios-bundle-id=com.familyguard.app
```

Expected: `lib/core/firebase/firebase_options.dart` remplacé avec les vraies options. `google-services.json` et `GoogleService-Info.plist` générés.

- [ ] **Step 5: Déployer les règles Firestore**

```bash
firebase deploy --only firestore:rules --project familyguard-app
```

Expected: "Deploy complete!"

- [ ] **Step 6: Déployer les Cloud Functions**

```bash
firebase deploy --only functions --project familyguard-app
```

Expected: "Deploy complete! Function onUserCreated deployed."

- [ ] **Step 7: Commit les fichiers de platform Firebase**

```bash
git add android/app/google-services.json ios/Runner/GoogleService-Info.plist lib/core/firebase/firebase_options.dart
git commit -m "chore: add Firebase platform config files (flutterfire configure)"
```

---

## Task 17: Final verification

- [ ] **Step 1: Run all Flutter tests**

```bash
flutter test
```

Expected: All tests PASS.

- [ ] **Step 2: Run Cloud Function tests**

```bash
cd functions && npm test && cd ..
```

Expected: All tests PASS.

- [ ] **Step 3: Full analysis**

```bash
dart analyze lib/
```

Expected: "No issues found!"

- [ ] **Step 4: Build web**

```bash
flutter build web
```

Expected: "✓ Built build/web" sans erreurs.

- [ ] **Step 5: Test golden path sur device/simulateur**

```bash
flutter run
```

Vérifier :
1. SplashScreen s'affiche → redirige vers LoginScreen
2. "Créer un compte" → RegisterScreen → inscription → Cloud Function crée `/users/{uid}` dans Firestore → redirige vers HomePlaceholderScreen
3. Logout → retour LoginScreen
4. Login → retour HomePlaceholderScreen
5. "Mot de passe oublié" → email de reset reçu
6. Icône profil → EditProfileScreen → modifier prénom/nom → sauvegarder
