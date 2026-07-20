import 'dart:js_interop';
import '../../../js_wallet.dart';
import 'ada.dart';
import 'aptos.dart';
import 'cosmos.dart';
import 'monero.dart';
import 'substrate.dart';
import 'sui.dart';
import 'zcash.dart';

class JSWalletStandardConst {
  static const String defaultVersion = '1.0.0';
  static const String standardConnectName = 'connect';
}

@JS()
extension type JSWalletStandardFeature(JSAny _) implements JSAny {
  @JS("standard:connect")
  external set connect(SolanaWalletAdapterStandardConnectFeature _);
  @JS("standard:events")
  external set events(JSWalletStandardEventsFeature _);

  /// solana
  @JS("solana:signAndSendTransaction")
  external set solanaSignAndSendTransaction(
      SolanaWalletAdapterSolanaSignAndSendTransactionFeature _);
  @JS("solana:signTransaction")
  external set solanaSignTransaction(SolanaWalletAdapterSolanaSignTransactionFeature _);
  @JS("solana:signAllTransactions")
  external set solanaSignAllTransactions(
      SolanaWalletAdapterSolanaSignAllTransactionsFeature _);
  @JS("solana:signMessage")
  external set solanaSignMessage(SolanaWalletAdapterSolanaSignMessageFeature _);
  @JS("solana:signAndSendAllTransactions")
  external set solanaSignAndSendAllTransactions(
      SolanaWalletAdapterSolanaSignAndSendAllTransactionsFeature _);
  @JS("solana:connect")
  external set solanaConnect(JSSolanaWalletStandardConnectFeature _);
  @JS("solana:events")
  external set solanaEvents(JSWalletStandardEventsFeature _);
  @JS("solana:signIn")
  external set solanaSignIn(SolanaWalletAdapterSolanaSignInFeature _);
  @JS("solana:disconnect")
  external set solanaDisconnect(JSWalletStandardDisconnectFeature _);

  /// ton
  @JS("ton:signAndSendTransaction")
  external set tonSignAndSendTransaction(
      TonWalletAdapterTonSignAndSendTransactionFeature _);
  @JS("ton:signTransaction")
  external set tonSignTransaction(TonWalletAdapterTonSignTransactionFeature _);
  @JS("ton:signMessage")
  external set tonSignMessage(TonWalletAdapterTonSignMessageFeature _);
  @JS("ton:connect")
  external set tonConnect(JSTonWalletStandardConnectFeature _);
  @JS("ton:events")
  external set tonEvents(JSWalletStandardEventsFeature _);
  @JS("ton:disconnect")
  external set tonDisconnect(JSWalletStandardDisconnectFeature _);

  /// stellar
  @JS("stellar:signAndSendTransaction")
  external set stellarSignAndSendTransaction(
      StellarWalletAdapterStellarSignAndSendTransactionFeature _);

  @JS("stellar:signTransaction")
  external set stellarSignTransaction(
      StellarWalletAdapterStellarSignTransactionFeature _);
  @JS("stellar:signMessage")
  external set stellarSignMessage(StellarWalletAdapterStellarSignMessageFeature _);

  @JS("stellar:events")
  external set stellarEvents(JSWalletStandardEventsFeature _);
  @JS("stellar:disconnect")
  external set stellarDisconnect(JSWalletStandardDisconnectFeature _);
  @JS("stellar:connect")
  external set stellarConnect(JSStellarWalletStandardConnectFeature _);

  /// cardano
  @JS("cardano:disconnect")
  external set cardanoDisconnect(JSWalletStandardDisconnectFeature _);
  @JS("cardano:connect")
  external set cardanoConnect(JSStellarWalletStandardConnectFeature _);
  @JS("cardano:events")
  external set cardanoEvents(JSWalletStandardEventsFeature _);
  @JS("cardano:getNetworkId")
  external set cardanoGetNetworkId(JSWalletStandardADAGetNetworkIdFeature _);
  @JS("cardano:getBalance")
  external set cardanoGetBalance(JSWalletStandardADAGetBalanceFeature _);
  @JS("cardano:getUtxos")
  external set cardanoGetUtxos(JSWalletStandardADAGetUtxosFeature _);
  @JS("cardano:getAddressUtxos")
  external set cardanoGetAddressUtxos(JSWalletStandardADAGetAddressUtxosFeature _);

  @JS("cardano:getCollateral")
  external set cardanoGetCollateral(JSWalletStandardADAGetCollateralFeature _);
  @JS("cardano:getUsedAddresses")
  external set cardanoGetUsedAddresses(JSWalletStandardADAGetUsedAddressesFeature _);
  @JS("cardano:getUnusedAddresses")
  external set cardanoGetUnusedAddresses(JSWalletStandardADAGetUnusedAddressesFeature _);
  @JS("cardano:getChangeAddress")
  external set cardanoGetChangeAddress(JSWalletStandardADAGetChangeAddressFeature _);

  @JS("cardano:getRewardAddresses")
  external set cardanoGetRewardAddresses(JSWalletStandardADAGetRewardAddressesFeature _);
  @JS("cardano:signTx")
  external set cardanoSignTx(JSWalletStandardADASignTxFeature _);
  @JS("cardano:signData")
  external set cardanoSignData(JSWalletStandardADASignDataFeature _);
  @JS("cardano:signMessage")
  external set cardanoSignMessage(JSWalletStandardADASignMessageFeature _);
  @JS("cardano:signTransaction")
  external set cardanoSignTransaction(JSWalletStandardADASignTransactionFeature _);
  @JS("cardano:signAndSendTransaction")
  external set cardanoSignAndTransaction(
      JSWalletStandardADASignAndSendTransactionFeature _);
  @JS("cardano:isEnabled")
  external set cardanoIsEnabled(JSWalletStandardADAIsEnabledFeature _);
  @JS("cardano:submitTx")
  external set cardanoSubmitTx(JSWalletStandardADASubmitTxFeature _);
  @JS("cardano:getScript")
  external set cardanoGetScript(JSWalletStandardADAGetScriptFeature _);

  @JS("cardano:submitTxs")
  external set cardanoSubmitTxs(JSWalletStandardADASubmitTxsFeature _);
  @JS("cardano:signTxs")
  external set cardanoSignTxs(JSWalletStandardADASignTxsFeature _);
  @JS("cardano:getAccountPub")
  external set cardanoGetAccountPub(JSWalletStandardADAGetAccountPubFeature _);
  @JS("cardano:getScriptRequirements")
  external set cardanoGetScriptRequirements(
      JSWalletStandardADAGetScriptRequirementsFeature _);
  @JS("cardano:submitUnsignedTx")
  external set cardanoSubmitUnsignedTx(JSWalletStandardADASubmitUnsignedTxFeature _);

  /// monero
  @JS("monero:signAndSendTransaction")
  external set moneroSignAndSendTransaction(
      MoneroWalletAdapterMoneroSignAndSendTransactionFeature _);
  @JS("monero:signMessage")
  external set moneroSignMessage(MoneroWalletAdapterMoneroSignMessageFeature _);
  @JS("monero:connect")
  external set moneroConnect(JSMoneroWalletStandardConnectFeature _);
  @JS("monero:events")
  external set moneroEvents(JSWalletStandardEventsFeature _);
  @JS("monero:disconnect")
  external set moneroDisconnect(JSWalletStandardDisconnectFeature _);

  /// ripple
  @JS("xrpl:signAndSendTransaction")
  external set rippleSignAndSendTransaction(
      RippleWalletAdapterRippleSignAndSendTransactionFeature _);
  @JS("xrpl:signTransaction")
  external set rippleSignTransaction(RippleWalletAdapterRippleSignTransactionFeature _);
  @JS("xrpl:signMessage")
  external set rippleSignMessage(RippleWalletAdapterRippleSignMessageFeature _);
  @JS("xrpl:connect")
  external set rippleConnect(JSRippleWalletStandardConnectFeature _);
  @JS("xrpl:events")
  external set rippleEvents(JSWalletStandardEventsFeature _);
  @JS("xrpl:disconnect")
  external set rippleDisconnect(JSWalletStandardDisconnectFeature _);

  /// bitcoin
  @JS("bitcoin:connect")
  external set bitcoinConnect(JSWalletStandardConnectFeature _);
  @JS("bitcoin:account")
  external set bitcoinAccount(JSWalletStandardAccountFeature _);
  @JS("bitcoin:signPersonalMessage")
  external set bitcoinSignPersonalMessage(JSWalletStandardSignPersonalMessageFeature _);
  @JS("bitcoin:signTransaction")
  external set bitcoinSignTransaction(JSWalletStandardSignTransactionFeature _);
  @JS("bitcoin:getAccountAddresses")
  external set bitcoingetAccountAddresses(JSWalletStandardGetAccountAddressesFeature _);
  @JS("bitcoin:sendTransaction")
  external set bitcoinSendTransaction(JSWalletStandardSendTransactionFeature _);
  @JS("bitcoin:disconnect")
  external set bitcoinDisconnect(JSWalletStandardDisconnectFeature _);

  @JS("bitcoin:events")
  external set bitcoinEvents(JSWalletStandardEventsFeature _);

  /// bitcoin cash
  @JS("bch:connect")
  external set bitcoinCashConnect(JSWalletStandardConnectFeature _);
  @JS("bch:account")
  external set bitcoinCashAccount(JSWalletStandardAccountFeature _);
  @JS("bch:signPersonalMessage")
  external set bitcoinCashSignPersonalMessage(
      JSWalletStandardSignPersonalMessageFeature _);
  @JS("bch:signTransaction")
  external set bitcoinCashSignTransaction(JSWalletStandardSignTransactionFeature _);
  @JS("bch:getAccountAddresses")
  external set bitcoinCashGetAccountAddresses(
      JSWalletStandardGetAccountAddressesFeature _);
  @JS("bch:sendTransaction")
  external set bitcoinCashSendTransaction(JSWalletStandardSendTransactionFeature _);
  @JS("bch:disconnect")
  external set bitcoinCashDisconnect(JSWalletStandardDisconnectFeature _);
  @JS("bch:events")
  external set bitcoinCashEvents(JSWalletStandardEventsFeature _);

  /// sui
  @JS("sui:connect")
  external set suiConnect(JSSuiWalletStandardConnectFeature _);
  @JS("sui:disconnect")
  external set suiDisconnect(SuiWalletAdapterStandardDisconnectFeature _);
  @JS("sui:reportTransactionEffects")
  external set suiReportTransactionEffects(
      SuiWalletAdapterStandardReportTransactionEffectskFeature _);
  @JS("sui:signAndExecuteTransaction")
  external set suiSignAndExecuteTransaction(
      SuiWalletAdapterStandardSignAndExecuteTransactionFeature _);
  @JS("sui:signAndExecuteTransactionBlock")
  external set suiSignAndExecuteTransactionBlock(
      SuiWalletAdapterStandardSignAndExecuteTransactionBlockFeature _);
  @JS("sui:signTransaction")
  external set suiSignTransaction(SuiWalletAdapterStandardSignTransactionFeature _);
  @JS("sui:signTransactionBlock")
  external set suiSignTransactionBlock(
      SuiWalletAdapterStandardSignTransactionBlockFeature _);
  @JS("sui:signPersonalMessage")
  external set suiSignPersonalMessage(
      SuiWalletAdapterStandardSignPersonalMessageFeature _);
  @JS("sui:signMessage")
  external set suiSignMessage(SuiWalletAdapterStandardSignMessageFeature _);
  @JS("sui:events")
  external set suiEvents(JSWalletStandardEventsFeature _);

  /// aptos
  @JS("aptos:connect")
  external set aptosConnect(AptosWalletAdapterStandardConnectFeature _);
  @JS("aptos:account")
  external set aptosAccount(AptosWalletAdapterStandardAccountFeature _);
  @JS("aptos:disconnect")
  external set aptosDisconnect(AptosWalletAdapterStandardDisconnectFeature _);
  @JS("aptos:network")
  external set aptosNetwork(AptosWalletAdapterStandardGetNetworkFeature _);
  @JS("aptos:onAccountChange")
  external set aptosOnAccountChange(AptosWalletAdapterStandardOnAccountChangeFeature _);
  @JS("aptos:onNetworkChange")
  external set aptosOnNetworkChange(AptosWalletAdapterStandardOnNetworkChangeFeature _);
  @JS("aptos:signTransaction")
  external set aptosSignTransaction(AptosWalletAdapterStandardSignTransactionFeature _);
  @JS("aptos:signMessage")
  external set aptosSignMessage(AptosWalletAdapterStandardSignMessageFeature _);
  @JS("aptos:changeNetwork")
  external set aptosChangeNetwork(AptosWalletAdapterStandardChangeNetworkFeature _);
  @JS("aptos:events")
  external set aptosEvents(JSWalletStandardEventsFeature _);

  /// substrate
  @JS("polkadot:signTransaction")
  external set substrateSignTransaction(
      SubstrateWalletAdapterSubstrateSignTransactionFeature _);
  @JS("polkadot:signMessage")
  external set substrateSignMessage(SubstrateWalletAdapterSubstrateSignMessageFeature _);
  @JS("polkadot:addNewChain")
  external set substrateAddNewChain(SubstrateWalletAdapterSubstrateAddNewChainFeature _);
  @JS("polkadot:connect")
  external set substrateConnect(JSSubstrateWalletStandardConnectFeature _);
  @JS("polkadot:events")
  external set substrateEvents(JSWalletStandardEventsFeature _);
  @JS("polkadot:disconnect")
  external set polkadotDisconnect(JSWalletStandardDisconnectFeature _);

  /// ethereum
  @JS("ethereum:sendTransaction")
  external set ethereumSendTransaction(EthereumWalletAdapterSendTransactionFeature _);
  @JS("ethereum:personalSign")
  external set ethereumPersonalSign(EthereumWalletAdapterPersonalSignFeature _);
  @JS("ethereum:ethSign")
  external set ethereumEthSign(EthereumWalletAdapterEthSignFeature _);
  @JS("ethereum:connect")
  external set ethereumConnect(EthereumWalletAdapterConnectFeature _);
  @JS("ethereum:events")
  external set ethereumEvents(JSWalletStandardEventsFeature _);
  @JS("ethereum:signTypedData")
  external set ethereumsignTypedData(EthereumWalletAdapterSignTypedDataFeature _);
  @JS("ethereum:signTypedDataV4")
  external set ethereumsignTypedDataV4(EthereumWalletAdapterSignTypedDataV4Feature _);
  @JS("ethereum:signTypedDataV3")
  external set ethereumsignTypedDataV3(EthereumWalletAdapterSignTypedDataV3Feature _);
  @JS("ethereum:addNewChain")
  external set ethereumAddNewChain(EthereumWalletAdapterAddNewChainFeature _);
  @JS("ethereum:request")
  external set ethereumRequest(EthereumWalletAdapteRequestFeature _);
  @JS("ethereum:disconnect")
  external set ethereumDisconnect(JSWalletStandardDisconnectFeature _);

  /// tron
  @JS("tron:signTransaction")
  external set tronSignTransaction(TronWalletAdapterSignTransactionFeature _);
  @JS("tron:signMessage")
  external set tronSignMessage(TronWalletAdapterSignMessageFeature _);
  @JS("tron:connect")
  external set tronConnect(TronWalletAdapterConnectFeature _);
  @JS("tron:events")
  external set tronEvents(JSWalletStandardEventsFeature _);
  @JS("tron:disconnect")
  external set tronDisconnect(JSWalletStandardDisconnectFeature _);

  /// cosmos
  @JS("cosmos:signTransaction")
  external set cosmosSignTransaction(CosmosWalletAdapterStandardSignTransactionFeature _);
  @JS("cosmos:signer")
  external set cosmosSigner(CosmosWalletAdapterSignerFeature _);
  @JS("cosmos:signMessage")
  external set cosmosSignMessage(CosmosWalletAdapterStandardSignMessageFeature _);

  @JS("cosmos:signTransactionDirect")
  external set cosmosSignTransactionDirect(
      CosmosWalletAdapterStandardSignTransactionDirectFeature _);
  @JS("cosmos:signTransactionAmino")
  external set cosmosSignTransactionAmino(
      CosmosWalletAdapterStandardSignTransactionAminoFeature _);

  @JS("cosmos:addNewChain")
  external set cosmosAddNewChain(CosmosWalletAdapterAddNewChainFeature _);
  @JS("cosmos:connect")
  external set cosmosConnect(CosmosWalletAdapterConnectFeature _);
  @JS("cosmos:events")
  external set cosmosEvents(JSWalletStandardEventsFeature _);
  @JS("cosmos:disconnect")
  external set cosmosDisconnect(JSWalletStandardDisconnectFeature _);

  @JS("zcash:payment")
  external set payment(ZcashWalletAdapterZcashPaymentFeature _);
  @JS("zcash:signMessage")
  external set zcashSignMessage(ZcashWalletAdapterZcashSignMessageFeature _);
  @JS("zcash:connect")
  external set zcashConnect(JSZcashWalletStandardConnectFeature _);
  @JS("zcash:events")
  external set zcashEvents(JSWalletStandardEventsFeature _);
  @JS("zcash:disconnect")
  external set zcashDisconnect(JSWalletStandardDisconnectFeature _);
}

@JS()
extension type JSWalletAdapter(JSAny _) implements JSAny {
  external set name(String _);
  external set version(String _);
  external set icon(String _);
}

@JS()
extension type JSWalletStandard(JSAny _) implements JSWalletAdapter {
  external JSArray<JSWalletStandardAccount> get accounts;
  external JSArray<JSString> get chains;
  external Proxy<JSWalletStandardFeature> get features;
  external set features(JSAny _);
  external set accounts(JSArray<JSWalletStandardAccount> _);
  external set chains(JSArray<JSString> _);
  external set isBitcoin(bool _);
}

@JS()
extension type JSWalletStandardAccount._(JSObject _) implements JSAny {
  external set address(String address);
  external String get address;
  external JSAny? get publicKey;
  external JSArray<JSString> get chains;
  external JSArray<JSString> get features;
  external set publicKey(JSAny? _);
  external set chains(JSArray<JSString> chains);
  external set features(JSArray<JSString> features);
  external set label(String? _);
  external set icon(String? _);
  external set name(String? _);
  external String? get name;
  String? get chain => chains[0].toDart;
}
extension type JSWalletStandardConnectParams._(JSObject _) implements JSAny {
  external bool? get silent;
  external JSArray<JSString>? chains;
}
extension type JSWalletStandardConnect._(JSObject _) implements JSAny {
  factory JSWalletStandardConnect.setup(List<JSWalletStandardAccount> accounts) {
    return JSWalletStandardConnect._(JSObject())..accounts = accounts.toJS;
  }
  external JSArray<JSWalletStandardAccount> get accounts;
  external set accounts(JSArray<JSWalletStandardAccount> _);
}
@JS()
extension type JSWalletStandardConnectFeature(JSAny _) implements JSAny {
  factory JSWalletStandardConnectFeature.setup(
      {required JSFunction connect, String version = SolanaJSConstant.version}) {
    return JSWalletStandardConnectFeature(JSObject())
      ..connect = connect
      ..version = version;
  }
  external set version(String version);
  external set connect(JSFunction _);
}
@JS()
extension type JSWalletStandardEventsFeature(JSAny _) implements JSAny {
  factory JSWalletStandardEventsFeature.setup(
      {required JSFunction on, String version = SolanaJSConstant.version}) {
    return JSWalletStandardEventsFeature(JSObject())
      ..on = on
      ..version = version;
  }
  external set version(String version);
  external set on(JSFunction _);
}

@JS()
extension type JSWalletStandardDisconnectFeature(JSAny _) implements JSAny {
  factory JSWalletStandardDisconnectFeature.setup(
      {required JSFunction disconnect,
      String version = JSWalletStandardConst.defaultVersion}) {
    return JSWalletStandardDisconnectFeature(JSObject())
      ..disconnect = disconnect
      ..version = version;
  }
  external set version(String version);
  external set disconnect(JSFunction _);
}
@JS()
extension type JSWalletStandardSignPersonalMessageFeature(JSAny _) implements JSAny {
  factory JSWalletStandardSignPersonalMessageFeature.setup(
      {required JSFunction signPersonalMessage,
      String version = JSWalletStandardConst.defaultVersion}) {
    return JSWalletStandardSignPersonalMessageFeature(JSObject())
      ..signPersonalMessage = signPersonalMessage
      ..version = version;
  }
  external set version(String version);
  external set signPersonalMessage(JSFunction _);
}
// typedef SNN = JSPromise<JSBitcoinSignTransactionResponse> Function(
//     JSBitcoinSignTransactionResponse);
@JS()
extension type JSWalletStandardSignTransactionFeature(JSAny _) implements JSAny {
  factory JSWalletStandardSignTransactionFeature.setup(
      {required JSFunction signTransaction,
      String version = JSWalletStandardConst.defaultVersion}) {
    return JSWalletStandardSignTransactionFeature(JSObject())
      ..signTransaction = signTransaction
      ..version = version;
  }
  external set version(String version);
  external set signTransaction(JSFunction _);
}
@JS()
extension type JSWalletStandardGetAccountAddressesFeature(JSAny _) implements JSAny {
  factory JSWalletStandardGetAccountAddressesFeature.setup(
      {required JSFunction getAccountAddresses,
      String version = JSWalletStandardConst.defaultVersion}) {
    return JSWalletStandardGetAccountAddressesFeature(JSObject())
      ..getAccountAddresses = getAccountAddresses
      ..version = version;
  }
  external set version(String version);
  external set getAccountAddresses(JSFunction _);
}
@JS()
extension type JSWalletStandardSendTransactionFeature(JSAny _) implements JSAny {
  factory JSWalletStandardSendTransactionFeature.setup(
      {required JSFunction sendTransaction,
      String version = JSWalletStandardConst.defaultVersion}) {
    return JSWalletStandardSendTransactionFeature(JSObject())
      ..sendTransaction = sendTransaction
      ..version = version;
  }
  external set version(String version);
  external set sendTransaction(JSFunction _);
}

@JS()
extension type JSWalletStandardSignMessageFeature(JSAny _) implements JSAny {
  factory JSWalletStandardSignMessageFeature.setup(
      {required JSFunction signMessage, String version = SolanaJSConstant.version}) {
    return JSWalletStandardSignMessageFeature(JSObject())
      ..signMessage = signMessage
      ..version = version;
  }
  external set version(String version);
  external set signMessage(JSFunction _);
}
extension type JSWalletStandardAccountFeature(JSAny _) implements JSAny {
  factory JSWalletStandardAccountFeature.setup(
      {required JSFunction account,
      String version = JSWalletStandardConst.defaultVersion}) {
    return JSWalletStandardAccountFeature(JSObject())
      ..account = account
      ..version = version;
  }
  external set version(String version);
  external set account(JSFunction _);
}

extension type JSWalletStandardChange._(JSObject _) implements JSAny {
  factory JSWalletStandardChange.setup(
      {List<String>? chains, List<JSWalletStandardAccount>? accounts}) {
    return JSWalletStandardChange._(JSObject())
      ..chains = chains?.map((e) => e.toJS).toList().toJS
      ..accounts = accounts?.toJS;
  }
  external set chains(JSArray<JSString>? chains);
  external set accounts(JSArray<JSWalletStandardAccount>? accounts);
  external JSArray<JSWalletStandardAccount>? get accounts;
  external JSArray<JSString>? get chains;
}
extension type JSWalletStandardEvent._(JSObject _) implements JSWalletStandardChange {
  factory JSWalletStandardEvent(JSWalletStandardChange change) {
    return JSWalletStandardEvent._(JSObject())
      ..change = change
      ..accounts = change.accounts
      ..chains = change.chains;
  }
  external set change(JSWalletStandardChange change);
  external JSWalletStandardChange get change;
}

extension type JSWalletNetworkEvent._(JSObject _) implements JSAny {
  factory JSWalletNetworkEvent(
      {required List<JSNetworkEventType> events,
      JSWalletStandardAccount? account,
      JSWalletConnectEvent? networkAccounts,
      JSWalletStandardChange? change,
      JSAny? disconnect,
      JSAny? chainChanged,
      JSAny? message}) {
    return JSWalletNetworkEvent._(JSObject())
      ..types = events.map((e) => e.name.toJS).toList().toJS
      ..change = change
      ..networkAccounts = networkAccounts
      ..disconnect = disconnect
      ..chainChanged = chainChanged
      ..account = account
      ..message = message;
  }
  List<JSNetworkEventType> get eventTypes =>
      types.toDart.map((e) => e.toDart).map((e) => JSNetworkEventType.name(e)).toList();
  external JSArray<JSString> get types;
  external set types(JSArray<JSString> _);

  external JSWalletConnectEvent? get networkAccounts;
  external set networkAccounts(JSWalletConnectEvent? _);

  external JSWalletStandardChange? get change;
  external set change(JSWalletStandardChange? _);

  external JSWalletStandardAccount? get account;
  external set account(JSWalletStandardAccount? _);

  external JSAny? get disconnect;
  external set disconnect(JSAny? _);
  external JSAny? get chainChanged;
  external set chainChanged(JSAny? _);

  external JSAny? get message;
  external set message(JSAny? _);
}
extension type JSWalletConnectEvent._(JSObject _) implements JSAny {
  factory JSWalletConnectEvent.setup(List<JSWalletStandardAccount> accounts) {
    return JSWalletConnectEvent._(JSObject())..accounts = accounts.toJS;
  }
  external JSArray<JSWalletStandardAccount> get accounts;
  external set accounts(JSArray<JSWalletStandardAccount> _);

  JSArray<JSString> get jsAddresses =>
      accounts.toDart.map((e) => e.address.toJS).toList().toJS;
}
