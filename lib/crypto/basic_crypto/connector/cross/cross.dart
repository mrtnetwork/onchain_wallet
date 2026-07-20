import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/core/worker.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/core/transporter.dart';

IResult<CryptoWorkerController> getCryptoWorker(
        AppWorkerApi workerApi, CryptoTransporterMain mainConnector) =>
    throw UnsupportedError('Cannot create a instance without dart:js or dart:io.');
