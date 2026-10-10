# Charte graphique — CaisseDZ (design system 2026)

Ce document décrit le système visuel implémenté dans l'application depuis le
**rebranding** (branche `rebrand`). Source : le design system « CaisseDZ Design
System » réalisé dans Claude Design. Les valeurs vivent dans
`lib/core/theme/app_style.dart` (`Appstyle`) et `lib/main.dart` (`ThemeData`).
Toute nouvelle UI réutilise ces tokens plutôt que d'introduire de nouvelles
valeurs.

> **Compatibilité.** Les noms historiques (`violet`, `crevete`, `gris`, `Tnoir`…)
> sont conservés : seules leurs valeurs ont changé, pour que les ~3 000 usages
> existants suivent la nouvelle marque sans modification. Pour du nouveau
> code, utiliser les **rôles sémantiques** (`primary`, `surface`, `textPrimary`,
> `success`…).

---

## 1. Logo & identité

- **Wordmark** : « Caisse**DZ** » — « Caisse » en texte principal, « DZ » en
  violet de marque, Inter 700, interlettrage −3 %, toujours de gauche à droite
  (même en arabe). Widget : `lib/core/widget/wordmark.dart` (`Wordmark`,
  option `inverse` pour fond violet).
- **Logo image** (`assets/icons/caisse_dz_logo.png`), icône Windows
  (`windows/runner/resources/app_icon.ico`) et icône d'installateur : même
  dessin qu'avant (panier + cerveau), fond recoloré au violet `#6A4CF0`.
- Ton : moderne, épuré, une seule couleur de marque (violet), surfaces
  blanches sur fond gris-lavande très clair, coins arrondis généreux.

---

## 2. Couleurs

### 2.1 Échelle violette (marque)

| Token | Hex | Usage |
|---|---|---|
| `purple50` | `#F3F0FF` | Fond violet très clair (`violetC`) |
| `purple100` | `#E8E2FF` | |
| `purple200` | `#D2C7FF` | « DZ » du wordmark inversé |
| `purple300` | `#B3A1FF` | |
| `purple400` | `#9077FA` | |
| `purple500` | `#7B5CF5` | Début du dégradé CTA (`crevete`) |
| `purple600` | `#6A4CF0` | **Primary** (`violet`, `primary`) |
| `purple700` | `#5638CC` | Primary pressé / texte violet (`indigo`, `primaryDark`) |
| `purple800` | `#422BA0` | (`blueF`, `maron` — ancien brun) |
| `purple900` | `#2E1F70` | (`maron2`) |
| `purple950` | `#1B1245` | |

`primarySoft #ECE8FF` : fond des boutons secondaires, badges et icônes teintées
de marque.

### 2.2 Neutres & texte

| Rôle | Token (ancien nom) | Hex |
|---|---|---|
| Fond d'écran | `background` (`grisnew`) | `#F6F6FA` |
| Surface (cartes, dialogs) | `surface` (`Tblanc`) | `#FFFFFF` |
| Surface 2 (champs, chips, boutons icône) | `surface2` (`grischamp`, `grisSC`) | `#F1F0F6` |
| Bordure de carte | `surfaceBorder` | `#EEEDF4` |
| Survol neutre | `neutral200` | `#E7E5F0` |
| Texte principal | `textPrimary` (`Tnoir`) | `#1B1A2E` |
| Texte secondaire / icônes inactives | `textSecondary` (`TgrisC`, `gris`) | `#8A889E` |
| Texte tertiaire / désactivé / bordures | `border` (`grisC`) | `#B4B2C4` |
| Texte gris foncé | `TgrisF`, `lavande` | `#6A6780` |
| Liens, titres de section | `Tblue` | `#6A4CF0` (primary) |

### 2.3 Sémantiques

Chaque rôle a trois tons : **fort** (icônes, points, boutons), **soft** (fond
teinté) et **ink** (texte sur le fond soft, contraste 4.5:1).
`Appstyle.softPour(c)` / `Appstyle.inkPour(c)` donnent les variantes d'une
couleur.

| Rôle | Fort | Soft | Ink |
|---|---|---|---|
| `success` (`green`) | `#16A34A` | `#E6F7EE` | `#0F7A37` |
| `warning` (`jaune`) | `#E0A100` | `#FFF6DD` | `#8F6400` |
| `danger` (`red`) | `#E5395F` | `#FDE8EE` | `#C2254A` |
| `info` (`blueC`) | `#3B6FF5` | `#E6EEFF` | `#2A55CC` |

Les couleurs Material codées en dur (`Colors.red`, `green`, `orange`, `blue`,
`grey`…) ont été remplacées par ces rôles dans tout `lib/`.

### 2.4 Dégradés

- `violetGradient` (hero) : `#6A4CF0 → #A996FB`, 135°.
- `ctaGradient` : `#7B5CF5 → #6A4CF0 → #5638CC`.

**Règle d'usage :** le violet est la **seule** couleur de marque (l'ancien accent
corail `crevete` devient un violet). Les autres couleurs sont sémantiques.
Couleurs à distinguer : différence de luminosité, pas seulement de teinte.

---

## 3. Typographie

| Contexte | Police |
|---|---|
| Latin (français, anglais) et chiffres | **Inter** (400, 500, 600, 700) |
| Arabe | **Alexandria** (400, 500, 600, 700) |

- Fichiers : `assets/fonts/Inter-*.ttf`, `assets/fonts/Alexandria-*.ttf` (SIL
  Open Font License, `assets/fonts/OFL-*.txt`).
- Inter n'a pas de glyphes arabes : `fontFamilyFallback: ['Alexandria']`, donc
  l'arabe s'affiche automatiquement en Alexandria. En RTL, le thème met
  Alexandria en tête.
- Les PDF arabes gardent **Cairo** (formes de présentation arabes nécessaires
  au moteur PDF).

### Échelle (`Appstyle.textXS` → `textXXLB`)

| Token | Taille | Régulier | « B » |
|---|---|---|---|
| `textXS` / `textXSB` | 13px | 400 | 600 |
| `textS` / `textSB` | 14px | 400 | 600 |
| `textM` / `textMB` | 18px | 400 | 600 |
| `textL` / `textLB` | 22px | 400 | 600 |
| `textXL` / `textXLB` | 26px | 400 | 600 |
| `textXXL` / `textXXLB` | 34px | 400 | 700 |

Le gras du design system est le **semibold (600)** ; le bold (700) est réservé
aux très grands titres et au wordmark. L'échelle `textpop_*` utilise aussi Inter.

Référence du design system (mobile) : display 32/40 700, h1 24/32 600,
h2 20/28 600, h3 17/24 600, corps 15/22 400, petit 13/18, légende 12/16 500,
label 11/14 600.

---

## 4. Espacement, rayons, ombres

### Espacement (grille de 4)

`spaceXS 4` · `spaceS 8` · `spaceM 12` · `spaceL 16` · `spaceXL 24` · `spaceXXL 32`

### Rayons

| Token | Valeur | Usage |
|---|---|---|
| `radiusXS` | 6 | Case à cocher, petit badge clavier |
| `radiusSM` | 8 | Petits éléments |
| `radiusMD` | 12 | Champs, boutons icône |
| `radiusButton` | 14 | Boutons |
| `radiusLG` | 16 | Panneaux |
| `radiusCard` | 20 | Cartes |
| `radiusXL` | 24 | Grandes sections |
| `radiusDialog` | 28 | Dialogs |
| `radiusPill` | 999 | Badges, chips |

Tous les `BorderRadius.circular(n)` de l'app passent par ces tokens.

### Ombres

Teinte `shadowTint #281E5A` (violet très foncé), jamais du noir pur.

- `shadowCard` : 6 %, blur 16, offset (0, 4).
- `shadowRaised` : 10 %, blur 28, offset (0, 8).
- `shadowSoft` / `shadowMedium` : versions constantes (7 % / 16 %).
- `shadowHover(color:)` : couleur du composant à 30 % (survol).

---

## 5. Composants

### Boutons (`MainButton`)
- Rayon 14, texte `textSB` (600).
- Variante **neutre** automatique : un bouton `Appstyle.gris` (Annuler,
  Fermer, Vider…) dont le texte est blanc ou non précisé devient fond
  `surface2` + texte et icône `textPrimary` (contraste lisible).
- Survol : soulèvement −2px, fond assombri, ombre colorée ; appui : scale 0.97.

### Champs (`FieldDecoration`)
- Vide : fond `surface2`, sans bordure visible.
- Focus : fond blanc, bordure `primary` 1.5px, halo `focusRing` 4px (primary 32 %).
- Rempli : teinte succès (repère « champ renseigné » conservé).
- Erreur : fond `dangerSoft`, bordure `danger`.

### Badges (`StatusBadge`, `EtatBadge`)
- Pastille (pill) 24px, fond « soft », point de la couleur forte, libellé
  11px/600 en teinte « ink ».

### Dialogs (`BaseDialog`)
- Fond blanc, rayon 28, bordure `surfaceBorder`, padding 24/20.

### Thème Material (`lib/main.dart`)
- Champs, boutons (elevated, filled, outlined, text), cartes, dialogs, chips,
  infobulles, snackbars, scrollbar et indicateurs de progression suivent les
  mêmes tokens.

### Iconographie
- Icônes PNG sous `assets/icons/`, toujours teintées via `color:`. Le design
  system utilise Lucide (trait 1.75) ; la migration des PNG vers Lucide n'est
  pas faite (voir « Reste à faire »).

---

## 6. Localisation & RTL

- Français (défaut), anglais, arabe ; RTL complet en arabe, police Alexandria.
- Le wordmark et les montants restent LTR.

---

## 7. Reste à faire / hors périmètre du rebranding

- **Thème sombre** : défini dans le design system (fond `#0E0C16`, surface
  `#181525`, primary `#8B70FA`…) mais non activé (l'app n'a pas de mode sombre).
- **Icônes Lucide** à la place des PNG.
- **Image de fond du login** (`assets/images/login_back.png`) : illustration
  violette conservée telle quelle.
