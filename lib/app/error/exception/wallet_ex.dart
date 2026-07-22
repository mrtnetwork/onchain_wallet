import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_wallet/app/serialization/serialization.dart';

import 'app_exception.dart';

class WalletException extends BaseAppException {
  const WalletException(super.message);
  const WalletException.message(super.message);

  @override
  bool get localizedMessage => false;

  factory WalletException.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: AppSerializationIdentifier.walletError,
    );
    return WalletException(values.rawValueAt(0));
  }

  @override
  AppSerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.walletError;
}

class WalletExceptionConst {
  static const WalletException pubkeyRequired =
      WalletException("public_key_required_derive_address");

  static const WalletException toManyNetworkImported =
      WalletException("to_many_networks_imported");

  static const WalletException invalidRequest = WalletException("invalid_request");
  static WalletException invalidAccountData(String where) =>
      WalletException("invalid_account_details");
  static const WalletException networkAlreadyExist =
      WalletException("network_chain_id_already_exist");
  static const WalletException addressGenerationFailed =
      WalletException("address_generation_failed");
  static const WalletException unsupportedAddressType =
      WalletException("unsupported_address_type");
  static const WalletException invalidBackupData =
      WalletException("invalid_wallet_backup");
  static const WalletException invalidBackupEncoding =
      WalletException("invalid_backup_encoding");
  static const WalletException invalidBackupOptions =
      WalletException("invalid_backup_options");
  static const WalletException unsupportedBackupContent =
      WalletException("unsupported_backup_content");
  static const WalletException invalidBackupChecksum =
      WalletException("invalid_wallet_backup_checksum");
  static const WalletException wrongBackupPassword =
      WalletException("wrong_backup_password");
  static const WalletException authFailed = WalletException("auth_failed");
  static const WalletException passwordTooWeak =
      WalletException("weak_password_validator");
  static const WalletException passwordUsedBefore =
      WalletException("password_used_before");
  static const WalletException incorrectWalletData =
      WalletException("wallet_data_is_invalid");
  static const WalletException tooManyAccounts = WalletException("to_many_accounts");
  static const WalletException incorrectNetwork = WalletException("incorrect_network");
  static const WalletException invalidProviderInformation =
      WalletException("invalid_provider_infomarion");
  static const WalletException addressAlreadyExist =
      WalletException("address_already_exist");

  static const WalletException keyAlreadyExist = WalletException("key_already_exists");
  static const WalletException accountDoesNotFound = WalletException("account_not_found");
  static const WalletException notAuthorizedSigningAccount =
      WalletException("signing_auth_validator");
  static const WalletException signerAccountNotFound =
      WalletException("signer_account_does_not_exists");
  static const WalletException noActiveProvider = WalletException("no_acitve_provider");

  /// signer_account_does_not_exists
  static const WalletException incompleteWalletSetup =
      WalletException("incomplete_wallet_setup");
  static const WalletException walletDoesNotExists =
      WalletException("wallet_does_not_exists");
  static const WalletException walletAlreadyInitialized =
      WalletException("wallet_already_initialized");
  static const WalletException toManyRequests = WalletException("to_many_request");
  static const WalletException rejectSigning =
      WalletException("user_rejected_signing_request");
  static const WalletException incorrectStatus =
      WalletException("incorrect_wallet_status");
  static const WalletException invalidContactDetails =
      WalletException("invalid_contact_details");
  static const WalletException contactExists = WalletException("contact_already_exist");
  static const WalletException invalidBalance = WalletException("invalid_balance");
  static const WalletException unsuportedFeature = WalletException("unsuported_feature");
  static const WalletException unsuportedBackupVersion =
      WalletException("unsuported_backup_version");
  static const WalletException featureUnavailableForMultiSignature =
      WalletException("feature__unavailable_for_multi_signature");
  static const WalletException insufficientBalance =
      WalletException("insufficient_balance");
  static const WalletException decryptionFailed = WalletException("decryption_failed");
  static const WalletException invalidNetworkInformation =
      WalletException("invalid_network_information");

  static const WalletException emptyThrow = WalletException("");
  static const WalletException invalidChainState = WalletException("invalid_chain_state");
  static const WalletException invalidWeb3AccountData =
      WalletException("invalid_web3_account_data");

  static const WalletException invalidRipplePrivateKeyAlgorithm =
      WalletException("invalid_ripple_privatekey_algorithm");

  static const WalletException inaccessibleKeyAlgorithm =
      WalletException("inaccessible_key_algorithm");
  static const WalletException invalidTokenInformation =
      WalletException("invalid_token_information");
  static const WalletException invalidNftInformation =
      WalletException("invalid_nft_information");

  static const WalletException walletIsLocked = WalletException("wallet_is_locked");
  static const WalletException networkTokenUnsuported =
      WalletException("network_support_token_error");
  static const WalletException networkNFTsUnsuported =
      WalletException("network_support_nft_error");
  static const WalletException tokenAlreadyExist =
      WalletException("token_already_exists");
  static const WalletException nftsAlreadyExist = WalletException("nfts_already_exists");

  static const WalletException walletAlreadyExists =
      WalletException("wallet_already_exists");
  static const WalletException walletNameExists = WalletException("wallet_name_exists");
  static const WalletException pageClosed = WalletException("page_closed");
  static const WalletException walletIsNotavailable =
      WalletException("wallet_is_not_available");

  static const WalletException ethSubscribe =
      WalletException("eth_subscribe_websocket_requirment");
  static const WalletException networkDoesNotExist =
      WalletException("network_does_not_exist");

  static const WalletException verificationWalletDataFailed =
      WalletException("wallet_data_verification_failed");

  static const WalletException storageIsNotAvailable =
      WalletException("storage_is_not_available");

  static const WalletException invalidWalletTransactionData =
      WalletException("invalid_wallet_transaction_data");

  static const WalletException invalidSwapInformation =
      WalletException("invalid_swap_information");

  static const WalletException invalidAccountUtxo =
      WalletException("invalid_account_utxo");

  static const WalletException dataBaseOperationFailed =
      WalletException("database_unexpected_error");
  static const WalletException externalWalletConnectionAlreadyExists =
      WalletException("external_wallet_connection_already_exists");
  static const WalletException toManyWalletConnections =
      WalletException("to_many_wallet_connections");
  static const WalletException externalWalletConnectionAuthenticatedFailed =
      WalletException("external_wallet_authentication_failed");
  static const WalletException nodeConnectionErr =
      WalletException("node_connection_error");
  static const WalletException tokenNotFound = WalletException("token_not_found");
  static const WalletException accountNameIsToLarge =
      WalletException("account_name_is_to_large");
  static const WalletException providerNotFound = WalletException("provider_not_found");
  static const WalletException providerAlreadyExists =
      WalletException("provider_already_exists");
  static const WalletException contactDoesNotExists =
      WalletException("contact_does_not_exists");

  static const WalletException badAccountSyncingConfiguration =
      WalletException("bad_account_syncing_configuration");
  static const WalletException invalidNetworkProviderConfiguration =
      WalletException("invalid_network_provider_configuration");
  static const WalletException invalidProviderAuthenticationConfiguration =
      WalletException("invalid_provider_authentication_configuration");
  static const WalletException blockSynchronizatioCanceled =
      WalletException("block_synchronization_canceled");

  static const WalletException saplingParamVerificationFailed =
      WalletException("sapling_parameters_verification_failed");

  static const WalletException zcashSigningErrorMerkle =
      WalletException("zcash_signing_internal_error_failed_to_build_utxo_merkle");
  static const WalletException zcashSigningErrorConstructLiberary =
      WalletException("zcash_signing_internal_error_construct_liberary");
  static const WalletException zcashSigningErrorUnexpected =
      WalletException("zcash_signing_internal_error_unexpected");

  static const WalletException moneroProofGenerationFailed =
      WalletException("monero_proof_generation_failed_desc");
  static const WalletException zcashMissingSaplingParameters =
      WalletException("missing_sapling_parameters");
  static const WalletException feeTokenNotFound = WalletException("fee_token_not_found");
  static const WalletException unsupportedSwapAsset =
      WalletException("unsupported_swap_asset");
}

class AppCryptoExceptionConst {
  static const AppCryptoException invalidCredential =
      AppCryptoException("invalid_credential");
  static const AppCryptoException invalidDerivationKey =
      AppCryptoException("invalid_key_derivation");
  static const AppCryptoException unsupportedDerivationIncreament =
      AppCryptoException("unsupported_derivation_increament");
  static const AppCryptoException bip32IndexOutOfRange =
      AppCryptoException("bip32_index_out_of_range");
  static const AppCryptoException invalidKeyDerivationPath =
      AppCryptoException("invalid_derivation_path");
  static const AppCryptoException invalidMnemonicPassphrase =
      AppCryptoException("invalid_passphrase");
  static const AppCryptoException invalidMnemonic =
      AppCryptoException("invalid_mnemonic");

  static const AppCryptoException invalidEncodedKeyData =
      AppCryptoException("invalid_encoded_key_data");
  static const AppCryptoException invalidBip39MnemonicWords =
      AppCryptoException("invalid_bip39_mnemonic_words");
  static const AppCryptoException invalidCoin = AppCryptoException("invalid_coin");
  static const AppCryptoException importedKeyDerivationNotAllowed =
      AppCryptoException("imported_key_derivation_not_allowed");
  static const AppCryptoException multiSigDerivationNotSuported =
      AppCryptoException("not_support_multisig_derivation");
  static const AppCryptoException privateKeyIsNotAvailable =
      AppCryptoException("private_key_is_not_available");
  static const AppCryptoException invalidHexBytes =
      AppCryptoException("invalid_hex_bytes_string");
  static const AppCryptoException invalidNeweAddressConfiguration =
      AppCryptoException("invalid_new_address_configuration");
  static const AppCryptoException zcashDeriveAddressIndexOutOfRange =
      AppCryptoException("zcash_address_derivation_index_out_of_range");
  static const AppCryptoException zcashDeriveTransparentAddressIndexOutOfRange =
      AppCryptoException("zcash_transparent_address_derivation_index_out_of_range");
  static const AppCryptoException zcashDeriveAddressBadSaplingDiversifierIndex =
      AppCryptoException("zcash_address_derivation_bad_sapling_diversifier");
  static const AppCryptoException failedToConnectToCryptoService =
      AppCryptoException("failed_to_connect_to_crypto_service");
  static const AppCryptoException cryptoOperationWasCanceled =
      AppCryptoException("crypto_operation_canceled");

  static const AppCryptoException cryptoServiceRequestTimeout =
      AppCryptoException("crypto_service_request_timeout");
  static AppCryptoException invalidSigningParameters(String where) {
    return AppCryptoException("invalid_signing_parameters");
  }
}

class AppExceptionConst {
  static const AppException requestCanceled = AppException("request_cancelled");
  static const AppException fileVerificationFiled =
      AppException("file_verification_fail");
  static const AppException invalidPriceFormat = AppException("invalid_price_format");
  static const AppException fileDoesNotExists = AppException("file_does_not_exist");
  static const AppException timeout = AppException("timeout_exception");
  static const AppException invalidFileFormat = AppException("invalid_file_content_desc");
  static const AppException failedToReadFileContent =
      AppException("failed_to_read_content");
  static const AppException invalidStorageParams =
      AppException("invalid_storage_operation_parameters");
  static const AppException fileSaveFailed = AppException("file_save_failed");

  static const AppException transactionStateNotReady =
      AppException("transaction_state_not_ready");

  static const AppException unsupportedNetworkFeature =
      AppException("unsupported_current_network_feature");

  static const AppCryptoException invalidMnemonic =
      AppCryptoException("invalid_mnemonic");
  static const AppException loginTimeout = AppException("login_request_timeout");
  static const AppException walletContextNotAvailable =
      AppException("wallet_context_not_available");
  static const AppException loginRequestRejected = AppException("login_request_rejected");
  static const AppException requiredServiceIsDisabled =
      AppException("required_service_is_disabled");

  static const AppException connectionAlreadyClosed =
      AppException("connection_already_closed");
  static const AppException resourceNotSupported = AppException("resource_not_supported");
  static const AppException missingChromeApi = AppException("missing_chrome_api");
  static const AppException dataChecksumMismatch = AppException("data_checksum_mismatch");
}

class WalletPairingExceptionConst {}
