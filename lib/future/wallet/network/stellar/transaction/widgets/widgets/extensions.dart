import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/widgets/widgets/progress_bar/widgets/stream_bottun.dart';
import 'package:stellar_dart/stellar_dart.dart';
import 'package:on_chain_wallet/future/wallet/network/stellar/transaction/types/types.dart';

extension ExtAccountReceivementStatusExtension on AccountReceivementStatus {
  StreamWidgetStatus get toProgressStatus {
    switch (this) {
      case AccountReceivementStatus.idle:
        return StreamWidgetStatus.idle;
      case AccountReceivementStatus.error:
        return StreamWidgetStatus.error;
      case AccountReceivementStatus.pending:
        return StreamWidgetStatus.progress;
      default:
        return StreamWidgetStatus.success;
    }
  }

  String? get message {
    switch (this) {
      case AccountReceivementStatus.idle:
        return null;
      case AccountReceivementStatus.error:
        return "retrieve_account_activity_failed".tr;
      case AccountReceivementStatus.pending:
        return null;
      case AccountReceivementStatus.inactive:
        return "recipient_account_inactive".tr;
      default:
        return "recipient_account_active".tr;
    }
  }
}

extension ExtOperationTypeDesc on OperationType {
  String get description {
    switch (this) {
      case OperationType.changeTrust:
        return "change_trust_desc".tr;
      case OperationType.createAccount:
        return "stellar_create_account_operation_desc".tr;
      case OperationType.manageBuyOffer:
        return "stellar_manage_buy_offer_desc".tr;
      case OperationType.manageSellOffer:
        return "stellar_manage_sell_offer_desc".tr;
      case OperationType.pathPaymentStrictReceive:
        return "stellar_path_payment_strict_receive_desc".tr;
      case OperationType.pathPaymentStrictSend:
        return "stellar_path_payment_strict_send_desc".tr;
      case OperationType.payment:
        return "stellar_payment_desc".tr;
      default:
        return '';
    }
  }

  String get translate {
    switch (this) {
      case OperationType.createAccount:
        return "create_an_account";
      case OperationType.payment:
        return "payment";
      case OperationType.pathPaymentStrictReceive:
        return "stellar_path_payment_strict_receive";
      case OperationType.manageSellOffer:
        return "stellar_manage_sell_offer";
      case OperationType.createPassiveSellOffer:
        return "create_passive_sell_offer";
      case OperationType.setOptions:
        return "set_options";
      case OperationType.changeTrust:
        return "change_trust";
      case OperationType.allowTrust:
        return "allow_trust";
      case OperationType.accountMerge:
        return "account_merge";
      case OperationType.inflation:
        return "inflation";
      case OperationType.manageData:
        return "manage_data";
      case OperationType.bumpSequence:
        return "bump_sequence";
      case OperationType.manageBuyOffer:
        return "stellar_manage_buy_offer";
      case OperationType.pathPaymentStrictSend:
        return "stellar_path_payment_strict_send";
      case OperationType.createClaimableBalance:
        return "create_claimable_balance";
      case OperationType.claimClaimableBalance:
        return "claim_claimable_balance";
      case OperationType.beginSponsoringFutureReserves:
        return "begin_sponsoring_future_reserves";
      case OperationType.endSponsoringFutureReserves:
        return "end_sponsoring_future_reserves";
      case OperationType.revokeSponsorship:
        return "revoke_sponsorship";
      case OperationType.clawback:
        return "clawback";
      case OperationType.clawbackClaimableBalance:
        return "clawback_claimable_balance";
      case OperationType.setTrustLineFlags:
        return "set_trust_line_flags";
      case OperationType.liquidityPoolDeposit:
        return "liquidity_pool_deposit";
      case OperationType.liquidityPoolWithdraw:
        return "liquidity_pool_withdraw";
      case OperationType.invokeHostFunction:
        return "invoke_host_function";
      case OperationType.extendFootprintTtl:
        return "extend_footprint_ttl";
      case OperationType.restoreFootprint:
        return "restore_footprint";
      default:
        return "";
    }
  }
}

extension ExtTransactiomTimeBoundTypeHelperText on TransactiomTimeBoundType {
  String get helperText {
    switch (this) {
      case TransactiomTimeBoundType.auto:
        return "stellar_time_bound_auto_desc".tr;
      case TransactiomTimeBoundType.none:
        return "stellar_time_bound_none_desc".tr;
      case TransactiomTimeBoundType.manual:
        return "expiration_time".tr;
    }
  }
}
