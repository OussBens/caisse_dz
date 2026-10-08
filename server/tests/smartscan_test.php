<?php
/**
 * Tests du service Smart Scan — base SQLite en mémoire, faux Mistral et
 * horloge contrôlée. Lancer :  php server/tests/smartscan_test.php
 */
require_once __DIR__ . '/../smartscan_core/SmartScanService.php';
require_once __DIR__ . '/../smartscan_core/SmartScanSchema.php';

const SECRET = 'SECRET-DE-TEST';

$echecs = 0;
$total = 0;
function verifier($condition, $libelle)
{
    global $echecs, $total;
    $total++;
    if ($condition) {
        echo "  ok  $libelle\n";
    } else {
        $echecs++;
        echo "  ÉCHEC  $libelle\n";
    }
}

/** Attend une SmartScanException avec ce code ; renvoie l'exception. */
function attendreErreur($code, callable $f, $libelle)
{
    try {
        $f();
        verifier(false, "$libelle (aucune erreur levée)");
    } catch (SmartScanException $e) {
        verifier($e->codeErreur === $code, "$libelle → $code" . ($e->codeErreur !== $code ? " (reçu {$e->codeErreur})" : ''));
        return $e;
    }
    return null;
}

/** Image PNG valide de 20×20, différente selon $graine (empreinte distincte). */
function image($graine = 0)
{
    // PNG RVB construit à la main (pas besoin de l'extension GD).
    $chunk = function ($type, $data) {
        return pack('N', strlen($data)) . $type . $data . pack('N', crc32($type . $data));
    };
    $pixel = chr($graine % 256) . chr(($graine >> 8) % 256) . chr(120);
    $lignes = str_repeat("\0" . str_repeat($pixel, 20), 20);
    $png = "\x89PNG\r\n\x1a\n"
        . $chunk('IHDR', pack('NNCCCCC', 20, 20, 8, 2, 0, 0, 0))
        . $chunk('IDAT', gzcompress($lignes))
        . $chunk('IEND', '');
    return 'data:image/png;base64,' . base64_encode($png);
}

class Contexte
{
    public $db;
    public $service;
    public $temps;
    public $reponseOcr = [200, '{"pages":[{"markdown":"Coca 1.5L  x6  120"}]}'];
    public $appels = 0;

    public function __construct(array $config = [])
    {
        $this->db = new PDO('sqlite::memory:');
        $this->db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        SmartScanSchema::installer($this->db);
        $this->temps = strtotime('2026-10-08 10:00:00');
        $ctx = $this;
        $this->service = new SmartScanService($this->db, array_merge([
            'secret_licence' => SECRET,
            'rate_par_minute' => 1000,
            'max_simultanes' => 1,
            'contact' => '0555 00 00 00',
        ], $config), function ($chemin, $payload) use ($ctx) {
            $ctx->appels++;
            if ($ctx->reponseOcr === 'exception') throw new Exception('réseau coupé');
            return $chemin === '/v1/ocr' ? $ctx->reponseOcr : [200, '{"choices":[{"message":{"content":"[]"}}]}'];
        }, function () use ($ctx) {
            return $ctx->temps;
        });
    }

    public function poste($deviceId = 'POSTE0000000000000000000000000001', $entreprise = 'Superette Test')
    {
        return $this->service->authentifier($deviceId, SmartScanService::cleLicence($deviceId, 'avance', SECRET), $entreprise);
    }

    /** n scans réussis espacés d'une seconde, images distinctes. */
    public function scanner(array $poste, $n, $graineDepart = 1000)
    {
        for ($i = 0; $i < $n; $i++) {
            $this->temps++;
            $this->service->scanner($poste, image($graineDepart + $i));
        }
    }
}

echo "Licence et clients\n";
$c = new Contexte();
attendreErreur('LICENSE_INVALID', function () use ($c) {
    $c->service->authentifier('POSTE1', 'FAUSSECLE', null);
}, 'clé fausse refusée');
attendreErreur('LICENSE_INVALID', function () use ($c) {
    $c->service->authentifier('', '', null);
}, 'licence absente refusée');
$p = $c->poste();
verifier((int)$p['client_id'] > 0, 'nouveau poste enregistré et rattaché à un client');
$cleBasic = SmartScanService::cleLicence('POSTE2', 'basic', SECRET);
verifier((int)$c->service->authentifier('POSTE2', $cleBasic, 'Autre')['client_id'] !== (int)$p['client_id'], 'licence "basic" acceptée, autre client');
$q = $c->service->quota((int)$p['client_id']);
verifier($q['plan'] === 'STANDARD' && $q['monthly_limit'] === 60 && $q['remaining'] === 60, 'forfait Standard : 60/mois');
verifier($q['client_nom'] === 'Superette Test', 'nom du client = nom de l\'entreprise');
verifier($q['renewal_date'] === '2026-11-01', 'renouvellement au 1er du mois suivant');
verifier($q['upgrade_available'] && $q['offers'][0]['code'] === 'SMART_SCAN_200' && $q['offers'][0]['prix_da'] === 3000, 'offre Smart Scan 200 proposée (prix depuis la base)');

echo "\nQuota Standard\n";
$c = new Contexte();
$p = $c->poste();
$r = $c->service->scanner($p, image(1));
verifier($r['success'] && $r['scan_id'] > 0 && strpos($r['text'], 'Coca') !== false, 'scan réussi : texte + scan_id');
verifier($r['quota']['used'] === 1 && $r['quota']['remaining'] === 59, 'compteur : 1 utilisé, 59 restants');
$c->scanner($p, 59);
$e = attendreErreur('SCAN_QUOTA_EXCEEDED', function () use ($c, $p) {
    $c->service->scanner($p, image(9999));
}, '61e scan refusé');
verifier($e && $e->donnees['used'] === 60 && $e->donnees['limit'] === 60 && $e->donnees['remaining'] === 0 && $e->donnees['upgrade_available'] === true, 'réponse structurée used/limit/remaining/upgrade_available');
$appelsAvant = $c->appels;
attendreErreur('SCAN_QUOTA_EXCEEDED', function () use ($c, $p) {
    $c->service->scanner($p, image(9998));
}, 'toujours refusé');
verifier($c->appels === $appelsAvant, 'aucun appel Mistral quand le quota est atteint');

echo "\nÉchecs non décomptés\n";
$c = new Contexte();
$p = $c->poste();
$cid = (int)$p['client_id'];
$cas = [
    'erreur Mistral 500' => [500, '{"error":"x"}'],
    'quota Mistral 429' => [429, '{"error":"rate"}'],
    'timeout / réseau (code 0)' => [0, 'timeout'],
    'texte vide' => [200, '{"pages":[{"markdown":"   "}]}'],
    'exception transport' => 'exception',
];
$graine = 1;
foreach ($cas as $libelle => $reponse) {
    $c->reponseOcr = $reponse;
    $c->temps += 1;
    try {
        $c->service->scanner($p, image($graine++));
        verifier(false, "$libelle : une erreur aurait dû être levée");
    } catch (SmartScanException $ex) {
        verifier($c->service->quota($cid)['used'] === 0, "$libelle : non décompté ({$ex->codeErreur})");
    }
}
attendreErreur('INVALID_IMAGE', function () use ($c, $p) {
    $c->service->scanner($p, 'data:image/png;base64,' . base64_encode('pas une image'));
}, 'image invalide refusée');
attendreErreur('INVALID_IMAGE', function () use ($c, $p) {
    $c->service->scanner($p, 'data:application/pdf;base64,' . base64_encode('%PDF'));
}, 'format non image refusé');
$petit = new Contexte(['taille_max_octets' => 50]);
$pp = $petit->poste();
attendreErreur('IMAGE_TOO_LARGE', function () use ($petit, $pp) {
    $petit->service->scanner($pp, image(1));
}, 'image trop lourde refusée');
$journal = $c->service->journal($cid, true);
verifier(count($journal) === 5 && $journal[0]['code_erreur'] !== null, 'échecs journalisés avec leur code d\'erreur');
$c->reponseOcr = [200, '{"pages":[{"markdown":"ok"}]}'];
$c->temps += 1;
$c->service->scanner($p, image(500));
verifier($c->service->quota($cid)['used'] === 1, 'scan suivant réussi : compté normalement');

echo "\nRéinitialisation mensuelle\n";
$c = new Contexte();
$p = $c->poste();
$cid = (int)$p['client_id'];
$c->scanner($p, 60);
verifier($c->service->quota($cid)['remaining'] === 0, 'octobre : 60/60 utilisés');
$c->temps = strtotime('2026-11-01 00:00:05');
$q = $c->service->quota($cid);
verifier($q['used'] === 0 && $q['remaining'] === 60, 'novembre : compteur remis à 60, rien de reporté');
$c->service->scanner($p, image(42));
verifier($c->service->quota($cid)['used'] === 1, 'novembre : scans comptés sur le nouveau mois');

echo "\nSmart Scan 200\n";
$c = new Contexte();
$p = $c->poste();
$cid = (int)$p['client_id'];
$c->scanner($p, 37);
$aboId = $c->service->activerForfait($cid, 'SMART_SCAN_200');
$q = $c->service->quota($cid);
verifier($q['plan'] === 'SMART_SCAN_200' && $q['monthly_limit'] === 200, 'limite = 200 (et non 60 + 200)');
verifier($q['used'] === 37 && $q['remaining'] === 163, 'scans du mois conservés : 37 / 200, 163 restants');
verifier($q['subscription_start'] === '2026-10-08' && $q['subscription_end'] === '2027-10-07', 'offre du 08/10/2026 au 07/10/2027');
verifier(!$q['upgrade_available'], 'plus d\'offre supérieure proposée');
$c->temps = strtotime('2027-10-07 23:00:00');
verifier($c->service->quota($cid)['plan'] === 'SMART_SCAN_200', 'encore active le dernier jour');
$c->temps = strtotime('2027-10-08 08:00:00');
$q = $c->service->quota($cid);
verifier($q['plan'] === 'STANDARD' && $q['monthly_limit'] === 60, 'expirée le lendemain : retour à 60');
$statut = $c->db->query("SELECT statut FROM ss_abonnements WHERE id = $aboId")->fetchColumn();
verifier($statut === 'expired', 'abonnement passé au statut expired');
$c->service->prolongerAbonnement($aboId, 12);
verifier($c->service->quota($cid)['plan'] === 'SMART_SCAN_200', 'prolongation : offre réactivée');
$c->service->annulerAbonnement($aboId);
verifier($c->service->quota($cid)['plan'] === 'STANDARD', 'annulation : retour au Standard');

echo "\nQuota exceptionnel\n";
$c = new Contexte();
$p = $c->poste();
$cid = (int)$p['client_id'];
$c->service->definirQuotaException($cid, 80);
verifier($c->service->quota($cid)['monthly_limit'] === 80, 'quota exceptionnel appliqué ce mois-ci');
$c->temps = strtotime('2026-11-02 09:00:00');
verifier($c->service->quota($cid)['monthly_limit'] === 60, 'quota exceptionnel non reconduit le mois suivant');

echo "\nAnti-abus\n";
$c = new Contexte(['rate_par_minute' => 3]);
$p = $c->poste();
for ($i = 0; $i < 3; $i++) {
    $c->service->scanner($p, image(10 + $i));
}
attendreErreur('RATE_LIMITED', function () use ($c, $p) {
    $c->service->scanner($p, image(99));
}, '4e scan dans la même minute refusé');
$c->temps += 61;
$c->service->scanner($p, image(100));
verifier(true, 'de nouveau autorisé après une minute');

$c = new Contexte();
$p = $c->poste();
$cid = (int)$p['client_id'];
$c->db->exec("INSERT INTO ss_scans (client_id, device_id, cree_le, statut, extractions) VALUES ($cid, 'X', '" . date('Y-m-d H:i:s', $c->temps - 10) . "', 'reserve', 0)");
attendreErreur('SCAN_IN_PROGRESS', function () use ($c, $p) {
    $c->service->scanner($p, image(1));
}, 'scan simultané refusé pendant un scan en cours');
$c->temps += 200;
$c->service->scanner($p, image(2));
verifier($c->service->quota($cid)['used'] === 1, 'réservation abandonnée expirée : ni bloquante ni décomptée');

$c->temps += 5;
attendreErreur('DUPLICATE_SCAN', function () use ($c, $p) {
    $c->service->scanner($p, image(2));
}, 'même bon renvoyé aussitôt : refusé');
verifier($c->service->quota($cid)['used'] === 1, 'doublon non décompté');

$c = new Contexte();
$p = $c->poste();
$cid = (int)$p['client_id'];
$c->service->bloquerPoste($p['device_id'], true);
attendreErreur('DEVICE_BLOCKED', function () use ($c) {
    $c->poste();
}, 'poste bloqué refusé');
$c->service->bloquerPoste($p['device_id'], false);
$c->service->majClient($cid, 'Superette Test', null, 'suspendu');
attendreErreur('CLIENT_SUSPENDED', function () use ($c, $p) {
    $c->service->scanner($p, image(1));
}, 'client suspendu refusé');

$c = new Contexte(['plafond_global_mensuel' => 2]);
$c->scanner($c->poste('POSTEA'), 1);
$c->scanner($c->poste('POSTEB'), 1, 50);
attendreErreur('SERVICE_UNAVAILABLE', function () use ($c) {
    $c->service->scanner($c->poste('POSTEC'), image(77));
}, 'plafond global mensuel de sécurité');

echo "\nExtraction des lignes\n";
$c = new Contexte(['extractions_par_scan' => 2]);
$p = $c->poste();
$scan = $c->service->scanner($p, image(1));
$corps = ['model' => 'mistral-small-latest', 'messages' => [['role' => 'user', 'content' => 'x']]];
list($code) = $c->service->extraire($p, $scan['scan_id'], $corps);
verifier($code === 200, 'extraction liée au scan acceptée');
verifier($c->service->quota((int)$p['client_id'])['used'] === 1, 'extraction ne consomme pas de quota');
$c->service->extraire($p, $scan['scan_id'], $corps);
attendreErreur('EXTRACTION_LIMIT', function () use ($c, $p, $scan, $corps) {
    $c->service->extraire($p, $scan['scan_id'], $corps);
}, 'nombre d\'extractions par scan limité');
attendreErreur('MODEL_NOT_ALLOWED', function () use ($c, $p, $scan) {
    $c->service->extraire($p, $scan['scan_id'], ['model' => 'mistral-large-latest', 'messages' => []]);
}, 'modèle non autorisé refusé');
$autre = $c->poste('POSTEAUTRE', 'Autre client');
attendreErreur('SCAN_NOT_FOUND', function () use ($c, $autre, $scan, $corps) {
    $c->service->extraire($autre, $scan['scan_id'], $corps);
}, 'scan d\'un autre client inaccessible');
$c->temps += 3600;
attendreErreur('SCAN_NOT_FOUND', function () use ($c, $p, $scan, $corps) {
    $c->service->extraire($p, $scan['scan_id'], $corps);
}, 'scan expiré inaccessible');

echo "\nPlusieurs postes, un seul compteur\n";
$c = new Contexte();
$p1 = $c->poste('POSTEMAGASIN1', 'Superette Centre');
$p2 = $c->poste('POSTEMAGASIN2', 'Superette Centre (caisse 2)');
$cid = (int)$p1['client_id'];
$c->service->rattacherPoste('POSTEMAGASIN2', $cid);
$p2 = $c->poste('POSTEMAGASIN2');
$c->scanner($p1, 30);
$c->scanner($p2, 30, 5000);
verifier($c->service->quota($cid)['used'] === 60, 'scans des 2 postes cumulés sur le même client');
attendreErreur('SCAN_QUOTA_EXCEEDED', function () use ($c, $p2) {
    $c->service->scanner($p2, image(8888));
}, 'quota commun atteint sur le 2e poste');

echo "\nDemande d'offre & administration\n";
$c = new Contexte();
$p = $c->poste();
$cid = (int)$p['client_id'];
$d = $c->service->demanderOffre($p, 'SMART_SCAN_200');
verifier($d['success'] && !$d['deja_demandee'] && $d['contact'] === '0555 00 00 00', 'demande enregistrée, contact renvoyé');
verifier($c->service->demanderOffre($p, 'SMART_SCAN_200')['deja_demandee'], 'pas de doublon de demande');
attendreErreur('OFFER_UNKNOWN', function () use ($c, $p) {
    $c->service->demanderOffre($p, 'STANDARD');
}, 'offre gratuite non demandable');
$c->service->activerForfait($cid, 'SMART_SCAN_200');
$statut = $c->db->query("SELECT statut FROM ss_demandes WHERE client_id = $cid")->fetchColumn();
verifier($statut === 'traitee', 'activation : demande marquée traitée');
$c->scanner($p, 3);
$liste = $c->service->listeClients();
verifier(count($liste) === 1 && $liste[0]['total_scans'] === 3 && $liste[0]['plan'] === 'SMART_SCAN_200' && $liste[0]['postes'] === 1, 'liste admin : forfait, total, postes');
$conso = $c->service->consommationParMois($cid);
verifier($conso[0]['mois'] === '2026-10' && $conso[0]['reussis'] === 3, 'consommation par mois');
$c->db->exec("INSERT INTO ss_forfaits (code, nom, prix_da, quota_mensuel, duree_mois, actif) VALUES ('SMART_SCAN_500', 'Smart Scan 500', 6000, 500, 12, 1)");
$q = $c->service->quota($cid);
verifier($q['upgrade_available'] && $q['offers'][0]['code'] === 'SMART_SCAN_500', 'nouveau forfait ajouté en base : proposé sans changer le code');

echo "\n" . ($total - $echecs) . " / $total tests réussis\n";
exit($echecs === 0 ? 0 : 1);
