# About OnChain Wallet

OnChain Wallet is an open-source multi-chain wallet built for secure, decentralized finance across multiple platforms.

## Networks

### Bitcoin and forked networks

- **Features:** Full support for Bitcoin and transactions on forked Bitcoin-based networks.
- **Supported Networks:** Bitcoin, Bitcoin Cash, Litecoin, Dogecoin, Dash, Bitcoin SV, and more.
- **Web3:** 
  - Wallet Standard (available on extension, Android, and macOS platforms.).
  - WalletConnect (available on all platforms).
  - [examples](https://mrtnetwork.github.io/onchain_dapp/)


### Ripple

- **Features:** Unlocking the potential of the Ripple network.
- **Highlights:** Comprehensive support for advanced cryptographic algorithms, NFTs, tokens, multisignature transactions, account settings, trust settings, escrow transactions, regular key settings, and more.
- **Web3:** 
  - Wallet Standard (available on extension, Android, and macOS platforms.).
  - WalletConnect (available on all platforms).
  - [examples](https://mrtnetwork.github.io/onchain_dapp/)

### Solana

- **Features:** Seamless support for Solana transactions.
- **Highlights:**
  - SPLToken transfer, account creation and token minting.
- **Web3:** 
  - Wallet Standard (available on extension, Android, and macOS platforms.).
  - WalletConnect (available on all platforms).
  - [examples](https://mrtnetwork.github.io/onchain_dapp/)


### Cardano

- **Features:** Streamlined support for Cardano transactions.
- **Highlights:**
  - Full compatibility with Shelley and Byron addresses and transactions.
  - Facilitates minting and transfer of assets.
  - Integration for stake certificates.
  - Allows for multiple account transactions.
  - Multisignature account.
- **Web3:** 
  - Wallet Standard (available on extension, Android, and macOS platforms.).
  - Cardano CIP-30 (available on extension, Android, and macOS platforms.).
  - WalletConnect (available on all platforms).
  - [examples](https://mrtnetwork.github.io/onchain_dapp/)

### Ethereum

- **Features:** Support for Ethereum transactions.
- **Highlights:** Compatibility with both legacy and EIP-1559 transactions. Import and manage ERC-20 assets effortlessly, and execute ERC-20 token transfers with ease.
- **Web3:** 
  - EIP-1193 (available on extension, Android, and macOS platforms.).
  - EIP-6963 (available on extension, Android, and macOS platforms.).
  - Wallet Standard (available on extension, Android, and macOS platforms.).
  - WalletConnect (available on all platforms).
  - [examples](https://mrtnetwork.github.io/onchain_dapp/)

### Tron

- **Features:** Seamless interaction with the Tron blockchain.
- **Highlights:** Confidence in sending TRX, TRC-20, and TRC-10 tokens. Support for native contracts, including multi-signature transactions. Control over updating account permissions, managing accounts, unstaking (v2), delegating resources, and creating/updating witnesses.
- **Web3:** 
  - TIP-1193 (available on extension, Android, and macOS platforms.).
  - Wallet Standard (available on extension, Android, and macOS platforms.).
  - WalletConnect (available on all platforms).
  - [examples](https://mrtnetwork.github.io/onchain_dapp/)


### Cosmos

- **Features:** Seamless support for Cosmos transactions.
- **Highlights:**
  - Support for Secp256k1, Secp256r1, Ed25519, and ETHSecp256k1
  - Supports importing networks based on forked Cosmos and Evmos chains.
- **Web3:** 
  - Wallet Standard (available on extension, Android, and macOS platforms.).
  - WalletConnect (available on all platforms).
  - [examples](https://mrtnetwork.github.io/onchain_dapp/)


### Ton

- **Features:** Seamless support for Ton transactions.
- **Highlights:** Jetton transfer, multiple message transfer.
- **Web3:** 
  - Wallet Standard (available on extension, Android, and macOS platforms.).
  - WalletConnect (available on all platforms).
  - [examples](https://mrtnetwork.github.io/onchain_dapp/)


### Stellar

- **Features:** Seamless Stellar transaction support.
- **Highlights:** Supports Payment, ChangeTrust, PathPayment, ManageBuyOffer, ManageSellOffer, and more.
- **Web3:** 
  - Wallet Standard (available on extension, Android, and macOS platforms.).
  - WalletConnect (available on all platforms).
  - [examples](https://mrtnetwork.github.io/onchain_dapp/)


### Substrate

- **Features:** Provides seamless support for Kusama, Polkadot transactions, and standalone chains.
- **Highlights:**
  - Enables importing Substrate networks, interacting with metadata, creating extrinsics, querying storage, and making runtime calls.
  - Multisig account
  - XCM Transfer between chains.
- **Web3:** 
  - Wallet Standard (available on extension, Android, and macOS platforms.).
  - Plkadot.js Injected (available on extension, Android, and macOS platforms.).
  - WalletConnect (available on all platforms).
  - [examples](https://mrtnetwork.github.io/onchain_dapp/)


### Monero

- **Features:** Seamless support for Monero transactions, Generate and verify proof.
- **Web3:** 
  - Wallet Standard (available on extension, Android, and macOS platforms.).
  - WalletConnect (available on all platforms).
  - [examples](https://mrtnetwork.github.io/onchain_dapp/)

### Zcash

- **Features:** Supports Zcash transactions: Transparent, Sapling, and Orchard
- **Web3:** 
  - Wallet Standard (available on extension, Android, and macOS platforms.).
  - WalletConnect (available on all platforms).
  - [examples](https://mrtnetwork.github.io/onchain_dapp/)


### SUI

- **Features:** Seamless support for Sui transactions.
- **Highlights:** Coin management, Multisig.
- **Web3:** 
  - Wallet Standard (available on extension, Android, and macOS platforms.).
  - WalletConnect (available on all platforms).
  - [examples](https://mrtnetwork.github.io/onchain_dapp/)


### Aptos

- **Features:** Seamless support for Aptos transactions.
- **Highlights:** Coin management, Multikey, MultiED25519.
- **Web3:** 
  - Wallet Standard (available on extension, Android, and macOS platforms.).
  - WalletConnect (available on all platforms).
  - [examples](https://mrtnetwork.github.io/onchain_dapp/)


## Swap

- Supports Chainflip, Maya, and THORChain protocols.

## Tor

- Supports Tor connections through network providers on native platforms.


## Platform Support

OnChain Wallet is available on:

- Android
- Linux
- Windows
- macOS
- Web
- Browser Extensions (Chrome, Brave, Firefox, Opera, etc)


## Build Instructions

Clone the repository and build using Flutter.
Ensure your build environment has Flutter and LLVM/Clang installed, as LLVM is required for compiling native dependencies.

- **WEB/Extensions**

 you can view the web version of OnChain Wallet at <https://mrtnetwork.github.io/onchain_wallet/>.

```shell
gh repo clone mrtnetwork/onchain_wallet
cd onchain_wallet
flutter pub get
dart run tool/build.dart web
dart run app_builder.dart extension --chrome
dart run app_builder.dart extension --firefox
dart run app_builder.dart extension --opera
dart run app_builder.dart extension --ie
```

- **Android**

```shell
gh repo clone mrtnetwork/onchain_wallet
cd onchain_wallet
flutter pub get
dart run tool/build.dart apk
```

- **Desktop**

```shell
gh repo clone mrtnetwork/onchain_wallet
cd onchain_wallet
flutter pub get
dart run tool/build.dart --windows
dart run tool/build.dart --macos
dart run tool/build.dart --linux
```


## Community-Driven Development

OnChain Wallet is not just a wallet; it's a community-driven project. We welcome collaboration, feedback, and contributions from the community. Together, we're building a decentralized future that prioritizes security, privacy, and inclusivity.


## Contributing

Contributions are welcome! Please follow these guidelines:

- Fork the repository and create a new branch.
- Make your changes and ensure tests pass.
- Submit a pull request with a detailed description of your changes.

## Feature requests and bugs

Please file feature requests and bugs in the issue tracker.

## Get Involved

Join us on our mission to redefine the landscape of decentralized finance. Contribute to our open-source project on [GitHub](https://github.com/mrtnetwork/mrtwallet) or connect with our community on [Telegram](https://t.me/blockchain_web3_solidity).

Thank you for choosing OnChain Wallet as your trusted partner in the world of decentralized finance.

## Support

1KMRGUzRFCuR9y73gUnjxfC1Dte8Ua3vcp

bc1q92fvc5jm4k8e5wegzmhzdv72gwe43sgfnuspgzfmj7llkd8xhmusgd44qf
