import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/paiementParam.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/utilis/api_response.dart';

class PaiementParamServices {
  final Database db;

  PaiementParamServices(this.db);

  static Future<PaiementParam> getPaiementParam() async {
    final db = await DbCreator.openDb();
    final result = await db.query('paiement_param', where: 'id = ?', whereArgs: [1]);

    if (result.isEmpty) {
      return PaiementParam(
        id: 1,
        especesVisible: true,
        carteVisible: true,
        chequeVisible: true,
        virementVisible: true,
      );
    }
    return PaiementParam.fromMap(result.first);
  }

  Future<ApiResponse<int>> updatePaiementParam(
    PaiementParam param,
    String modifiedByCode,
  ) async {
    try {
      param.dateModif = DateTime.now();
      param.modifParCode = modifiedByCode;

      final rows = await db.update(
        'paiement_param',
        param.toMap(),
        where: 'id = ?',
        whereArgs: [param.id],
      );

      if (rows == 0) {
        await db.insert('paiement_param', param.toMap());
      }

      return ApiResponse(success: true, message: "Modes de paiement mis à jour", data: rows);
    } catch (e) {
      return ApiResponse(success: false, message: "Erreur enregistrement: $e");
    }
  }

  /// Filtre `ListsConst.modePaiementList` (clés françaises fixes) selon la
  /// visibilité configurée, puis traduit pour l'affichage. À utiliser
  /// uniquement pour les sélecteurs de *nouvelle* saisie (pas les filtres
  /// de recherche historiques, qui doivent garder tous les modes).
  static List<String> visibleDisplayList(
    PaiementParam param,
    ListsConstTranslator translator, {
    String? toujoursInclure,
    bool inclurePoints = false,
  }) {
    final visibles = ListsConst.modePaiementList.where((mode) {
      if (mode == toujoursInclure) return true;
      if (mode == 'Points') return inclurePoints;
      return param.isVisible(mode);
    }).toList();

    return visibles.map(translator.translateModePaiement).toList();
  }
}
