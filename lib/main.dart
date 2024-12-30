import 'package:flutter/material.dart';
import 'package:usb_serial/usb_serial.dart';

void main() {
  runApp(const PiezoApp());
}

class PiezoApp extends StatelessWidget {
  const PiezoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Piezo Power',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const PiezoScreen(),
    );
  }
}

class PiezoScreen extends StatefulWidget {
  const PiezoScreen({Key? key}) : super(key: key);

  @override
  PiezoScreenState createState() => PiezoScreenState();
}

class PiezoScreenState extends State<PiezoScreen> {
  UsbPort? _port;
  int pressCount = 0;
  double voltage = 0.0;
  bool isConnecting = true;
  bool isConnected = false;
  String? _status = 'Searching for USB devices...';

  @override
  void initState() {
    super.initState();
    connectToUsb();
  }

  @override
  void dispose() {
    disconnectUsb();
    super.dispose();
  }

  Future<void> connectToUsb() async {
    try {
      setState(() {
        _status = 'Scanning for USB devices...';
      });

      List<UsbDevice> devices = await UsbSerial.listDevices();

      if (devices.isEmpty) {
        setState(() {
          _status = 'No USB devices found.';
          isConnecting = false;
          isConnected = false;
        });
        return;
      }

      _port = await devices.first.create();

      if (!await _port!.open()) {
        setState(() {
          _status = 'Failed to open USB port.';
          isConnecting = false;
          isConnected = false;
        });
        return;
      }

      _port!.setDTR(true);
      _port!.setRTS(true);

      _port!.inputStream?.listen((data) {
        final receivedData = String.fromCharCodes(data).trim();
        parseAndUpdateData(receivedData);
      });

      setState(() {
        _status = 'Connected to USB device.';
        isConnecting = false;
        isConnected = true;
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        isConnecting = false;
        isConnected = false;
      });
    }
  }

  void disconnectUsb() {
    _port?.close();
    setState(() {
      isConnected = false;
      _status = 'Disconnected.';
    });
  }

  void parseAndUpdateData(String data) {
    print('Received data: $data');
    final pressMatch = RegExp(r'pressCount:(\d+)').firstMatch(data);
    final voltageMatch = RegExp(r'voltage:([\d.]+)').firstMatch(data);

    if (pressMatch != null && voltageMatch != null) {
      setState(() {
        pressCount = int.parse(pressMatch.group(1)!);
        voltage = double.parse(voltageMatch.group(1)!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Piezo Power'),
      ),
      body: isConnecting
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : isConnected
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Center(
                      child: Text(
                        'WELCOME TO PIEZO POWER',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Press Count: $pressCount',
                      style: const TextStyle(fontSize: 20),
                    ),
                    Text(
                      'Voltage: ${(voltage * 1000).toStringAsFixed(2)} mV',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ],
                )
              : Center(
                  child: Text(
                    _status ?? 'Disconnected.',
                    style: const TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ),
    );
  }
}
