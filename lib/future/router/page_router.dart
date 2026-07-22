import 'package:flutter/material.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/wallet/swap/pages/pages/review_transaction.dart';
import 'package:on_chain_wallet/future/wallet/transaction/pages/transaction_state_builder.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network.dart';

class PageRouter {
  ///TransactionStateBuilder
  static const String transaction = "/transaction";

  static const String manageTokens = "/account/tokens";

  /// bitcoin casah
  static const String bitcoinCashTransaction = "/bitcoincash/transaction";

  static const String bitcoinTransaction = "/bitcoin/transaction";
  static const String rippleTransfer = "/ripple/transfer";
  // static const String rippleAddToken = "/ripple/import_token";
  static const String rippleAddNfts = "/ripple/import_nfts";
  static const String rippleTransaction = "/ripple/transaction";
  static const String rippleMultisigAddress = "/ripple/setup_multisig_address";
  static const String rippleSettingPage = "setting/ripple";
  static const String rippleKeyConversion = "setting/ripple/key_conversion";
  static const String ethereumTransaction = "/ethereum/transfer";

  static const String stellarTransaction = "/stellar/transfer";
  static const String stellarSettingPage = "setting/stellar";
  static const String stellarKeyConversion = "setting/stellar/key_conversion";
  static const String contacts = "setting/contacts";
  // tron
  static const String tronTransfer = "/tron/transfer";
  static const String tronTransaction = "/tron/transaction";
  static const String tronMultiSigAddress = "/tron/setup_multisig_address";
  // solana transfer
  static const String solanaTransfer = "/solana/transfer";
  static const String solanaTransaction = "/solana/transaction";

  static const String solanaSettingPage = "setting/solana";
  static const String solanaKeyConversion = "setting/solana/key_conversion";

  // ton transfer
  static const String tonTransfer = "/ton/transfer";

  // substrate transfer
  static const String substrateTransfer = "/substrate/transfer";
  static const String substrateTransaction = "/substrate/transaction";
  static const String substrateMultisigTransaction =
      "/substrate/multi_signature/transaction";
  static const String importSubstrateNetwork = "/substrate/networks/import";
  static const String substrateMultisigAddress = "/substrate/setup_multisig_address";

  /// cardano
  static const String cardanoTransaction = "/cardano/transaction";
  static const String cardanoMultisigAddress = "/cardano/setup_multisig_address";
  static const String cardanoMultisigAccountInfo = "/cardano/multisig_account_info";

  static const String cosmosTransfer = "/cosmos/transfer";
  static const String cosmosTransaction = "/cosmos/transaction";

  /// CosmosTransactionFieldsView

  static const String importCosmosNetwork = "/cosmos/networks/import";
  static const String setupGenericAddress = "/networks/setup_address";

  /// aotos
  static const String aptosTransfer = "/aptos/transfer";
  static const String aptosMultisigAddress = "/aptos/setup_multisig_address";
  static const String aptosMultisigAccountInfo = "/aptos/multisig_account_info";
  static const String aptosSettingPage = "setting/aptos";
  static const String aptosKeyConversion = "setting/aptos/key_conversion";

  /// sui
  static const String suiTransfer = "/sui/transfer";
  static const String suiMultisigAddress = "/sui/setup_multisig_address";
  static const String suiMultisigAccountInfo = "/sui/multisig_account_info";
  static const String suiSettingPage = "setting/sui";
  static const String suiKeyConversion = "setting/sui/key_conversion";
  static const String setupBitcoinMultsig = "/bitcoin/setup_multisig_address";

  static const String bitcoinMultisigAccountInfo = "/bitcoin/multisig_account_info";
  static const String bitcoinCashMultisigAccountInfo =
      "/bitcoinCash/multisig_account_info";
  static const String createWallet = "/create_wallet";
  static const String createSubWallet = "/create_sub_wallet";
  static const String setup = "/setup";
  static const String home = "/";

  static const String setting = "/setting";
  static const String updateSetting = "/setting/update";

  /// acccount
  static const String removeAccount = "/account/remove";
  static const String importAccount = "/account/import";
  static const String showPublicKey = "account/public_key";

  /// security
  static const String changePassword = "/security/password";
  static const String eraswWallet = "/security/erase";
  static const String backupWallet = "/security/backup";
  static const String exportPrivateKey = "/security/privateKey";
  static const String manageImportedKey = "/security/manageKeys";
  static const String exportSeed = "/security/seed";

  /// importnetworks
  static const String importEthereumNetwork = "/networks/import";
  // static const String editEvmNetwork = "/networks/edit";
  static const String updateEthereumProvider = "/networks/ethereum/providers";

  static const String updateElectrumProviders = "/networks/bitcoin/providers";
  static const String updateSolanaProviders = "/networks/solana/providers";
  static const String updateSubstrateProviders = "/networks/substrate/providers";
  static const String updateRippleProviders = "/networks/ripple/providers";
  static const String updateCardanoProviders = "/networks/cardano/providers";
  static const String updateTonProviders = "/networks/ton/providers";
  static const String updateCosmosProviders = "/networks/cosmos/providers";
  static const String updateMoneroProviders = "/networks/monero/providers";
  static const String updateStellarProviders = "/networks/stellar/providers";
  static const String updateTronProviders = "/networks/tron/providers";
  static const String updateSuiProviders = "/networks/sui/providers";
  static const String updateAptosProviders = "/networks/aptos/providers";
  static const String updateZcashProviders = "/networks/zcash/providers";
  static const String updateNetwork = "/networks/update";

  /// UpdateStellarProvider
  static const String importERC20Token = "ethereum/import_token";
  static const String importTronToken = "tron/import_trc10_token";

  static const String tonSettings = "setting/ton";
  static const String tonMnemonic = "setting/ton/mnemonic";
  static const String importJettons = "ton/import_jettons";

  static const String barcodeScanner = "barcode_scanner";

  static const String moneroSettings = "setting/monero";
  static const String moneroSyncOptions = "setting/monero/sync_options";
  static const String moneroGenerateProof = "setting/monero/generate_transaction_proof";
  static const String moneroVerifyProof = "setting/monero/verify_proof";
  static const String moneroImportUtxos = "setting/monero/import_utxos";
  static const String moneroWalletRpc = "setting/monero/wallet_rpc";
  static const String moneroAccountSync = "setting/monero/sync";
  static const String moneroMnemonic = "setting/monero/mnemonic";
  static const String moneroTransfer = "/monero/transfer";
  static const String moneroUpdateSyncNetwork =
      "settings/monero/update_synchronization_network";
  static const String moneroCreateSynchronizationRequest =
      "settings/monero/create_synchronization_request";

  /// WalletConnectView
  /// web3
  static const String web3Request = "web3/";
  static const String walletConnect = "web3/wallet_connect";
  static const String manageDaps = "web3/manage_dapps";
  static const String walletConnectPairing = "web3/wallet_connect/pairing";
  static const String web3Ethereum = "web3/ethereum";
  static const String web3Tron = "web3/tron";
  static const String web3Solana = "web3/solana";
  static const String web3Ton = "web3/ton";
  static const String web3Stellar = "web3/stellar";
  static const String web3Ripple = "web3/ripple";
  static const String web3Substrate = "web3/substrate";
  static const String web3Aptos = "web3/aptos";
  static const String web3Sui = "web3/sui";
  static const String web3Cosmos = "web3/cosmos";
  static const String web3Bitcoin = "web3/bitcoin";
  static const String web3Permission_ = "web3/permission";
  static const String web3Global = "web3/connect";
  static const String web3WalletConnect = "web3/wallet_connect";

  static const String webview = "web/";
  static const String webviewMenu = "web/menu";
  static const String webviewRemoveHistory = "web/history";
  static const String webViewSearch = "webview/search";
  static const String settingMenu = "setting/menu";

  static const String swapTransaction = "swap/transaction";

  static const String publicKeyDeration = "account/public_key_derivation";

  static const String zcashAccountSync = "setting/zcash/sync";
  // static const String zcashCreateSyncRequest =
  //     "settings/zcash/create_synchronization_request";
  static const String zcashUpdateSyncNetwork =
      "settings/zcash/update_synchronization_network";

  /// zcash
  static Widget _page(String? name) {
    switch (name) {
      case cardanoMultisigAccountInfo:
        return const CardanoMultisigAccountInfoView();
      case cardanoMultisigAddress:
        return const SetupCardanoMultisigAddress();
      case web3Request:
        return const Web3StatePageBuilder();
      case manageTokens:
        return const ManageAccountTokenView();
      case transaction:
        return const TransactionStateBuilder();
      case substrateMultisigAddress:
        return const SetupSubstrateMultisigAddress();
      case suiMultisigAddress:
        return const SetupSuiMultisigAddress();
      case setupBitcoinMultsig:
        return const SetupBitcoinMultiSigAddressView();
      case exportSeed:
        return const ExportSeedView();
      case changePassword:
        return const ChangeWalletPasswordView();
      case eraswWallet:
        return const EraseWalletView();
      case exportPrivateKey:
        return const AccountPrivteKeyView();
      case removeAccount:
        return const DeleteAccountView();
      case importAccount:
        return const ImportAccountView();
      case setting:
        return const AppSettingView();
      case updateSetting:
        return const UpdateWalletSettingView();
      case backupWallet:
        return const BackupWalletView();
      case manageImportedKey:
        return const ManageImportedKeysView();
      case setupGenericAddress:
        return const NetworkGenericAddressDerivationView();
      case rippleAddNfts:
        return const MonitorRippleNFTsView();
      case rippleMultisigAddress:
        return const SetupRippleMutlisigAddressView();
      case importERC20Token:
        return const ImportERC20TokenView();
      case importTronToken:
        return const MonitorTronTokenView();
      case tronMultiSigAddress:
        return const SetupTronMultiSigAddressView();
      case importEthereumNetwork:
        return const ImportEthereumNetwork();
      case updateElectrumProviders:
        return const ImportElectrumProviderView();
      case updateCardanoProviders:
        return const UpdateCardanoProvider();
      case updateRippleProviders:
        return const UpdateRippleProviderView();
      case importCosmosNetwork:
        return const CosmosImportNetworkView();
      case updateSolanaProviders:
        return const UpdateSolanaProvider();
      case updateSuiProviders:
        return const UpdateSuiProvider();
      case updateAptosProviders:
        return const UpdateAptosProvider();
      case updateCosmosProviders:
        return const UpdateCosmosProvider();
      case updateSubstrateProviders:
        return const UpdateSubstrateProvider();
      case updateMoneroProviders:
        return const UpdateMoneroProvider();
      case updateStellarProviders:
        return const UpdateStellarProvider();
      case updateZcashProviders:
        return const UpdateZcashProvider();
      case tonSettings:
        return const TonSettingsView();
      case tonMnemonic:
        return const GenerateTonMnemonicView();
      case contacts:
        return const ManageAccountContactsView();
      case rippleSettingPage:
        return const RippleFeaturePageView();
      case stellarSettingPage:
        return const StellarFeaturePageView();
      case solanaSettingPage:
        return const SolanaFeaturePageView();
      case suiSettingPage:
        return const SuiFeaturePageView();
      case aptosSettingPage:
        return const AptosFeaturePageView();
      case rippleKeyConversion:
        return const RippleKeyConversionView();
      case stellarKeyConversion:
        return const StellarKeyConversionView();
      case solanaKeyConversion:
        return const SolanaKeyConversionView();
      case suiKeyConversion:
        return const SuiKeyConversionView();
      case aptosKeyConversion:
        return const AptosKeyConversionView();
      case showPublicKey:
        return const AccountPublicKeyView();
      case createWallet:
        return const WalletSetupPageWidget();
      case createSubWallet:
        return const SubWalletSetupPageView();
      case barcodeScanner:
        return const BarcodeScannerView();
      case updateEthereumProvider:
        return const UpdateEthereumProvider();
      case updateTonProviders:
        return const UpdateTonProvider();
      case walletConnect:
        return WalletConnectView();
      case manageDaps:
        return ManageWeb3DapssView();
      case updateTronProviders:
        return const UpdateTronProvider();
      case moneroSettings:
        return const MoneroSettingsView();
      // case moneroSyncOptions:
      //   return const MoneroSyncOptionsView();
      case moneroGenerateProof:
        return const MoneroGenerateTxProofView();
      case moneroVerifyProof:
        return const MoneroVerifyTxProofView();
      case moneroImportUtxos:
        return const MoneroImportUtxos();
      case moneroWalletRpc:
        return const MoneroSyncWithWalletRpcView();
      case moneroAccountSync:
        return const MoneroAccountSyncView();
      case moneroMnemonic:
        return const GenerateMoneroMnemonicView();
      case moneroUpdateSyncNetwork:
        return const MoneroUpdateSyncNetwork();
      case moneroCreateSynchronizationRequest:
        return const MoneroCreateSynchronizationRequest();
      case importSubstrateNetwork:
        return const SubstrateImportChainView();
      case updateNetwork:
        return const UpdateNetworkView();
      case substrateMultisigTransaction:
        return const SubstrateMultisigAddressTxesView();
      case bitcoinMultisigAccountInfo:
      case bitcoinCashMultisigAccountInfo:
        return const BitcoinMultisigAccountInfoView();
      case suiMultisigAccountInfo:
        return const SuiMultisigAccountInfoView();
      case aptosMultisigAccountInfo:
        return const AptosMultisigAccountInfoView();
      case aptosMultisigAddress:
        return const SetupAptosMultisigAddress();
      case web3Global:
        return const GlobalWeb3FieldsView();
      case zcashAccountSync:
        return const ZcashAccountSyncView();
      case swapTransaction:
        return const TransactionReviewView();
      case zcashUpdateSyncNetwork:
        return const ZcashUpdateSyncNetwork();
      default:
        return const WalletScreen();
    }
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return MaterialPageView(child: _page(settings.name));
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
        settings: settings,
        reverseTransitionDuration: const Duration(milliseconds: 300),
        allowSnapshotting: false,
        fullscreenDialog: false,
        opaque: false);
  }

  static String updateProvider(NetworkType network) {
    switch (network) {
      case NetworkType.ethereum:
        return updateEthereumProvider;
      case NetworkType.zcash:
        return updateZcashProviders;
      case NetworkType.solana:
        return updateSolanaProviders;
      case NetworkType.ton:
        return updateTonProviders;
      case NetworkType.tron:
        return updateTronProviders;
      case NetworkType.xrpl:
        return updateRippleProviders;
      case NetworkType.cardano:
        return updateCardanoProviders;
      case NetworkType.cosmos:
        return updateCosmosProviders;
      case NetworkType.monero:
        return updateMoneroProviders;
      case NetworkType.stellar:
        return updateStellarProviders;
      case NetworkType.substrate:
        return updateSubstrateProviders;
      case NetworkType.bitcoinAndForked:
      case NetworkType.bitcoinCash:
        return updateElectrumProviders;
      case NetworkType.sui:
        return updateSuiProviders;
      case NetworkType.aptos:
        return updateAptosProviders;
    }
  }

  static String? web3Page(WalletNetwork network) {
    return web3Request;
  }

  static String? importNetwork(NetworkType type) {
    switch (type) {
      case NetworkType.ethereum:
        return importEthereumNetwork;
      case NetworkType.cosmos:
        return importCosmosNetwork;
      case NetworkType.substrate:
        return importSubstrateNetwork;
      default:
        return null;
    }
  }

  static String? multisigAccountInfo(NetworkType type) {
    switch (type) {
      case NetworkType.cardano:
        return cardanoMultisigAccountInfo;
      case NetworkType.bitcoinAndForked:
        return bitcoinMultisigAccountInfo;
      case NetworkType.bitcoinCash:
        return bitcoinCashMultisigAccountInfo;
      case NetworkType.sui:
        return suiMultisigAccountInfo;
      case NetworkType.aptos:
        return aptosMultisigAccountInfo;
      default:
        return null;
    }
  }

  static String? multisigAddressDerivation(NetworkType type) {
    switch (type) {
      case NetworkType.cardano:
        return cardanoMultisigAddress;
      case NetworkType.bitcoinAndForked:
      case NetworkType.bitcoinCash:
        return setupBitcoinMultsig;
      case NetworkType.sui:
        return suiMultisigAddress;
      case NetworkType.substrate:
        return substrateMultisigAddress;
      case NetworkType.aptos:
        return aptosMultisigAddress;
      case NetworkType.xrpl:
        return rippleMultisigAddress;
      case NetworkType.tron:
        return tronMultiSigAddress;
      default:
        return null;
    }
  }

  static String? networkSettings(WalletNetwork network) {
    switch (network.type) {
      case NetworkType.ton:
        return tonSettings;
      case NetworkType.monero:
        return moneroSettings;
      case NetworkType.xrpl:
        return rippleSettingPage;
      case NetworkType.stellar:
        return stellarSettingPage;
      case NetworkType.solana:
        return solanaSettingPage;
      case NetworkType.sui:
        return suiSettingPage;
      case NetworkType.aptos:
        return aptosSettingPage;
      default:
        return null;
    }
  }
}
