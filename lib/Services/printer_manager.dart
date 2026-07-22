import 'dart:typed_data';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

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
}