<?php
/**
 * Administration Smart Scan — à placer à côté de index.php.
 * Accès protégé par ADMIN_PASSWORD (.env), session + jeton CSRF.
 *
 * Clients, forfaits, quotas, postes, demandes d'offre, journal et erreurs
 * OCR. Toutes les actions passent par SmartScanService (mêmes règles que
 * l'API utilisée par Caisse DZ).
 */
ini_set('display_errors', 0);
ini_set('log_errors', 1);

// .env partagé avec index.php
foreach (@file(__DIR__ . '/.env', FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) ?: [] as $ligne) {
    if (strpos(trim($ligne), '#') === 0 || strpos($ligne, '=') === false) continue;
    list($k, $v) = explode('=', $ligne, 2);
    $_ENV[trim($k)] = trim($v, " \t\"'");
}
require_once __DIR__ . '/smartscan_core/routes.php';

session_set_cookie_params(['httponly' => true, 'secure' => smartscanEstHttps(), 'samesite' => 'Strict']);
session_start();
header('Content-Type: text/html; charset=utf-8');
header('X-Frame-Options: DENY');

function h($v)
{
    return htmlspecialchars((string)$v, ENT_QUOTES, 'UTF-8');
}
function dateFr($d)
{
    return $d ? date('d/m/Y', strtotime($d)) : '—';
}
function dateHeureFr($d)
{
    return $d ? date('d/m/Y H:i', strtotime($d)) : '—';
}
function lien(array $params)
{
    return '?' . http_build_query($params);
}
function csrf()
{
    return '<input type="hidden" name="csrf" value="' . h($_SESSION['csrf']) . '">';
}

$motDePasse = $_ENV['ADMIN_PASSWORD'] ?? '';
if ($motDePasse === '') {
    http_response_code(503);
    exit('Administration désactivée : définissez ADMIN_PASSWORD dans le fichier .env.');
}
if (smartscanEnv('SMARTSCAN_HTTPS_OBLIGATOIRE', '1') !== '0' && !smartscanEstHttps()) {
    http_response_code(403);
    exit('Connexion sécurisée (HTTPS) obligatoire.');
}

// ── Connexion / déconnexion
if (isset($_GET['deconnexion'])) {
    session_destroy();
    header('Location: ' . strtok($_SERVER['REQUEST_URI'], '?'));
    exit;
}
if (empty($_SESSION['admin'])) {
    $erreur = '';
    if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['mot_de_passe'])) {
        if (hash_equals($motDePasse, (string)$_POST['mot_de_passe'])) {
            session_regenerate_id(true);
            $_SESSION['admin'] = true;
            $_SESSION['csrf'] = bin2hex(random_bytes(16));
            header('Location: ' . $_SERVER['REQUEST_URI']);
            exit;
        }
        sleep(2); // ralentit les essais de mot de passe
        $erreur = 'Mot de passe incorrect.';
        error_log('[smartscan-admin] échec de connexion depuis ' . ($_SERVER['REMOTE_ADDR'] ?? '?'));
    }
    ?><!doctype html><html lang="fr"><head><meta charset="utf-8"><title>Smart Scan — Administration</title>
    <style>body{font-family:Inter,"Segoe UI",system-ui,Arial;background:#F6F6FA;display:flex;justify-content:center;align-items:center;height:100vh;margin:0}
    form{background:#fff;padding:32px;border-radius:16px;box-shadow:0 4px 20px rgba(117,93,179,.15);width:320px}
    h1{color:#6A4CF0;font-size:20px;margin:0 0 20px}input{width:100%;padding:10px;border:1px solid #E7E5F0;border-radius:10px;box-sizing:border-box}
    button{margin-top:14px;width:100%;padding:10px;background:#6A4CF0;color:#fff;border:0;border-radius:10px;cursor:pointer}.err{color:#E5395F;margin-top:10px}</style></head>
    <body><form method="post"><h1>Smart Scan — Administration</h1>
    <input type="password" name="mot_de_passe" placeholder="Mot de passe" autofocus required>
    <button>Se connecter</button><?php if ($erreur) echo '<div class="err">' . h($erreur) . '</div>'; ?></form></body></html><?php
    exit;
}

// ── Base et service
try {
    // DB_DSN (facultatif) : autre base, ex. SQLite pour les tests.
    $db = new PDO(
        $_ENV['DB_DSN'] ?? ('mysql:host=' . ($_ENV['DB_HOST'] ?? 'localhost') . ';dbname=' . ($_ENV['DB_NAME'] ?? '') . ';charset=utf8mb4'),
        $_ENV['DB_USER'] ?? '',
        $_ENV['DB_PASSWORD'] ?? ''
    );
    $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (Exception $e) {
    error_log('[smartscan-admin] ' . $e->getMessage());
    exit('Connexion à la base impossible (voir .env).');
}
$service = smartscanService($db);

$message = $_SESSION['message'] ?? '';
unset($_SESSION['message']);

// Premier lancement : tables Smart Scan absentes → installation automatique
// (idempotente), sinon la page ne pourrait même pas afficher son bouton.
try {
    $db->query('SELECT 1 FROM ss_forfaits LIMIT 1');
    $db->query('SELECT 1 FROM ss_demandes LIMIT 1');
} catch (Exception $e) {
    try {
        SmartScanSchema::installer($db);
        $message = 'Tables Smart Scan installées (premier lancement).';
    } catch (Exception $e2) {
        error_log('[smartscan-admin] installation : ' . $e2->getMessage());
        exit('Installation des tables Smart Scan impossible : ' . h($e2->getMessage())
            . '<br>Vérifiez que l\'utilisateur MySQL a le droit CREATE.');
    }
}

// Erreur imprévue pendant l'affichage : message lisible au lieu d'une page blanche.
set_exception_handler(function ($e) {
    error_log('[smartscan-admin] ' . get_class($e) . ': ' . $e->getMessage());
    echo '<div style="margin:20px;padding:14px;background:#E5395F;color:#fff;border-radius:10px;font-family:Inter,"Segoe UI",system-ui,Arial">'
        . 'Erreur : ' . h($e->getMessage()) . '</div>';
});

// ── Actions (POST + CSRF), puis redirection (pas de double envoi au rafraîchissement)
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!hash_equals($_SESSION['csrf'], (string)($_POST['csrf'] ?? ''))) {
        http_response_code(400);
        exit('Jeton de sécurité invalide, rechargez la page.');
    }
    $a = $_POST['action'] ?? '';
    $cid = (int)($_POST['client_id'] ?? 0);
    try {
        switch ($a) {
            case 'installer':
                SmartScanSchema::installer($db);
                $ok = 'Tables Smart Scan installées / à jour.';
                break;
            case 'activer':
                $service->activerForfait($cid, $_POST['forfait'], $_POST['debut'] ?: null, (int)$_POST['mois'] ?: null, $_POST['note'] ?: null);
                $ok = 'Offre activée.';
                break;
            case 'annuler':
                $service->annulerAbonnement((int)$_POST['abonnement_id']);
                $ok = 'Offre désactivée.';
                break;
            case 'prolonger':
                $service->prolongerAbonnement((int)$_POST['abonnement_id'], max(1, (int)$_POST['mois']));
                $ok = 'Offre prolongée.';
                break;
            case 'quota_exception':
                $service->definirQuotaException($cid, $_POST['quota'] === '' ? null : (int)$_POST['quota']);
                $ok = 'Quota du mois mis à jour.';
                break;
            case 'client':
                $service->majClient($cid, trim($_POST['nom']), trim($_POST['contact']) ?: null, $_POST['statut']);
                $ok = 'Client enregistré.';
                break;
            case 'rattacher':
                $service->rattacherPoste($_POST['device_id'], (int)$_POST['vers_client']);
                $ok = 'Poste rattaché.';
                break;
            case 'bloquer':
                $service->bloquerPoste($_POST['device_id'], $_POST['bloque'] === '1');
                $ok = 'Poste mis à jour.';
                break;
            case 'demande':
                $service->marquerDemande((int)$_POST['demande_id'], $_POST['statut']);
                $ok = 'Demande mise à jour.';
                break;
            case 'forfait':
                $service->enregistrerForfait($_POST['code'], $_POST['nom'], $_POST['prix_da'], $_POST['quota_mensuel'], $_POST['duree_mois'], !empty($_POST['actif']));
                $ok = 'Forfait enregistré.';
                break;
            default:
                $ok = '';
        }
        $_SESSION['message'] = $ok;
    } catch (Exception $e) {
        $_SESSION['message'] = 'Erreur : ' . $e->getMessage();
    }
    header('Location: ' . $_SERVER['REQUEST_URI']);
    exit;
}

$page = $_GET['page'] ?? 'clients';
?><!doctype html>
<html lang="fr"><head><meta charset="utf-8"><title>Smart Scan — Administration</title>
<style>
body{font-family:Inter,"Segoe UI",system-ui,Arial;background:#F6F6FA;margin:0;color:#1B1A2E}
header{background:#fff;border-bottom:1px solid #e3def3;padding:12px 24px;display:flex;gap:18px;align-items:center}
header b{color:#6A4CF0;font-size:18px;margin-right:12px}header a{color:#5638CC;text-decoration:none}header a.on{font-weight:700;color:#6A4CF0}
main{padding:20px 24px}.carte{background:#fff;border-radius:14px;padding:16px;margin-bottom:16px;box-shadow:0 2px 8px rgba(117,93,179,.08)}
table{border-collapse:collapse;width:100%;font-size:13px}th{background:#6A4CF0;color:#fff;text-align:left;padding:7px}td{padding:6px 7px;border-bottom:1px solid #eee}
.pill{padding:2px 8px;border-radius:10px;font-size:12px;color:#fff}.vert{background:#16A34A}.rouge{background:#E5395F}.gris{background:#8A889E}.violet{background:#6A4CF0}.orange{background:#E0A100}
.msg{background:#16A34A;color:#fff;padding:10px 14px;border-radius:10px;margin-bottom:14px}
input,select{padding:5px 7px;border:1px solid #E7E5F0;border-radius:8px}button{padding:5px 12px;background:#6A4CF0;color:#fff;border:0;border-radius:8px;cursor:pointer}
button.sec{background:#8A889E}button.danger{background:#E5395F}form.inline{display:inline}.grille{display:grid;grid-template-columns:repeat(4,1fr);gap:12px}
.chiffre{font-size:26px;font-weight:700;color:#6A4CF0}.barre{height:8px;background:#eee;border-radius:4px;overflow:hidden}.barre div{height:100%;background:#6A4CF0}
</style></head><body>
<header><b>Smart Scan</b>
<a class="<?= $page === 'clients' ? 'on' : '' ?>" href="<?= lien(['page' => 'clients']) ?>">Clients</a>
<a class="<?= $page === 'demandes' ? 'on' : '' ?>" href="<?= lien(['page' => 'demandes']) ?>">Demandes (<?= count($service->demandes()) ?>)</a>
<a class="<?= $page === 'journal' ? 'on' : '' ?>" href="<?= lien(['page' => 'journal']) ?>">Journal</a>
<a class="<?= $page === 'erreurs' ? 'on' : '' ?>" href="<?= lien(['page' => 'erreurs']) ?>">Erreurs OCR</a>
<a class="<?= $page === 'forfaits' ? 'on' : '' ?>" href="<?= lien(['page' => 'forfaits']) ?>">Forfaits</a>
<span style="flex:1"></span><a href="?deconnexion=1">Déconnexion</a></header>
<main>
<?php if ($message): ?><div class="msg"><?= h($message) ?></div><?php endif; ?>

<?php if ($page === 'clients'): $clients = $service->listeClients(); ?>
<div class="carte">
  <form method="post" class="inline" style="float:right"><?= csrf() ?><input type="hidden" name="action" value="installer"><button class="sec">Installer / mettre à jour les tables</button></form>
  <h3 style="margin-top:0">Clients (<?= count($clients) ?>)</h3>
  <table><tr><th>Client</th><th>Forfait</th><th>Quota</th><th>Utilisés</th><th>Restants</th><th>Début</th><th>Expiration</th><th>Offre</th><th>Total scans</th><th>Dernière utilisation</th><th>Postes</th><th>Statut</th></tr>
  <?php foreach ($clients as $c): ?>
    <tr><td><a href="<?= lien(['page' => 'client', 'id' => $c['client_id']]) ?>"><?= h($c['client_nom']) ?></a></td>
      <td><?= h($c['plan_nom']) ?></td><td><?= (int)$c['monthly_limit'] ?></td><td><?= (int)$c['used'] ?></td><td><?= (int)$c['remaining'] ?></td>
      <td><?= dateFr($c['subscription_start']) ?></td><td><?= dateFr($c['subscription_end']) ?></td>
      <td><span class="pill <?= $c['status'] === 'active' ? 'vert' : 'gris' ?>"><?= $c['status'] === 'active' ? 'active' : 'standard' ?></span></td>
      <td><?= (int)$c['total_scans'] ?></td><td><?= dateHeureFr($c['derniere_utilisation']) ?></td><td><?= (int)$c['postes'] ?></td>
      <td><span class="pill <?= $c['statut_client'] === 'actif' ? 'vert' : 'rouge' ?>"><?= h($c['statut_client']) ?></span></td></tr>
  <?php endforeach; ?>
  </table>
</div>

<?php elseif ($page === 'client'):
    $f = $service->ficheClient((int)($_GET['id'] ?? 0));
    $c = $f['client'];
    $q = $f['quota'];
    $aboActif = null;
    foreach ($f['abonnements'] as $ab) if ($ab['statut'] === 'active') { $aboActif = $ab; break; }
    $payants = array_filter($service->forfaits(), function ($x) { return (int)$x['prix_da'] > 0 && (int)$x['actif'] === 1; });
?>
<div class="carte"><h3 style="margin-top:0"><?= h($c['nom']) ?> <small style="color:#8A889E">#<?= (int)$c['id'] ?></small></h3>
  <div class="grille">
    <div><div>Forfait</div><div class="chiffre" style="font-size:20px"><?= h($q['plan_nom']) ?></div></div>
    <div><div>Utilisés ce mois</div><div class="chiffre"><?= (int)$q['used'] ?> / <?= (int)$q['monthly_limit'] ?></div>
      <div class="barre"><div style="width:<?= $q['monthly_limit'] ? min(100, round($q['used'] * 100 / $q['monthly_limit'])) : 100 ?>%"></div></div></div>
    <div><div>Restants</div><div class="chiffre"><?= (int)$q['remaining'] ?></div><small>Renouvellement : <?= dateFr($q['renewal_date']) ?></small></div>
    <div><div>Offre</div><div class="chiffre" style="font-size:16px"><?= $aboActif ? 'Du ' . dateFr($aboActif['debut']) . '<br>au ' . dateFr($aboActif['fin']) : 'Aucune offre payante' ?></div></div>
  </div>
</div>

<div class="carte"><h4 style="margin-top:0">Offre</h4>
  <form method="post" class="inline"><?= csrf() ?><input type="hidden" name="action" value="activer"><input type="hidden" name="client_id" value="<?= (int)$c['id'] ?>">
    <select name="forfait"><?php foreach ($payants as $p): ?><option value="<?= h($p['code']) ?>"><?= h($p['nom']) ?> — <?= (int)$p['prix_da'] ?> DA / <?= (int)$p['duree_mois'] ?> mois</option><?php endforeach; ?></select>
    début <input type="date" name="debut" value="<?= date('Y-m-d') ?>"> durée <input type="number" name="mois" placeholder="mois" style="width:70px">
    <input name="note" placeholder="note (paiement…)"> <button>Activer</button></form>
  <?php if ($aboActif): ?>
    &nbsp; <form method="post" class="inline"><?= csrf() ?><input type="hidden" name="action" value="prolonger"><input type="hidden" name="abonnement_id" value="<?= (int)$aboActif['id'] ?>">
      <input type="number" name="mois" value="12" style="width:60px"> mois <button class="sec">Prolonger</button></form>
    <form method="post" class="inline" onsubmit="return confirm('Désactiver l\'offre ?')"><?= csrf() ?><input type="hidden" name="action" value="annuler"><input type="hidden" name="abonnement_id" value="<?= (int)$aboActif['id'] ?>"><button class="danger">Désactiver</button></form>
  <?php endif; ?>
  <p><form method="post" class="inline"><?= csrf() ?><input type="hidden" name="action" value="quota_exception"><input type="hidden" name="client_id" value="<?= (int)$c['id'] ?>">
    Quota exceptionnel pour <?= date('m/Y') ?> : <input type="number" name="quota" value="<?= $c['quota_exception_mois'] === date('Y-m') ? (int)$c['quota_exception'] : '' ?>" placeholder="vide = normal" style="width:110px"> <button class="sec">Appliquer</button></form></p>
  <table><tr><th>Forfait</th><th>Début</th><th>Fin</th><th>Prix</th><th>Statut</th><th>Note</th></tr>
  <?php foreach ($f['abonnements'] as $ab): ?><tr><td><?= h($ab['forfait_code']) ?></td><td><?= dateFr($ab['debut']) ?></td><td><?= dateFr($ab['fin']) ?></td><td><?= (int)$ab['prix_da'] ?> DA</td>
    <td><span class="pill <?= $ab['statut'] === 'active' ? 'vert' : ($ab['statut'] === 'expired' ? 'orange' : 'gris') ?>"><?= h($ab['statut']) ?></span></td><td><?= h($ab['note']) ?></td></tr><?php endforeach; ?>
  </table>
</div>

<div class="carte"><h4 style="margin-top:0">Client</h4>
  <form method="post"><?= csrf() ?><input type="hidden" name="action" value="client"><input type="hidden" name="client_id" value="<?= (int)$c['id'] ?>">
    <input name="nom" value="<?= h($c['nom']) ?>" required> <input name="contact" value="<?= h($c['contact']) ?>" placeholder="contact">
    <select name="statut"><option value="actif">actif</option><option value="suspendu" <?= $c['statut'] === 'suspendu' ? 'selected' : '' ?>>suspendu</option></select> <button>Enregistrer</button></form>
</div>

<div class="carte"><h4 style="margin-top:0">Postes (licences)</h4>
  <table><tr><th>Poste</th><th>Entreprise</th><th>Licence</th><th>Premier appel</th><th>Dernier appel</th><th>Rattacher à</th><th></th></tr>
  <?php $tous = $service->clientsSimples(); foreach ($f['postes'] as $p): ?>
    <tr><td><code><?= h($p['device_id']) ?></code></td><td><?= h($p['entreprise']) ?></td><td><?= h($p['palier_licence']) ?></td>
      <td><?= dateHeureFr($p['premier_appel']) ?></td><td><?= dateHeureFr($p['dernier_appel']) ?></td>
      <td><form method="post" class="inline"><?= csrf() ?><input type="hidden" name="action" value="rattacher"><input type="hidden" name="device_id" value="<?= h($p['device_id']) ?>">
        <select name="vers_client"><?php foreach ($tous as $t): ?><option value="<?= (int)$t['id'] ?>" <?= (int)$t['id'] === (int)$c['id'] ? 'selected' : '' ?>><?= h($t['nom']) ?></option><?php endforeach; ?></select> <button class="sec">OK</button></form></td>
      <td><form method="post" class="inline"><?= csrf() ?><input type="hidden" name="action" value="bloquer"><input type="hidden" name="device_id" value="<?= h($p['device_id']) ?>">
        <input type="hidden" name="bloque" value="<?= (int)$p['revoque'] === 1 ? '0' : '1' ?>"><button class="<?= (int)$p['revoque'] === 1 ? 'sec' : 'danger' ?>"><?= (int)$p['revoque'] === 1 ? 'Débloquer' : 'Bloquer' ?></button></form></td></tr>
  <?php endforeach; ?></table>
</div>

<div class="carte"><h4 style="margin-top:0">Consommation par mois</h4>
  <table><tr><th>Mois</th><th>Scans réussis (comptés)</th><th>Échecs (non comptés)</th></tr>
  <?php foreach ($f['consommation'] as $m): ?><tr><td><?= h($m['mois']) ?></td><td><?= (int)$m['reussis'] ?></td><td><?= (int)$m['echoues'] ?></td></tr><?php endforeach; ?></table>
</div>
<div class="carte"><h4 style="margin-top:0">Derniers scans</h4><?php $lignes = $service->journal((int)$c['id'], false, 100); include __DIR__ . '/smartscan_core/admin_journal.php'; ?></div>

<?php elseif ($page === 'demandes'): ?>
<div class="carte"><h3 style="margin-top:0">Demandes d'offre en attente</h3>
  <table><tr><th>Date</th><th>Client</th><th>Offre</th><th>Poste</th><th></th></tr>
  <?php foreach ($service->demandes() as $d): ?>
    <tr><td><?= dateHeureFr($d['cree_le']) ?></td><td><a href="<?= lien(['page' => 'client', 'id' => $d['client_id']]) ?>"><?= h($d['client_nom']) ?></a></td>
      <td><?= h($d['forfait_code']) ?></td><td><code><?= h($d['device_id']) ?></code></td>
      <td><form method="post" class="inline"><?= csrf() ?><input type="hidden" name="action" value="demande"><input type="hidden" name="demande_id" value="<?= (int)$d['id'] ?>">
        <input type="hidden" name="statut" value="refusee"><button class="sec">Classer</button></form>
        <a href="<?= lien(['page' => 'client', 'id' => $d['client_id']]) ?>">Activer l'offre →</a></td></tr>
  <?php endforeach; ?></table>
</div>

<?php elseif ($page === 'journal' || $page === 'erreurs'): ?>
<div class="carte"><h3 style="margin-top:0"><?= $page === 'erreurs' ? 'Erreurs OCR / analyse' : 'Journal des scans' ?></h3>
  <?php $lignes = $service->journal(null, $page === 'erreurs', 300); include __DIR__ . '/smartscan_core/admin_journal.php'; ?></div>

<?php elseif ($page === 'forfaits'): ?>
<div class="carte"><h3 style="margin-top:0">Forfaits</h3>
  <p style="color:#8A889E">Le forfait <b>STANDARD</b> est celui de tout client sans offre payante. Les prix et quotas sont lus par l'application depuis l'API : rien à modifier dans Caisse DZ.</p>
  <table><tr><th>Code</th><th>Nom</th><th>Prix (DA)</th><th>Quota / mois</th><th>Durée (mois)</th><th>Actif</th><th></th></tr>
  <?php foreach (array_merge($service->forfaits(), [['code' => '', 'nom' => '', 'prix_da' => '', 'quota_mensuel' => '', 'duree_mois' => 12, 'actif' => 1]]) as $fo): ?>
    <tr><form method="post"><?= csrf() ?><input type="hidden" name="action" value="forfait">
      <td><input name="code" value="<?= h($fo['code']) ?>" <?= $fo['code'] !== '' ? 'readonly' : 'placeholder="NOUVEAU_CODE"' ?> required></td>
      <td><input name="nom" value="<?= h($fo['nom']) ?>" required></td><td><input type="number" name="prix_da" value="<?= h($fo['prix_da']) ?>" style="width:90px"></td>
      <td><input type="number" name="quota_mensuel" value="<?= h($fo['quota_mensuel']) ?>" style="width:90px" required></td>
      <td><input type="number" name="duree_mois" value="<?= h($fo['duree_mois']) ?>" style="width:70px"></td>
      <td><input type="checkbox" name="actif" value="1" <?= (int)$fo['actif'] === 1 ? 'checked' : '' ?>></td>
      <td><button><?= $fo['code'] === '' ? 'Ajouter' : 'Enregistrer' ?></button></td></form></tr>
  <?php endforeach; ?></table>
</div>
<?php endif; ?>
</main></body></html>
