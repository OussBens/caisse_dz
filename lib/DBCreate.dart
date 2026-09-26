import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DbCreator {
  static Database? _db;
  static final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// Ferme la connexion active (nécessaire avant de remplacer le fichier
  /// .db lors d'une restauration de sauvegarde).
  static Future<void> closeDb() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }

  static String getDbFilePath() => path.join(getLocalFolder(), 'caisse_real.db');

  /// Fichier d'identifiant machine (voir [_getMachineId]) utilisé pour
  /// dériver la clé de chiffrement de la base. Doit être sauvegardé et
  /// restauré EN MÊME TEMPS que le `.db` (voir BackupService) — sans lui,
  /// une base restaurée sur une machine où ce fichier a été perdu peut
  /// devenir indéchiffrable.
  static String getMidFilePath() => path.join(getLocalFolder(), '.mid');

  static String getLocalFolder() {
    final home = Platform.isWindows
        ? Platform.environment['APPDATA']!
        : Platform.environment['HOME']!;
    final folder = path.join(home, 'Caisse DZ');
    final dir = Directory(folder);
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return folder;
  }

  // Helper method to check activation status from secure storage
  static Future<bool> _isActivated() async {
    try {
      final encryptedActivation = await _secureStorage.read(key: 'activated');
      return encryptedActivation != null && encryptedActivation.isNotEmpty;
    } catch (e) {
      print('Error checking activation status: $e');
      return false;
    }
  }

  static Future<Database> openDb() async {
    // Réutilise la connexion déjà ouverte : chaque méthode de service appelle
    // openDb() indépendamment (parfois 8-9 fois pour un seul écran, ex.
    // ProduitScreen.loadAllData), donc sans ce court-circuit chaque appel
    // recréait une nouvelle DatabaseFactory et une nouvelle connexion native
    // vers le même fichier sans jamais fermer la précédente, ce qui finissait
    // par saturer les handles/locks SQLite et geler l'appli.
    if (_db != null && _db!.isOpen) {
      return _db!;
    }

    // Get activation status from secure storage instead of SharedPreferences

   //Maitnent reste comme ca toujours true mais aprés changé vers is Activated oiu non
    final isActivated = await _isActivated();

    final dbName = isActivated ? 'caisse_real.db' : 'caisse_real.db';


    final dbPath = path.join(getLocalFolder(), dbName);

    print('Opening database: $dbName (Activated: $isActivated)');
    print('Database path: $dbPath');

    final machineId = await _getMachineId();
    final password = sha256.convert(utf8.encode("CAISSE_${machineId}_SECRET")).toString();

    sqfliteFfiInit();

    final databaseFactory = createDatabaseFactoryFfi(ffiInit: sqfliteFfiInit);

    _db = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 47,
        onConfigure: (db) async {
          await db.execute("PRAGMA KEY = '$password'");
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          print('Creating database schema for ${isActivated ? "REAL" : "DEMO"} mode');

          try {
            await db.rawQuery("SELECT count(*) FROM sqlite_master");
          } catch (e) {
            throw Exception('Failed to initialize encrypted database: $e');
          }

          final now = DateTime.now().toIso8601String();

          // Create all tables first (always needed)
          await _createRole(db);
          await _createParametre(db);
          await _createZakatParametre(db);
          await _createUtilisateur(db);
          await _createMagasins(db);
          await _createCategories(db);
          await _createSousCategories(db);
          await _createClients(db);
          await _createFournisseurs(db);
          await _createRemises(db);
          await _createCaisseGestion(db);
          await _createProduits(db);
          await _createParmUser(db);  // This creates the userparam table
          await _createProduitMagasinDetail(db);
          await _createPacks(db);
          await _createPackdetaile(db);
          await _createPannier(db);
          await _createPannierProduit(db);
          await _createMovmentes(db);
          await _createSortie(db);
          await _createRetours(db);
          await _createTransfertCaisse(db);
          await _createTransfertMagasin(db);
          await _createVerssement(db);
          await _createZakat(db);
          await _createBesionList(db);
          await _createBesionListDetail(db);
          await _createSmartScan(db);
          await _createSmartScanProduit(db);
          await _createHistorique(db);
          await _createProduitCodeDetail(db);
          await _createCatalogSync(db);
          await _createCaisseParam(db);
          await _createRoleDetail(db);
          await _createEntrepriseParam(db);
          await _createPaiementParam(db);
          await _createImprimanteParam(db);
          await _createBackupParam(db);
          await _createBonReception(db);
          await _createJournalFiscal(db);
          await _createClotureCaisse(db);
          await _createCaisseSession(db);
          await _createCaisseMouvement(db);

          // ONLY INSERT DEFAULT DATA IF ACTIVATED
          if (isActivated) {
            print('Inserting default data for REAL mode');
            await _insertDefaultData(db, now);
          } else {
            print('Demo mode - no default data inserted');
          }
        },
        // Schema migration hook. Bump `version` above and add a branch here
        // whenever a future feature needs to alter an existing installation's
        // schema (new column/table/index) without losing existing data.
        // Example for the next migration:
        //   if (oldVersion < 2) {
        //     await db.execute('ALTER TABLE produits ADD COLUMN nouvelle_colonne TEXT');
        //   }
        onUpgrade: (db, oldVersion, newVersion) async {
          print('Upgrading database from v$oldVersion to v$newVersion');

          if (oldVersion < 2) {
            // Suppression des champs compteurs/historique dénormalisés
            // devenus inutiles (recalculés en direct ou plus utilisés).
            const dropColumns = <String, List<String>>{
              'categories': ['nombre'],
              'sous_categories': ['nombre'],
              'clients': ['credit', 'total_achat', 'nbr_achat'],
              'remises': ['nombre'],
              'packs': ['nomber'],
              'magasins': ['nombre_produit', 'taux_stockage'],
              'fournisseurs': [
                'credit', 'total_achat', 'nbr_achat', 'dernier_achat',
                'nbrRetour', 'totalVerse', 'solde', 'avance', 'nbrVersement',
              ],
              'produits': [
                'quantitederneirachat', 'datederneirachat', 'totalretour',
                'totalachat', 'totalvente', 'besion_status',
              ],
              'role': ['nombre_utilisateur'],
              'utilisateur': ['nbr_vente', 'total_vendu'],
            };

            for (final entry in dropColumns.entries) {
              for (final column in entry.value) {
                try {
                  await db.execute('ALTER TABLE ${entry.key} DROP COLUMN $column');
                } catch (e) {
                  print('Skip drop ${entry.key}.$column: $e');
                }
              }
            }
          }

          if (oldVersion < 3) {
            // produit_code_detail : produit_nom redondant, on identifie
            // désormais uniquement par produit_code.
            try {
              await db.execute('ALTER TABLE produit_code_detail DROP COLUMN produit_nom');
            } catch (e) {
              print('Skip drop produit_code_detail.produit_nom: $e');
            }
          }

          if (oldVersion < 4) {
            // produit_magasin_detail : magasin_nom/produit_nom redondants,
            // on identifie désormais uniquement par magasin_code/produit_code.
            for (final column in ['magasin_nom', 'produit_nom']) {
              try {
                await db.execute('ALTER TABLE produit_magasin_detail DROP COLUMN $column');
              } catch (e) {
                print('Skip drop produit_magasin_detail.$column: $e');
              }
            }
          }

          if (oldVersion < 5) {
            // panniers : ajout de client_code pour lier fiablement le panier
            // au client (au lieu du nom, qui peut être ambigu ou renommé),
            // même principe que retours.client_code.
            try {
              await db.execute('ALTER TABLE panniers ADD COLUMN client_code TEXT REFERENCES clients(code)');
            } catch (e) {
              print('Skip add panniers.client_code: $e');
            }
          }

          if (oldVersion < 6) {
            // Champs d'audit "créé par" : on n'identifie plus le créateur par
            // son nom (modifiable) mais uniquement par cree_par_code (clé
            // étrangère stable vers utilisateur.code). Le nom est donc
            // supprimé ; panniers n'en avait pas besoin car caisser_code
            // joue déjà ce rôle.
            const tablesWithCreePar = <String>[
              'role', 'utilisateur', 'magasins', 'categories', 'sous_categories',
              'clients', 'remises', 'packs', 'userparam', 'produits',
              'fournisseurs', 'parametre', 'zakatParam', 'produit_pack_detail',
              'mouvements', 'entree', 'produit_magasin_detail', 'panniers',
              'retours', 'verssements', 'smart_scan', 'besion_list_detail',
              'besionList', 'caisseGestion', 'pannierProduit',
              'smartScanProduit', 'sortie', 'transfert', 'zakat', 'Historique',
              'produit_code_detail', 'roledetail', 'caisseparam',
            ];

            for (final table in tablesWithCreePar) {
              try {
                await db.execute('ALTER TABLE $table DROP COLUMN cree_par');
              } catch (e) {
                print('Skip drop $table.cree_par: $e');
              }
            }
          }

          if (oldVersion < 7) {
            // Champ d'audit "modifié par" : même principe que cree_par_code,
            // on identifie le dernier modificateur par modif_par_code (clé
            // étrangère stable vers utilisateur.code) plutôt que par son nom.
            const tablesWithModifPar = <String>[
              'caisseparam', 'roledetail', 'categories', 'sous_categories',
              'clients', 'remises', 'packs', 'userparam', 'produits',
              'fournisseurs', 'parametre', 'zakatParam', 'magasins',
              'mouvements', 'entree', 'panniers', 'retours', 'verssements',
              'smart_scan', 'utilisateur', 'role', 'besion_list_detail',
              'besionList', 'caisseGestion', 'pannierProduit',
              'smartScanProduit', 'sortie', 'transfert', 'zakat',
            ];

            for (final table in tablesWithModifPar) {
              try {
                await db.execute('ALTER TABLE $table RENAME COLUMN modif_par TO modif_par_code');
              } catch (e) {
                print('Skip rename $table.modif_par: $e');
              }
            }
          }

          if (oldVersion < 8) {
            // Champ d'audit "annulé par" : même principe que cree_par_code /
            // modif_par_code, on identifie l'annulateur par annul_par_code
            // (code utilisateur, stable) plutôt que par son nom.
            const tablesWithAnnulPar = <String>[
              'roledetail', 'categories', 'sous_categories', 'clients',
              'remises', 'packs', 'fournisseurs', 'magasins', 'mouvements',
              'entree', 'panniers', 'retours', 'verssements', 'smart_scan',
              'utilisateur', 'role', 'besion_list_detail', 'besionList',
              'caisseGestion', 'pannierProduit', 'smartScanProduit', 'sortie',
              'transfert', 'zakat',
            ];

            for (final table in tablesWithAnnulPar) {
              try {
                await db.execute('ALTER TABLE $table RENAME COLUMN annul_par TO annul_par_code');
              } catch (e) {
                print('Skip rename $table.annul_par: $e');
              }
            }

            // produits utilise une nomenclature différente (annuler_par).
            try {
              await db.execute('ALTER TABLE produits RENAME COLUMN annuler_par TO annuler_par_code');
            } catch (e) {
              print('Skip rename produits.annuler_par: $e');
            }
          }

          if (oldVersion < 9) {
            // Suite de la normalisation des relations métier (produit, client,
            // fournisseur, magasin, catégorie/sous-catégorie, caisse) : on
            // n'identifie plus ces entités par leur nom (dénormalisé, non
            // stable) mais par leur code/id, même principe que les champs
            // d'audit cree_par_code/modif_par_code/annul_par_code.

            // mouvements : nom_produit supprimé (code_produit suffit) ;
            // client/fournisseur (nom) remplacés par client_code/fournisseur_code.
            try {
              await db.execute('ALTER TABLE mouvements ADD COLUMN client_code TEXT REFERENCES clients(code)');
            } catch (e) {
              print('Skip add mouvements.client_code: $e');
            }
            try {
              await db.execute('ALTER TABLE mouvements ADD COLUMN fournisseur_code TEXT REFERENCES fournisseurs(code)');
            } catch (e) {
              print('Skip add mouvements.fournisseur_code: $e');
            }
            try {
              await db.execute('''
                UPDATE mouvements
                SET fournisseur_code = (
                  SELECT code FROM fournisseurs WHERE fournisseurs.nom = mouvements.fournisseur
                )
                WHERE fournisseur IS NOT NULL
              ''');
            } catch (e) {
              print('Skip backfill mouvements.fournisseur_code: $e');
            }
            try {
              await db.execute('''
                UPDATE mouvements
                SET client_code = (
                  SELECT code FROM clients WHERE clients.nom = mouvements.client
                )
                WHERE client IS NOT NULL
              ''');
            } catch (e) {
              print('Skip backfill mouvements.client_code: $e');
            }
            // sortie : produit (nom) supprimé (produit_code suffit) ;
            // categorie/souscategorie (nom) remplacés par categorie_code/sous_categorie_code.
            try {
              await db.execute('ALTER TABLE sortie ADD COLUMN categorie_code TEXT REFERENCES categories(code)');
            } catch (e) {
              print('Skip add sortie.categorie_code: $e');
            }
            try {
              await db.execute('ALTER TABLE sortie ADD COLUMN sous_categorie_code TEXT REFERENCES sous_categories(code)');
            } catch (e) {
              print('Skip add sortie.sous_categorie_code: $e');
            }
            try {
              await db.execute('''
                UPDATE sortie
                SET categorie_code = (
                  SELECT code FROM categories WHERE categories.nom = sortie.categorie
                )
                WHERE categorie IS NOT NULL
              ''');
            } catch (e) {
              print('Skip backfill sortie.categorie_code: $e');
            }
            try {
              await db.execute('''
                UPDATE sortie
                SET sous_categorie_code = (
                  SELECT code FROM sous_categories WHERE sous_categories.nom = sortie.souscategorie
                )
                WHERE souscategorie IS NOT NULL
              ''');
            } catch (e) {
              print('Skip backfill sortie.sous_categorie_code: $e');
            }

            // entree : produit/fournisseur (nom) supprimés, produit_code/
            // fournisseur_code (déjà présents) suffisent.

            // produits : categorie/sous_categorie/remise (nom) supprimés
            // (categorie_id/sous_categorie_id/remise_id suffisent) ;
            // fournisseur (nom) remplacé par fournisseur_code.
            try {
              await db.execute('ALTER TABLE produits ADD COLUMN fournisseur_code TEXT REFERENCES fournisseurs(code)');
            } catch (e) {
              print('Skip add produits.fournisseur_code: $e');
            }
            try {
              await db.execute('''
                UPDATE produits
                SET fournisseur_code = (
                  SELECT code FROM fournisseurs WHERE fournisseurs.nom = produits.fournisseur
                )
                WHERE fournisseur IS NOT NULL
              ''');
            } catch (e) {
              print('Skip backfill produits.fournisseur_code: $e');
            }

            const dropColumnsV9 = <String, List<String>>{
              'mouvements': ['nom_produit', 'client', 'fournisseur'],
              'sortie': ['produit', 'categorie', 'souscategorie'],
              'entree': ['produit', 'fournisseur'],
              'produits': ['categorie', 'sous_categorie', 'remise', 'fournisseur'],
            };
            for (final entry in dropColumnsV9.entries) {
              for (final column in entry.value) {
                try {
                  await db.execute('ALTER TABLE ${entry.key} DROP COLUMN $column');
                } catch (e) {
                  print('Skip drop ${entry.key}.$column: $e');
                }
              }
            }
          }

          if (oldVersion < 10) {
            // Suite de la normalisation : besionList, caisseGestion, panniers,
            // pannierProduit, produit_pack_detail, retours, smart_scan,
            // smartScanProduit, sous_categories, transfert, verssements.

            // besionList : fournisseur (nom) -> fournisseur_code.
            try {
              await db.execute('ALTER TABLE besionList ADD COLUMN fournisseur_code TEXT REFERENCES fournisseurs(code)');
            } catch (e) {
              print('Skip add besionList.fournisseur_code: $e');
            }
            try {
              await db.execute('''
                UPDATE besionList
                SET fournisseur_code = (
                  SELECT code FROM fournisseurs WHERE fournisseurs.nom = besionList.fournisseur
                )
                WHERE fournisseur IS NOT NULL
              ''');
            } catch (e) {
              print('Skip backfill besionList.fournisseur_code: $e');
            }

            // sous_categories : categorie_nom -> categorie_code (backfill via
            // categorie_id, plus fiable qu'un matching par nom).
            try {
              await db.execute('ALTER TABLE sous_categories ADD COLUMN categorie_code TEXT REFERENCES categories(code)');
            } catch (e) {
              print('Skip add sous_categories.categorie_code: $e');
            }
            try {
              await db.execute('''
                UPDATE sous_categories
                SET categorie_code = (
                  SELECT code FROM categories WHERE categories.id = sous_categories.categorie_id
                )
              ''');
            } catch (e) {
              print('Skip backfill sous_categories.categorie_code: $e');
            }

            // verssements : beneficiare (nom, client ou fournisseur selon
            // typebeneficiare) -> beneficiare_code.
            try {
              await db.execute('ALTER TABLE verssements ADD COLUMN beneficiare_code TEXT');
            } catch (e) {
              print('Skip add verssements.beneficiare_code: $e');
            }
            try {
              await db.execute('''
                UPDATE verssements
                SET beneficiare_code = (
                  SELECT code FROM clients WHERE clients.nom = verssements.beneficiare
                )
                WHERE typebeneficiare = 'Client'
              ''');
            } catch (e) {
              print('Skip backfill verssements.beneficiare_code (client): $e');
            }
            try {
              await db.execute('''
                UPDATE verssements
                SET beneficiare_code = (
                  SELECT code FROM fournisseurs WHERE fournisseurs.nom = verssements.beneficiare
                )
                WHERE typebeneficiare = 'Fournisseur'
              ''');
            } catch (e) {
              print('Skip backfill verssements.beneficiare_code (fournisseur): $e');
            }

            const dropColumnsV10 = <String, List<String>>{
              'besionList': ['fournisseur'],
              'caisseGestion': ['magasin'],
              'panniers': ['client', 'caisser'],
              'pannierProduit': ['nom_produit'],
              'produit_pack_detail': ['pack_nom', 'produit_nom'],
              'retours': ['nom_produit', 'client', 'fournisseur'],
              'smart_scan': ['fournisseur'],
              'smartScanProduit': ['nom_produit'],
              'sous_categories': ['categorie_nom'],
              'transfert': ['caisse_exp', 'caisse_dest'],
              'verssements': ['beneficiare'],
            };
            for (final entry in dropColumnsV10.entries) {
              for (final column in entry.value) {
                try {
                  await db.execute('ALTER TABLE ${entry.key} DROP COLUMN $column');
                } catch (e) {
                  print('Skip drop ${entry.key}.$column: $e');
                }
              }
            }
          }

          if (oldVersion < 11) {
            // Seuil par produit (seuil_min/seuil_max/seuil_bool) remplacé par
            // un seuil global unique (table parametre.minimum/maximum).
            for (final column in ['seuil_min', 'seuil_max', 'seuil_bool']) {
              try {
                await db.execute('ALTER TABLE produits DROP COLUMN $column');
              } catch (e) {
                print('Skip drop produits.$column: $e');
              }
            }
          }

          if (oldVersion < 12) {
            // Smart Scan : montant/nbrProduit/reste sont désormais toujours
            // calculés depuis la liste de produits, donc ecart/activity/
            // quantite_article ne sont plus utiles.
            for (final column in ['ecart', 'activity', 'quantite_article']) {
              try {
                await db.execute('ALTER TABLE smart_scan DROP COLUMN $column');
              } catch (e) {
                print('Skip drop smart_scan.$column: $e');
              }
            }
          }

          if (oldVersion < 13) {
            // Trace le panier (retour client) ou l'entrée/smartscan (retour
            // fournisseur) à l'origine d'un retour.
            try {
              await db.execute('ALTER TABLE retours ADD COLUMN retour_correspond_de TEXT');
            } catch (e) {
              print('Skip add retours.retour_correspond_de: $e');
            }
          }

          if (oldVersion < 14) {
            // Module Paramètres : infos boutique, visibilité des modes de
            // paiement, config imprimante, config sauvegarde DB.
            await _createEntrepriseParam(db);
            await _createPaiementParam(db);
            await _createImprimanteParam(db);
            await _createBackupParam(db);
          }

          if (oldVersion < 15) {
            // Trace le panier à l'origine d'un versement (encaissement à la
            // vente), pour pouvoir répercuter une modification du montant
            // versé du panier sur le versement correspondant.
            try {
              await db.execute('ALTER TABLE verssements ADD COLUMN code_pannier TEXT');
            } catch (e) {
              print('Skip add verssements.code_pannier: $e');
            }
          }

          if (oldVersion < 16) {
            // Entrée rapide (1 produit) fusionnée dans Smart Scan : toute
            // création d'entrée passe désormais par smart_scan/
            // smartScanProduit (Smart Scan à 1 produit). On migre les
            // anciennes lignes 'entree' avant de supprimer la table.
            // Note : 'entree' ne stockait pas de prix de vente par ligne,
            // on utilise donc le prix de vente actuel du produit en repli.
            try {
              final entrees = await db.query('entree');
              for (final e in entrees) {
                final produitRows = await db.query(
                  'produits',
                  where: 'code = ?',
                  whereArgs: [e['produit_code']],
                  limit: 1,
                );
                final prixVenteActuel = produitRows.isNotEmpty
                    ? (produitRows.first['prix_vente'] as num).toDouble()
                    : (e['prix'] as num).toDouble();

                await db.insert('smart_scan', {
                  'code': e['code'],
                  'date': e['date'],
                  'montant': e['montant'],
                  'paye': e['montant'],
                  'reste': 0.0,
                  'nbr_produit': 1,
                  'fournisseur_code': e['fournisseur_code'],
                  'etat': e['etat'],
                  'observation': e['observation'],
                  'date_cree': e['date_cree'],
                  'cree_par_code': e['cree_par_code'],
                  'date_modif': e['date_modif'],
                  'modif_par_code': e['modif_par_code'],
                  'date_annul': e['date_annul'],
                  'annul_par_code': e['annul_par_code'],
                  'motif_annul': e['motif_annul'],
                });

                await db.insert('smartScanProduit', {
                  'code_SmartScan': e['code'],
                  'code_produit': e['produit_code'],
                  'quantite': e['quantite'],
                  'prix': e['prix'],
                  'prixVente': prixVenteActuel,
                  'total': e['montant'],
                  'cree_par_code': e['cree_par_code'],
                  'date_cree': e['date_cree'],
                  'etat': e['etat'],
                  'modif_par_code': e['modif_par_code'],
                  'date_modif': e['date_modif'],
                  'annul_par_code': e['annul_par_code'],
                  'date_annul': e['date_annul'],
                  'motif_annul': e['motif_annul'],
                });
              }
            } catch (e) {
              print('Skip migration entree -> smart_scan: $e');
            }

            try {
              await db.execute('DROP TABLE IF EXISTS entree');
            } catch (e) {
              print('Skip drop table entree: $e');
            }
          }

          if (oldVersion < 17) {
            // code_pannier (rempli seulement pour les versements liés à un
            // encaissement panier) renommé en code_operation et rendu
            // obligatoire : un versement doit désormais toujours référencer
            // l'opération qui le justifie (panier, retour ou smart scan).
            // Les versements historiques sans code_pannier (créés via les
            // anciens formulaires manuels, qui ne le renseignaient pas)
            // reçoivent leur propre code en repli, faute de lien réel connu.
            try {
              await db.execute('ALTER TABLE verssements ADD COLUMN code_operation TEXT');
            } catch (e) {
              print('Skip add verssements.code_operation: $e');
            }
            try {
              await db.execute('''
                UPDATE verssements
                SET code_operation = COALESCE(code_pannier, code)
              ''');
            } catch (e) {
              print('Skip backfill verssements.code_operation: $e');
            }
            try {
              await db.execute('ALTER TABLE verssements DROP COLUMN code_pannier');
            } catch (e) {
              print('Skip drop verssements.code_pannier: $e');
            }
          }

          if (oldVersion < 18) {
            // Table de correspondance produit local <-> produit du catalogue
            // distant bensds.com, pour la synchronisation (CatalogSyncService).
            try {
              await _createCatalogSync(db);
            } catch (e) {
              print('Skip create catalog_sync: $e');
            }
          }

          if (oldVersion < 19) {
            // caisse_dz devient mono-magasin : l'écran/service de gestion des
            // magasins est supprimé, donc le flag de permission roledetail.magasin
            // n'a plus de sens. La table magasins (avec sa seule ligne système
            // MAG0000) est conservée comme FK fixe pour gestion_caisse,
            // caisseparam et produit_magasin_detail.
            try {
              await db.execute('ALTER TABLE roledetail DROP COLUMN magasin');
            } catch (e) {
              print('Skip drop roledetail.magasin: $e');
            }
          }

          if (oldVersion < 20) {
            // Le montant versé/reste d'un pannier n'est plus stocké : il est
            // recalculé dynamiquement à partir des versements liés
            // (table verssements, code_operation = code du pannier).
            try {
              await db.execute('ALTER TABLE panniers DROP COLUMN verse');
            } catch (e) {
              print('Skip drop panniers.verse: $e');
            }
            try {
              await db.execute('ALTER TABLE panniers DROP COLUMN reste');
            } catch (e) {
              print('Skip drop panniers.reste: $e');
            }
          }

          if (oldVersion < 21) {
            // Même principe que pour panniers (v20) : le montant versé/reste
            // d'un smart scan (entrée fournisseur) n'est plus stocké, il est
            // recalculé depuis les versements liés (code_operation = code du
            // smart scan).
            try {
              await db.execute('ALTER TABLE smart_scan DROP COLUMN paye');
            } catch (e) {
              print('Skip drop smart_scan.paye: $e');
            }
            try {
              await db.execute('ALTER TABLE smart_scan DROP COLUMN reste');
            } catch (e) {
              print('Skip drop smart_scan.reste: $e');
            }
          }

          if (oldVersion < 22) {
            // Nouvelle table pour la réception de photos de bons fournisseur
            // envoyées depuis l'app mobile (ou jointes depuis le disque),
            // en attente d'être transformées en Smart Scan (voir écran
            // Entrée > onglet IA).
            try {
              await _createBonReception(db);
            } catch (e) {
              print('Skip create bon_reception: $e');
            }
          }

          if (oldVersion < 23) {
            // Le fournisseur d'un bon reçu du mobile est désormais résolu
            // vers un code stable (matché par nom, ou fournisseur système
            // "Général" par défaut) plutôt que stocké en texte libre only.
            try {
              await db.execute('ALTER TABLE bon_reception ADD COLUMN fournisseur_code TEXT');
            } catch (e) {
              print('Skip add bon_reception.fournisseur_code: $e');
            }
          }

          if (oldVersion < 24) {
            // Trace qui a transformé la photo en Smart Scan, affiché sur la
            // vignette (écran Entrée > IA) à côté des dates de réception/scan.
            try {
              await db.execute('ALTER TABLE bon_reception ADD COLUMN traite_par_code TEXT');
            } catch (e) {
              print('Skip add bon_reception.traite_par_code: $e');
            }
          }

          if (oldVersion < 25) {
            // Dossier de stockage configurable pour tous les fichiers générés
            // (Excel, PDF de facture/BL...) — voir Paramètres > Sauvegarde.
            try {
              await db.execute('ALTER TABLE backup_param ADD COLUMN dossier_documents TEXT');
            } catch (e) {
              print('Skip add backup_param.dossier_documents: $e');
            }
          }

          if (oldVersion < 26) {
            // Caisse attachée à l'utilisateur : la caisse de l'écran caisse
            // (paramètre) est verrouillée sur cette caisse pour tout rôle
            // autre que Admin.
            try {
              await db.execute('ALTER TABLE utilisateur ADD COLUMN caisse_code TEXT REFERENCES caisseGestion(code)');
            } catch (e) {
              print('Skip add utilisateur.caisse_code: $e');
            }
          }

          if (oldVersion < 27) {
            // Token d'API mobile : généré par POST /api/auth/login, vérifié
            // ensuite via le header Authorization Bearer sur les endpoints
            // de sync avec l'app compagnon (BonReceptionServer).
            try {
              await db.execute('ALTER TABLE utilisateur ADD COLUMN api_token TEXT');
            } catch (e) {
              print('Skip add utilisateur.api_token: $e');
            }
          }

          if (oldVersion < 28) {
            // Traçabilité de l'appareil mobile source pour les mouvements de
            // stock créés via POST /api/sync/push/stock-movement.
            try {
              await db.execute('ALTER TABLE smart_scan ADD COLUMN device_id_mobile TEXT');
            } catch (e) {
              print('Skip add smart_scan.device_id_mobile: $e');
            }
          }

          if (oldVersion < 29) {
            // Traçabilité de l'appareil mobile source pour les produits
            // créés/modifiés via POST /api/sync/push/product.
            try {
              await db.execute('ALTER TABLE produits ADD COLUMN device_id_mobile TEXT');
            } catch (e) {
              print('Skip add produits.device_id_mobile: $e');
            }
          }

          if (oldVersion < 30) {
            // Traçabilité de l'appareil mobile source pour les retours créés
            // via POST /api/sync/push/return.
            try {
              await db.execute('ALTER TABLE retours ADD COLUMN device_id_mobile TEXT');
            } catch (e) {
              print('Skip add retours.device_id_mobile: $e');
            }
          }

          if (oldVersion < 31) {
            // uuid : idempotence des ventes envoyées par le mobile (POST
            // /api/sync/push/sale) — évite de créer un doublon si le mobile
            // retente un envoi après un timeout réseau. device_id_mobile :
            // même traçabilité que les autres endpoints de sync.
            try {
              await db.execute('ALTER TABLE panniers ADD COLUMN uuid TEXT');
            } catch (e) {
              print('Skip add panniers.uuid: $e');
            }
            try {
              await db.execute('ALTER TABLE panniers ADD COLUMN device_id_mobile TEXT');
            } catch (e) {
              print('Skip add panniers.device_id_mobile: $e');
            }
          }

          if (oldVersion < 32) {
            // Photo (bon de livraison/facture) jointe depuis le mobile via
            // POST /api/smartscan/upload, même convention que
            // bon_reception.chemin_photo.
            try {
              await db.execute('ALTER TABLE smart_scan ADD COLUMN chemin_photo TEXT');
            } catch (e) {
              print('Skip add smart_scan.chemin_photo: $e');
            }
          }

          if (oldVersion < 33) {
            // Nombre de décimales à afficher/saisir sur les champs quantité
            // dans toute l'app (Paramètres > Système) — voir QuantiteFormat.
            try {
              await db.execute('ALTER TABLE parametre ADD COLUMN decimales_quantite INTEGER NOT NULL DEFAULT 2');
            } catch (e) {
              print('Skip add parametre.decimales_quantite: $e');
            }
          }

          if (oldVersion < 34) {
            // Scellement fiscal : chaque ticket encaissé porte l'empreinte
            // SHA-256 de son contenu + l'empreinte du ticket précédent sur la
            // même caisse (chaînage façon registre inviolable — conformité
            // art. 51 bis, voir PannierServices._sealPannier). Les tickets
            // créés avant cette migration restent à `hash` NULL : le premier
            // ticket scellé après mise à jour redémarre une chaîne (genèse).
            try {
              await db.execute('ALTER TABLE panniers ADD COLUMN hash TEXT');
            } catch (e) {
              print('Skip add panniers.hash: $e');
            }
            try {
              await db.execute('ALTER TABLE panniers ADD COLUMN hash_precedent TEXT');
            } catch (e) {
              print('Skip add panniers.hash_precedent: $e');
            }
          }

          if (oldVersion < 35) {
            // Registre fiscal append-only (JournalFiscalServices) — voir
            // _createJournalFiscal.
            try {
              await _createJournalFiscal(db);
            } catch (e) {
              print('Skip create journal_fiscal: $e');
            }
          }

          if (oldVersion < 36) {
            // Clôtures de caisse (rapport Z) — voir _createClotureCaisse.
            try {
              await _createClotureCaisse(db);
            } catch (e) {
              print('Skip create cloture_caisse: $e');
            }
          }

          if (oldVersion < 37) {
            // Programme de bonus/fidélité (Paramètres > Système) : voir
            // Paramters.activeBonus/bonusTaux et Client.soldeBonus.
            try {
              await db.execute('ALTER TABLE parametre ADD COLUMN active_bonus INTEGER NOT NULL DEFAULT 0');
            } catch (e) {
              print('Skip add parametre.active_bonus: $e');
            }
            try {
              await db.execute('ALTER TABLE parametre ADD COLUMN bonus_taux REAL NOT NULL DEFAULT 0');
            } catch (e) {
              print('Skip add parametre.bonus_taux: $e');
            }
            try {
              await db.execute('ALTER TABLE clients ADD COLUMN solde_bonus REAL NOT NULL DEFAULT 0');
            } catch (e) {
              print('Skip add clients.solde_bonus: $e');
            }
          }

          if (oldVersion < 38) {
            // Second stock parallèle "Nombre" (pièces), en plus de
            // "Quantité" (poids/mesure) — voir Paramters.activeNombreQuantite
            // et Produit.nombre. Colonnes nullables sur les lignes de
            // mouvement (aucune valeur tant que le paramètre n'est pas actif
            // ou non renseignée sur cette ligne) ; NOT NULL DEFAULT 0 sur les
            // compteurs de stock (produits, produit_magasin_detail).
            try {
              await db.execute('ALTER TABLE parametre ADD COLUMN active_nombre_quantite INTEGER NOT NULL DEFAULT 0');
            } catch (e) {
              print('Skip add parametre.active_nombre_quantite: $e');
            }
            try {
              await db.execute('ALTER TABLE produits ADD COLUMN nombre REAL NOT NULL DEFAULT 0');
            } catch (e) {
              print('Skip add produits.nombre: $e');
            }
            try {
              await db.execute('ALTER TABLE produit_magasin_detail ADD COLUMN nombre REAL NOT NULL DEFAULT 0');
            } catch (e) {
              print('Skip add produit_magasin_detail.nombre: $e');
            }
            try {
              await db.execute('ALTER TABLE pannierProduit ADD COLUMN nombre REAL');
            } catch (e) {
              print('Skip add pannierProduit.nombre: $e');
            }
            try {
              await db.execute('ALTER TABLE smartScanProduit ADD COLUMN nombre REAL');
            } catch (e) {
              print('Skip add smartScanProduit.nombre: $e');
            }
            try {
              await db.execute('ALTER TABLE retours ADD COLUMN nombre REAL');
            } catch (e) {
              print('Skip add retours.nombre: $e');
            }
            try {
              await db.execute('ALTER TABLE sortie ADD COLUMN nombre REAL');
            } catch (e) {
              print('Skip add sortie.nombre: $e');
            }
            try {
              await db.execute('ALTER TABLE mouvements ADD COLUMN nombre REAL');
            } catch (e) {
              print('Skip add mouvements.nombre: $e');
            }
          }

          if (oldVersion < 39) {
            // Override par produit du paramètre global activeNombreQuantite :
            // si l'option globale est désactivée, un produit avec
            // nombre_actif=1 garde quand même le champ "nombre" (au lieu de
            // "quantité") — voir Produit.nombreActif.
            try {
              await db.execute('ALTER TABLE produits ADD COLUMN nombre_actif INTEGER NOT NULL DEFAULT 0');
            } catch (e) {
              print('Skip add produits.nombre_actif: $e');
            }
          }

          if (oldVersion < 40) {
            // Architecture caisse à 3 niveaux (Ouverture -> Mouvements ->
            // Clôture) — voir _createCaisseSession/_createCaisseMouvement.
            // Toute vente/achat/versement/retour doit désormais être
            // rattachée à une session ouverte pour sa caisse.
            try {
              await _createCaisseSession(db);
            } catch (e) {
              print('Skip create caisse_session: $e');
            }
            try {
              await _createCaisseMouvement(db);
            } catch (e) {
              print('Skip create caisse_mouvement: $e');
            }
          }

          if (oldVersion < 41) {
            // Sortie devient un type de mouvement propre (aligné sur
            // ListsConst.typeMouvement) au lieu d'être encodé en chaîne
            // libre "Sortie ( Don )" — le sous-type (Don/Expiration/Autre)
            // est désormais stocké séparément dans sous_type.
            try {
              await db.execute('ALTER TABLE mouvements ADD COLUMN sous_type TEXT');
            } catch (e) {
              print('Skip add mouvements.sous_type: $e');
            }
          }

          if (oldVersion < 42) {
            // Nom/Prénom de l'utilisateur, saisis désormais dans Paramètres
            // > Information utilisateur (le champ Utilisateur y était grisé
            // faute de donnée à afficher).
            try {
              await db.execute('ALTER TABLE utilisateur ADD COLUMN nom TEXT');
            } catch (e) {
              print('Skip add utilisateur.nom: $e');
            }
            try {
              await db.execute('ALTER TABLE utilisateur ADD COLUMN prenom TEXT');
            } catch (e) {
              print('Skip add utilisateur.prenom: $e');
            }
          }

          if (oldVersion < 43) {
            // Un mouvement (vente/achat/sortie/retour) n'indiquait pas dans
            // quel magasin il avait eu lieu — impossible jusqu'ici de
            // recalculer un stock par magasin à partir du journal des
            // mouvements. Les lignes déjà existantes restent à NULL
            // (magasin non connu rétroactivement) ; seuls les nouveaux
            // mouvements le renseignent, voir MouvementsServices.
            try {
              await db.execute('ALTER TABLE mouvements ADD COLUMN magasin_code TEXT');
            } catch (e) {
              print('Skip add mouvements.magasin_code: $e');
            }
          }

          if (oldVersion < 44) {
            // Sortie et Retour ne savaient pas non plus dans quel magasin ils
            // avaient eu lieu — même besoin que pour mouvements (v43), pour
            // que le stock par magasin reste correct après une sortie ou un
            // retour, pas seulement une vente/un achat.
            try {
              await db.execute('ALTER TABLE sortie ADD COLUMN magasin_code TEXT');
            } catch (e) {
              print('Skip add sortie.magasin_code: $e');
            }
            try {
              await db.execute('ALTER TABLE retours ADD COLUMN magasin_code TEXT');
            } catch (e) {
              print('Skip add retours.magasin_code: $e');
            }
          }

          if (oldVersion < 45) {
            // Le stock produit n'est plus un compteur caché sur produits.quantite
            // (désynchronisable, cf. v42-44) mais calculé en direct depuis le
            // journal des mouvements — voir MouvementsServices.quantiteProduit()/
            // totauxParProduit(). Le champ devenu inutile est supprimé.
            try {
              await db.execute('ALTER TABLE produits DROP COLUMN quantite');
            } catch (e) {
              print('Skip drop produits.quantite: $e');
            }
          }

          if (oldVersion < 46) {
            // Même principe que produits.quantite (v45) appliqué au stock par
            // magasin : produit_magasin_detail.quantite était un compteur
            // caché désynchronisable, désormais calculé en direct depuis le
            // journal des mouvements filtré par magasin_code.
            try {
              await db.execute('ALTER TABLE produit_magasin_detail DROP COLUMN quantite');
            } catch (e) {
              print('Skip drop produit_magasin_detail.quantite: $e');
            }
          }

          if (oldVersion < 47) {
            // Nouveau module : transfert de marchandise entre magasins
            // (distinct du transfert d'argent entre caisses, table `transfert`).
            await _createTransfertMagasin(db);
          }
        },
      ),
    );

    // Filet de sécurité : si l'app a d'abord tourné en mode non activé, le
    // fichier .db a été créé sans données par défaut (`_insertDefaultData`
    // n'est appelé que dans `onCreate`, gardé par `isActivated` — voir plus
    // haut). Comme ce fichier existe déjà, `onCreate` ne se redéclenche
    // jamais après activation : l'utilisateur ADMIN (et tout le reste :
    // rôle, magasin, caisse, catégories...) ne sont alors jamais créés.
    // Résultat : tout ce qui référence utilisateur(code) en clé étrangère
    // (userparam, Historique...) échoue avec une erreur de contrainte à
    // chaque enregistrement (ex. écran Paramètres). On répare ça ici : dès
    // que l'app est activée, si la table utilisateur est vide, on insère
    // les données par défaut a posteriori.
    if (isActivated) {
      try {
        final result = await _db!.rawQuery('SELECT COUNT(*) AS c FROM utilisateur');
        final count = (result.first['c'] as int?) ?? 0;
        if (count == 0) {
          print('Utilisateur table empty on an activated install — seeding default data now');
          await _insertDefaultData(_db!, DateTime.now().toIso8601String());
        }
      } catch (e) {
        print('Could not verify/seed default data on activated install: $e');
      }
    }

    return _db!;
  }

  // Separate method for inserting default data to keep code organized
  static Future<void> _insertDefaultData(Database db, String now) async {
    try {
      final saltedHash = sha256.convert(utf8.encode("123456SYSTEM_SALT")).toString();

      // ROLE
      await db.insert('role', {
        'code': 'ADMIN',
        'rolenom': 'admin',
        'etat': 1,
        'cree_par_code': 'SYSTEM',
        'date_cree': now
      });

      // UTILISATEUR
      await db.insert('utilisateur', {
        'etat': 1,
        'role': 'admin',
        'code': 'ADMIN',
        'credit': 0,
        'username': 'admin',
        'password': saltedHash,
        'date_cree': now,
        'role_code': 'ADMIN',
        'telephone': '0000000000',
        'cree_par_code': 'SYSTEM',
        'dernier_acces': now,
      });

      await db.insert('roledetail',{
        'id'        : 1,
        'rolecode'  : 'ADMIN',

        'dash'          : 1,
        'stock'         : 1,
        'zakat'         : 1,
        'besion'        : 1,
        'client'        : 1,
        'entree'        : 1,
        'sortie'        : 1,
        'caisse'        : 1,
        'retour'        : 1,
        'pannier'       : 1,
        'produit'       : 1,
        'parametre'     : 1,
        'historique'    : 1,
        'fournisseur'   : 1,
        'utilisateur'   : 1,
        'gestionCaisse' : 1,

        'date_cree'     : now,
        'cree_par_code' : 'ADMIN'
      });

      // MAGASINS
      await db.insert('magasins', {
        'code': 'MAG0000',
        'nom': 'Magasin System',
        'adresse': 0,
        'etat': 1,
        'observation': 'Magasin System',
        'date_cree': now,
        'cree_par_code': 'ADMIN',
      });

      // CAISSE GESTION
      await db.insert('caisseGestion', {
        'code': 'CIS0000',
        'etat': 1,
        'magasin_code': 'MAG0000',
        'date_cree': now,
        'typecaisse': "Physique",
        'nom_caisse': 'Caisse System',
        'cree_par_code': 'ADMIN',
        'solde_initial': 0,
        'observation': 'Caisse System',
      });

      // CATEGORIES
      await db.insert('categories', {
        'nom': 'Sans Categorie',
        'code': 'CATE0000',
        'etat': 1,
        'observation': 'System categorié',
        'date_cree': now,
        'cree_par_code': 'ADMIN',
      });

      // SOUS CATEGORIES
      await db.insert('sous_categories', {
        'nom': 'Sans Sous-Catego',
        'code': 'SC0000',
        'categorie_code': 'CATE0000',
        'categorie_id': 1,
        'observation': 'Sous categorié System',
        'etat': 1,
        'date_cree': now,
        'cree_par_code': 'ADMIN',
      });

      // CLIENTS
      await db.insert('clients', {
        'code': 'CLN0000',
        'nom': 'Comptoire',
        'telephone': "07 00 00 00 00",
        'email': "comptoire@email.com",
        'fax': "000 000 000",
        'wilaya': "Alger",
        'adresse': "",
        'etat': 1,
        'type': 'Autre',
        'activity': '',
        'nif': '',
        'nis': '',
        'nrc': '',
        'rib': '',
        'banque': '',
        'dernier_achat': now,
        'observation': 'CLient System',
        'date_cree': now,
        'cree_par_code': 'ADMIN',
      });

      // FOURNISSEURS
      await db.insert('fournisseurs', {
        'code': 'FOR0000',
        'nom': 'Géneral',
        'telephone': "07 00 00 00 00",
        'email': "general@email.com",
        'fax': "000 000 000",
        'wilaya': "Alger",
        'adresse': "",
        'etat': 1,
        'type': 'Autre',
        'activity': '',
        'observation': 'Fournisseur System',
        'date_cree': now,
        'cree_par_code': 'ADMIN',
      });

      // PARAMETRE
      await db.insert('parametre', {
        'id': 1,
        'taux_marge_percentage': 5,
        'taux_marge_montant': 0,
        'minimum': 1,
        'maximum': 100,
        'type_marge': 'montant',
        'cree_par_code': 'ADMIN',
        'date_cree': now,
      });

      // ZAKAT PARAM
      await db.insert('zakatParam', {
        'id': 1,
        'nissab': 0,
        'taux': 0,
        'cree_par_code': 'ADMIN',
        'date_cree': now,
      });

      // ENTREPRISE PARAM (infos boutique affichées sur tickets/BL/QR)
      await db.insert('entreprise_param', {
        'id': 1,
        'nom_boutique': 'Ma Boutique',
      });

      // PAIEMENT PARAM (visibilité des modes de paiement, tous visibles par défaut)
      await db.insert('paiement_param', {'id': 1});

      // IMPRIMANTE PARAM
      await db.insert('imprimante_param', {'id': 1});

      // BACKUP PARAM
      await db.insert('backup_param', {'id': 1});

      // HISTORIQUE
      await db.insert('Historique', {
        'code': 'INIT',
        'type': 'SYSTEM',
        'description': 'Initialisation base de données',
        'operation': 'CREATE_DB',
        'cree_par_code': 'ADMIN',
        'date_cree': now
      });

      // CAISSE PARAM
      await db.insert('caisseparam', {
        'user': 'ADMIN',
        'colis': 'default',
        'caisse': 'Caisse System',
        'magasin': 'Magasin System',
        'date_cree': now,
        'caisseCode': 'CIS0000',
        'magasinCode': 'MAG0000',
        'cree_par_code': 'ADMIN',
      });

      // USER PARAMETERS FOR ADMIN USER
      await db.insert('userparam', {
        'nom': 'admin',
        'magasin': 'Magasin System',
        'magasinid': '1',
        'language': 'fr',
        'currency': 'DZD',
        'cree_par_code': 'ADMIN',
        'cree_le': now,
      });

      // Optional: Add a history entry for user param creation
      await db.insert('Historique', {
        'code': 'UP_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'USER_PARAM',
        'description': 'Création des paramètres utilisateur pour admin',
        'operation': 'INSERTION',
        'cree_par_code': 'ADMIN',
        'date_cree': now,
        'observation': 'Paramètres par défaut pour l\'utilisateur admin',
      });

      print('Default data inserted successfully');
    } catch (e) {
      print('Error inserting default data: $e');
      rethrow;
    }
  }

  // Better machine ID that doesn't change on network changes
  static Future<String> _getMachineId() async {
    final prefs = await SharedPreferences.getInstance();
    String? machineId = prefs.getString('machine_id');

    if (machineId == null) {
      String systemInfo = '';
      if (Platform.isWindows) {
        systemInfo += Platform.environment['COMPUTERNAME'] ?? '';
        systemInfo += Platform.environment['PROCESSOR_IDENTIFIER'] ?? '';
        systemInfo += Platform.environment['SYSTEMDRIVE'] ?? '';
      } else {
        systemInfo += Platform.environment['HOSTNAME'] ?? '';
      }

      final idFile = File(path.join(getLocalFolder(), '.mid'));
      if (await idFile.exists()) {
        systemInfo += await idFile.readAsString();
      } else {
        final randomId = DateTime.now().millisecondsSinceEpoch.toString();
        await idFile.writeAsString(randomId);

        try {
          await Process.run('attrib', ['+h', idFile.path]);
        } catch (_) {}
        systemInfo += randomId;
      }

      machineId = sha256.convert(utf8.encode(systemInfo)).toString();
      await prefs.setString('machine_id', machineId);
    }

    return machineId;
  }

  static Database get db => _db!;
  static  Future<void>  _createCaisseParam  (Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS caisseparam (
        id          INTEGER PRIMARY KEY,
        colis       TEXT NOT NULL,
        caisse      TEXT NOT NULL,
        user        TEXT NOT NULL,
        caisseCode  TEXT NOT NULL,
        magasin     TEXT NOT NULL,
        magasinCode TEXT NOT NULL,
        magasinPD   INTEGER NOT NULL DEFAULT 1,
        caissePD    INTEGER NOT NULL DEFAULT 1,
        
        date_cree     TEXT NOT NULL,
        cree_par_code TEXT NOT NULL,
        
        date_modif  TEXT,
        modif_par_code   TEXT,
        
        FOREIGN KEY (user)          REFERENCES  utilisateur   (code),
        FOREIGN KEY (caisseCode)    REFERENCES  caisseGestion (code),
        FOREIGN KEY (magasinCode)   REFERENCES  magasins      (code),
        FOREIGN KEY (cree_par_code) REFERENCES  utilisateur   (code)
      )
    ''');
  }
  static Future<void> _createProduitCodeDetail(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS produit_code_detail (
      id            INTEGER PRIMARY KEY AUTOINCREMENT,
      produit_code  TEXT    NOT NULL,
      date_cree     TEXT    NOT NULL DEFAULT (datetime('now')),
      cree_par_code TEXT    NOT NULL,
      codebar       TEXT    NOT NULL,
      UNIQUE(produit_code, codebar),
      FOREIGN KEY (produit_code)  REFERENCES produits(code),
      FOREIGN KEY (cree_par_code) REFERENCES utilisateur(code)
    )
  ''');
  }

  /// Correspondance produit local <-> produit du catalogue distant
  /// bensds.com : une ligne par produit local déjà synchronisé, utilisée
  /// par CatalogSyncService pour décider POST (création) vs PUT (mise à
  /// jour) et pour tracer les échecs de synchronisation sans jamais
  /// bloquer la sauvegarde locale (architecture offline-first).
  static Future<void> _createCatalogSync(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS catalog_sync (
      id                 INTEGER PRIMARY KEY AUTOINCREMENT,
      produit_code       TEXT    NOT NULL,
      catalog_product_id INTEGER,
      code_produit       TEXT,
      sync_status        TEXT    NOT NULL DEFAULT 'pending',
      last_error         TEXT,
      synced_at          TEXT,
      date_cree          TEXT    NOT NULL DEFAULT (datetime('now')),
      UNIQUE(produit_code),
      FOREIGN KEY (produit_code) REFERENCES produits(code)
    )
  ''');
  }




  static Future<void> _createRoleDetail(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS roledetail (
        id        INTEGER PRIMARY KEY,
        rolecode  TEXT NOT NULL,
        
        dash          INTEGER NOT NULL,
        stock         INTEGER NOT NULL,
        zakat         INTEGER NOT NULL,
        besion        INTEGER NOT NULL,
        client        INTEGER NOT NULL,
        entree        INTEGER NOT NULL,
        sortie        INTEGER NOT NULL,
        caisse        INTEGER NOT NULL,
        retour        INTEGER NOT NULL,
        pannier       INTEGER NOT NULL,
        produit       INTEGER NOT NULL,
        parametre     INTEGER NOT NULL,
        historique    INTEGER NOT NULL,
        fournisseur   INTEGER NOT NULL,
        utilisateur   INTEGER NOT NULL,
        gestionCaisse INTEGER NOT NULL,
        
        date_cree     TEXT NOT NULL,
        cree_par_code TEXT NOT NULL,
        
        date_modif    TEXT,
        modif_par_code     TEXT,
        date_annul    TEXT,
        annul_par_code     TEXT,
        motif_annul   TEXT,
        
        FOREIGN KEY (cree_par_code) REFERENCES utilisateur(code),
        FOREIGN KEY (rolecode)      REFERENCES role(code)
      )
    ''');
  }

  static Future<void> _createEntrepriseParam(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS entreprise_param (
        id              INTEGER PRIMARY KEY,
        nom_boutique    TEXT NOT NULL DEFAULT '',
        logo_path       TEXT,
        adresse         TEXT,
        telephone       TEXT,
        email           TEXT,
        rc              TEXT,
        nif             TEXT,
        nis             TEXT,
        article         TEXT,
        message_ticket  TEXT,
        date_modif      TEXT,
        modif_par_code  TEXT
      )
    ''');
  }

  static Future<void> _createPaiementParam(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS paiement_param (
        id                INTEGER PRIMARY KEY,
        especes_visible   INTEGER NOT NULL DEFAULT 1,
        carte_visible     INTEGER NOT NULL DEFAULT 1,
        cheque_visible    INTEGER NOT NULL DEFAULT 1,
        virement_visible  INTEGER NOT NULL DEFAULT 1,
        date_modif        TEXT,
        modif_par_code    TEXT
      )
    ''');
  }

  static Future<void> _createImprimanteParam(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS imprimante_param (
        id               INTEGER PRIMARY KEY,
        type_imprimante  TEXT NOT NULL DEFAULT 'bluetooth',
        nom_imprimante   TEXT,
        adresse_ip       TEXT,
        port             INTEGER,
        mac_bluetooth    TEXT,
        largeur_rouleau  INTEGER NOT NULL DEFAULT 80,
        date_modif       TEXT,
        modif_par_code   TEXT
      )
    ''');
  }

  static Future<void> _createBackupParam(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS backup_param (
        id                  INTEGER PRIMARY KEY,
        dossier_backup      TEXT,
        dossier_documents   TEXT,
        auto_backup_actif   INTEGER NOT NULL DEFAULT 0,
        frequence           TEXT NOT NULL DEFAULT 'demarrage',
        derniere_sauvegarde TEXT,
        modif_par_code      TEXT
      )
    ''');
  }

  static Future<void> _createCategories(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id            INTEGER PRIMARY KEY,
        nom           TEXT NOT NULL,
        code          TEXT UNIQUE NOT NULL,
        etat          INTEGER NOT NULL DEFAULT 1,
        date_cree     TEXT NOT NULL,
        cree_par_code TEXT NOT NULL,
        observation TEXT,
        date_modif  TEXT,
        modif_par_code   TEXT,
        date_annul  TEXT,
        annul_par_code   TEXT,
        motif_annul TEXT,
        FOREIGN KEY (cree_par_code) REFERENCES utilisateur(code)
      )
    ''');
  }

  static Future<void> _createSousCategories(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sous_categories (
        id INTEGER PRIMARY KEY,
        nom   TEXT UNIQUE NOT NULL,
        code  TEXT UNIQUE NOT NULL,
        categorie_code TEXT    NOT NULL,
        categorie_id  INTEGER NOT NULL,
        observation TEXT,
        etat INTEGER NOT NULL DEFAULT 1,
        date_cree TEXT NOT NULL DEFAULT (datetime('now')),
        cree_par_code TEXT NOT NULL,
        date_modif TEXT ,
        modif_par_code TEXT,
        date_annul TEXT,
        annul_par_code TEXT,
        motif_annul TEXT,
        FOREIGN KEY (categorie_id)  REFERENCES categories(id),
        FOREIGN KEY (categorie_code) REFERENCES categories(code),
        FOREIGN KEY (cree_par_code) REFERENCES utilisateur(code)
      )
    ''');
  }

  static Future<void> _createClients(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS clients (
        id INTEGER PRIMARY KEY,
        code      TEXT UNIQUE NOT NULL,
        nom       TEXT UNIQUE NOT NULL,
        telephone TEXT NOT NULL,
        email     TEXT,
        fax       TEXT,
        wilaya  TEXT NOT NULL,
        adresse TEXT,
        etat      INTEGER NOT NULL DEFAULT 1,
        type      TEXT NOT NULL,
        activity  TEXT,
        nif TEXT,
        nis TEXT,
        nrc TEXT,
        rib     TEXT,
        banque  TEXT,
        dernier_achat TEXT,
        observation   TEXT,
        solde_bonus   REAL NOT NULL DEFAULT 0,
        date_cree     TEXT NOT NULL DEFAULT(datetime('now')),
        cree_par_code TEXT NOT NULL,
        date_modif    TEXT,
        modif_par_code     TEXT,
        date_annul    TEXT,
        annul_par_code     TEXT,
        motif_annul   TEXT,
        FOREIGN KEY (cree_par_code) REFERENCES utilisateur(code)
      )
    ''');
  }

  static Future<void> _createRemises(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS remises (
        id            INTEGER PRIMARY KEY,
        code          TEXT UNIQUE NOT NULL,
        nom           TEXT NOT NULL,
        type          TEXT NOT NULL,
        montant       REAL NOT NULL,
        taux          REAL NOT NULL,
        taux_type     TEXT NOT NULL,
        debut         TEXT NOT NULL,
        observation   TEXT,
        etat          INTEGER NOT NULL DEFAULT 1,
        cree_par_code TEXT NOT NULL,
        cree_le       TEXT NOT NULL DEFAULT (datetime('now')),
        fin TEXT,
        modif_le TEXT,
        modif_par_code TEXT,
        annul_le TEXT,
        annul_par_code TEXT,
        motif_annul TEXT,
        FOREIGN KEY (cree_par_code) REFERENCES utilisateur(code)
      )'''
    );
  }

  static Future<void> _createPacks(Database db) async {
    await db.execute("""
      CREATE TABLE IF NOT EXISTS packs (
        id                  INTEGER PRIMARY KEY,
        code                TEXT    UNIQUE  NOT NULL,
        nom                 TEXT    UNIQUE  NOT NULL,
        description         TEXT,
        etat                INTEGER DEFAULT 1,
        quantite_totale     INTEGER NOT NULL DEFAULT 0,
        prix_vente          REAL    NOT NULL DEFAULT 0,
        prix_vente_original REAL,
        cree_par_code       TEXT    NOT NULL,
        cree_le             TEXT    NOT NULL DEFAULT (datetime('now')),
        modif_par_code           TEXT,
        modif_le            TEXT,
        annul_par_code           TEXT,
        annul_le            TEXT,
        motif_annul         TEXT,
        FOREIGN KEY (cree_par_code) REFERENCES utilisateur(code)
      )
    """);
  }

  static Future<void> _createParmUser(Database db) async {
    await db.execute("""
      CREATE TABLE IF NOT EXISTS userparam (
        id            INTEGER PRIMARY KEY,
        nom           TEXT UNIQUE NOT NULL,
        magasin       TEXT NOT NULL,
        magasinid     TEXT NOT NULL,
        language       TEXT NOT NULL,
        currency      TEXT NOT NULL,
        cree_par_code TEXT NOT NULL, 
        cree_le       TEXT NOT NULL DEFAULT (datetime('now')),
        modif_par_code     TEXT,
        modif_le      TEXT,
        FOREIGN KEY (cree_par_code) REFERENCES utilisateur(code)
      ) 
    """);
  }


  static Future<void> _createProduits(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS produits (
      id INTEGER PRIMARY KEY,
      nom           TEXT UNIQUE NOT NULL,
      code          TEXT UNIQUE NOT NULL,
      marque        TEXT NOT NULL,
      description   TEXT,
      code_barre    TEXT,
      numero_serie  TEXT,
      fournisseur_code TEXT,
      categorie_id INTEGER,
      sous_categorie_id INTEGER,
      remise_id INTEGER,
      prix_achat  REAL    NOT NULL DEFAULT 0,
      prix_vente  REAL    NOT NULL DEFAULT 0,
      tva         REAL    NOT NULL DEFAULT 0,
      marge_taux  REAL    DEFAULT 0,
      marge_bool  INTEGER DEFAULT 0,
      unite_mesure  TEXT    NOT NULL ,
      nombre        REAL    NOT NULL DEFAULT 0,
      multicodebar  INTEGER DEFAULT 0,
      marge_tauxPrct  REAL,
      observation   TEXT,
      date_empreint TEXT,
      emballage1    REAL,
      emballage2    REAL,
      emballagep1   REAL,
      emballagep2   REAL,
      etat          INTEGER NOT NULL DEFAULT 1,
      date_cree     TEXT NOT NULL DEFAULT (datetime('now')),
      cree_par_code TEXT NOT NULL,
      date_modif  TEXT,
      modif_par_code   TEXT,
      annuler_par_code TEXT,
      annuler_le  TEXT,
      motif_annul TEXT,
      service INTEGER DEFAULT 0,
      taille  TEXT,
      couleur TEXT,
      photos  TEXT,
      besion          INTEGER NOT NULL DEFAULT 0,
      nombre_actif    INTEGER NOT NULL DEFAULT 0,
      device_id_mobile TEXT,
      FOREIGN KEY (cree_par_code) REFERENCES utilisateur(code),
      FOREIGN KEY (categorie_id) REFERENCES categories(id),
      FOREIGN KEY (sous_categorie_id) REFERENCES sous_categories(id),
      FOREIGN KEY (fournisseur_code) REFERENCES fournisseurs(code)
  )
  ''');
  }

  static Future<void> _createFournisseurs(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS fournisseurs (
        id INTEGER PRIMARY KEY,
        code      TEXT NOT NULL UNIQUE,
        nom       TEXT NOT NULL,
        telephone TEXT NOT NULL,
        email TEXT,
        fax TEXT,
        wilaya TEXT,
        adresse TEXT,
        type      TEXT NOT NULL,
        activity  TEXT NOT NULL,
        etat INTEGER NOT NULL DEFAULT 1,
        observation   TEXT,
        date_cree     TEXT DEFAULT (datetime('now')),
        cree_par_code TEXT NOT NULL,
        date_modif TEXT,
        modif_par_code TEXT,
        date_annul TEXT,
        annul_par_code TEXT,
        motif_annul TEXT,
        FOREIGN KEY (cree_par_code) REFERENCES utilisateur(code)     
      )
      '''
    );
  }

  static Future<void> _createParametre(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS parametre (
      id                    INTEGER PRIMARY KEY,
      taux_marge_percentage REAL DEFAULT 0,
      taux_marge_montant    REAL DEFAULT 0,
      type_marge            TEXT NOT NULL,
      minimum               REAL DEFAULT 0,
      maximum               REAL DEFAULT 0,
      decimales_quantite    INTEGER NOT NULL DEFAULT 0,
      active_bonus          INTEGER NOT NULL DEFAULT 0,
      bonus_taux            REAL NOT NULL DEFAULT 0,
      active_nombre_quantite INTEGER NOT NULL DEFAULT 0,
      date_cree             TEXT NOT NULL,
      cree_par_code         TEXT NOT NULL,
      date_modif            TEXT,
      modif_par_code             TEXT,
      FOREIGN KEY (cree_par_code) REFERENCES utilisateur(code)
    )
  ''');
  }
  static Future<void> _createZakatParametre(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS zakatParam (
      
        id            INTEGER PRIMARY KEY,
        nissab        REAL DEFAULT 0,
        taux          REAL DEFAULT 0,
        date_cree     TEXT NOT NULL,
        cree_par_code TEXT NOT NULL,
        date_modif    TEXT,
        modif_par_code     TEXT,
        
        FOREIGN KEY (cree_par_code) REFERENCES utilisateur(code)
      )
    ''');
  }

  static Future<void> _createPackdetaile(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS produit_pack_detail (
        id                  INTEGER PRIMARY KEY AUTOINCREMENT,
        pack_code           TEXT    NOT NULL,
        produit_code        TEXT    NOT NULL,
        prix_unitaire       REAL    NOT NULL DEFAULT 0,
        quantite            INTEGER NOT NULL DEFAULT 1,
        montant             REAL    NOT NULL DEFAULT 0,
        date_cree           TEXT    NOT NULL DEFAULT (datetime('now')),
        cree_par_code       TEXT    NOT NULL,
        FOREIGN KEY (cree_par_code) REFERENCES utilisateur(code),
        FOREIGN KEY (pack_code)     REFERENCES packs(code),
        FOREIGN KEY (produit_code)  REFERENCES produits(code)
      )
    ''');
  }

  static Future<void> _createMagasins(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS magasins (
      id              INTEGER PRIMARY KEY AUTOINCREMENT,
      code            TEXT NOT NULL UNIQUE,
      nom             TEXT NOT NULL,
      adresse         TEXT,
      etat            INTEGER NOT NULL DEFAULT 1,
      observation     TEXT,
      date_cree       TEXT DEFAULT (datetime('now')),
      cree_par_code   TEXT NOT NULL, 
      date_modif      TEXT DEFAULT (datetime('now')),
      modif_par_code       TEXT,
      date_annul      TEXT,
      annul_par_code       TEXT,
      motif_annul     TEXT,
      FOREIGN KEY (cree_par_code) REFERENCES utilisateur(code)
    )
  ''');
  }

  static Future<void> _createMovmentes(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS mouvements (
      id            INTEGER PRIMARY KEY AUTOINCREMENT,
      date          TEXT    DEFAULT (datetime('now')),
      code          TEXT    NOT NULL UNIQUE,
      code_produit  TEXT    NOT NULL,
      quantite      REAL    DEFAULT 0,
      nombre        REAL,
      prix_achat    REAL    DEFAULT 0,
      prix_vente    REAL    DEFAULT 0,
      code_operation TEXT NOT NULL,
      client_code       TEXT,
      fournisseur_code  TEXT,
      magasin_code  TEXT,
      type          TEXT,
      sous_type     TEXT,
      etat          INTEGER NOT NULL DEFAULT 1,
      date_cree     TEXT DEFAULT (datetime('now')),
      cree_par_code TEXT NOT NULL,
      date_modif    TEXT,
      modif_par_code     TEXT,
      date_annul    TEXT,
      annul_par_code     TEXT,
      motif_annul   TEXT,
      FOREIGN KEY (code_produit)      REFERENCES produits(code),
      FOREIGN KEY (client_code)       REFERENCES clients(code),
      FOREIGN KEY (fournisseur_code)  REFERENCES fournisseurs(code),
      FOREIGN KEY (magasin_code)      REFERENCES magasins(code),
      FOREIGN KEY (cree_par_code)     REFERENCES utilisateur(code)
    )
    ''');
  }
  static Future<void> _createProduitMagasinDetail(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS produit_magasin_detail (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        magasin_code  TEXT    NOT NULL,
        produit_code  TEXT    NOT NULL,
        nombre        REAL    NOT NULL DEFAULT 0,
        date_cree     TEXT    NOT NULL DEFAULT (datetime('now')),
        cree_par_code TEXT    NOT NULL,
        FOREIGN KEY (magasin_code)  REFERENCES magasins(code),
        FOREIGN KEY (produit_code)  REFERENCES produits(code),
        FOREIGN KEY (cree_par_code) REFERENCES utilisateur(code)
      )
    ''');
  }

  static Future<void> _createPannier(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS panniers (
        id                INTEGER PRIMARY KEY,
        code              TEXT NOT NULL UNIQUE,
        nombre_article    INTEGER NOT NULL,
        quantite_produit  INTEGER NOT NULL,
        montant           REAL NOT NULL,
        montant_achat           REAL NOT NULL,
        marge           REAL NOT NULL,
        mode_paiement     TEXT NOT NULL,
        caisser_code      TEXT NOT NULL,
        caisse            TEXT NOT NULL,
        caisse_code       TEXT NOT NULL,
        etat              INTEGER NOT NULL DEFAULT 1,
        observation       TEXT,
        type_pannier      TEXT,
        client_code       TEXT,
        date_cree         TEXT DEFAULT (datetime('now')),
        date              TEXT DEFAULT (datetime('now')),
        date_modif        TEXT,
        modif_par_code         TEXT,
        date_annul        TEXT,
        annul_par_code         TEXT,
        motif_annul       TEXT,
        uuid              TEXT,
        device_id_mobile  TEXT,
        hash              TEXT,
        hash_precedent    TEXT,
        FOREIGN KEY (caisser_code)      REFERENCES utilisateur(code),
        FOREIGN KEY (caisse_code)       REFERENCES caisseGestion(code),
        FOREIGN KEY (client_code)       REFERENCES clients(code)
      )
    ''');
  }

  static Future<void> _createRetours(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS retours (
        id                INTEGER PRIMARY KEY,
        code              TEXT    NOT NULL UNIQUE,
        code_produit      TEXT    NOT NULL,
        quantite          REAL    NOT NULL,
        nombre            REAL,
        prix_achat        REAL    NOT NULL,
        prix_vente        REAL    NOT NULL,
        type              TEXT    NOT NULL,
        cree_par_code     TEXT    NOT NULL,
        etat              INTEGER NOT NULL DEFAULT 1,
        date_cree         TEXT    NOT NULL DEFAULT (datetime('now')),
        date              TEXT    NOT NULL DEFAULT (datetime('now')),
        client_code       TEXT,
        fournisseur_code  TEXT,
        retour_correspond_de TEXT,
        magasin_code      TEXT,
        observation       TEXT,
        date_modif        TEXT,
        modif_par_code         TEXT,
        date_annul        TEXT,
        annul_par_code         TEXT,
        motif_annul       TEXT,
        device_id_mobile  TEXT,
        FOREIGN KEY (client_code)       REFERENCES  clients(code),
        FOREIGN KEY (fournisseur_code)  REFERENCES fournisseurs(code),
        FOREIGN KEY (code_produit)      REFERENCES produits(code),
        FOREIGN KEY (magasin_code)      REFERENCES magasins(code),
        FOREIGN KEY (cree_par_code)     REFERENCES utilisateur(code)
      )
    ''');
  }

  static Future<void> _createVerssement(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS verssements (
        id              INTEGER PRIMARY KEY,
        code            TEXT    NOT NULL UNIQUE,
        typebeneficiare TEXT    NOT NULL,
        type            TEXT    NOT NULL,
        sense           TEXT    NOT NULL,
        etat            INTEGER NOT NULL DEFAULT 1,
        montant         REAL    NOT NULL,
        beneficiare_code TEXT   NOT NULL,
        mode_paiement   TEXT    NOT NULL,
        code_operation  TEXT    NOT NULL,
        date            TEXT    NOT NULL,
        date_cree       TEXT    NOT NULL DEFAULT (datetime('now')),
        cree_par_code   TEXT    NOT NULL,
        caisse          TEXT,
        observation     TEXT,
        date_modif      TEXT,
        modif_par_code       TEXT,
        date_annul      TEXT,
        annul_par_code       TEXT,
        motif_annul     TEXT,
        FOREIGN KEY (cree_par_code) REFERENCES utilisateur(code)
      )
    ''');
  }

  static Future<void> _createSmartScan(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS smart_scan (
        id                INTEGER PRIMARY KEY,
        code              TEXT    NOT NULL  UNIQUE,
        date              TEXT    NOT NULL,
        montant           REAL    NOT NULL,
        nbr_produit       INTEGER NOT NULL,
        fournisseur_code  TEXT    NOT NULL,
        etat              INTEGER NOT NULL  DEFAULT 1,
        observation       TEXT,
        date_cree         TEXT    NOT NULL  DEFAULT (datetime('now')),
        cree_par_code     TEXT    NOT NULL,
        date_modif        TEXT,
        modif_par_code         TEXT,
        date_annul        TEXT,
        annul_par_code         TEXT,
        motif_annul       TEXT,
        device_id_mobile  TEXT,
        chemin_photo      TEXT,
        FOREIGN KEY (fournisseur_code)  REFERENCES fournisseurs(code),
        FOREIGN KEY (cree_par_code)     REFERENCES utilisateur(code)
      )
    ''');
  }

  static Future<void> _createBonReception(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS bon_reception (
        id                INTEGER PRIMARY KEY,
        fournisseur       TEXT,
        fournisseur_code  TEXT,
        num_bon           TEXT,
        commentaire       TEXT,
        chemin_photo      TEXT    NOT NULL,
        date_reception    TEXT    NOT NULL  DEFAULT (datetime('now')),
        statut            TEXT    NOT NULL  DEFAULT 'recu',
        device_id         TEXT,
        date_traitement   TEXT,
        traite_par_code   TEXT,
        smart_scan_code   TEXT,
        FOREIGN KEY (smart_scan_code)  REFERENCES smart_scan(code),
        FOREIGN KEY (fournisseur_code) REFERENCES fournisseurs(code),
        FOREIGN KEY (traite_par_code)  REFERENCES utilisateur(code)
      )
    ''');
  }

  static Future<void> _createUtilisateur(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS utilisateur (
        id            INTEGER PRIMARY KEY,
        code          TEXT    NOT NULL  UNIQUE,
        etat          INTEGER NOT NULL DEFAULT 1,
        role          TEXT    NOT NULL,
        credit        REAL    NOT NULL,
        username      TEXT    NOT NULL UNIQUE,
        password      TEXT    NOT NULL,
        nom           TEXT,
        prenom        TEXT,
        telephone     TEXT    NOT NULL,
        role_code     TEXT    NOT NULL,
        caisse_code   TEXT,
        date_cree     TEXT    NOT NULL DEFAULT (datetime('now')),
        cree_par_code TEXT    NOT NULL,
        dernier_acces TEXT    NOT NULL,
        observation   TEXT,
        date_modif    TEXT,
        modif_par_code     TEXT,
        date_annul    TEXT,
        annul_par_code     TEXT,
        motif_annul   TEXT,
        api_token     TEXT,
        FOREIGN KEY (role_code)     REFERENCES role(code),
        FOREIGN KEY (caisse_code)   REFERENCES caisseGestion(code)
      )
    ''');
  }

  static Future<void> _createRole(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS role (
        id                  INTEGER PRIMARY KEY,
        code                TEXT NOT NULL UNIQUE,
        rolenom             TEXT NOT NULL UNIQUE,
        etat                INTEGER NOT NULL DEFAULT 1,
        observation         TEXT,
        date_cree           TEXT NOT NULL DEFAULT (datetime('now')),
        cree_par_code       TEXT,
        date_modif          TEXT,
        modif_par_code           TEXT,
        date_annul          TEXT,
        annul_par_code           TEXT,
        motif_annul         TEXT
      )
    ''');
  }

  static Future<void> _createBesionListDetail(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS besion_list_detail(
        id                INTEGER PRIMARY KEY,
        besion_list_code  TEXT NOT NULL,
        produit_code      TEXT NOT NULL,
        produit_nom       TEXT NOT NULL,
        quantite          REAL NOT NULL,
        prix              REAL NOT NULL,
        montant           REAL NOT NULL,
        date_cree         TEXT NOT NULL DEFAULT (datetime('now')),
        cree_par_code     TEXT NOT NULL,
        date_modif        TEXT,
        modif_par_code         TEXT,
        date_annul        TEXT,
        annul_par_code         TEXT,
        motif_annul       TEXT,
        FOREIGN KEY (besion_list_code)  REFERENCES  besionList(code),
        FOREIGN KEY (produit_code)      REFERENCES  produits(code),
        FOREIGN KEY (cree_par_code)     REFERENCES  utilisateur(code)
      )
    ''');
  }

  static Future<void> _createBesionList(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS besionList(
        id              INTEGER PRIMARY KEY,
        code            TEXT    NOT NULL UNIQUE,
        numero          TEXT    NOT NULL,
        date            TEXT    NOT NULL,
        montant         REAL    NOT NULL,
        nomber_article  INTEGER NOT NULL,
        quantite        REAL    NOT NULL,
        fournisseur_code TEXT   NOT NULL,
        etat            INTEGER NOT NULL DEFAULT 1,
        observation     TEXT,
        date_cree       TEXT    NOT NULL DEFAULT (datetime('now')),
        cree_par_code   TEXT    NOT NULL,
        date_modif      TEXT,
        modif_par_code       TEXT,
        date_annul      TEXT,
        annul_par_code       TEXT,
        motif_annul     TEXT,
        FOREIGN KEY (cree_par_code) REFERENCES utilisateur(code),
        FOREIGN KEY (fournisseur_code) REFERENCES fournisseurs(code)
      )
    ''');
  }

  static Future<void> _createCaisseGestion(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS caisseGestion(
        id INTEGER PRIMARY KEY,
        code TEXT NOT NULL UNIQUE,
        etat INTEGER NOT NULL DEFAULT 1,
        magasin_code TEXT NOT NULL,
        date_cree TEXT NOT NULL DEFAULT (datetime('now')),
        typecaisse TEXT NOT NULL,
        nom_caisse TEXT NOT NULL,
        cree_par_code TEXT NOT NULL,
        solde_initial REAL NOT NULL,
        observation TEXT,
        date_modif      TEXT,
        modif_par_code       TEXT,
        date_annul      TEXT,
        annul_par_code       TEXT,
        motif_annul     TEXT,
        FOREIGN KEY (cree_par_code) REFERENCES utilisateur(code),
        FOREIGN KEY (magasin_code)  REFERENCES magasins(code)
      )
    ''');
  }

  static Future<void> _createPannierProduit(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pannierProduit(
        id INTEGER PRIMARY KEY,
        prix REAL NOT NULL,
        etat INTEGER NOT NULL DEFAULT 1,
        total REAL NOT NULL,
        total_achat REAL NOT NULL,
        prix_achat REAL NOT NULL,
        quantite REAL NOT NULL,
        nombre REAL,
        date_cree TEXT NOT NULL DEFAULT (datetime ('now')),
        code_pannier TEXT NOT NULL,
        code_produit TEXT NOT NULL,
        cree_par_code TEXT NOT NULL,
        modif_par_code       TEXT,
        annul_par_code       TEXT,
        date_annul      TEXT,
        date_modif      TEXT,
        motif_annul     TEXT,
        FOREIGN KEY (code_pannier)  REFERENCES panniers(code),
        FOREIGN KEY (cree_par_code) REFERENCES utilisateur(code)
      )
    ''');
  }

  static Future<void> _createSmartScanProduit(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS smartScanProduit(
        id              INTEGER PRIMARY KEY,
        code_SmartScan  TEXT    NOT NULL,
        code_produit    TEXT    NOT NULL,
        quantite        REAL    NOT NULL,
        nombre          REAL,
        prix            REAL    NOT NULL,
        prixVente       REAL    NOT NULL,
        total           REAL    NOT NULL,
        cree_par_code   TEXT    NOT NULL,
        date_cree       TEXT    NOT NULL,
        etat            INTEGER NOT NULL DEFAULT 1,
        
        modif_par_code       TEXT,
        annul_par_code       TEXT,
        date_annul      TEXT,
        date_modif      TEXT,
        motif_annul     TEXT,
        FOREIGN KEY (code_SmartScan)  REFERENCES smart_scan(code),
        FOREIGN KEY (code_produit)    REFERENCES produits(code),
        FOREIGN KEY (cree_par_code)   REFERENCES utilisateur(code)
      )
    ''');
  }

  static Future<void> _createSortie(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sortie(
        id            INTEGER PRIMARY KEY,
        etat          INTEGER NOT NULL DEFAULT 1,
        date          TEXT    NOT NULL,
        code          TEXT    NOT NULL UNIQUE,
        type          TEXT    NOT NULL,
        date_cree     TEXT    NOT NULL DEFAULT(datetime('now')),
        cree_par_code TEXT    NOT NULL,
        montant       REAL    NOT NULL,
        quantite      REAL    NOT NULL,
        nombre        REAL,
        prix          REAL    NOT NULL,
        produit_code  TEXT    NOT NULL,
        sous_categorie_code TEXT,
        magasin_code  TEXT,
        observation   TEXT,
        date_modif    TEXT,
        categorie_code      TEXT,
        modif_par_code     TEXT,
        annul_par_code     TEXT,
        date_annul    TEXT,
        motif_annul   TEXT,
        FOREIGN KEY (cree_par_code)        REFERENCES utilisateur(code),
        FOREIGN KEY (produit_code)         REFERENCES produits(code),
        FOREIGN KEY (categorie_code)       REFERENCES categories(code),
        FOREIGN KEY (sous_categorie_code)  REFERENCES sous_categories(code),
        FOREIGN KEY (magasin_code)         REFERENCES magasins(code)
      )
    ''');
  }

  static Future<void> _createTransfertCaisse(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transfert(
        id  INTEGER PRIMARY KEY,
        code TEXT NOT NULL UNIQUE,
        date_transfert TEXT NOT NULL,
        montant REAL NOT NULL,
        etat INTEGER NOT NULL DEFAULT 1,
        date_cree TEXT NOT NULL DEFAULT(datetime('now')),
        cree_par_code TEXT NOT NULL,
        caisse_exp_code TEXT NOT NULL,
        caisse_dest_code TEXT NOT NULL,
        observation TEXT,
        date_modif TEXT,
        modif_par_code TEXT,
        date_annul TEXT,
        annul_par_code TEXT,
        motif_annul TEXT,
        FOREIGN KEY (cree_par_code)     REFERENCES utilisateur(code),
        FOREIGN KEY (caisse_exp_code)   REFERENCES caisseGestion(code),
        FOREIGN KEY (caisse_dest_code)  REFERENCES caisseGestion(code)
      )
    ''');
  }

  // Transfert de marchandise entre deux magasins (distinct de `transfert`
  // ci-dessus, qui est un transfert d'argent entre deux caisses) — voir
  // MouvementsServices : chaque transfert génère 2 mouvements liés (Sortie
  // au magasin source, Entrée au magasin destination).
  static Future<void> _createTransfertMagasin(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transfert_magasin(
        id  INTEGER PRIMARY KEY,
        code TEXT NOT NULL UNIQUE,
        date TEXT NOT NULL,
        produit_code TEXT NOT NULL,
        quantite REAL NOT NULL,
        nombre REAL,
        magasin_source_code TEXT NOT NULL,
        magasin_dest_code TEXT NOT NULL,
        etat INTEGER NOT NULL DEFAULT 1,
        observation TEXT,
        date_cree TEXT NOT NULL DEFAULT(datetime('now')),
        cree_par_code TEXT NOT NULL,
        date_modif TEXT,
        modif_par_code TEXT,
        date_annul TEXT,
        annul_par_code TEXT,
        motif_annul TEXT,
        FOREIGN KEY (cree_par_code)         REFERENCES utilisateur(code),
        FOREIGN KEY (produit_code)          REFERENCES produits(code),
        FOREIGN KEY (magasin_source_code)   REFERENCES magasins(code),
        FOREIGN KEY (magasin_dest_code)     REFERENCES magasins(code)
      )
    ''');
  }

  static Future<void> _createZakat(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS zakat(
        id INTEGER PRIMARY KEY,
        taux REAL NOT NULL,
        etat INTEGER DEFAULT 1,
        code TEXT NOT NULL UNIQUE,
        annee INTEGER NOT NULL,
        stock REAL NOT NULL,
        dettes REAL NOT NULL,
        nissab REAL NOT NULL,
        status TEXT NOT NULL,
        creances REAL NOT NULL,
        date_cree TEXT NOT NULL DEFAULT(datetime('now')),
        liquidites  REAL NOT NULL,
        obligatoire INTEGER NOT NULL,
        montant_zakat REAL NOT NULL,
        capital_total REAL NOT NULL,
        cree_par_code TEXT NOT NULL,
        date_zakat_due TEXT NOT NULL,
        date_debut_hawl TEXT NOT NULL,
        date_paiement TEXT,
        observation TEXT,
        date_modif TEXT,
        modif_par_code TEXT,
        date_annul TEXT,
        annul_par_code TEXT,
        motif_annul TEXT,
        FOREIGN KEY (cree_par_code)     REFERENCES utilisateur(code)
      )
    ''');
  }

  static Future<void> _createHistorique(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Historique(
        id            INTEGER PRIMARY KEY,
        code          TEXT NOT NULL UNIQUE,
        type          TEXT NOT NULL,
        description   TEXT NOT NULL,
        operation     TEXT NOT NULL,
        cree_par_code TEXT NOT NULL,
        date_cree     TEXT NOT NULL,
        observation   TEXT,
        FOREIGN KEY (cree_par_code)     REFERENCES utilisateur(code)
      )
    ''');
  }

  /// Registre fiscal append-only (JournalFiscalServices) : chaque événement
  /// significatif (vente, annulation...) y est inséré avec un scellement
  /// SHA-256 chaîné, indépendant des autres tables métier. Aucune méthode
  /// d'update/delete n'existe côté service — cette table ne doit jamais être
  /// modifiée après insertion (conformité art. 51 bis).
  static Future<void> _createJournalFiscal(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS journal_fiscal (
        id                INTEGER PRIMARY KEY,
        code              TEXT NOT NULL UNIQUE,
        type_operation    TEXT NOT NULL,
        code_operation    TEXT NOT NULL,
        caisse_code       TEXT,
        utilisateur_code  TEXT NOT NULL,
        montant           REAL,
        donnees_avant     TEXT,
        donnees_apres     TEXT,
        hash              TEXT NOT NULL,
        hash_precedent    TEXT NOT NULL,
        date_evenement    TEXT NOT NULL,
        FOREIGN KEY (utilisateur_code)  REFERENCES utilisateur(code)
      )
    ''');
  }

  /// Clôtures de caisse (rapport Z) : chaque clôture fige définitivement une
  /// période (voir ClotureCaisseServices.cloturer) — les tickets de cette
  /// période ne peuvent plus être annulés (PannierServices.annulerPannier),
  /// seul un Retour reste possible. Scellée par un chaînage SHA-256 propre à
  /// chaque caisse (indépendant du chaînage par ticket et de celui du
  /// journal fiscal).
  static Future<void> _createClotureCaisse(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cloture_caisse (
        id                        INTEGER PRIMARY KEY,
        code                      TEXT NOT NULL UNIQUE,
        caisse_code               TEXT NOT NULL,
        date_debut                TEXT NOT NULL,
        date_fin                  TEXT NOT NULL,
        total_ventes              REAL NOT NULL,
        total_annule              REAL NOT NULL,
        nombre_tickets            INTEGER NOT NULL,
        nombre_tickets_annules    INTEGER NOT NULL,
        repartition_paiement      TEXT,
        utilisateur_code          TEXT NOT NULL,
        date_cree                 TEXT NOT NULL,
        hash                      TEXT NOT NULL,
        hash_precedent            TEXT NOT NULL,
        FOREIGN KEY (caisse_code)       REFERENCES caisseGestion(code),
        FOREIGN KEY (utilisateur_code)  REFERENCES utilisateur(code)
      )
    ''');
  }

  /// Session de caisse (ouverture -> mouvements -> clôture) : la période
  /// pendant laquelle une caisse est active. Une seule session `ouverte`
  /// doit exister à la fois par `caisse_code` (contrainte applicative, voir
  /// CaisseSessionServices.ouvrirSession — pas de contrainte SQL dédiée).
  static Future<void> _createCaisseSession(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS caisse_session (
        id                INTEGER PRIMARY KEY,
        code              TEXT NOT NULL UNIQUE,
        caisse_code       TEXT NOT NULL,
        statut            TEXT NOT NULL DEFAULT 'ouverte',
        solde_ouverture   REAL NOT NULL,
        date_ouverture    TEXT NOT NULL,
        solde_theorique   REAL,
        solde_reel        REAL,
        ecart             REAL,
        date_cloture      TEXT,
        observation       TEXT,
        etat              INTEGER NOT NULL DEFAULT 1,
        date_cree         TEXT NOT NULL,
        cree_par_code     TEXT NOT NULL,
        date_modif        TEXT,
        modif_par_code    TEXT,
        date_annul        TEXT,
        annul_par_code    TEXT,
        motif_annul       TEXT,
        FOREIGN KEY (caisse_code)     REFERENCES caisseGestion(code),
        FOREIGN KEY (cree_par_code)   REFERENCES utilisateur(code)
      )
    ''');
  }

  /// Grand-livre des mouvements de caisse : chaque encaissement/décaissement
  /// réel (vente, achat, versement, retour, ouverture/clôture de session,
  /// mouvement manuel) est journalisé ici, rattaché à une caisse_session.
  /// `code_operation` référence de façon polymorphe (selon `type`) le code
  /// d'un Pannier/SmartScan/Retour/Verssement — pas de contrainte FK dédiée,
  /// même principe que mouvements.code_operation.
  static Future<void> _createCaisseMouvement(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS caisse_mouvement (
        id                INTEGER PRIMARY KEY,
        code              TEXT NOT NULL UNIQUE,
        session_code      TEXT NOT NULL,
        caisse_code       TEXT NOT NULL,
        type              TEXT NOT NULL,
        sens              TEXT NOT NULL,
        montant           REAL NOT NULL,
        mode_paiement     TEXT,
        code_operation    TEXT,
        client_code       TEXT,
        fournisseur_code  TEXT,
        motif             TEXT,
        reference         TEXT,
        date              TEXT NOT NULL,
        etat              INTEGER NOT NULL DEFAULT 1,
        date_cree         TEXT NOT NULL,
        cree_par_code     TEXT NOT NULL,
        date_modif        TEXT,
        modif_par_code    TEXT,
        date_annul        TEXT,
        annul_par_code    TEXT,
        motif_annul       TEXT,
        FOREIGN KEY (session_code)      REFERENCES caisse_session(code),
        FOREIGN KEY (caisse_code)       REFERENCES caisseGestion(code),
        FOREIGN KEY (client_code)       REFERENCES clients(code),
        FOREIGN KEY (fournisseur_code)  REFERENCES fournisseurs(code),
        FOREIGN KEY (cree_par_code)     REFERENCES utilisateur(code)
      )
    ''');
  }
}