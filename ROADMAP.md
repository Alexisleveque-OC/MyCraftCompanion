# 🏭 MyCraftCompanion – Roadmap

---

# 🟢 PHASE 1 – CurseForge Release Ready

## 🎯 Objectif
Release stable, propre, traduite et compréhensible.

### Core
- [x] **Modularité** : Séparer la logique des données, de l'interface et des intégrations.
- [x] **Fiabilité en combat** : Empêcher les erreurs LUA via des cadres sécurisés (Frames).
- [x] Interface de MAJ
- [x] Note de MAJ avant release
- [x] Traduction complète EN
- [x] Micro tuto (première ouverture comment ça marche+ bouton aide)

---

# 🟡 PHASE 2 – Core UX & Factory View

## 🎯 Objectif
Structurer les persos et centraliser la vision industrielle.

### Auctionator
- [x] Connexion Auctionator pour lecture prix HV
- [x] Estimation budget du jour
- [x] Estimation profit simplifiée

### Factory View (les coût doivent être éstimés depuis les infos d'auctionator)
- [x] Nouvelle Vue Factory (toggle au survol de la minimap)
  - [x] Coût total estimé d’une session
  - [x] Revenus estimés après vente
  - [x] Crafts à effectuer sur ce perso

### Profils & Configuration (une nouvelle vu pour les config de l'addon)
- [x] Définir le personnage acheteur
- [x] Définir profil par perso (pas d'impact pour le moment mais feature à venir), à mettre en dessous du nom du perso dans l'UI :
  - Equipment Crafter 
  - Resource Producer
- [x] Figer le nom du perso dans l'UI de manière que meme si on descend avec le scroll on garde le nom du perso en haut de la fenêtre.

### UI / UX
- [x] **Refonte Esthétique** : Bordures modernes et palette cohérente ("Or MCC").
- [x] **Suppression de recettes** : Bouton d'effacement rapide (✕) ajouté dans l'UI WoW et la Factory View MCC.
- [x] Icônes de rank visibles :
  - [x] Liste des compos dans recipes
  - [x] Shopping list (qualité, tooltip, prix, icônes Atlas)
- [x] Hyperliens & Tooltips cliquables (Crafts, Composants, Shopping List, Dropdowns)
- [x] Intégrer logo dans l’UI
- [x] Supprimer persos sans craft
- [x] Afficher le perso connecter en premier pour duplication métier depuis un autre perso

- [x] **Organisation des dossiers** : Création des dossiers Core, Locales, UI, Media et découpage des fichiers (UI.lua notamment) pour une meilleure maintenabilité.

---

# 🟠 PHASE 2.5 – Launch Process [v0.4] [/]

## 🎯 Objectif Work, work ! 
Orchestration complète d’une session industrielle.

### 2.5.1 fix
- [x] Compter correcteemnt les inventaires

### 2.5.2 Configuration
- [x] Définir personnage vendeur

### 2.5.3 Work, work ! (Feature Signature)[v0.4.0] [x]
- [x] Bouton "Work, work !" ou en FR 'Encore du travail ?'
- [x] Bouton "Jobs Done !" ou en FR 'Travail terminé !'
- [x] Définir si à la connexion le process doit être lancer automatiquement pour ce perso

#### Pour le perso Acheteur
- Analyse de l’HV
- Vérification Warbank
- Retrait PO si nécessaire
- Génération liste Auctionator
- Achat compos
- Dépôt Warbank
- Vérification compos
- Alerte si compos manquantes
- Craft métier 1 → métier 2
- Envoi au vendeur
- Passage aux crafteurs

#### Pour un perso Crafteur
- Vérification compos
- Alerte si compos manquantes
- Craft métier 1 → métier 2
- Envoi au vendeur

### 2.5.4 "Que me reste t-il à faire ?" [v0.4.1] [/]
- [x] Calcul et affichage de la concentration des persos (Offline inclus)
- [x] affichage du Cout en concentration du craft
- [x] affichage dans la toggle des personnages à connecter si potentielle perte de concentration (Minimap)
- [??] Configuration pour afficher les infos (dans la toggle) ou non (par défaut à "toujours afficher")
 - Lors d'une session uniquement 
 - Toujours afficher 
 - Jamais afficher
- [??] Définir une configuration: utilisé les infos rentré par l'user ou le cap par la concentration pour calculer la shopping list et les crafts à faire.

### 2.5.5 UI/UX [v0.4.2] [??]
- [??] pouvoir plier/déplier (masquer la liste des ingrédients mais garder la mardit cap et profit) les recettes dans L'UI pour que ce soit plus lisible. ça permettra d'avoir juste une sélection de recette et voir ce qui est le plus rentable en fonction des composants qu'on aura choisi
- [??] Une case "Ignorer ce personnage aujourd'hui"
- [??] Copier la recette depuis un autre personnage

---

# 🔵 PHASE 3 – Définir un mode

## Objectif
Rendre l'addon plus libre pour tous le monde. Autant pour les débutant que pour les crafteurs éxpérimentés.

### 3.1 Pouvoir séléctioner plusieurs rank d'ingrédients
-  [!!] Modifier le Dropdown pour afficher le nom de l'item et au dessous le nombres d'entrée en fonction du nombre de rank disponibles
-  [!!] Adapter le calcul de la shoppingList a cette nouvelle feature

### 3.2 Modes de sélection d'ingrédients
- [!!] **Mode Expert** : "Laisse-moi choisir mes ingrédients" - Permet de choisir manuellement les composants pour chaque recette.
 - ce mode au clic sur "Définir craft MCC " on laisse tout à blanc
- [!!] **Mode Guidé** : "Je me laisse porter" - MCC définit par défaut les ingrédients les plus simples à utiliser.
  - Bien mettre une note que ça ne sera pas forcément le plus opti mais le plus simple
  - il va y avoir un peu de travail pour pour connaitre toutes les recettes et leur ingrédients.
  - il faut conseillé les métiers simples pour les joueurs (joa, forge, enchant, calli)
  - un mini guide écrit :
   - les points à gagner rapidement et facilement
    - la liste des outils à aller chercher
    - les commandes 
    - la quète hebdo
    - le first craft  
   - Quel spé et talent séléctionner en premier
   - Ne pas oublier les outils de métier
   - Ne pas Négliger l'acuité pour créer des outils plus puissant pour le long terme### UI/UX
- [??] définir

### 3.3 UI/UX
- [!!] **Mode Semi-Automatique workflow** : Option pour activer/désactiver les automatismes spécifiques (ex: choisir de sauter ou non l'étape de dépôt automatiquement).
  - Ajouter le saut d'étaps auto pour le deposit warbound

---

# 🔵 PHASE 4 – Smart Optimisation
(on pourrait meme diviser cette phase en 3 je pense, la partie optimisation des talents / optimisation du stuff / alerte marché)

## 🎯 Objectif
Rendre l’addon intelligent sans dépendance externe. l'objectif ici est de faire un path des points de talents de métiers a dépenser en fonction de la configuration du personnage. Si c'est un mass crafteur de ressource , ou un crafteur d'équipement. Comme vus plus haut. J'aimerai que le guide des talents pour les craft de ressource soit mis en place rapidement, pour les équipements ça peu être un coming soon (avant la p4)

### Guide Talents (Urgent)
- [!!] Path recommandé rentabilité concentration
  - Mise en surbrillance Alloy / Multicraft etc.

### Optimisation des stats
- [??] Vérification cohérence stats selon profil :
  - Equipment → Resourcefulness
  - Mass crafting → Multicraft
  - Exceptions (Enchant → Ingenuity)
- [??] Alerte si acuité suffisante pour upgrade métier
- [??] Suggestion équipement métier optimal

---

# 🔵 PHASE 5 – Optimisation
(des Idées en vrac)

### Alertes Marché
- [??] Alerte compos X % moins cher
- [??] Alerte craft X % plus cher que moyenne

### Configuration avancée
- [??] Banque de guilde personnalisée (nom) (analyse et alerte si des compos sont en BDG)

### Auto-fill
- [??] **Auto-fill reagents** : Insérer automatiquement les compos choisis dans l'UI lors de l'ouverture du métier (si possible) ou bouton toggle.
- [??] **Sync ingrédients MCC ↔ WoW UI** : Sélectionner les ingrédients directement depuis l'interface WoW et/ou valider depuis MCC vers l'UI du métier WoW. + replacer le bouton "définir craft"


---

# ⚪ PHASE 6 (Optionnel) – Intégration CraftSim

## 🎯 Objectif
Calcul avancé et priorisation automatique.

- [##] Profit estimé complet via CraftSim
- [##] Alertes craft non rentable
- [##] Priorisation automatique des crafts
- [##] Modes :
  - 💰 Max Profit
  - 📦 Max Volume
  - ⚖️ Balanced

---

# 🧠 Vision Long Terme

MyCraftCompanion devient :
> L’outil d’orchestration industrielle multi-reroll.

Logistique + stratégie + optimisation.

CraftSim = bonus avancé, pas dépendance.
