# Documentation des Métriques d'Analyse d'Entretien (SkillSpace)

Ce document détaille l'ensemble des métriques collectées et analysées par l'IA lors d'une simulation d'entretien.

## 1. Score Global (Global Score)
*   **Plage :** 0 - 100
*   **Description :** Une évaluation globale de la performance du candidat, combinant la qualité des réponses (fond) et la fluidité de l'élocution (forme).

## 2. Analyse STAR (Situation, Task, Action, Result)
L'IA évalue la structure des réponses selon la méthodologie STAR :
*   **Situation :** Capacité à poser le contexte (0-100).
*   **Task (Tâche) :** Définition claire des objectifs ou défis (0-100).
*   **Action :** Précision des étapes entreprises par le candidat (0-100).
*   **Result (Résultat) :** Mise en avant des bénéfices et résultats concrets (0-100).
*   **Éléments Manquants :** Liste textuelle des parties de la méthode STAR oubliées par le candidat.

## 3. Analyse Vocale & Fluidité (Speech Analysis)
Cette section analyse la **forme** du discours, calculée à partir des disfluences détectées dans la voix via Whisper.

### Métriques Brutes (Metrics) :
*   **Filler Count (Hésitations) :** Nombre de mots de remplissage détectés (`euh`, `mmm`, `hmm`, `donc`, `alors`, etc.).
*   **Repetition Count (Répétitions) :** Nombre de fois où le candidat répète le même mot consécutivement.
*   **Pause Count (Silences) :** Estimation des silences prolongés ou hésitants.
*   **Words Per Minute (WPM) :** Vitesse de débit de parole (idéal : ~120-140 mots/min).
*   **Average Response Length :** Longueur moyenne des réponses en nombre de mots.
*   **Hesitation Score (Stress Vocal) :** Score de 0 à 100 calculé selon le ratio (Hésitations + Pauses) / Nombre de mots.

### Traits Vocaux (Inferred Traits) :
*   **Confidence (Confiance) :** Niveau d'assurance perçu (0-100).
*   **Stress :** Niveau de tension vocale détecté (0-100).
*   **Calmness (Calme) :** Stabilité émotionnelle dans la voix (0-100).
*   **Uncertainty (Incertitude) :** Fréquence des doutes exprimés (0-100).

## 4. Traits de Personnalité (Big Five)
L'IA déduit les traits psychométriques basés sur le lexique utilisé et l'attitude :
*   **Openness (Ouverture) :** Curiosité et ouverture d'esprit.
*   **Conscientiousness (Conscience) :** Organisation et sérieux.
*   **Extraversion :** Niveau d'énergie sociale et dynamisme.
*   **Agreeableness (Amabilité) :** Coopération et empathie.
*   **Emotional Stability (Stabilité) :** Capacité à gérer la pression.

## 5. Compétences de Communication (Skills)
*   **Clarity (Clarté) :** Aptitude à exprimer des idées de manière compréhensible.
*   **Relevance (Pertinence) :** Capacité à répondre directement à la question posée.
*   **Structure :** Organisation logique du discours.

## 6. Analyse Comportementale (Behavioral Analysis)
*   **Stress Level :** Niveau de stress global perçu.
*   **Self-Confidence :** Confiance en soi globale.
*   **Engagement :** Niveau d'implication dans l'échange.

---
*Dernière mise à jour : 15 Mai 2026*
