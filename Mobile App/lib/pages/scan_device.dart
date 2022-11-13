import 'package:flutter/material.dart';
import 'package:keys_tracker_app/constants.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanDevice extends StatelessWidget {
  static const String ROUTE = "scan_device";
  static RegExp MAC_REGX =
      RegExp(r"^([0-9a-fA-F][0-9a-fA-F]:){5}([0-9a-fA-F][0-9a-fA-F])$");

  const ScanDevice({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Scan Tracker",
          style: TextStyle(color: kTextPrimary),
        ),
        foregroundColor: kPrimaryColor,
      ),
      body: MobileScanner(
        allowDuplicates: false,
        onDetect: (barcode, args) {
          if (barcode.rawValue != null) {
            final String code = barcode.rawValue!;
            if (MAC_REGX.hasMatch(code)) {
              Navigator.pop(context, code);
            }
          }
        },
      ),
    );
  }
}
