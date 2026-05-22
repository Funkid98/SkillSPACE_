# SkillSpace Backend — Questions & Réponses (PFE)

---

## 1. Quelles bibliothèques Node.js avez-vous utilisées et pourquoi ?

### Bibliothèques communes (5 services)

| Bibliothèque | Rôle |
|---|---|
| **express** | Framework web — gère le routage HTTP, les middlewares, et le cycle requête/réponse |
| **mongoose** | ODM pour MongoDB — définit les schémas, modèles, et gère toutes les opérations CRUD |
| **cors** | Middleware qui ajoute les headers `Access-Control-Allow-*` pour que le front Flutter Web puisse appeler les APIs |
| **dotenv** | Charge les variables d'environnement depuis les fichiers `.env` (clés API, secrets JWT, URI MongoDB) |

### Authentification & Sécurité

| Bibliothèque | Rôle |
|---|---|
| **bcryptjs** | Hachage et vérification des mots de passe avec l'algorithme bcrypt (10 salt rounds) |
| **jsonwebtoken** | Création et vérification des JWT pour l'authentification stateless |
| **google-auth-library** | Vérification des tokens Google OAuth2 côté serveur pour Google Sign-In |

### Intelligence Artificielle

| Bibliothèque | Rôle |
|---|---|
| **groq-sdk** | SDK pour l'API Groq — appelle des LLMs (Llama/Mixtral) pour la génération de quiz, simulation d'entretien, extraction de compétences |
| **openai** | SDK OpenAI — fournisseur IA alternatif pour l'analyse de CV et l'évaluation de quiz |
| **@google/generative-ai** | SDK Google Gemini — autre option IA pour la génération de contenu |

### Gestion de fichiers

| Bibliothèque | Rôle |
|---|---|
| **multer** | Middleware pour le upload de fichiers (CVs, photos de profil) via `multipart/form-data` |
| **mammoth** | Convertit les fichiers `.docx` (Word) en texte pour l'analyse IA des CVs |
| **pdf-parse** | Extrait le texte des fichiers `.pdf` pour la même pipeline d'analyse |

### Communication

| Bibliothèque | Rôle |
|---|---|
| **axios** | Client HTTP pour les appels inter-services et les APIs externes |
| **nodemailer** | Envoi d'emails transactionnels (planification d'entretien, notifications) |

### Développement

| Bibliothèque | Rôle |
|---|---|
| **nodemon** | Redémarrage automatique du serveur lors des modifications de code en développement |

---

## 2. Quel est le rôle d'Express vs Axios ?

### Express = Réception (entrant)
Express transforme Node.js en serveur web capable de recevoir et traiter les requêtes HTTP du front Flutter.

```js
// Sans Express — Node.js brut (complexe)
http.createServer((req, res) => {
  if (req.url === '/api/login' && req.method === 'POST') { ... }
});

// Avec Express — propre et organisé
app.post('/api/login', loginController);
app.get('/api/profile', authMiddleware, profileController);
```

### Axios = Envoi (sortant)
Axios permet à un service backend d'appeler un autre service ou une API externe.

```
Flutter ──requête──► login-register (port 3000)
                           │
                           │ axios.get('http://localhost:3001/api/...')
                           ▼
                     candidat-service (port 3001)
```

**Analogie :** Express = réceptionniste (écoute les appels entrants). Axios = téléphone (passe des appels sortants).

---

## 3. Qu'est-ce que CORS et pourquoi l'utiliser ?

CORS (Cross-Origin Resource Sharing) résout une restriction de sécurité du navigateur. Par défaut, le navigateur bloque les requêtes vers une origine différente.

```
Flutter Web (http://localhost:8080)  →  API Express (http://localhost:3000)
              ❌ Bloqué sans cors (port différent = origine différente)
              ✅ Autorisé avec cors (headers Access-Control-Allow-Origin)
```

**Important :**
- CORS est appliqué uniquement par les **navigateurs** (pas mobile, pas Postman, pas serveur-serveur)
- Sans cors, le serveur traite quand même la requête, mais le **navigateur refuse de lire la réponse**
- Flutter mobile/desktop n'est pas affecté par CORS

---

## 4. Quelle sécurité avez-vous utilisée ? (Cookies vs JWT)

### Notre choix : JWT Bearer Token (pas de cookies)

**Flux d'authentification :**
```
1. L'utilisateur se connecte → le serveur crée un JWT → l'envoie dans le body
2. Flutter stocke le JWT (SharedPreferences)
3. Chaque requête inclut : Authorization: Bearer <token>
4. Le middleware auth vérifie le token avec jwt.verify()
```

**3 couches de sécurité :**
- **bcryptjs** → hachage des mots de passe (jamais stockés en clair)
- **jsonwebtoken** → authentification stateless via tokens signés
- **google-auth-library** → vérification des tokens Google Sign-In

---

## 5. Quelle est la différence entre Cookies et JWT ?

| | Cookie + Session | JWT Bearer Token (notre choix) |
|---|---|---|
| Données stockées où ? | Sur le **serveur** (DB/Redis). Le cookie contient juste un sessionId | Dans le **token lui-même** (payload signé) |
| Envoyé comment ? | **Automatiquement** par le navigateur | **Manuellement** dans le header Authorization |
| Serveur stateful ? | ✅ Oui — doit stocker toutes les sessions | ❌ Non — vérifie juste la signature |
| Fonctionne sur mobile ? | ❌ Non — les cookies sont un concept navigateur | ✅ Oui — c'est juste un header HTTP |
| Multi-services ? | ❌ Difficile — cookie lié à un seul origin/port | ✅ Facile — même token envoyé partout |
| Déconnexion | Facile — supprimer la session du serveur | Plus difficile — token valide jusqu'à expiration |

### Pourquoi pas les cookies dans notre projet ?

1. **Flutter ≠ Navigateur** — Flutter mobile/desktop n'a pas de `document.cookie`
2. **Microservices** — Un cookie créé par le port 3000 n'est PAS envoyé au port 3001 (origine différente). Avec JWT, on envoie le même token à tous les services
3. **Stateless** — Pas besoin de stocker les sessions en base de données

---

## 6. Pourquoi avoir choisi une architecture microservices ?

### Réponse courte
> "SkillSpace a 5 domaines distincts avec des responsabilités et des intégrations IA différentes. Les microservices permettent à chaque service d'évoluer indépendamment."

### Architecture

```
Flutter App
    ├──► login-register (3000) ── Auth, JWT, Google OAuth
    ├──► candidat-service (3001) ── CVs, Quiz, IA (Groq + OpenAI + Gemini)
    ├──► interview-service (3002) ── Simulation d'entretien IA (Groq)
    ├──► offer-service (3003) ── Offres d'emploi + extraction IA
    └──► recruter-service (3004) ── Dashboard recruteur
```

### 4 raisons

**1. Isolation des pannes**
Si l'IA d'entretien (Groq) tombe en panne, les candidats peuvent toujours se connecter, uploader des CVs et consulter les offres. En monolithe, un crash = tout tombe.

**2. Différents fournisseurs IA par service**
- candidat-service → Groq + OpenAI + Gemini
- interview-service → Groq uniquement
- offer-service → Groq uniquement

Chaque service gère ses propres dépendances IA sans alourdir les autres.

**3. Scalabilité d'équipe**
Chaque membre de l'équipe travaille sur son service sans conflits de merge.

**4. Scalabilité indépendante**
Si 100 candidats passent des quiz mais seulement 2 recruteurs sont en ligne, on peut scaler candidat-service sans gaspiller de ressources sur recruter-service.

### Si on vous demande les inconvénients (montrer la maturité)

> "La communication inter-services ajoute de la complexité. Par exemple, quand le recruteur planifie un entretien, recruter-service doit appeler candidat-service via axios. En monolithe, ce serait un simple appel de fonction. Mais pour notre cas d'usage, les avantages l'emportent."

---

## 7. Qu'est-ce que `MediaQuery.of(context).size.width - 32` ?

Le `-32` compense le padding horizontal total (16px gauche + 16px droite = 32px) défini dans le widget parent `Padding`. Cela garantit que le conteneur glassmorphique s'adapte parfaitement à l'intérieur des marges, quelle que soit la taille de l'écran.
