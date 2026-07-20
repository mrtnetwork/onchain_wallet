import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:xrpl_dart/xrpl_dart.dart';

class RippleConst {
  static const int maxIouPrecision = 18;
  static const String aboutRippleTrustSet = "https://xrpl.org/trustset.html";
  static const String aboutRipplePayment = "https://xrpl.org/payment.html";
  static const String aboutRippleCurrency =
      "https://xrpl.org/currency-formats.html";
  static const String aboutRippleAccountSet =
      "https://xrpl.org/accountset.html";
  static const String aboutNftoken = "https://xrpl.org/nftokenmint.html";
  static const String aboutNftokenCreateOffer =
      "https://xrpl.org/nftokencreateoffer.html";
  static const String aboutNftokenBurn = "https://xrpl.org/nftokenburn.html";
  static const String abountNftokenCancelOffer =
      "https://xrpl.org/nftokencanceloffer.html";
  static const String aboutNftAcceptOffer =
      "https://xrpl.org/nftokenacceptoffer.html";
  static const String aboutScrowCreate = "https://xrpl.org/escrowcreate.html";
  static const String aboutScrowfinish = "https://xrpl.org/escrowfinish.html";
  static const String aboutScrowCancel = "https://xrpl.org/escrowcancel.html";
  static const String aboutRegularKey = "https://xrpl.org/escrowcancel.html";
  static const String aboutSignerList = "https://xrpl.org/signerlistset.html";
  static const int maxDomainLength = 512;
  static const int rippleTranactionHashLength = 64;
  static const int maxEmailHashLength = 32;
  static const int maxWalletLocatorLength = 64;
  static const int maxRippleTag = BinaryOps.mask32;
  static BigRational get max32UnsignedRational =>
      BigRational.from(maxRippleTag);
  static BigRational get maxNftTokenTransferRate =>
      BigRational.from(NFTTokenConst.maxTransferFee);

  static BigRational get rippleAccountTransferRateMax =>
      BigRational.from(AccountSetConst.maxTransferRate);
  static BigRational get rippleAccountTransferRateMin =>
      BigRational.from(AccountSetConst.minTransferRate);
  static BigRational get rippleAccountSetTickSizeMax =>
      BigRational.from(AccountSetConst.maxTickSize);
  static BigRational get rippleAccountSetTickSizeMin =>
      BigRational.from(AccountSetConst.minTickSize);

  static RegExp get currencyCodeRegex =>
      RegExp(r'^[A-Za-z0-9?@#$%^&*<>(){}[\]]{3}$');
}
