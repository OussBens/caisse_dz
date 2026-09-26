import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:win32/win32.dart';

// Constantes Win32 non exposées comme nommées par le package `win32`
// (valeurs stables documentées par l'API winspool).
const int _kPrinterEnumLocal = 0x00000002;
const int _kPrinterEnumConnections = 0x00000004;

class PrinterManager {
  static final PrinterManager _instance = PrinterManager._internal();
  factory PrinterManager() => _instance;
  PrinterManager._internal();

  bool _isConnected = false;
  String? _macAddress;

  bool get isConnected => _isConnected;

  /// Initialize and check Bluetooth
  Future<bool> initBluetooth() async {
    return await PrintBluetoothThermal.bluetoothEnabled;
  }

  /// Get paired Bluetooth printers
  Future<List<BluetoothInfo>> getBondedPrinters() async {
    return await PrintBluetoothThermal.pairedBluetooths;
  }

  /// Connect to printer
  Future<bool> connect(String macAddress) async {
    _macAddress = macAddress;
    _isConnected = await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
    return _isConnected;
  }

  /// Disconnect
  Future<void> disconnect() async {
    await PrintBluetoothThermal.disconnect;
    _isConnected = false;
  }

  /// Print receipt bytes
  Future<bool> print(List<int> bytes) async {
    if (!_isConnected) return false;
    return await PrintBluetoothThermal.writeBytes(bytes);
  }

  /// Check connection status
  Future<bool> checkConnection() async {
    _isConnected = await PrintBluetoothThermal.connectionStatus;
    return _isConnected;
  }

  // ==========================================================
  // IMPRIMANTE WINDOWS (USB / imprimante normale via spouleur)
  // ==========================================================

  /// Liste les imprimantes installées sur Windows (files d'attente locales
  /// et connexions réseau ajoutées au système), utilisée pour peupler le
  /// sélecteur d'imprimante des paramètres (types `usb` et `normale`).
  Future<List<String>> getWindowsPrinters() {
    return Future(() {
      final printers = <String>[];
      const flags = _kPrinterEnumLocal | _kPrinterEnumConnections;
      final pcbNeeded = calloc<Uint32>();
      final pcReturned = calloc<Uint32>();

      try {
        EnumPrinters(flags, nullptr, 4, nullptr, 0, pcbNeeded, pcReturned);
        final bufferSize = pcbNeeded.value;
        if (bufferSize == 0) return printers;

        final buffer = calloc<Uint8>(bufferSize);
        try {
          final ok = EnumPrinters(flags, nullptr, 4, buffer, bufferSize, pcbNeeded, pcReturned);
          if (ok == 0) return printers;

          final structSize = sizeOf<PRINTER_INFO_4>();
          final count = pcReturned.value;
          for (var i = 0; i < count; i++) {
            final info = Pointer<PRINTER_INFO_4>.fromAddress(buffer.address + i * structSize);
            final name = info.ref.pPrinterName.toDartString();
            if (name.isNotEmpty) printers.add(name);
          }
        } finally {
          calloc.free(buffer);
        }
      } finally {
        calloc.free(pcbNeeded);
        calloc.free(pcReturned);
      }

      return printers;
    });
  }

  /// Envoie des octets bruts (ESC/POS) à une file d'attente Windows en
  /// mode RAW (sans transformation par le pilote). Fonctionne pour une
  /// imprimante thermique USB installée comme file "Generic / Text Only"
  /// ou tout pilote acceptant les données brutes.
  Future<bool> printRawToWindowsPrinter(String printerName, List<int> bytes) {
    return Future(() {
      final printerNamePtr = printerName.toNativeUtf16();
      final phPrinter = calloc<IntPtr>();

      try {
        final opened = OpenPrinter(printerNamePtr, phPrinter, nullptr);
        if (opened == 0) return false;
        final hPrinter = phPrinter.value;

        final docInfo = calloc<DOC_INFO_1>();
        final docNamePtr = 'Ticket CaisseDZ'.toNativeUtf16();
        final dataTypePtr = 'RAW'.toNativeUtf16();
        docInfo.ref
          ..pDocName = docNamePtr
          ..pOutputFile = nullptr
          ..pDatatype = dataTypePtr;

        try {
          final jobId = StartDocPrinter(hPrinter, 1, docInfo);
          if (jobId == 0) return false;

          try {
            if (StartPagePrinter(hPrinter) == 0) return false;

            final dataPtr = calloc<Uint8>(bytes.length);
            final pcWritten = calloc<Uint32>();
            try {
              dataPtr.asTypedList(bytes.length).setAll(0, bytes);
              final written = WritePrinter(hPrinter, dataPtr.cast(), bytes.length, pcWritten);
              EndPagePrinter(hPrinter);
              return written != 0;
            } finally {
              calloc.free(dataPtr);
              calloc.free(pcWritten);
            }
          } finally {
            EndDocPrinter(hPrinter);
          }
        } finally {
          calloc.free(docNamePtr);
          calloc.free(dataTypePtr);
          calloc.free(docInfo);
        }
      } finally {
        if (phPrinter.value != 0) ClosePrinter(phPrinter.value);
        calloc.free(phPrinter);
        calloc.free(printerNamePtr);
      }
    });
  }

  // ==========================================================
  // IMPRIMANTE RÉSEAU (ESC/POS via socket TCP, port 9100 standard)
  // ==========================================================

  Future<bool> printRawToNetworkPrinter(String ip, int port, List<int> bytes) async {
    Socket? socket;
    try {
      socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 5));
      socket.add(bytes);
      await socket.flush();
      return true;
    } catch (e) {
      return false;
    } finally {
      socket?.destroy();
    }
  }

  // ==========================================================
  // CODE-BARRES (ESC/POS natif, pour les impressions en octets bruts)
  // ==========================================================

  /// Construit la séquence ESC/POS (GS h / GS w / GS H / GS k) imprimant un
  /// code-barres CODE128 nativement sur l'imprimante thermique, plutôt qu'une
  /// image : plus net et fiable à scanner que du texte/ASCII-art. Le HRI
  /// (texte lisible sous les barres) est désactivé (GS H 0) car le code est
  /// déjà réimprimé en texte par le générateur de reçu juste en dessous.
  List<int> buildBarcodeBytes(String data, {int height = 80, int moduleWidth = 2}) {
    // '{' + 'B' sélectionne le jeu de caractères CODE128 B (ASCII imprimable),
    // adapté aux codes alphanumériques générés par CodeGenerator.
    final payload = <int>[0x7B, 0x42, ...data.codeUnits];
    return <int>[
      0x1D, 0x68, height, // GS h n -> hauteur du code-barres (points)
      0x1D, 0x77, moduleWidth, // GS w n -> largeur d'un module
      0x1D, 0x48, 0x00, // GS H n -> position du texte HRI (0 = aucun)
      0x1D, 0x6B, 0x49, payload.length, ...payload, // GS k 73 n data -> CODE128
    ];
  }
}
