import 'package:flutter/material.dart';

import '../cross/core.dart'
    if (dart.library.js_interop) '../cross/web.dart'
    if (dart.library.io) '../cross/native.dart';

class BarcodeScannerView extends StatefulWidget {
  const BarcodeScannerView({super.key});

  @override
  // ignore: no_logic_in_create_state
  State<BarcodeScannerView> createState() => barcodeScannerState();
}
