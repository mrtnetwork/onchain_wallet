import 'package:on_chain_wallet/app/models/models/asset.dart';
import 'package:on_chain_wallet/app/models/models/image.dart';

class APPConst {
  static const APPAssetUri assetErc20Abi = APPAssetUri(url: "assets/solidity/erc20.json");
  static const APPAssetUri assetErc721Abi =
      APPAssetUri(url: "assets/solidity/erc721.json");
  static const APPAssetUri assetErc1155Abi =
      APPAssetUri(url: "assets/solidity/erc1155.json");
  static const APPAssetUri cosmosChainRegistery =
      APPAssetUri(url: "assets/chains.bin", package: 'cosmos_sdk');
  static const APPAssetUri assetWebviewScript =
      APPAssetUri(url: "assets/webview/script.js");
  static const String logoPath = "/assets/image/wallet.png";
  static const APPAssetUri assetWebviewPageScript =
      APPAssetUri(url: "assets/webview/script_page.js");
  static const APPAssetUri assetsTronWeb = APPAssetUri(url: "assets/webview/tron_web.js");

  static const APPImage logo = APPImage.local("assets/image/wallet.png");
  static const APPImage wc = APPImage.local("assets/image/wc.png");
  static const APPImage telegramLogo = APPImage.local("assets/image/t.png");
  static const APPImage githubLogo = APPImage.local("assets/image/g.png");
  static const APPImage ltc = APPImage.local("assets/image/ltc.png");
  static const APPImage bch = APPImage.local("assets/image/bch.png");
  static const APPImage btc = APPImage.local("assets/image/btc.png");
  static const APPImage doge = APPImage.local("assets/image/doge.png");
  static const APPImage pepecoin = APPImage.local("assets/image/pepecoin.png");
  static const APPImage bsv = APPImage.local("assets/image/bsv.png");
  static const APPImage dash = APPImage.local("assets/image/dash.png");
  static const APPImage xrp = APPImage.local("assets/image/xrp.png");
  static const APPImage eth = APPImage.local("assets/image/eth.png");
  static const APPImage matic = APPImage.local("assets/image/matic.png");
  static const APPImage bnb = APPImage.local("assets/image/bnb.png");
  static const APPImage trx = APPImage.local("assets/image/trx.png");
  static const APPImage sol = APPImage.local("assets/image/sol.png");
  static const APPImage ada = APPImage.local("assets/image/ada.png");
  static const APPImage atom = APPImage.local("assets/image/atom.png");
  static const APPImage cacao = APPImage.local("assets/image/cacao.png");
  static const APPImage avalance = APPImage.local("assets/image/avax.png");
  static const APPImage arbitrum = APPImage.local("assets/image/arb.png");
  static const APPImage base = APPImage.local("assets/image/base.png");
  static const APPImage optimistic = APPImage.local("assets/image/op.png");

  static const APPImage thor = APPImage.local("assets/image/thor.png");
  static const APPImage kujira = APPImage.local("assets/image/kujira.png");
  static const APPImage osmo = APPImage.local("assets/image/osmo.png");
  static const APPImage gram = APPImage.local("assets/image/gram.png");
  static const APPImage polkadot = APPImage.local("assets/image/polkadot.png");
  static const APPImage substrate = APPImage.local("assets/image/substrate.png");
  static const APPImage moonbeam = APPImage.local("assets/image/moonbeam.png");
  static const APPImage moonriver = APPImage.local("assets/image/moonriver.png");
  static const APPImage astar = APPImage.local("assets/image/astar.png");
  static const APPImage hydration = APPImage.local("assets/image/hydration.png");
  static const APPImage bifrost = APPImage.local("assets/image/bifrost.png");
  static const APPImage cf = APPImage.local("assets/image/cf.png");
  static const APPImage centrifuge = APPImage.local("assets/image/cfg.png");
  static const APPImage acala = APPImage.local("assets/image/acala.png");

  static const APPImage kusama = APPImage.local("assets/image/ksm.png");
  static const APPImage stellar = APPImage.local("assets/image/xlm.png");
  static const APPImage monero = APPImage.local("assets/image/monero.png");
  static const APPImage aptos = APPImage.local("assets/image/aptos.png");
  static const APPImage sui = APPImage.local("assets/image/sui.png");
  static const APPImage tor = APPImage.local("assets/image/tor.png");
  static const APPImage zcash = APPImage.local("assets/image/zcash.png");
  static const String name = "OnChain";
  static const String applicationId = "com.mrtnetwork.on_chain_wallet";
  static const String authenticateReason = "Authenticate to proceed";

  static const Duration animationDuraion = Duration(milliseconds: 400);
  static const Duration milliseconds100 = Duration(milliseconds: 100);
  static const Duration milliseconds200 = Duration(milliseconds: 200);
  static const Duration oneSecoundDuration = Duration(seconds: 1);
  static const Duration twoSecoundDuration = Duration(seconds: 2);
  static const Duration tenSecoundDuration = Duration(seconds: 10);
  static const Duration futureTimeout = Duration(seconds: 10);

  static const double double80 = 80;
  static const double double40 = 40;
  static const double double20 = 20;
  static const double iconSize = 24;
  // static const double largeIconSize = iconSize * 2;
  static const double smallIconSize = 12;
  static const double largeIconSize = 80;
  static const double tooltipConstrainedWidth = 300;
  static const double dialogWidth = 650;
  static const double maxViewWidth = 650;
  static const double maxDialogHeight = 600;
  static const double maxTextFieldWidth = 400;
  static const double numberFieldsWidth = 450;
  static const double qrCodeWidth = 300;
  static const int maxNameLength = 20;
  static final RegExp accountNameRegExp = RegExp(r'^[^\n]{0,20}$');
  static final RegExp keyNameRegex = RegExp(r'^[^\n]{0,20}$');
  static final RegExp hex32Bytes = RegExp(r'^(0x)?[0-9a-fA-F]{64}$');
  static final hrpRegex = RegExp(r'^[a-z][a-z0-9]*$');
  static const double circleRadius25 = 25;
  static const double circleRadius12 = 12.5;
  static const double elevation = 2;
  static const double desktopAppWidth = 1200;
  static const double desktopAppHeight = 768;
  static const double naviationRailWidth = 80;
  static const String exampleBase58 = "sEd7FSsSXz9CGy....";
  static const String exampleBase32 = "GD2YLIOLNVQXNA....";
  static const String exampleHex = "0xa3f1df47";

  static const String exampleAuthenticatedHeader = "Authorization";
  static const String exampleAuthenticatedQuery = "api_key";
  static const String exampleDouble = "0.0025";

  static const String exampleAuthenticatedHeaderValue =
      "Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==";
  static const String exampleAuthenticatedQueryValue = "api_key";

  static const String exampleAuthenticatedDigestAuthRealm = "monero-rpc";
  static const String exampleChannelId = "channel-1441";
  static const int defaultDecimalPlaces = 8;

  static const int maximumHeaderValue = 400;

  static const double largeCircleRadius = 60;
  static const double largeCircleRadius120 = 120;

  static const double disabledOpacity = 0.3;
  static const double defaultOpacity = 1;
}
