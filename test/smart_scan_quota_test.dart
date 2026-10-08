import 'package:caisse_dz/Services/ai_proxy.dart';
import 'package:caisse_dz/data/models/smart_scan_quota.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  // Réponse réelle de GET /smartscan/quota (voir server/tests).
  const jsonStandard = {
    'client_id': 1,
    'client_nom': 'Supérette Test',
    'plan': 'STANDARD',
    'plan_nom': 'Smart Scan',
    'monthly_limit': 60,
    'used': 12,
    'remaining': 48,
    'renewal_date': '2026-11-01',
    'subscription_start': null,
    'subscription_end': null,
    'status': 'standard',
    'upgrade_available': true,
    'offers': [
      {'code': 'SMART_SCAN_200', 'nom': 'Smart Scan 200', 'prix_da': 3000, 'quota_mensuel': 200, 'duree_mois': 12},
    ],
    'contact': '0555 00 00 00',
  };

  test('quota Standard lu depuis l\'API', () {
    final q = SmartScanQuota.fromJson(Map<String, dynamic>.from(jsonStandard));
    expect(q.limiteMensuelle, 60);
    expect(q.utilises, 12);
    expect(q.restants, 48);
    expect(q.progression, closeTo(0.2, 0.001));
    expect(q.offreActive, isFalse);
    expect(q.epuise, isFalse);
    expect(q.renouvellement, DateTime(2026, 11, 1));
    expect(q.offres.single.prixDa, 3000);
    expect(q.offres.single.quotaMensuel, 200);
  });

  test('offre payante active : dates de l\'offre', () {
    final q = SmartScanQuota.fromJson({
      ...jsonStandard,
      'plan': 'SMART_SCAN_200',
      'plan_nom': 'Smart Scan 200',
      'monthly_limit': 200,
      'used': 37,
      'remaining': 163,
      'status': 'active',
      'subscription_start': '2026-10-08',
      'subscription_end': '2027-10-07',
      'upgrade_available': false,
      'offers': [],
    });
    expect(q.offreActive, isTrue);
    expect(q.finOffre, DateTime(2027, 10, 7));
    expect(q.restants, 163);
  });

  test('quota épuisé', () {
    final q = SmartScanQuota.fromJson({...jsonStandard, 'used': 60, 'remaining': 0});
    expect(q.epuise, isTrue);
    expect(q.progression, 1);
  });

  test('refus SCAN_QUOTA_EXCEEDED du serveur reconnu avec son quota', () {
    final reponse = http.Response(
      '{"success":false,"error":"SCAN_QUOTA_EXCEEDED","message":"Votre quota mensuel de Smart Scan est atteint.",'
      '"used":60,"limit":60,"remaining":0,"upgrade_available":true,'
      '"quota":{"plan":"STANDARD","plan_nom":"Smart Scan","monthly_limit":60,"used":60,"remaining":0,"offers":[]}}',
      429,
    );
    final erreur = AiProxy.erreurServeur(reponse);
    expect(erreur, isNotNull);
    expect(erreur!.estQuotaAtteint, isTrue);
    expect(erreur.quota!.epuise, isTrue);
  });

  test('erreur Mistral relayée (non BENS) non confondue avec un refus du serveur', () {
    final reponse = http.Response('{"object":"error","message":"Rate limit exceeded"}', 429);
    expect(AiProxy.erreurServeur(reponse), isNull);
  });

  test('réponse 200 : pas d\'erreur', () {
    expect(AiProxy.erreurServeur(http.Response('{"success":true}', 200)), isNull);
  });
}
