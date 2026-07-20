import 'package:blockchain_utils/networks/types/address.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/types/account.dart';

typedef APPCHAIN = Chain<
    IAddress,
    TokenCore,
    NFTCore,
    WalletNetwork,
    ChainTransaction,
    ChainAccount,
    NetworkClient,
    NetworkApiProvider<WalletNetwork, NetworkClient>,
    IChainContext<IAddress, TokenCore, NFTCore, WalletNetwork, ChainTransaction,
        ChainAccount, NetworkClient, NetworkApiProvider<WalletNetwork, NetworkClient>>>;
typedef APPNETWORKCONTROLLER = NetworkController<ChainAccount, APPCHAIN, Web3ChainAccount,
    Web3InternalChain, ChainConfig>;
typedef APPNETWORKCONTROLLERCHAINCONFIG<ACCOUNT extends APPCHAIN,
        CONFIG extends ChainConfig>
    = NetworkController<ChainAccount, ACCOUNT, Web3ChainAccount, Web3InternalChain,
        CONFIG>;
typedef APPCHAINADDRESS<NETWORKADDRESS extends IAddress> = Chain<
    NETWORKADDRESS,
    TokenCore,
    NFTCore,
    WalletNetwork,
    ChainTransaction,
    ChainAccount<NETWORKADDRESS, TokenCore, NFTCore, ChainTransaction, WalletNetwork>,
    CLIENTNADDRESS<NETWORKADDRESS>,
    NetworkApiProvider<WalletNetwork, CLIENTNADDRESS<NETWORKADDRESS>>,
    IChainContext<
        NETWORKADDRESS,
        TokenCore,
        NFTCore,
        WalletNetwork,
        ChainTransaction,
        ChainAccount<NETWORKADDRESS, TokenCore, NFTCore, ChainTransaction, WalletNetwork>,
        CLIENTNADDRESS<NETWORKADDRESS>,
        NetworkApiProvider<WalletNetwork, CLIENTNADDRESS<NETWORKADDRESS>>>>;

typedef APPCHAINTOKENCLIENTACCOUNT<
        TOKEN extends TokenCore,
        CLIENT extends NetworkClient,
        ACCOUNT extends ChainAccount<IAddress, TOKEN, NFTCore, ChainTransaction,
            WalletNetwork>>
    = Chain<
        IAddress,
        TOKEN,
        NFTCore,
        WalletNetwork,
        ChainTransaction,
        ACCOUNT,
        CLIENT,
        NetworkApiProvider<WalletNetwork, CLIENT>,
        IChainContext<IAddress, TOKEN, NFTCore, WalletNetwork, ChainTransaction, ACCOUNT,
            CLIENT, NetworkApiProvider<WalletNetwork, CLIENT>>>;
typedef APPCHAINACCOUNTTOKEN<
        TOKEN extends TokenCore,
        ACCOUNT extends ChainAccount<IAddress, TOKEN, NFTCore, ChainTransaction,
            WalletNetwork>>
    = Chain<
        IAddress,
        TOKEN,
        NFTCore,
        WalletNetwork,
        ChainTransaction,
        ACCOUNT,
        CLIENTDYNAMIC,
        NetworkApiProvider<WalletNetwork, CLIENTDYNAMIC>,
        IChainContext<IAddress, TOKEN, NFTCore, WalletNetwork, ChainTransaction, ACCOUNT,
            CLIENTDYNAMIC, NetworkApiProvider<WalletNetwork, CLIENTDYNAMIC>>>;

typedef APPCHAINTOKEN<TOKEN extends TokenCore>
    = ChainAccount<IAddress, TOKEN, NFTCore, ChainTransaction, WalletNetwork>;
typedef APPCHAINTX<TX extends ChainTransaction>
    = ChainAccount<IAddress, TokenCore, NFTCore, TX, WalletNetwork>;

typedef APPCHAINACCOUNT<CHAINACCOUNT extends ChainAccount> = Chain<
    IAddress,
    TokenCore,
    NFTCore,
    WalletNetwork,
    ChainTransaction,
    CHAINACCOUNT,
    NetworkClient,
    NetworkApiProvider,
    IChainContext<IAddress, TokenCore, NFTCore, WalletNetwork, ChainTransaction,
        CHAINACCOUNT, NetworkClient, NetworkApiProvider>>;

typedef APPCHAINACCOUNTTX<TRANSACTION extends ChainTransaction,
        CHAINACCOUNT extends ACCOUNTX<TRANSACTION>>
    = Chain<
        IAddress,
        TokenCore,
        NFTCore,
        WalletNetwork,
        TRANSACTION,
        CHAINACCOUNT,
        CLIENTNTX<TRANSACTION>,
        NetworkApiProvider<WalletNetwork, CLIENTNTX<TRANSACTION>>,
        IChainContext<
            IAddress,
            TokenCore,
            NFTCore,
            WalletNetwork,
            TRANSACTION,
            CHAINACCOUNT,
            CLIENTNTX<TRANSACTION>,
            NetworkApiProvider<WalletNetwork, CLIENTNTX<TRANSACTION>>>>;

typedef APPCHAINTOKENNETWORKACCOUNTCLIENT<
        TOKEN extends TokenCore,
        NETWORK extends WalletNetwork,
        CHAINACCOUNT extends ChainAccount<IAddress, TOKEN, NFTCore, ChainTransaction,
            NETWORK>,
        CL extends CLIENTNWORK<NETWORK>>
    = Chain<
        IAddress,
        TOKEN,
        NFTCore,
        NETWORK,
        ChainTransaction,
        CHAINACCOUNT,
        CL,
        NetworkApiProvider<NETWORK, CL>,
        IChainContext<IAddress, TOKEN, NFTCore, NETWORK, ChainTransaction, CHAINACCOUNT,
            CL, NetworkApiProvider<NETWORK, CL>>>;
typedef APPCHAINADDRESSNETWORKACCOUNTCLIENT<
        NETWORKADDRESS extends IAddress,
        NETWORK extends WalletNetwork,
        CHAINACCOUNT extends ACCOUNADDRESSNETWORK<NETWORKADDRESS, NETWORK>,
        CL extends CLIENTNADDRESSNETWORK<NETWORKADDRESS, NETWORK>>
    = Chain<
        NETWORKADDRESS,
        TokenCore,
        NFTCore,
        NETWORK,
        ChainTransaction,
        CHAINACCOUNT,
        CL,
        NetworkApiProvider<NETWORK, CL>,
        IChainContext<NETWORKADDRESS, TokenCore, NFTCore, NETWORK, ChainTransaction,
            CHAINACCOUNT, CL, NetworkApiProvider<NETWORK, CL>>>;

typedef ACCOUNTADDRESS<NETWORKADDRESS extends IAddress>
    = ChainAccount<NETWORKADDRESS, TokenCore, NFTCore, ChainTransaction, WalletNetwork>;
typedef ACCOUNTX<TX extends ChainTransaction>
    = ChainAccount<IAddress, TokenCore, NFTCore, TX, WalletNetwork>;
typedef ACCOUNADDRESSNETWORK<NETWORKADDRESS extends IAddress,
        NETWORK extends WalletNetwork>
    = ChainAccount<NETWORKADDRESS, TokenCore, NFTCore, ChainTransaction, NETWORK>;
typedef ACCOUNTTOKEN<TOKEN extends TokenCore>
    = ChainAccount<IAddress, TOKEN, NFTCore, ChainTransaction, WalletNetwork>;

///
///
// typedef CLIENTNWORKPROVIDER<NETWORKPROVIDER extends NetworkApiProvider,
//         NETWORK extends WalletNetwork>
//     = NetworkClient<ChainTransaction, NETWORKPROVIDER, BaseNetworkToken, IAddress,
//         WalletNetwork>;
typedef CLIENTNWORK<NETWORK extends WalletNetwork>
    = NetworkClient<ChainTransaction, BaseNetworkToken, IAddress, NETWORK>;
typedef CLIENTNTX<TX extends ChainTransaction>
    = NetworkClient<TX, BaseNetworkToken, IAddress, WalletNetwork>;
typedef CLIENTNADDRESS<ADDRESS extends IAddress>
    = NetworkClient<ChainTransaction, BaseNetworkToken, ADDRESS, WalletNetwork>;
typedef CLIENTNADDRESSNETWORK<ADDRESS extends IAddress, NETWORK extends WalletNetwork>
    = NetworkClient<ChainTransaction, BaseNetworkToken, ADDRESS, NETWORK>;
typedef CLIENTDYNAMIC
    = NetworkClient<ChainTransaction, BaseNetworkToken, IAddress, WalletNetwork>;
