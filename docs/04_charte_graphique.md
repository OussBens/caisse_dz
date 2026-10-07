# Charte graphique — CaisseDZ

Ce document décrit le système visuel réellement implémenté dans l'application (extrait de `lib/core/theme/app_style.dart` et des composants partagés), pas une proposition théorique. Toute nouvelle UI doit réutiliser ces tokens plutôt qu'introduire de nouvelles valeurs.

---

## 1. Logo & identité

- Logo : `assets/icons/caisse_dz_logo.png` — panier de course stylisé + cerveau (symbolise un POS "intelligent"), texte "Caisse DZ" en deux lignes.
- Le logo apparaît sur fond violet plein (carré arrondi) dans la sidebar et l'écran de login, et en blanc/silhouette sur l'image de fond du login.
- Accroche produit : *"Logiciel de caisse POS — Simple, Rapide et Sécurisé"*.
- Ton général : moderne, épuré, dominante violette, coins arrondis partout (aucun angle droit dans les composants interactifs).

---

## 2. Couleurs

### 2.1 Couleur de marque (primaire)

| Rôle | Nom token | Hex | Usage |
|---|---|---|---|
| Primaire | `violet` | `#755DB3` | Actions principales, item de sidebar actif, titres de section, focus des champs |
| Primaire (dégradé) | `violetGradient` | `#6C5DD3 → #9B80ED` | Fonds de header ponctuels |
| Primaire clair (fond) | `violetC` | `#F6F4FD` | Fond des champs de saisie, fond des catégories de sidebar, hover léger |
| Primaire foncé | `indigo` | `#57315A` | Contraste fort (indicateur d'onglet secondaire, texte sur fond clair) |

### 2.2 Couleur secondaire / accent

| Rôle | Nom token | Hex | Usage |
|---|---|---|---|
| Accent (call-to-action "nouveau") | `crevete` | `#FF8989` | Boutons "Nouveau", badges, accents chaleureux — toujours en complément du violet, jamais seul comme couleur de marque |

### 2.3 Neutres (gris)

| Nom token | Hex | Usage |
|---|---|---|
| `gris` | `#858585` | Icônes/texte inactifs |
| `grisC` | `#CFCFCF` | Bordures par défaut |
| `grisSC` | `#F8F8F8` | Fond de champ désactivé |
| `grisnew` | `#F6F6F6` | Fond d'écran général (`background`) |
| `grischamp` | `#F3F3F3` | Fond de champ alternatif |

### 2.4 Texte

| Nom token | Hex | Usage |
|---|---|---|
| `Tnoir` | `#0A1629` | Texte principal (`textPrimary`) |
| `TnoirC` | `#4E4E4E` | Texte principal secondaire |
| `TgrisF` | `#404040` | Texte hint/désactivé |
| `TgrisC` | `#91929E` | Texte secondaire (`textSecondary`) |
| `Tblanc` | `#FFFFFF` | Texte sur fond coloré |
| `Tblue` / `Tred` | `#408CFE` / `#FF3B00` | Liens / erreurs inline ponctuelles |

### 2.5 Couleurs sémantiques (alias)

| Rôle sémantique | Alias vers | Hex |
|---|---|---|
| `success` | `green` | `#52B8A5` |
| `warning` | `jaune` | `#ECBB5F` |
| `danger` | `red` | `#D24728` |
| `info` | `blueC` | `#558CD2` |

### 2.6 Couleurs de catégorie / module (charts, cartes de module)

`blueF #442C80` · `maron #C08252` · `maron2 #7E5973` · `green2 #4E7984` · `lavande #866F88` — utilisées pour distinguer visuellement les tuiles du menu rapide (logo → grille de modules) et certains graphiques ; assignées par rotation, pas par sens fixe.

**Règle d'usage :** le violet reste la seule couleur "de marque". Le crevete est le seul accent secondaire à statut égal. Toutes les autres couleurs (gris, sémantiques, catégorie) sont fonctionnelles, jamais décoratives seules.

---

## 3. Typographie

| Contexte | Police |
|---|---|
| Interface par défaut (français / anglais) | **Poppins** |
| Interface en arabe (RTL) | **Cairo** (bascule automatique selon la langue) |
| Échelle de texte `Appstyle.textXS…textXXLB` (utilisée par la majorité des widgets historiques) | **NunitoSans** |
| Disponible mais peu utilisé actuellement | **Tajawal** |

### Échelle de taille (`Appstyle.textXS` → `textXXLB`)

| Token | Taille | Graisse régulière | Graisse "B" (bold) |
|---|---|---|---|
| `textXS` / `textXSB` | 13px | 400 | 700 |
| `textS` / `textSB` | 14px | 400 | 700 |
| `textM` / `textMB` | 18px | 400 | 700 |
| `textL` / `textLB` | 22px | 400 | 700 |
| `textXL` / `textXLB` | 26px | 400 | 700 |
| `textXXL` / `textXXLB` | 34px | 400 | 700 |

Une échelle parallèle `textpop_XS…textpop_XLB` existe en Poppins pour les écrans qui n'utilisent pas NunitoSans.

**Règle d'usage :** titre d'écran → `textXLB`, titre de section/carte → `textLB` ou `textMB`, corps de texte → `textS`/`textSB`, libellés secondaires/metadata → `textXS`.

---

## 4. Espacement & rayons

### Espacement (multiples de 4 — `Appstyle.spaceXS…spaceXXL`)

`spaceXS 4` · `spaceS 8` · `spaceM 12` · `spaceL 16` · `spaceXL 24` · `spaceXXL 32`

### Rayons de bordure (`Appstyle.radiusSM…radiusXL`)

`radiusSM 8` · `radiusMD 12` · `radiusLG 16` · `radiusXL 24`

Exceptions observées et acceptées : les dialogs (`BaseDialog`) utilisent `14px` (entre SM et MD), les cartes de statistiques et sections utilisent souvent `16-18px`. Pour tout nouveau composant, partir de `radiusMD` (boutons, champs) ou `radiusLG` (cartes, dialogs) plutôt que d'inventer une valeur.

### Ombres

- **Carte au repos** (`Appstyle.shadowCard`) : noir 8% opacité, blur 10, offset (0, 3).
- **Survol / actif** (`Appstyle.shadowHover(color:)`) : couleur du composant à 30% opacité, blur 16, offset (0, 6) — utilisée par les boutons et cartes au survol.

---

## 5. Composants clés

### Boutons (`MainButton`)
- Rayon 12px, padding horizontal 24 / vertical 14, texte `textSB` blanc.
- Survol : léger soulèvement (-2px), fond assombri de 8%, ombre colorée (`shadowHover`).
- Appui : tassement (scale 0.97).
- Transition : 160ms, courbe `easeOut`.
- Icône à gauche par défaut (option `iconOnRight`), badge point rouge optionnel (filtres actifs), état `loading` avec spinner.
- Couleur du bouton = sens de l'action : violet (action principale/neutre), crevete (créer/nouveau), gris (annuler/secondaire), rouge (danger/supprimer).

### Dialogs (`BaseDialog` + `TitreAvecLigne`)
- Fond blanc, coins arrondis 14px, largeur/hauteur fixées par écran.
- En-tête standard : icône (26px, teinte grise) + titre (`textLB` gris) sur une ligne, puis une **ligne de séparation fine** (2px) pleine largeur sous le titre — y compris sous un éventuel bouton de fermeture "X" (passé en `trailing`, jamais dans un `Row` externe qui casserait la ligne).
- Footer : actions alignées à droite ou en `spaceBetween` (Annuler à gauche, action principale à droite).

### Sidebar (`SideBarWidget` / `AppShell`)
- Montée une seule fois par session (persistante d'un module à l'autre), largeur 80px repliée / 220px dépliée.
- Modules groupés par catégorie (Ventes, Stock, People, Autre) avec en-tête violet clair cliquable.
- Item actif : fond violet plein, icône + texte blancs à pleine opacité. Item inactif : icône/texte gris à 80% d'opacité (0.8), passant en violet au survol.
- Transition de contenu entre modules : fondu + léger glissement (260ms).

### Cartes / tuiles (menu rapide, stats)
- Fond blanc, bordure fine colorée à 15-40% d'opacité selon l'état, coins arrondis 16-18px.
- Survol : légère mise à l'échelle (1.04), ombre colorée ; icône dans un cercle à fond teinté 12-14%.

### Iconographie
- Icônes custom PNG sous `assets/icons/` (pas de police d'icônes unique) + `Icons.*` Material ponctuels pour les actions génériques (fermer, filtrer, trier).
- Toujours teintées via `color:` selon l'état (gris inactif / violet hover / blanc sur fond actif), jamais utilisées avec leurs couleurs sources.

---

## 6. Localisation & RTL

- 3 langues : français (défaut), anglais, arabe.
- En arabe, l'interface bascule en RTL complet (mise en page ET police Cairo) — tout nouveau composant doit être testé dans les deux sens plutôt que supposer LTR.

---

## 7. Principes transverses

1. **Une seule couleur de marque** (violet) + **un seul accent** (crevete) — toute autre couleur est sémantique ou fonctionnelle.
2. **Coins arrondis systématiques**, jamais d'angle droit sur un élément interactif.
3. **Micro-interactions cohérentes** : survol = léger soulèvement + ombre colorée ; clic = léger tassement ; transitions courtes (150-260ms, `easeOut`).
4. **Hiérarchie typographique stricte** via l'échelle `Appstyle.text*`, jamais de taille de police codée en dur.
5. **Espacements et rayons via tokens** (`spaceX`/`radiusX`), jamais de valeur ad hoc (`12.5`, `18`, etc.) sans raison documentée.
