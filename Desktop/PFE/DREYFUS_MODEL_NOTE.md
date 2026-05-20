# Modèle d'Acquisition des Compétences de Dreyfus
## Application dans SkillSpace — Évaluation des Compétences par Quiz IA

---

## 1. Qu'est-ce que le Modèle de Dreyfus ?

Le **modèle d'acquisition des compétences de Dreyfus** (Dreyfus & Dreyfus, 1980, Université de Berkeley) est un cadre académique reconnu internationalement qui décrit comment un individu progresse dans l'apprentissage d'une compétence.

Le modèle original comporte **5 stades** :

| Stade | Nom | Description |
|-------|-----|-------------|
| 1 | **Novice** (Débutant) | Suit des règles rigides, peu de jugement contextuel |
| 2 | **Débutant avancé** | Reconnaît certains aspects situationnels |
| 3 | **Compétent** | Planifie consciemment, gère la complexité |
| 4 | **Maîtrise** | Perception holistique, priorisation intuitive |
| 5 | **Expert** | Transcende les règles, intuition profonde |

### Adaptation pour SkillSpace

Pour notre plateforme de recrutement, nous avons **simplifié le modèle en 3 niveaux** adaptés à l'évaluation technique dans un contexte de recrutement :

| Niveau SkillSpace | Stades Dreyfus couverts | Description |
|-------------------|------------------------|-------------|
| **Débutant** (Beginner) | Novice + Débutant avancé | Rappel de règles de base, connaissances fondamentales |
| **Intermédiaire** (Intermediate) | Compétent | Reconnaissance de patterns, application en contexte |
| **Avancé** (Advanced) | Maîtrise + Expert | Connaissances approfondies, cas limites, conception système |

---

## 2. Architecture du Quiz (Scoring Pondéré)

Chaque quiz contient **5 questions** avec un système de **scoring pondéré** :

```
Score = (Nombre_Q1_à_Q4_correctes × 15) + (Q5_correcte × 40)
```

| Question | Type (Dreyfus) | Points |
|----------|---------------|--------|
| Q1 – Q4 | Mémorisation / Compréhension | **15 pts** chacune (max 60) |
| Q5 | Application / Analyse / Résolution de problème | **40 pts** (max 40) |
| **Total** | | **100 pts** |

### Justification de la pondération

Cette pondération reflète le principe Dreyfus selon lequel **la compétence appliquée surpasse la mémorisation** :
- Les questions Q1–Q4 évaluent les **connaissances théoriques** (rappel de règles)
- La question Q5 évalue la **résolution de problèmes en situation réelle** (application pratique)
- Un candidat qui maîtrise la théorie (60 pts) mais échoue en pratique (0 pts) obtient seulement 60/100
- Un candidat qui résout le problème pratique démontre une compétence de niveau supérieur

> Cette approche est cohérente avec les modèles d'évaluation pondérés utilisés dans le **GMAT**, le **SAT**, et les examens de **certification professionnelle**.

---

## 3. Génération Adaptative des Questions

L'IA (Groq / LLaMA 3.3) génère des questions **adaptées au stade Dreyfus** sélectionné :

### Niveau Débutant
- **Q1–Q4** : Rappel de règles de base et connaissances fondamentales
- **Q5** : Scénario de résolution de problème simple

### Niveau Intermédiaire
- **Q1–Q4** : Reconnaissance de patterns et connaissances appliquées en contexte
- **Q5** : Scénario de résolution de problème réel

### Niveau Avancé
- **Q1–Q4** : Connaissances approfondies, cas limites et conception système
- **Q5** : Scénario complexe de résolution de problème système

---

## 4. Détermination du Niveau (Vérification de Cohérence Dreyfus)

Après le calcul du score, le système effectue une **vérification croisée** entre le score obtenu et le niveau que le candidat a déclaré. Cette logique est **déterministe** (codée en dur dans le backend, jamais déléguée à l'IA) :

### Règles de promotion/maintien/rétrogradation

#### Si le candidat a choisi "Débutant" :
| Score | Niveau Déterminé | Statut |
|-------|------------------|--------|
| **100/100** | Intermédiaire | `underrated` (sous-estimé → promu) |
| **0–99** | Débutant | `confirmed` (confirmé) |

#### Si le candidat a choisi "Intermédiaire" :
| Score | Niveau Déterminé | Statut |
|-------|------------------|--------|
| **100/100** | Avancé | `underrated` (sous-estimé → promu) |
| **40–99** | Intermédiaire | `confirmed` (confirmé) |
| **0–39** | Débutant | `overrated` (surestimé → rétrogradé) |

#### Si le candidat a choisi "Avancé" :
| Score | Niveau Déterminé | Statut |
|-------|------------------|--------|
| **80–100** | Avancé | `confirmed` (confirmé) |
| **40–79** | Intermédiaire | `overrated` (surestimé → rétrogradé) |
| **0–39** | Débutant | `critical_mismatch` (écart critique) |

> **Principe clé** : Seul un score **parfait (100/100)** permet de passer au niveau supérieur. Cela garantit que la promotion est méritée et non aléatoire.

---

## 5. Mapping du Score vers le Pourcentage de Compétence

Le score brut du quiz (0–100) est **mappé vers une plage de pourcentage** cohérente avec le niveau déterminé :

| Niveau Déterminé | Plage de pourcentage stocké | Formule |
|------------------|---------------------------|---------|
| Débutant | 0% – 39% | `floor(score/100 × 39)` |
| Intermédiaire | 40% – 79% | `40 + floor(score/100 × 39)` |
| Avancé | 80% – 100% | `80 + floor(score/100 × 20)` |

### Exemple concret
Un candidat passe le quiz **Débutant en Java** et obtient **45/100** :
1. Score brut = 45
2. Niveau déterminé = **Débutant** (car score < 100 sur un quiz Débutant)
3. Pourcentage stocké = `floor(45/100 × 39)` = **17%**
4. Le badge de compétence affiche correctement **"Débutant"**

---

## 6. Implémentation dans le Code

### Fichiers concernés

| Fichier | Rôle |
|---------|------|
| `ai-service.js` → `generateQuiz()` | Génération des questions adaptées au stade Dreyfus |
| `ai-service.js` → `evaluateQuiz()` | Évaluation par l'IA (feedback en français, analyse des réponses) |
| `quiz-controller.js` → `evaluateQuizHandler()` | Calcul déterministe du score + enforcement du niveau Dreyfus |
| `quiz_modal.dart` | Interface utilisateur (affichage du résultat depuis le backend) |

### Flux complet

```
1. Candidat choisit un niveau (Débutant/Intermédiaire/Avancé)
            ↓
2. L'IA génère 5 questions adaptées au stade Dreyfus choisi
            ↓
3. Le candidat répond aux 5 questions
            ↓
4. L'IA évalue chaque réponse (correct/incorrect + feedback)
            ↓
5. Le backend recalcule le score de manière déterministe
   Score = (Q1-Q4 correctes × 15) + (Q5 correcte × 40)
            ↓
6. Le backend applique les règles Dreyfus pour déterminer le niveau
   (promotion uniquement si score parfait)
            ↓
7. Le score est mappé vers la plage de pourcentage du niveau déterminé
            ↓
8. Le pourcentage est sauvegardé en base de données
            ↓
9. Le frontend affiche le résultat (niveau + score brut + feedback)
```

---

## 7. Références Académiques

- **Dreyfus, S.E. & Dreyfus, H.L.** (1980). *A Five-Stage Model of the Mental Activities Involved in Directed Skill Acquisition*. University of California, Berkeley.
- **Dreyfus, H.L.** (2004). *A Phenomenology of Skill Acquisition as the basis for a Merleau-Pontian Non-representationalist Cognitive Science*. University of California, Berkeley.
- **Benner, P.** (1984). *From Novice to Expert: Excellence and Power in Clinical Nursing Practice*. Addison-Wesley. (Application du modèle Dreyfus dans le domaine médical)

---

> **Note** : Le modèle de Dreyfus est utilisé dans de nombreux domaines professionnels (médecine, ingénierie, aviation, éducation) pour structurer l'évaluation et la progression des compétences. Son application dans SkillSpace apporte une **rigueur académique** au processus d'évaluation des candidats, tout en restant adapté au contexte du recrutement technique.
