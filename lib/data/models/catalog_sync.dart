/// Ligne de correspondance produit local <-> produit du catalogue distant
/// bensds.com (table `catalog_sync`). Voir CatalogSyncService.
class CatalogSync {
  final int? id;
  final String produitCode;
  final int? catalogProductId;
  final String? codeProduit;
  final String syncStatus; // 'pending' | 'success' | 'error'
  final String? lastError;
  final DateTime? syncedAt;
  final DateTime dateCree;

  const CatalogSync({
    this.id,
    required this.produitCode,
    this.catalogProductId,
    this.codeProduit,
    this.syncStatus = 'pending',
    this.lastError,
    this.syncedAt,
    required this.dateCree,
  });

  factory CatalogSync.fromMap(Map<String, dynamic> map) {
    return CatalogSync(
      id: map['id'] as int?,
      produitCode: map['produit_code'] as String,
      catalogProductId: map['catalog_product_id'] as int?,
      codeProduit: map['code_produit'] as String?,
      syncStatus: (map['sync_status'] as String?) ?? 'pending',
      lastError: map['last_error'] as String?,
      syncedAt: map['synced_at'] != null ? DateTime.tryParse(map['synced_at'] as String) : null,
      dateCree: DateTime.tryParse(map['date_cree'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'produit_code': produitCode,
      'catalog_product_id': catalogProductId,
      'code_produit': codeProduit,
      'sync_status': syncStatus,
      'last_error': lastError,
      'synced_at': syncedAt?.toIso8601String(),
      'date_cree': dateCree.toIso8601String(),
    };
  }
}
