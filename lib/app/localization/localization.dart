enum APPLocale { en }

class Localization {
  static const Map<APPLocale, Map<String, String>> languages = {
    APPLocale.en: {
      "wellcome": "Welcome To OnChain Wallet",
      "your_gateway_to_decentralized_world":
          "Your Gateway to Decentralized World",
      "setup": "Setup wallet",
      "use_mnemonic": "Use Existing Mnemonic",
      "generate_mnemonic": "Generate New Mnemonic",
      "enter_mne": "Enter mnemonic",
      "enter_mnemonic": "Safely Enter Your Mnemonic",
      "enter_mnemonic_desc":
          "Securely enter your mnemonic to access and manage your cryptocurrency funds.",
      "e_mnemonic":
          "Import an existing 12–24 word recovery phrase to access your wallet.",
      "enter_passphrase_desc":
          "If you have used a mnemonic passphrase to create the master key, use the following option to enter the passphrase",
      "enter_passphrase_desc2":
          " Warning: We do not store your passphrase in wallet storage or backups. The mnemonic passphrase is now required to validate the backup checksum and will also be required when restoring your backup. Please enter the passphrase if you selected one when generating your wallet.",
      "g_mnemonic": "Create a new wallet with a 12–24 word recovery phrase.",
      "invalid_mnemonic_ordering": "The entered mnemonic order is incorrect",
      "n_of_mnemonic_words": "Number of mnemonic words",
      "count_words": "___1__ Words",
      "n_word": "___1__-word",
      "generate": "Generate",
      "setup_password": "Setup password",
      "continue": "Continue",
      "p_note1":
          "Your wallet password is not stored anywhere and cannot be recovered if forgotten.",
      "p_note2":
          "Your mnemonic phrase is the only way to recover your wallet. Do not forget it!",
      "p_note3":
          "Keep your wallet password and mnemonic phrase in a safe place and never share them with anyone.",
      "p_note4":
          "If you lose your wallet password and mnemonic, you may permanently lose access to your funds.",
      "p_note5":
          "If you set a passphrase for your mnemonic, it won’t be stored in the wallet. Recovery options will only display your mnemonic phrase.",
      "e_password": "Enter password",
      "c_password": "Confirm password",
      "invalid_password": "Invalid password. password must not be empty.",
      "weak_password_validator": "Password is too weak.",
      "normal_password_desc": "Add more variety & length.",
      "strong_password_desc": "Good password strength.",
      "fair": "Fair",
      "fair_passowrd_desc": "Needs more improvement",
      "password_used_before": "This password has been used before.",
      "p_does_not_match": "Password does not match",
      "show_mnemonic_desc":
          "Please treat your mnemonic phrase with the utmost care and confidentiality. Do not share it with anyone, and ensure it remains hidden from prying eyes. Your mnemonic is the key to accessing your funds and should be kept secure at all times. Any unauthorized access may result in the loss of your assets.",
      "r_generate": "Re-generate",
      "v_mnemonic": "Verify mnemonic",
      "v_mnemonic_desc":
          "Please verify your mnemonic phrase to ensure its accuracy. Carefully enter your mnemonic words in the correct order to confirm your access to your account. This step is crucial for securing your wallet and funds.",
      "Language": "Language",
      "reset": "Reset",
      "passphrase": "Passphrase",
      "mn_password": "BIP39 passphrase",
      "enable_mnemonic_password": "Enable BIP39 passphrase",
      "password_should_not_be_empty": "Password should not be empty",
      "passphrase_should_not_be_empty": "Passphrase should not be empty",
      "wallet_data_is_invalid": "The wallet data is invalid",
      "invalid_mnemonic": "Invalid mnemonic",
      "invalid_account_details": "Invalid account details",
      "invalid_passphrase": "invalid mnemonic passphrase.",
      "close": "Close",
      "launch_the_wallet": "Launching the wallet",
      "password": "Password",
      "unlock": "Unlock",
      "generate_from_hd_wallet":
          "Creating an address from your HD wallet seed or imported keys.",
      "setup_network_address": "Setup ___1__ address",
      "setup_network_address_desc":
          "You have not set up any ___1__ account. To begin setup, please click on the 'Setup Address' button.",
      "setup_address": "Setup Address",
      "setup_addresses": "Setup Addresses",
      "choose_bitcoin_address_type": "Choose Address Type",
      "bitcoin_type_recomended":
          "We recommend creating a ___1__ address due to their enhanced security features and lower cost fees.",
      "standard_derivation": "Standard Derivation",
      "address_index": "Address index",
      "key_derivation": "Key derivation",

      "bip32_key_index_validate":
          "The key index should not be negative and should be less than 2^32 - 1.",
      "hardened_index": "Hardened key with an index of ___1__.",
      "path": "Path",
      "setup_derivation_path": "Setup Derivation path",
      "setup_derivation": "Setup Derivation",
      "generate_address": "Generate address",
      "invalid_coin": "Invalid coin",
      "to_many_accounts":
          "Too many accounts, please use custom path derivation",
      "incorrect_network": "Incorrect network",
      "invalid_provider_infomarion": "Invalid provider information.",
      "invalid_bip_key_index": "invalid bip proposal derivation index",
      "address_already_exist": "Address already exist",
      "generating_new_addr": "Generating new address",
      "copied_to_clipboard": "Copied to cliboard.",
      "copied_to_clipboard_faild": "Copy action unsuccessful.",
      "copy_to_clipboard": "Copy to cliboard.",
      "selected": "Selected",
      "switch_account": "Switch account",
      "new_address": "New Address",
      "request_error": "The request encountered an error",
      "invalid_request_type":
          "Invalid type, request result can be string, list, or map",
      "export_mnemonic": "Export mnemonic",
      "export_mnemonic_desc":
          "Export your mnemonic for secure backup and recovery",
      "export_mnemonic_desc2":
          "Safeguard your cryptographic assets by securely storing your mnemonic. Use a trusted hardware wallet, secure offline storage, or a reputable password manager to ensure the protection of your valuable information. Remember, the safety of your assets starts with the responsible management of your mnemonic and passphrase.",
      "export": "Export",
      "mnemonic_security_des1":
          "Make sure nobody can access or view your mnemonic, as it serves as a critical key to your account.",
      "mnemonic_security_des2":
          "Refrain from using the copy icon, as there is a risk of mnemonic leakage through apps that may monitor the copy function.",
      "mnemonic_security_des3":
          "Do not take pictures of your mnemonic, as storing it in image format is not a safe practice and can compromise its security.",
      "show_mnemonic": "Show mnemonic",
      "backup_mnemonic": "Backup mnemonic",
      "b_using_web3_secret_defination": "Backup using the Web3 SSD.",
      "about_web3_secret_defination":
          "You can learn more about saving with Web3 Secret Storage Definition version 3 by following this",
      "about_web3_defination_desc1":
          "At present, only your mnemonic is stored in the Web3 storage definition.",
      "encoding": "Encoding type",
      "backup_encoding_desc":
          "This type of backup can only be decoded by the OnChain Wallet application.",
      "create_backup": "Create a backup",
      "creating_backup_desc":
          "Creating a backup, this process may take a few seconds",
      "backup_desc1":
          "Kindly save the backup text in a text file and securely store it.",
      "backup_desc2":
          "Only the current wallet password can decrypt the backup. If the password is forgotten, the file cannot be opened.",
      "restore_backup": "Restore backup",
      "restore_backuo_desc": "Recover wallet from backup",
      "enter_backup": "Input backup text.",
      "bcakup_validator":
          "The backup must be a valid bytes as hexadecimal string.",
      "input_backup_password": "Input backup password.",
      "password_validator_desc": "Password should not be empty.",
      "clipboard_empty": "Clipboard is empty.",
      "invalid_bitcoin_address_type": "Invalid BIP49 address type.",
      "retrieving_transaction": "Retrieving Transactions. Please Wait.",
      "recipients": "Recipients",
      "recipient": "Recipient",
      "tap_to_select": "Tap to select",
      "receiver_address": "Receiver address",
      "receiver_address_desc":
          "Input the recipient's address in the field below.",
      "address": "Address",
      "invalid_network_address":
          "The provided address is not valid for ___1__ network.",
      "list_of_recipients": "List of recipients",

      "transaction_fee": "Transaction fee",
      "replace_by_fee": "Replace by fee",
      "decimal_int_validator":
          "Please enter the amount as a decimal or an integer",
      "int_validator": "Please enter the amount as an integer",
      "price_less_than": "The value must be less than ___1__",
      "price_greather_than": "The amount must be greater than ___1__",
      "receiver": "Receiver",
      "setup_output_amount": "Setup output amount",
      "amount": "Amount",
      "setup_custom_fee": "Setup fee",
      "setup_transaction_fee": "Setup transaction fee",
      "account_not_found": "Account not found",
      "sign_transaction": "Sign transaction",
      "signing_tx_desc":
          "The wallet is requesting you to sign the data with the following accounts.",
      "signing_tx_desc1":
          "Kindly provide your wallet password to sign the data (Transaction, Message, etc.). otherwise, close the page.",
      "wallet_is_locked": "Wallet is locked.",
      "to_many_request": "Too many requests",
      "user_rejected_signing_request":
          "The transaction signing request has been declined.",
      "incorrect_wallet_status":
          "The wallet is currently unprepared for this operation.",
      "select_account": "Select account",
      "send_transaction": "Send transaction",

      "multi_sig_addr": "Multi-signature address",
      "establishing_multi_sig_addr": "Establishing a multi-signature address.",
      "multi_sig_desc":
          "This feature is specifically crafted to enhance the security of your funds. It involves creating an account with the public keys of multiple chosen accounts. This address serves as an added layer of security, ensuring that even if one of your private keys is compromised, your funds remain both accessible and secure.",
      "mutli_sig_desc2":
          "To sign unspent transactions for this address, it requires all the corresponding private keys associated with the public keys used in its creation",
      "multi_sig_desc3":
          "The transaction fee for this address increases by 10% with the inclusion of each additional public key.",
      "multi_sig_desc4":
          "The loss of private keys associated with added addresses will lead to a loss of funds.",
      "list_of_public_keys": "List of Public Keys",
      "list_of_signers": "List of signers",
      "multi_sig_desc5":
          "By selecting the 'add' option from your accounts, you can obtain the public key of the chosen account to create the address.",
      "public_key_already_exist": "Public key already exist",
      "threshold_configuration": "Threshold configuration",

      // "threshhold_desc":
      //     "Specify the transaction signature threshold. This threshold indicates the number of signatures required to confirm the transaction. For example, setting it to 5 means that the transaction requires 5 signatures.",

      "threshold": "Threshold",
      "signer_wight_desc1": "The weight assigned to the signer.",
      "weight": "Weight",
      "threshhold_desc2":
          "The signer's weight must not surpass the specified threshold.",
      "threshhold_desc3":
          "The cumulative weight of the signatories must meet the specified threshold.",
      "review_address": "Review address",
      "review_address_desc":
          "Please ensure that important and critical information about the multi-signature account, including the public key and order used, the weight assigned to the added public key, as well as the script details, is in a safe and accessible place. This is vital to protect your funds.",
      "public_keys_and_weight_of_each":
          "Public keys and their respective weights",
      "public_key": "Public key",
      "multi_sig_script": "Multi-signature script",
      "address_script": "Address script",
      "type_of_address": "Type of address",
      "backup_as_text": "Backup as text",
      "address_details2": "Details for a Multi-Signature Address.",
      "address_backup_desc1":
          "Kindly preserve the following text in a secure location to ensure you have the essential information for recreating the address when needed",
      "address_details": "Address details",
      "address_added_to_accounts":
          "The address has been successfully added to your accounts.",
      "unavailable_multi_sig_public_key":
          "The public key is unavailable for this multi-signature address.",
      "switch_network": "Switch network",
      "erase_wallet": "Erase wallet",
      "security": "Security",
      "multi_signature": "Multi-signature",
      "export_private_key": "Export private key",
      "remove_account": "Remove account",
      "comperessed_public_key": "Compressed public key",
      "uncomperessed_public_key": "Uncompressed public key",
      "extended_public_key": "Extended public key",
      "private_key_is_not_available": "The private key is not available",
      "export_private_key_desc":
          "Remember, the security of your private key is crucial for safeguarding your digital assets. Take these precautions seriously to minimize the risk of unauthorized access and potential loss of funds.",
      "private_key": "Private key",
      "extended_private_key": "Extended private key",
      "remove_account_desc":
          "Remove the account from the network accounts list.",
      "remove_accounts_desc1":
          "Prior to account deletion, kindly ensure you have securely backed up the private key associated with this account.",
      "enter_wallet_password_to_continue":
          "Please enter your wallet password to continue.",
      "wallet_password": "Wallet password",
      "backup_private_key_desc":
          "To generate a backup, kindly proceed to the 'Extract Private Key' page.",
      "remove_account_pls_wait": "Removing account. please wait.",
      "account_deleted": "Account successfully deleted.",
      "import_account": "Account Import",
      "inidicate_type_of_key": "Indicate the type of your private key.",
      "import_account_desc1":
          "The new account should align with the app's coin and network settings.",
      "import_account_desc2":
          "Please enter your private key, extended key, or Wallet Import Format (WIF) to proceed.",
      "key_type": "Key type",
      "imported": "Imported",
      "importing_key_pls_wait": "Importing key. please wait.",
      "setup_new_address": "Setup new address",
      "address_imported_desc1":
          "Key successfully imported. Please proceed to the 'New Address' option in the address menu to create a new address.",
      "hd_wallet": "HD Wallet",
      "imported_key": "Imported key",

      "not_support_multisig_derivation":
          "Derivation from a multisig address is not supported.",
      "p2wsh_one_of_one_desc":
          "Generated from a standard P2WSH one-of-one multisig script",
      "non_derivation": "Non-derivation",
      "import_key_derivation_desc2":
          "The address is created without derivation.",
      "imported_at": "Imported at ___1__",
      "address_added_success":
          "The address has been successfully added to the wallet",
      "generate_new_address": "Generate new address",
      "spendable_amount": "Spendable amount",
      "utxos": "Unspent transactions",
      "choose_all": "Choose all.",
      "setup_memo": "Setup memo",
      "tap_to_add_memo": "Tap to add a memo.",
      "character_length_min_validator":
          "The character count must exceed ___1__ letters.",
      "character_length_max_validator":
          "The character count must be fewer than ___1__ letters.",
      "transaction_memo": "Transaction memo",
      "memo_desc1":
          "The transaction fee escalates based on the volume of entered text.",
      "memo": "Memo",
      "share_as_file": "Share as file",
      "file_verification_fail":
          "We couldn't verify the file's integrity. It may be corrupted or tampered with. please try again",
      "show_barcode": "Show barcode",
      "change_password": "Change password",
      "wallet_password_desc":
          "Strengthen your wallet's security with a password update.",
      "change_password_desc":
          "If you've utilized the program's backup feature, the new password won't unlock previous backups. Ensure you create a new backup or remember the current backup password to maintain access.",
      "password_changed": "Wallet password successfully updated.",
      "changing_password": "Password update in progress. Please wait.",
      "enter_new_password": "New Password",
      "delete_wallet": "Delete Wallet",
      "delete_wallet_desc":
          "Deleting the wallet will irreversibly erase all associated data. To regain access, you'll need either the mnemonic or the account's private key. Make certain you have a secure backup in place before initiating this irreversible process.",
      // "delete_wallet_confirmation": "Wallet Deletion Confirmation",
      "deleting_wallet": "Deleting wallet. Please wait.",
      "wallet_deleted_success": "Wallet Deleted Successfully",
      "export_security_phrase": "Export and backup Seed Phrase",
      "wallet_preferences": "Wallet Preferences",
      "clear_wallet_data": "Clear Wallet Data",
      "two_minute": "Two Minute",
      "five_minute": "Five Minute",
      "ten_minute": "Ten Minute",
      "thirty_minute": "Thirty Minute",
      "automatic_loc": "Automatic lock",
      "customize_wallet_settings": "Customize Wallet Settings",
      "update_settings": "Update setting",
      "updating": "Updating",
      "setting_update_successfully": "Settings updated successfully",
      "import_private_key": "Import private key",
      "view_on_explorer": "View on Explorer",
      "lock_wallet": "Lock wallet",
      "dark_mode": "Dark mode",
      "primary_color_palette": "Primary Color Palette",
      "select_color_from_blow":
          "Select the primary color for the program from the following options:",
      "color_changed": "The primary color has been successfully modified.",
      "wallet_in_progress_wait":
          "The wallet is in processing, please await completion.",
      "request_cancelled": "The request was cancelled",
      "invalid_request": "Invalid request",
      "settings": "Settings",
      "about_onchain_wallet": "About OnChain Wallet",
      "active": "Active",
      "network_all_request_error": "All requests have encountered errors",
      "network_some_request_error": "Some requests have encountered errors",
      "service_provider": "Service provider",
      "choose_provider": "Choose a provider.",
      "select_provider_desc": "Select a provider from the options below",
      "backup_wallet": "Create a wallet backup.",
      "backup_wallet_desc":
          "Safeguard your crypto assets by securely storing essential elements such as mnemonic phrases, imported private keys, addresses, and more through a reliable web3 definition storage solution. This ensures a protected backup mechanism for your wallet's crucial information.",
      "backup": "Backup",
      "backup_wallet_desc1":
          "This backup can only be decrypted using this application.",
      "invalid_wallet_backup": "Invalid wallet backup.",
      "invalid_wallet_backup_checksum":
          "Checksum verification failed: Invalid passphrase.",
      "unsupported_backup_content": "Unsupported backup content",
      "wrong_backup_password": "Wrong backup password",
      "adjust_app_brightness": "Adjust App Brightness",
      "define_primary_of_app":
          "Define the primary color scheme for the application",
      "manage_imported_key": "Administer Imported Keys",
      "manage_key_desc1": "Delete Imported Keys from Your Wallet",
      "retrieving_imported_keys_wait": "Retrieving Imported Keys. Please Wait.",
      "no_imported_key_found": "No Imported Private Keys Detected",
      "manage_key_desc2":
          "If the key is removed, and an address has already been generated with the corresponding account, it will become inaccessible in the wallet.",
      "inventory_keys": "Keys Inventory",
      "remove": "Remove",
      "wif": "WIF (Wallet Import Format)",
      "deleting_key": "Deleting Key. Please Wait.",
      "ripple": "Ripple",
      "classic_address": "Classic address",
      "x_address": "X-Address",
      "x_address_desc":
          "The new 𝗫-address format aims to replace the use of a separate destination tag.",
      "tag": "Tag",
      "enter_tag_desc": "The tag must be a value between 0 and 2^32-1.",
      "tag_validator": "The tag must be a value between 0 and 2^32-1.",
      "tap_to_choose_address": "Tap to choose address",
      "invalid_contact_details": "Contact details are invalid",
      "contacts": "Contacts",
      "add_to_contacts": "Add to Contacts",
      "contact_name_validator":
          "The contact name must be at least 3 characters long",
      "name_of_contact": "Name of contact",
      "contact_desc_1":
          "The contact will be saved in the ___1__ network contact list and will only be available within this network.",
      "new_contact": "New Contact",
      "contact_already_exist": "Contact already exists",
      "contact_saved": "Contact saved successfully",
      "tap_to_enter_amount": "Tap to enter amount",
      "retrieving_network_condition":
          "Retrieving network condition. Please Wait.",
      "memo_data": "Memo data",
      "memo_format": "Memo format",
      "memo_type": "Memo type",
      "memos": "Memos",
      "memo_desc": "You can add multiple notes up to 1 KB to this transaction.",
      "tap_to_create_memo": "Tap to create memo",
      "create_memo": "Create memo",

      "memos_field": "Memos Field",
      "memo_data_desc":
          "Arbitrary hex value, conventionally containing the content of the memo.",
      "memo_format_desc":
          "Hex value representing characters allowed in URLs. Conventionally containing information on how the memo is encoded",
      "memo_type_desc":
          "Hex value representing characters allowed in URLs. Conventionally, a unique relation (according to RFC 5988) that defines the format of this memo.",
      "tap_to_input_value": "Tap to input the value",
      "empty_desc":
          "If you submit an empty value, it will be recorded. To cancel, please close the page.",
      "hex_desc":
          "Inputs must be in hexadecimal format. If the entered input is not in hexadecimal, the program will convert it to hexadecimal.",
      "setup_input": "Setup input",
      "value_is_empty": "The value is empty.",
      "trust_set": "TrustSet",
      "tust_line_desc": "Create a trust line for holding tokens.",
      "issuer": "Issuer",
      "currency": "Currency",
      "tap_to_enter_currency_code": "Tap to enter the currency code",

      "regular_exception_validate_desc":
          "The input must match the following regular expression ___1__",
      "enter_valid_number": "Please enter a valid number",
      "minium_numnber_validator":
          "The input number should not be less than ___1__",
      "maximum_number_validator":
          "The input number should not be greater than ___1__",
      "trust_set_quality_in": "Quality In",
      "trust_set_quality_out": "Quality out",
      "trust_set_quality_in_desc":
          "Value incoming balances on this trust line at the ratio of this number per 1,000,000,000 units. A value of 0 is shorthand for treating balances at face value.",
      "trust_set_quality_out_desc":
          "Value outgoing balances on this trust line at the ratio of this number per 1,000,000,000 units. A value of 0 is shorthand for treating balances at face value",
      "trust_set_fields": "TrustSet Fields",
      "trust_set_flags": "TrustSet Flags",
      "account": "Account",
      "insufficient_balance_error":
          "Insufficient balance: You need ___1__ to complete this transaction.",
      "account_set": "AccountSet",
      "account_set_desc":
          "An AccountSet transaction modifies the properties of an account in the XRP Ledger.",
      "domain": "Domain",
      "domain_desc":
          "The domain that owns this account, as a string of hex representing the ASCII for the domain in lowercase.",
      "account_set_fields": "AccountSet Fields",
      "character_length_validator_desc":
          "The ___1__ length cannot exceed ___2__ characters (___3__ bytes).",
      "email_hash": "Email Hash",
      "ripple_email_hash_desc":
          "An arbitrary 128-bit value. Conventionally, clients treat this as the md5 hash of an email address to use for displaying a Gravatar  image.",
      "ripple_message_key": "Message key",
      "ripple_message_key_desc":
          "Public key for sending encrypted messages to this account.",
      "ripple_message_key_desc2":
          "it must be exactly 33 bytes, with the first byte indicating the key type: 0x02 or 0x03 for secp256k1 keys, 0xED for Ed25519 keys. To remove the key, use an empty value",
      "ripple_public_key":
          "Please enter a valid secp256k1 or Ed25519 (Ripple) public key.",
      "ripple_nft_token_minter": "NFT token minter",
      "ripple_nft_token_minter_desc":
          "Another account that can mint NFTokens for you.",
      "ripple_transfer_rate": "Transfer rate",
      "ripple_transfer_rate_desc":
          "The fee to charge when users transfer this account's tokens, represented as billionths of a unit.",
      "ripple_transfer_rate_desc2":
          "Cannot be more than 2000000000 or less than 1000000000, except for the special case 0 meaning no fee",
      "ripple_validate_transfer_rate":
          "Please enter a valid number for the transfer rate.",
      "ripple_tick_size": "Tick size",
      "ripple_tick_size_desc":
          "Tick size to use for offers involving a currency issued by this address",
      "ripple_tick_size_desc2":
          "The exchange rates of those offers is rounded to this many significant digits. Valid values are 3 to 15 inclusive, or 0 to disable.",
      "ripple_validate_tick_size":
          "Please enter a valid number for the tick size.",
      "ripple_enable_account_set_flags": "Enable account set flags",
      "ripple_disable_account_set_flags": "Disable account set flags",
      "invalid_balance": "Invalid balance information",
      "network_support_token_error":
          "Token issuance not supported by the network.",
      "network_support_nft_error": "NFT issuance not supported by the network.",
      "invalid_token_information": "Invalid token information",
      "invalid_nft_information": "Invalid NFT information",
      "token_already_exists": "Token already exists.",
      "nfts_already_exists": "NFTs already exists.",
      "services": "Services",
      "tokens": "Tokens",
      "no_tokens_found": "No tokens found in the account.",
      "monitor_my_tokens": "Monitor my tokens.",
      "add_token": "Add Token",
      "fetching_account_token_please_wait":
          "Retrieving account tokens. please wait.",
      "no_items_found": "No items found.",
      "yes": "Yes",
      "no": "No",
      "add_token_to_your_account": "Add token to your account?",
      "remove_token_from_account": "Remove Token from Your Account?",
      "remove_token": "Remove token",
      "token_transfer": "Token Transfer",
      "token_info": "Token info",
      "manage_tokens": "Manage Tokens",
      "add_or_remove_tokens": "Add or Remove Tokens from Your Account",
      "nfts": "NFTs",
      "manage_nfts": "Manage NFTs",
      "manage_nfts_desc":
          "Administer NFTs: Burn, Manage, Create, or Cancel Offers",
      "serial": "Serial",
      "nfts_id": "NFTs ID",
      "uri": "URI",
      "ripple_nftokentaxon":
          "	An arbitrary taxon, or shared identifier, for a series or collection of related NFTs",
      "ripple_mint_token_issuer":
          "The issuer of the token, if the sender of the account is issuing it on behalf of another account.",
      "ripple_mint_token_transfer_rate":
          "The value specifies the fee charged by the issuer for secondary sales of the NFToken, if such sales are allowed",
      "nft_token_uri":
          "The contents could decode to an HTTP or HTTPS URL, an IPFS URI, a magnet link",
      "flags": "Flags",
      "nft_flags_field_desc":
          "Transactions of the NFTokenMint type support additional values in the Flags field,",
      "ripple_nfttoken_fields": "NFTokenMint Fields",
      "ripple_nftoken_burn_id":
          "The NFToken to be removed by this transaction.",
      "token_id": "Token ID",
      "owner": "Owner",
      "ripple_nftoken_burn_owner":
          "The owner of the NFToken to burn. Only used if that owner is different than the account sending this transaction.",
      "ripple_nftoken_burn_fields": "NFTokenBurn Fields",
      "ripple_create_offer_owner":
          "Who owns the corresponding NFToken. If the offer is to buy a token, this field must be present and it must be different than the Account field (since an offer to buy a token one already holds is meaningless)",
      "expiration": "Expiration",
      "ripple_create_offer_expiration":
          "Indicates the time after which the offer will no longer be valid.",
      "destination": "Destination",
      "ripple_create_offer_destination":
          "If present, indicates that this offer may only be accepted by the specified account.",
      "ripple_create_nft_offer_id":
          "	Identifies the NFToken object that the offer references.",
      "token_issuer": "Generally, the account that issues this token.",
      "token_amount": "Token Amount",
      "token_currency": "Arbitrary currency code for the token. Cannot be XRP.",
      "setup_currency_amount": "Setup currency amount",
      "nft_offer_flag_desc":
          "Transactions of the NFTokenCreateOffer type support additional values in the Flags field",
      "ripple_nftoken_create_offer_fields": "NFTokenCreateOffer fields",
      "ripple_nftoken_accept_offer_fields": "NFTokenAcceptOffer fields",
      "ripple_accept_offer_sell_offer":
          "Identifies the NFTokenOffer that offers to sell the NFToken",
      "ripple_accept_offer_buy_offer":
          "Identifies the NFTokenOffer that offers to buy the NFToken.",
      "ripple_accept_offer_broker_fee":
          "specifies the amount that the broker keeps as part of their fee for bringing the two offers together; the remaining amount is sent to the seller of the NFToken being bought.",
      "ripple_nftoken_cancel_offer_fields": "NFTokenCancelOffer fields",
      "ripple_cancel_nft_token_nftoken_offers":
          "An array of IDs of the NFTokenOffer objects to cancel (not the IDs of NFToken objects, but the IDs of the NFTokenOffer objects)",
      "ripple_escrow_create_fields": "EscrowCreate Fields",
      "ripple_escrow_create_amount":
          "	Amount of XRP to deduct from the sender's balance and escrow.",
      "ripple_escrow_create_destionation": "Address to receive escrowed XRP.",
      "ripple_escrow_create_cancel_after":
          "This value is immutable; the funds can only be returned to the sender after this time.",
      "ripple_escrow_create_finish_after":
          "when the escrowed XRP can be released to the recipient. This value is immutable, and the funds can't be accessed until this time.",
      "condition": "Condition",
      "ripple_escrow_create_condition":
          "if this condition is fulfilled. If the condition is not fulfilled before the expiration time specified in the CancelAfter field, the XRP can only revert to the sender.",
      "ripple_escrow_finish_fields": "EscrowFinish Fields",
      "ripple_escrow_finish_owner":
          "Address of the source account that funded the held payment.",
      "ripple_escrow_finish_sequence":
          "	Transaction sequence of EscrowCreate transaction that created the held payment to finish.",
      "ripple_escrow_finish_condition":
          "Hex value matching the previously-supplied of the held payment.",
      "ripple_escrow_finish_fulfillment":
          "Hex value of the fulfillment matching the held payment's Condition.",
      "ripple_escrow_cancel_fields": "EscrowCancel Fields",
      "ripple_escrow_cancel_owner":
          "Address of the source account that funded the escrow payment.",
      "ripple_escrow_cancel_offer_sequence":
          "Transaction sequence (or Ticket number) of EscrowCreate transaction that created the escrow to cancel.",
      "ripple_trust_set_flags":
          "Transactions of the TrustSet type support additional values in the Flags field, as follows:",
      "invoiceid": "InvoiceID",
      "ripple_payment_invoiceid":
          "Arbitrary 256-bit hash representing a specific reason or identifier for this payment.",
      "payment_flags": "Payment Flags",
      "ripple_payment_flags":
          "Transactions of the Payment type support additional values in the Flags field, as follows",
      "ripple_accept_offer_desc":
          "The NFTokenAcceptOffer transaction is used to accept offers to buy or sell an NFToken.",
      "ripple_nftoken_burn_desc":
          "The NFTokenBurn transaction is used to remove a NFToken object from the NFTokenPage in which it is being held, effectively removing the token from the ledger (burning it).",
      "ripple_nftoken_cancel_offer_desc":
          "The NFTokenCancelOffer transaction can be used to cancel existing token offers created using NFTokenCreateOffer.",
      "ripple_create_nftoken_offer_desc":
          "Creates either a new Sell offer for an NFToken owned by the account executing the transaction, or a new Buy offer for an NFToken owned by another account.",
      "ripple_mint_nftoken_desc":
          "The NFTokenMint transaction creates a non-fungible token and adds it to the relevant NFTokenPage object of the NFTokenMinter as an NFToken object",

      "ripple_escrow_cancel_desc": "Return escrowed XRP to the sender.",
      "ripple_escrow_create_desc":
          "Sequester XRP until the escrow process either finishes or is canceled.",
      "ripple_escrow_finish_desc":
          "Deliver XRP from a held payment to the recipient.",

      "fulfillment_desc":
          "Crypto condition fulfillment refers to the automated execution of predefined conditions in blockchain-based smart contracts, ensuring trustless and transparent outcomes without the need for intermediaries.",
      "create_random_fulfillment": "Create random fulfillment.",
      "fulfillment": "Fulfillment",
      "fulfillment_desc2":
          "Ensure to securely save both fulfillment and conditions, as they are essential for completing transactions in the escrow process.",
      "apply_for_condition": "Apply for condition.",
      "saved_fulfillment_desc":
          "Are you certain that the fulfillment and conditions have been securely saved?",
      "key_algorithm": "Key algorithm",
      "key_algorithms": "Key algorithms",
      "invalid_ripple_privatekey_algorithm":
          "Invalid Ripple private key encryption algorithm.",
      "coin_support_derivation_desc":
          "Selected coin only supports hardened indices.",
      "cannot_export_public_key": "Unable to export public key.",
      "regular_key": "RegularKey",
      "ripple_regular_key_desc":
          "A SetRegularKey transaction assigns, changes, or removes the regular key pair associated with an account.",

      "ripple_regular_key_field_desc":
          "A XRP Address that indicates the regular key pair to be assigned to the account. If omitted, removes any existing regular key pair from the account. Must not match the master key pair for the address.",
      "ripple_signer_list_fields": "SignerListSet Fields",
      "ripple_set_signer_list_desc":
          "The SignerListSet transaction creates, replaces, or removes a list of signers that can be used to multi-sign a transaction. This transaction type was introduced by the MultiSign amendment",
      "ripple_signer_quorum_desc":
          "A target number for the signer weights. A multi-signature from this list is valid only if the sum weights of the signatures provided is greater than or equal to this value. To delete a signer list, use the value 0.",
      "ripple_signer_entries_desc":
          "Array of SignerEntry objects, indicating the addresses and weights of signers in this list. This signer list must have at least 1 member and no more than 32 members.",
      "ripple_signer_entery": "Signer Entry",
      "ripple_signer_entery_desc":
          "Each member of the SignerEntries field is an object that describes that signer in the list",
      "ripple_signer_enteris_fields": "SignerEntries fields",

      "ripple_signer_weight": "SignerWeight",
      "ripple_signer_weight_desc":
          "The weight of a signature from this signer. A multi-signature is only valid if the sum weight of the signatures provided meets or exceeds the signer list's SignerQuorum value.",
      "ripple_wallet_locator": "WalletLocator",
      "ripple_signer_entry_wallet_locator_desc":
          "Arbitrary hexadecimal data. This can be used to identify the signer or for other, related purposes.",
      "hash256_validator":
          "Invalid hash256: The hash256 value must be a hexadecimal string with a length of 64 characters",
      "setup_signer": "Setup signer",

      "disable_master_key_addr":
          "Master key disablement is active. Please utilize a multi-signature account for signing or creating transactions.",
      "ripple_multi_sig_address_desc":
          "Ripple accommodates both multi-signature and regular key signature transactions.",
      "ripple_multi_sig_account_desc":
          "Kindly input the address of the primary account supporting either multi-signature or regular key transactions.",
      "retrieving_account_information":
          "Retrieving account information. Please Wait.",
      "get_account_information": "Get account information",
      "ripple_mutlti_sig_address_not_found":
          "The account could not be found or does not support the multi-signature feature",
      "ripple_multi_sig_address_desc2":
          "Please choose either a signer list or a regular key to create a multi-signature address.",
      "signer_list": "Signer list",
      "account_does_not_support_feature":
          "The account does not support this feature",
      "multi_sig_feature_type": "Multi-signature Feature Type",
      "signerquorum": "SignerQuorum",
      "ripple_multi_sig_addres_signer_list_desc":
          "Please choose the required number of signers, matching the Signer Quorum, If the desired account is not in your account list, you must first add it to your wallet through the settings.",
      "account_does_not_match_with_signer_account":
          "The account does not match with the signer account.",
      "ripple_multi_sig_addres_signer_list_desc2":
          "Kindly tap each address to confirm the availability of its private key",
      "ripple_multi_sig_regular_key_desc":
          "The account has a regular key. To send and sign the transaction, you need the private key of the regular key address",
      "its_not_multisig_account": "It is not a multi-signature account",
      "ripple_account_signature_updated_desc":
          "The account signature settings have been updated. To ensure proper functionality, we recommend removing the account from your list and adding it again with the revised settings.",
      "accounts": "Accounts",
      "private_keys": "Private keys",
      "private_keys__signing_access_desc":
          "The data requires the use of the following private keys to complete the signing process.",
      "amount_for_each_output":
          "Kindly input the preferred quantity for each output.",
      "cancel": "Cancel",
      "account_name": "Account name",
      "setup_or_update_account_name": "Establish or Refresh Account Name",
      "remove_account_name_desc":
          "If you wish to remove the account name, please confirm by entering an empty text.",
      "disable_standard_derivation":
          "You can manually create a BIP32 path to generate an address by disabling the standard derivation.",
      "transfer": "Transfer",
      "slow": "Slow",
      "normal": "Normal",
      "high": "High",
      "max_base_fee": "Max base fee",
      "max_priority": "Max priority",
      "gas_price": "Gas Price",
      "gwei": "GWEI",
      "eip_1559_gas_fee": "EIP-1559 Gas Fee",
      "legacy_gas_fee": "Legacy Gas Fee",
      "what_is_max_fee":
          "Max base fee refers to the upper limit or maximum value that the base fee component of a transaction can reach within the Ethereum network",
      "what_is_prority_fee":
          "the Priority Fee in Ethereum, especially in the context of EIP-1559, is an extra amount that users can include in their transactions to increase the likelihood of miners including them in the next block.",
      "eth_fee_desc":
          "The transaction's true cost is determined by multiplying the maximum base fee by the specified gas limit.",
      "eth_legacy_fee_desc":
          "The transaction's true cost is determined by multiplying the gas price by the specified gas limit.",
      "gas_limit": "Gas limit",
      "gas_limit_desc":
          "is the unit used to measure the amount of computational effort required to execute operations or smart contracts. Each operation consumes a certain amount of gas, and the gas limit determines the total computational resources available for the transaction.",
      "gas_limit_validator":
          "The gas limit must be set to a value greater than zero.",
      "gas_limit_helper":
          "The gas limit is below the current network conditions.",
      "prority_fee_validator":
          "The priority fee should be a non-negative decimal value.",
      "max_base_fee_validator":
          "The Max base fee should be a non-negative decimal value.",
      "gas_price_fee_validator":
          "The Gas price should be a non-negative decimal value.",
      "max_base_fee_helper1":
          "The Max base fee is below the current network conditions.",
      "gas_price_fee_helper1":
          "The Gas price is below the current network conditions.",
      "max_base_fee_helper2":
          "The Max base fee is higher than the current network conditions.",
      "gas_price_fee_helper2":
          "The Gas price is higher than the current network conditions.",
      "max_priority_helper1":
          "The Max priority is below the current network conditions.",
      "max_priority_helper2":
          "The Max priority is higher than the current network conditions.",
      "input_the_amout": "Input the transaction amount in the field below",
      "import_token": "Import Token",
      "contract_address": "Contract address",
      "import_erc20_token": "Import ERC-20 token",
      "import_trc20_token": "Import TRC-20 token",
      "import_erc20_desc":
          "Input the contract address of your token to import it into your account.",
      "add_to_my_account": "Add to My Account",
      "retrieving_contract_detauls":
          "Retrieving smart contract information. Please Wait.",
      "smart_contract_not_found":
          "No smart contract found; please verify the contract address.",
      "import_new_token": "Import new token",
      "transfer_erc20": "Transfer ERC-20",
      "transfer_trc20": "Transfer TRC-20",
      "multi_sig_account_does_not_supported":
          "Your account lacks the necessary permissions to initiate this transaction. Please utilize the multi-signature feature for authorization.",
      "total_burn": "Total burn",
      "fee_limit": "Fee Limit",
      "default": "Default",
      "custom": "Custom",
      "burn": "Burn",
      "bandwidth": "Bandwidth",
      "energy": "Energy",
      "trx_burned_for_resource": "Trx burned for resource",
      "tron_fee_limit_desc":
          "The fee limit represents the maximum amount of energy or bandwidth that a user is allowed to consume for a specific transaction",
      "low_fee_limit_desc":
          "The specified fee limit is insufficient for the operation's resource requirements.",
      "erc20": "ERC-20",
      "trc20": "TRC-20",
      "trc10": "TRC-10",
      "update_account_permission": "Update account permission",
      "permissions": "Permissions",
      "tron_permission_desc":
          "Choose the permission you wish to modify or remove.",
      "permission_name": "Permission name",
      "input_the_permission_name": "Input the permission name",
      "operations": "Operations",
      "tron_operations_desc":
          "This permission grants access to the following operations.",
      "all_operations": "All Operations",
      "tron_threshhold_desc":
          "Operation is permitted only when the combined weights of the involved signatures surpass the specified value",
      "tron_permission_key": "Signers (Key)",
      "tron_permission_key_desc":
          "The accounts and weights that all own the permission, 5 keys at most.",
      "tap_to_input_new_signer": "Tap to input new signer",
      "signer": "Signer",
      "signer_already_exist": "The signer already exist",
      "new_active_permission": "New active permission",
      "update_permission": "Update permission",
      "remove_permission": "Remove permission",
      "tron_signer_validator_desc":
          "The number of signers should not exceed 5.",
      "tron_signer_validator_witness_desc":
          "The required number of witness signers is 1.",
      "tron_permission_threshhold_validator":
          "The cumulative weight of the signatories must meet the specified threshold.",
      "update_account_permissions": "Update the account's permission.",
      "tron_multi_sig_desc":
          "Tron supports multi-signature transactions, allowing you to select a specific permission and initiate transactions corresponding to that chosen permission.",
      "tron_multi_sig_desc2":
          "Kindly input the Tron address to which you intend to send transactions.",
      "tron_multi_sig_select_permission":
          "Kindly choose the permission you desire.",
      "tron_multi_sig_addres_threshhold":
          "Please choose the required number of signers, matching the threshhold, If the desired account is not in your account list, you must first add it to your wallet through the settings.",
      "tron_account_permission_not_access_desc":
          "The account permission has been modified, or the current authorization does not grant access to initiate this type of transaction.",
      "tron_stack_v2": "Stake2.0",
      "tron_unstack_v2": "Unstake2.0",
      "frozen_balance": "Frozen balance",
      "unfreeze_balance": "Unfreeze balance",
      "trx_stake_amount": "TRX stake amount",
      "trx_unstake_amount": "The amount of TRX to unstake",
      "resource": "Resource",
      "trx_stake_type": "TRX stake type",
      "stacke_amount": "Stake amount",
      "stacking_balance_in_your_account": "Staking balance in your account",
      "delegated_resource": "Delegate Resource",
      "delegate_resource_desc":
          "Delegate bandwidth or energy resources to other accounts",
      "delegatable_amount": "Delegatable  amount",
      "delegatable_amount_desc": "The amount of delegatable resource share",
      "resource_delegated_amount": "Resource delegate amount",
      "resource_receiver_address": "Resource receiver address",
      "lock": "Lock",
      "lock_period": "Lock period",
      "tron_delegate_resource_lock_desc":
          "Whether to lock the resource delegation, enable means locked the delegation, the delegating cannot be canceled within the period specified by the lock period",
      "tron_delegate_lock_time_desc":
          "Lock time,The unit is block interval(3 seconds), indicates the time of how many blocks which the delegation will be locked",
      "tron_delegate_lock_time_desc2":
          "Lock time,The unit is block interval(3 seconds), indicates the time of how many blocks which the delegation will be locked. Only when lock is true, this field is valid. If the delegate lock period is 1 day, the lock_period is: 28800. The minimum value of lock_period is the remaining lock period of this type of resource that was delegated last time, and the maximum value is 864000 (30 days). If lock is true and lock_period is not set or set to 0, lock_period will be set to the default value 86400 (3 days) automatically",
      "retrieving_resources": "Retrieving Resources. Please Wait.",
      "balance": "Balance",
      "undelegated_balance_desc":
          "Amount of TRX staked for resources to be delegated",
      "undelegated_resource": "UnDelegate Resource",
      "undelegated_resource_desc":
          "Cancel the delegation of bandwidth or energy",
      "url": "Url",
      "create_witness": "Create Witness",
      "create_witness_desc": "Apply to become a witness.",
      "tron_create_witness_url_desc": "The website URL of the SR node",
      "update_witness": "Update witness",
      "update_witness_desc": "Edit the URL of the witness's official website.",
      "permission_type": "Permission type",
      "update_account": "Update account",
      "account_name_desc": "name of the account",
      "modify_account_name": "Modify account name",
      "key_name": "Key name",
      "import_private_key_key_name_desc":
          "A distinctive identifier for enhanced key differentiation.",
      "import_evm_network": "Import ethereum network",
      "import": "Import",
      "import_new_network": "Import new network",
      "import_new_network_desc1":
          "Providing an incorrect or malicious RPC endpoint can compromise the security of your wallet. Always double-check the accuracy of the RPC URL before adding a new network.",
      "import_new_network_desc2":
          "Custom networks might lack the same level of security as well-established, widely-used networks. Ensure that you trust the administrators and community behind the custom network to minimize potential vulnerabilities.",
      "chain_id": "Chain ID",
      "rpc_url": "RPC Url",
      "network_name": "Network name",
      "network_name_desc": "Give your custom network a descriptive name.",
      "symbol": "Symbol",
      "symbol_desc": "Add a symbol for easy identification.",
      "chain_id_validator": "Please enter a valid chain ID.",
      "rpc_url_validator":
          "Please enter a valid RPC URL starting with 'http' or 'https'.",
      "network_name_validator":
          "Please enter a valid network name without special characters, with a maximum length of 20 characters.",
      "symbol_validator":
          "Please enter a valid Symbol without special characters, with a maximum length of 6 characters.",
      "http_error_404":
          "Error 404: Resource Not Found. The requested URL or endpoint could not be located on the server.",
      "http_error_400":
          "Error 400: Bad Request. The server could not understand the request due to invalid syntax or missing parameters.",
      "http_error_401":
          "Error 401: Unauthorized. Access to the requested resource is denied due to missing or incorrect authentication credentials.",
      "http_error_403":
          "Error 403: Forbidden. Access to the requested resource is forbidden.",
      "http_error_405":
          "Error 405: Method Not Allowed. The specified HTTP method is not supported for the requested resource",
      "http_error_408":
          "Error 408: Request Timeout. The server timed out while waiting for the request",
      "http_error_500":
          "Error 500: Internal Server Error. The server encountered an unexpected condition that prevented it from fulfilling the reques",
      "http_error_503":
          "Error 503: Service Unavailable. The server is currently unable to handle the request due to temporary overloading or maintenance of the server",
      "server_unexpected_response": "Unexpected server response",
      "network_chain_id_already_exist": "The network already exists.",
      "network_imported_to_your_wallet":
          "The network has been successfully imported to your wallet.",
      "providers": "Providers",
      "checking_rpc_network_info": "Checking RPC Network Information",
      "rpc_url_already_exists": "A provider already exists with this RPC URL.",
      "tap_to_add_new_service_provider": "Tap to add a new service provider.",
      "update_network": "Update Network",
      "chain_id_of_network": "The chain ID of the network",
      "updating_network": "Updating network information. Please Wait.",
      "network_updated_successfully":
          "The network has been successfully updated.",
      "invalid_network_information": "Invalid network information.",
      "to_many_networks_imported": "Too many networks have been imported.",
      "import_network": "Import network",
      "backup_multi_sig_address_desc":
          "Are you certain that the address information has been securely saved?",
      "remaining_amount": "Remaining amount",
      "remaining_amount_and_receiver":
          "Remaining amount of UTXO and receiver address.",
      "cost_for_transaction": "Cost for transactions",
      "memo_desc2":
          "Additional message or information attached to a transaction.",
      "custom_derivation": "Custom derivation",
      "key_already_exists": "Private key already exists",
      "read_more": "Read more...",
      "choose_token": "Choose token",
      "total_supply": "Total supply",
      "https": "HTTPS",
      "gist": "Github (gist)",
      "content": "Content",
      "nft": "NFT",
      "capability": "Capability",
      "none": "None",
      "mutable": "Mutable",
      "minting": "Minting",
      "commitment": "Commitment",
      "commitment_desc": "The commitment contents of the NFT",
      "commitment_validate_desc":
          "The commitment must be a maximum of 40 bytes (80 characters).",
      "max": "MAX",
      "tap_to_add_new_receipment": "Tap to add new recipient",
      "operation": "Operation",
      "setup_operation": "Setup Operation",
      "remaining_token_amount": "Remaining token amount",
      "remaining_token_amount_and_receiver":
          "Remaining token amount of UTXO and receiver address.",
      "tap_to_add_commitment": "Tap to add commitment",
      "without_commitment": "Without commitment",
      "update_commitment": "Update commitment",
      "transaction_ordering": "Transaction Ordering",
      "transaction_ordering_desc":
          "The order in which these inputs and outputs are listed in transaction.",
      "bip69": "BIP-69",
      "shuffle": "Shuffle",
      "inputs": "Inputs",
      "outputs": "Outputs",
      "save": "Save",
      "bip_69_desc":
          "Lexicographical Indexing of Transaction Inputs and Outputs",
      "shuffle_desc": "Mixing inputs and outputs (random)",
      "none_ordering_transaction_desc":
          "The order of selected UTXOs, added outputs, remaining output, and notes determines the shuffle.",
      "manually": "Manually",
      "manually_ordering_transaction_desc": "Sort manually before sending.",
      "ft": "Fungible Token",
      "transaction_generated_with_number_accounts":
          "A transaction has been generated, involving ___1__ accounts",
      "transaction_need_number_private_key_to_complete":
          "The transaction requires the input of ___1__ private keys for completion.",
      "node_connection_error":
          "The connection with the node could not be established",
      "network_unbale_change_providers": "Unable to modify default providers.",
      "protocol": "Protocol",
      "network_protocol_not_supported":
          "The ___1__ protocol is not supported on this platform.",
      "network_tittle_tcp_ssl_url":
          "Enter the ___1__ URL or IPv4 address without any prefix, including the port, like example.com:50002.",

      "network_title_websocket_url":
          "Please supply the WebSocket address, including the WS or WSS prefix, and if necessary, specify the port. For example, wss://example.com.",

      "network_title_http_url":
          "Provide the HTTP/HTTPS address with prefix (http:// or https://). Include port if needed. Example: https://example.com:8080",
      "network_title_http_wss_url":
          "Provide the address with appropriate prefix (http://, https://, ws://, or wss://). Include port if needed. Examples: https://example.com:8080 or wss://example.com:8080",
      "network_title_socket_url":
          "Provide the address with appropriate prefix (tcp://, tls://, ws://, or wss://). Include port if needed. Examples: tls://example.com:8080 or wss://example.com:8080",
      "network_tcp_address_validator":
          "Invalid TCP or IPv4 address. Please refer to the example address for proper formatting.",
      "network_websocket_address_validator":
          "Invalid Websocket address. Please refer to the example address for proper formatting.",
      "invalid_protocol_url":
          "Invalid URL format. Must include protocol prefix, host address, and port number. Follow the format shown in the example.",
      "unsupported_protocol_by_selected_service":
          "The URL protocol is not supported by this service",
      "network_waiting_for_response": "Awaiting a reply. please wait.",
      "network_verify_server_status": "Verify server status.",
      "network_update_node_provider": "Update node provider",
      "securely_add_providers": "Securely Add Node Providers",
      "network_security_desc":
          "Ensuring the security of your wallet is paramount. When adding a new provider, it's crucial to verify the RPC endpoint's accuracy to prevent potential security compromises. Before integration, double-check the RPC URL for correctness. Take an additional layer of caution by cross-referencing the current server header with a trusted block explorer or other reliable sources. These measures enhance security, providing confidence that the provider added to your wallet is secure and free from any malicious intent.",

      "network_update_network_providers": "Update network providers.",
      "network": "Network",
      "network_change_detect_desc":
          "Prioritize the use of the 'Update Network Provider' option before making any changes.",
      "network_no_provider_detected":
          "No node provider detected. Please add a provider for the network.",
      "network_add_provider": "Tap to add new service provider.",
      "network_explorer_address_link": "Explore Address Link",
      "network_explorer_transaction_link": "Explore Transaction Link",
      "network_evm_explorer_address_desc":
          "To retrieve the current link in the explorer, please use #address as a placeholder for the actual address in the link, such as https://example.com/address/#address.",
      "network_evm_explorer_transaction_desc":
          "To retrieve the current link in the explorer, please use #txid as a placeholder for the actual transaction in the link, such as https://example.com/tx/#txid.",
      "validate_link_desc":
          "Please enter a valid URL starting with 'http' or 'https'.",
      "default_providers": "Default providers.",
      "api_unknown_error": "An unidentified error occurred during the request",
      "api_http_timeout_error":
          "Request Timeout: The server did not respond within the specified time frame",
      "api_http_client_error":
          "An error occurred on the client side during the request.",
      "network_genesis_hash_validator":
          "The Genesis Hash is incompatible with the current network.",
      "network_incorrect_chain_id":
          "The Chain ID is not compatible with the current network.",
      "network_provider_log_details": "Provider Log Details",
      "network_total_request": "Total requests",
      "network_total_success_request": "Total Success Requests",
      "network_request_details": "Request details",
      "request": "Request",
      "response": "Response",
      "error": "Error",
      "status": "Status",
      "toggle_currency": "Toggle Currency",
      "network_tron_provider_desc":
          "For the time being, the Tron network exclusively supports the Trongrid API.",
      "min": "MIN",
      "bitcoin_rbf_error":
          "When using RBF, make sure your UTXOs have been confirmed; otherwise, you may encounter a non-final error",
      "inaccessible_key_algorithm":
          "Key algorithm inaccessible in multisig account.",
      "select_era_for_generate_addr":
          "Please select the Cardano era to generate the address.",
      "shelly": "Shelley",
      "byron": "Byron",
      "recommended_address_type":
          "We recommend using the latest era (Shelley) to access all network features.",
      "cardano_era": "Cardano Era",
      "master_key_generation": "Master Key Generation",
      "cardano_bip32_master_key":
          "Cardano supports two different methods for generating the BIP32 master key.",
      "choose_master_key_gen":
          "Please choose the master key generation method.",
      "ledger": "Ledger",
      "icarus": "Icarus",
      "shelley_address_format": "Shelley address format",
      "base": "Base",
      "reward": "Reward",
      "enterprise": "Enterprise",
      "seed_generation": "Seed Generation",
      "seed_generation_type":
          "Please select the method for generating the seed",
      "byron_legacy_seed": "Byron Legacy Seed",
      "bip39_seed": "BIP-39 Seed",
      "byron_legacy": "Byron legacy",
      "first_index": "First index",
      "second_index": "second index",
      "basic": "Basic",
      "assets": "Assets",
      "unsuported_feature": "Unsuported feature",
      "the_amount_is_unspecified": "The amount is unspecified.",
      "amount_must_exceed": "The output amount must exceed ___1__.",
      "back_to_the_page": "Back to the page",
      "label": "Label",
      "metadatum_label": "Metadatum label",
      "enther_valid_un_label": "Please enter a valid unsigned number.",
      "label_already_exists": "The label you entered already exists.",
      "associated_token_program": "Associated Token Program",
      "create_associated_token_account": "Create Associated Token Account",
      "mint": "Mint",
      "owner_address": "Owner address",
      "mint_address": "Mint address",
      "mint_address_desc": "The mint account address",
      "program_address": "Program address",
      "program_address_desc": "The address of token program",
      "associated_token_address": "Associated token address",
      "new_account_address": "New Account address",
      "solana_new_account_desc":
          "Please provide the address for the account you wish to create, the account should be imported to your wallet before creation",
      "owner_of_account": "The owner of account",
      "account_size": "Account size",
      "lamports": "Lamports",
      "create_account": "Create Account",
      "solana_create_account_desc":
          "A created account is initialized to be owned by a built-in program called the System program.",
      "setup_account_size": "Setup account size",
      "solana_create_account_lamports_desc":
          "Amount of lamports to transfer to the created account",
      "solana_account_size_desc":
          "the amount of memory allocated to store data associated with the account on the blockchain",
      "mint_authority": "Mint authority",
      "decimals": "Decimals",
      "solana_mint_decimal_desc":
          "Number of base 10 digits to the right of the decimal place",
      "mint_authority_desc": "The authority of mint tokens.",
      "freeze_authority": "Freeze authority",
      "freeze_authority_desc": "The freeze authority of the mint.",
      "program_id": "Program ID",
      "solana_program_id_desc": "The unique identifier of the application",
      "mint_address_to_initialize": "The mint address to initialize.",
      "setup_token_decimal": "Setup token decimals",
      "initialize_mint": "Initialize mint",
      "initiailize_mint_desc":
          "Initializing a mint in Solana creates a new token type.",
      "mint_to": "Mint to",
      "mint_address_mint_desc": "The mint address",
      "mint_to_desc": "Mints new tokens to an account.",
      "authority": "Authority",
      "mint_to_authority_desc": "The mint's minting authority.",
      "mint_to_amount_desc": "The amount of new tokens to mint.",
      "use_owner_account_instead_pda_desc":
          "The account to mint tokens to. Utilize owner account. application automatically locates current PDA account.",
      "name": "Name",
      "update_token": "Update token",
      "update_token_information": "Update token information",
      "update_token_desc": "Update the name and symbol of the token",
      "token_symbol_validator":
          "The token symbol must be at least 2 characters long",
      "token_denom_validator":
          "The token denom must be at least 2 characters long",
      "token_name_validator":
          "The token name must be at least 3 characters long",
      "asset_name": "Asset name",
      "tap_to_select_account": "Tap to select account",
      "certificates": "Certificates",
      "add_certificate_to_transaction": "Add certificates to the transaction",
      "tap_to_add_certificate": "Tap to add certificate",
      "deregistration": "Deregistration",
      "delegation": "Delegation",
      "certificate_type": "Certificate type",
      "add_certificate_to_transaction_desc":
          "Please choose the certificate you would like to include in the transaction.",
      "certificate": "Certificate",
      "stake_address": "Stake address",
      "setup_certificate": "Setup certificate",
      "stake_registration": "Stake Registration",
      "stake_address_validator": "The account does not possess a stake address",
      "stake_deregistration": "Stake Deregistration",
      "stake_delegation": "Stake Delegation",
      "deposit": "Deposit",
      "cannot_send_ada_to_stake_address":
          "Sending ADA or assets to a stake address is not allowed.",
      "ada_base_stake_key_same_error":
          "ensure that the base key and stake key are not generated using the same key.",
      "feature__unavailable_for_multi_signature":
          "The feature is unavailable for multi-signature addresses.",
      "select_creation_type": "Select creation type",
      "setup_address_derivation_keys_desc":
          "In the setup derivation, you can select imported keys if they exist.",
      "please_following_steps_to_generate_address":
          "Please follow these steps to generate an address.",
      "stake_key": "Stake key",
      "main_key": "Main key",
      "base_key": "Base key",
      "switch_between_keys":
          "Please switch between keys to view information about each one.",
      "retrieve_account_informations":
          "Please wait while we retrieve the account informations.",
      "public_keys": "Public keys",
      "Invalid_coin_default_path": "Invalid coin default path",
      "invalid_hd_wallet_derivation_path": "Invalid HD wallet derivation path",
      "invalid_substrate_path": "Invalid substrate path.",
      "derivation_path": "Derivation path",
      "hd_wallet_path_max_indeqxes":
          "only supports up to ___1__ HD wallet indexes.",
      "unsupported_hd_wallet_index": "Unsupported hd wallet index.",
      "hd_wallet_hardened_desc":
          "For hardened indices, append ' or h to the end of the index.",
      "hd_wallet_substrate_hardened_desc":
          "For hardened indices, append // to the start of the index.",
      "imported_": "Imported(___1__)",
      "hd_path": "HD Path",
      "hd_path_key": "HD Path key",
      "invalid_byron_legacy_hd_path_key": "Invalid byron legacy HD path key",
      "byron_legacy_hd_wallet_length_desc":
          "Byron Legacy only supports the first two HD wallet indexes, such as m/1/2.",
      "byron_legacy_hd_path_key_desc":
          "Invalid HD Path key bytes. Please provide the HD path key in hexadecimal format.",
      "byron_legacy_hd_path_key_length_desc":
          "The HD path key should be 32 bytes in length.",
      "byron_legacy_hd_path_key_desc2":
          "Please provide the HD path key in hexadecimal format.",
      "manually_set_hd_path": "Manually set HD path details.",
      "byron_legacy_hd_path_generate_from_master_key_desc":
          "Do not toggle on for generating from master key.",
      "wallet_type": "Wallet type",
      "types_of_wallet_contracts": "Types of Wallet Contracts",
      "ton_wallet_contract_desc":
          "TON wallet smart contracts with different features and security levels.",

      "sub_wallet_id_validator":
          "The sub wallet id must be a value between 0 and ___1__.",
      "sub_wallet_id": "Sub wallet id",
      "sub_wallet_id_desc":
          "which allows you to create multiple wallets using the same public key (so you can have only one seed phrase and lots of wallets)",
      "ton_mnemonic_feature_desc":
          "We are using standard BIP-39 seed generation for the TON network. To use the Ton Mnemonic feature, generate a private key from your mnemonic in the settings (import key feature).",
      "ton_mnemonic": "Ton Mnemonic",
      "generate_ton_private_key":
          "Generate a private key from your TON mnemonic.",
      "network_settings": "Network settings",
      "ton_mnemonic_desc":
          "The TON network uses its algorithm to generate private keys from mnemonics. You can create or import a TON mnemonic, convert it to a private key, and import it into your wallet.",

      "external_mnemonic_desc2":
          "We don't store your mnemonic or mnemonic password in the wallet. Instead, we generate a private key for you to import into the wallet if desired",
      "mnemonic_password": "Mnemonic password.",
      "mnemonic_password_desc":
          "If your mnemonic has a password or you want to generate a mnemonic with a password, enable it.",
      "password_empty_validator": "Password must not be empty.",
      "create_import_mnemonic": "Create/Import Mnemonic",
      "choose_an_action": "Choose an Action",
      "enter_mnemonic_desc3":
          "Please enter your BIP39 mnemonic phrase below, consisting of 8 to 48 words, separated by spaces.",
      "generate_private_key": "Generate private key",
      "invalid_bip39_mnemonic_words": "Invalid BIP39 mnemonic words.",
      "validating_mnemonic": "Validating mnemonic",
      "validate_ton_mnemonic": "Validate Ton mnemonic",
      "validate_ton_mnemonic_desc":
          "Ensure the entered mnemonic is a valid TON mnemonic.",
      "generating_private_key": "Generating private key. Please wait.",
      "import_to_wallet": "Import to wallet.",
      "wrong_network_key_error":
          "The private key is not associated with the ___1__ network",
      "generate_ton_mnemonic": "Generate Ton mnemonic",
      "ton_mnemonic_words_desc":
          "You can generate a mnemonic phrase with 8 to 48 words, though most wallets support only 24-word mnemonics.",
      "ton_mnemonic_words_length_validator":
          "The TON mnemonic supports 8 to 48 words.",
      "generating_mnemonic": "Generating mnemonic. Please wait.",
      "estimating_fee_please_wait": "Estimating fee. Please wait.",
      "bounce": "Bounce",
      "ton_bounce_desc2":
          "If the destination contract is missing or errors, the message returns with remaining value, minus fees.",
      "message_body": "Message body",
      "comment": "Comment",
      "binary_comment": "Binary comment",
      "cell": "Cell",
      "type_of_message_body": "Type of message body",
      "choose_the_type": "Choose the type",
      "ton_message_body_comment_validator":
          "Please enter a comment for your message body.",
      "invalid_hex_bytes_string": "Invalid hexadecimal byte string.",
      "ton_invalid_cell_string_data":
          "Invalid cell data. Please enter a valid string in base64 or hexadecimal format.",
      "enter_binary_message_as_hex":
          "Please enter the binary message in hexadecimal format.",
      "enter_comment_as_string_or_hex":
          "Please enter the comment in plain text or hexadecimal format.",
      "enter_cell_as_hex_or_base64":
          "Please enter a valid string in base64 or hexadecimal format.",
      "update_messsage": "Update message.",
      "message_options": "Message options",
      "ton_bounceable_vs_non_bounceable":
          "Bounceable vs Non-Bounceable Addresses",
      "ton_address_type_desc":
          "We recommend using a stable, non-bounceable address for the wallet contract.",
      "bouncable": "Bounceable",
      "non_bouncable": "Non-Bouncable",
      "jettons": "Jettons",
      "no_jettons_found": "No jettons found in the account.",
      "import_jettons": "Import Jettons",
      "data_verification_failed": "Data verification failed.",
      "select_token": "Select Token",
      "jetton_transfer": "Jetton transfer",
      "select_jetton_desc": "Please select the jetton you want to transfer",
      "forward_amount": "Forward Ton amount",
      "total_amount": "Total amount",
      "the_jetton_amount_is_unspecified": "The jetton amount is unspecified.",
      "ton_total_amount_validator":
          "The total amount must be greater than the forward amount. (Forward amount + message fee = total amount)",
      "ton_jetton_transfer_desc":
          "Please make sure you understand the jetton transfer fields. If not, read this link before making a transaction.",
      "ton_total_amount_desc_2":
          "If the Forward amount is zero, the total minus the fee will be transferred to the destination. Otherwise, the total amount minus the Message fees and Forward fees will be returned to your account.",
      "remove_recipient": "Remove recipient",
      "remove_recipient_desc": "Remove the recipient?",
      "unknown_error": "Unknown error",
      "some_action_failed":
          "Some actions failed during the processing:  ___1__ .",
      "arbitrary_request_number": "Arbitrary request number.",
      "query_id": "Query ID",
      "jetton_transfer_fields": "Jetton transfer fields.",
      "ton_query_id_validator": "Invalid Query Id",
      "url_does_not_exists": "URL does not exist.",
      "ripple_key_conversion": "Ripple key conversion",
      "ripple_key_conversion_desc":
          "Generate private key from ripple seed or enteropy",
      "secret_key_conversion_desc2":
          "You can convert your specific blockchain key or recovery phrase into a private key, which can then be imported into a wallet to manage addresses, transactions, and other network operations.",
      "ripple_key": "Ripple key",
      "select_ripple_seed_or_entropy": "Please enter your Ripple key.",
      "example_s": "Example: ___1__ .",
      "ripple_seed_entropy_validator": "Please enter a valid ripple ___1__ .",
      "seed": "Seed",
      "entropy": "Entropy",
      "inidicate_type_of_ripple_key": "Indicate the type of your ripple key.",
      "ripple_key_type": "Ripple key type",
      "choose_key_algorithm_desc":
          "Which type of algorithm would you like to use to create the private key?",
      "import_private_key_desc":
          "Your private key has been successfully generated. click the 'Import to Wallet' button which can then be imported into a wallet to manage addresses, transactions, and other network operations.",
      "coin_type": "Coin type",
      "choose_key_coin_desc": "To which coin is your key-related?",
      "invalid_key_length": "Invalid key length.",
      "invalid_key_encoding_format": "Invalid key encoding format.",
      "enter_key_base58_desc": "Please enter your key in Base58 format.",
      "enter_key_hex_desc": "Please enter your key in Hexadecimal format.",
      "enter_key_bech32_desc": "Please enter your key in Bech32 format.",
      // "restore_from_backup": "Restore from backup.",
      "restore_backup_desc":
          "Restore your mnemonic, private key, or other information you generated with the app backup option.",
      "restore_encrypted_backup": "Restore encrypted backup",
      "restoring_backup_please_wait": "Restoring backup. please wait. ",
      "show_content": "Show content.",
      "backup_restored_desc": "Your backup has been successfully restored.",
      "qr_code": "QR Barcode",
      "submit": "Submit",
      "live_price": "Live price",
      "coin_gecko_desc":
          "We can also provide live price updates for your token balance using CoinGecko. To enable this, locate your token on CoinGecko, find the API ID on the token's page, and select the appropriate name here.",
      "retrieving_token_information": "Retrieving token. Please wait.",
      "api_id": "API ID",
      "coingecko_api_id_validator":
          "The API ID must be at least 2 characters long",
      "retrieving_token_price": "Retrieving token price. Please wait.",
      "updating_token": "Updating token. Please wait. ",
      "token_updated_successfully": "The token has been successfully updated.",
      "invalid_api_id": "Invalid API ID.",
      "token_decimals": "Token decimals",
      "token_decimals_validator":
          "The number of token decimal places must be between 0 and 255.",
      "change_token_decimal_desc":
          "Warning: Changing the token decimal places can significantly impact token balances and transactions. For example, changing from 9 to 10 decimal places may cause balance discrepancies and potential loss of funds. Proceed with caution and ensure you understand the consequences before making this change. The number of decimal places must be between 0 and 255.",
      "change_token_decimal_desc3":
          "Warning: Changing token decimal places can significantly impact balances and transactions. Ensure the decimal setting is accurate before proceeding.",
      "change_decimals": "Change decimals",
      "change_token_decimal_desc2":
          "The token decimal places will be changed from ___1__ to ___2__ .",
      "customize_key_derivation": "Customize derivation",
      "ada_customize_derivation_desc":
          "Choose seed, master key, and address generation type",
      "choose_mnemonic_lang_desc":
          "Choose your mnemonic language. We recommend using English as it is more universal.",
      "wallet_already_exists": "Wallet already exists.",
      "unlock_access_desc":
          "This feature only works on an unlocked wallet. Please enter your wallet password to continue.",
      "unlock_wallet": "Unlock Wallet",

      "incomplete_wallet_setup": "Wallet setup is incomplete",
      "switch_wallets": "Switch wallets",
      "wallet_does_not_exists": "Wallet does not exists.",
      "wallet_settings": "Wallet settings",
      "wallet_settings_desc":
          "Modify your wallet name, set password requirements, and choose it as the default app wallet.",
      "wallet_name": "Wallet name",
      "wallet_identifier_name": "Wallet identifier name",
      "password_requirement": "Password requirement",
      "wallet_password_requirement_desc2":
          "Wallet access requires a password. When disabled, the wallet stays open except for actions that still prompt for a password.",
      "wallet_locktime_desc":
          "After this period, password wallets lock, and non-password wallets are read-only.",
      "wallet_name_validator":
          "Wallet name must be between 3 and 15 characters long.",
      "wallet_name_validator2": "Wallet name already exists.",
      "wallet_name_exists": "A wallet with this name already exists.",
      "generate_keystore": "Generate keystore",
      "generate_keystore_desc": "Generate Keystore V3 from private key.",
      "verification_backup_review": "Backup Verification Review",
      "verification_backup_desc":
          "Please review the backup verification before importing it to your wallet.",
      "backup_verification_success_desc":
          "Backup successfully passed checksum verification",
      "backup_verification_failed_desc":
          "Verification failed. Please recheck your passphrase.",
      "unsuported_legacy_backup": "Unsupported: Legacy backup",
      "total_accounts": "Total accounts",
      "verifying_backup_please_wait": "Verifying backup. Please wait",
      "unverified_account": "Unverified Account",
      "unverified_account_desc":
          "The verification of these accounts failed, so they cannot be imported into your wallet.",
      "signing_auth_validator": "This account is not authorized for signing.",
      "unsuported_key": "Unsupported key",
      "use_key_store_backup_desc":
          "A keystore backup can be unlocked by any compliant Web3 wallet, such as TronLink, MetaMask, and others.",

      "mnemonic": "Mnemonic",
      "keystore": "Keystore",
      "ton_wallet_validator_desc":
          "Wallet contract v1 only support on message per transaction.",
      "qr_code_scanner": "Barcode scanner",
      "getting_scanner_ready": "Getting scanner ready, please wait.",
      "ripple_address_validator_desc":
          "Please enter the Ripple address tag or disable this feature.",
      "insert_address_tag": "Enter the address tag",
      "ripple_xaddress_feature": "X-address feature.",
      "ripple_xaddress_tag_validator":
          "The provided tag does not match the x-address tag.",
      "retrive_barcode_data": "Retrieve barcode data",
      "coin_not_found": "Unable to locate a proposal with the given coin name.",
      "keypair_type": "Keypair type",
      "choose_key_algorithm_desc2":
          "Which type of algorithm would you like to use to create the address?",
      "disable_standard_derivation_desc":
          "You can manually setup a derivation path.",
      "custom_path_derivation_desc":
          "Ensure you remember the chosen path for custom derivation. Forgetting it could result in losing your funds.",
      "connection_attempt_unsuccessful": "Connection attempt unsuccessful.",
      "node_connectiong_please_wait": "Connecting to the node. Please wait.",

      "tip": "Tip",
      "barcode_scanning_terminated": "Barcode scanning has been terminated.",
      "provider": "Provider",
      "account_options": "Account options",
      "node_connection_desc":
          "All actions are disabled until connection is established.",
      "testnet_price_desc":
          "You are on the testnet network, and prices are not valid.",
      "testnet": "Testnet",
      "slip_44_desc":
          "BIP-0044 defines a logical hierarchy for deterministic wallets. Level 2 of the hierarchy describes a coin type in use.",
      "barcode_scanner_not_supported_browser":
          "Barcode scanner is not supported in your browser.",
      "message": "Message",
      "sign_message": "Sign message",
      "sign_messages": "Sign messages",
      "version": "Version",
      "primary_type": "Primary type",
      "decryption_failed": "Decryption process failed.",
      "initializing_requirements": "Initializing requirements. Please wait.",
      "coin_type_desc2":
          "The coin type is always determined by a hardened index. You can also set up a custom derivation on the setup address page.",
      "authenticated": "Authentication",
      "add_provider_authenticated": "Add authentication to your provider.",
      "authenticated_type": "Authentication Type",
      "authenticated_key": "Authentication key",
      "authenticated_value": "Authentication value",
      "example_value": "Example: ___1__",
      "authenticated_key_validator":
          "Please enter at least one character for the authentication key.",
      "authenticated_value_validator":
          "Please enter at least one character for the authentication value.",
      "value_is_to_large": "The provided value is too large.",
      "address_type": "Address type",
      "processing_request": "Processing request, please wait.",
      "protect_wallet": "Protect wallet",
      "required_password_to_sign_transaction":
          "Authentication will be required to sign transactions securely",
      "wallet_is_not_available": "The wallet is not available",
      "new_tab": "New tab",
      "history": "History",
      "bookmark": "Bookmark",
      "bookmarks": "Bookmarks",
      "remove_all": "Remove all",
      "histories": "Histories",
      "file_does_not_exist": "File does not exists.",
      "web3_request_rejected_desc":
          "Request has been canceled or the client does not exist.",
      "updating_permission": "Updating permission. please wait.",
      "enter_wallet_password_request":
          "Kindly enter your wallet password to proceed with the request.",
      "application_name": "Application name",
      "edit_application_name_desc":
          "You can edit the program name for easier identification.",
      "application_name_validator":
          "The application name must be at least 3 characters long.",
      "web3_activation": "Web3 activation",
      "web3_activation_desc":
          "You can also enable or disable the Web3 feature for this application. (Applying this change requires reloading the page.)",
      "eth_subscribe_websocket_requirment":
          "`eth_subscribe` method only works with the WebSocket protocol.",
      "unknown": "Unknown",
      "creation_contract": "Creation Contract",
      "method_name": "Method name",
      "transfer_amount": "Transfer amount",
      "transaction_type": "Transaction type",
      "smart_contract": "Smart contract",
      "network_does_not_exist": "Network does not exists.",
      "web3_request_account_desc":
          "The request should be processed using this account.",
      "client": "Client",
      "web3_client_desc": "This request was generated by the application.",
      "web3_sending_response_to_client":
          "Sending the response to the client. Please wait.",
      "web3_sending_response_error_desc":
          "The client did not receive the response as it was closed during transmission.",
      "web3_response_successfully_desc":
          "The client has successfully received the response.",
      "verifying_contract": "Verifying Contract",
      "remove_network": "Remove network",
      "remove_network_desc2":
          "Are you sure you want to remove the network from the wallet?",
      "remove_network_desc":
          "All accounts, contacts, and any other chain-related data will be permanently removed from the wallet. This action cannot be undone.",
      "contract": "Contract",
      "transfer_token_desc": "The amount of token will be transferred.",
      "transaction_data": "Transaction data",
      "tron_contract": "Tron contract",
      "tron_transaction_type": "Tron transaction type",
      "tron_transaction_destination_desc":
          "Transaction destination, such as TRX receiver, token recipient, or smart contract.",
      "tron_total_spent_desc": "Total TRX to be spent in this transaction.",
      "contract_information": "Contract information",
      "information": "Information",
      "transaction_id": "Transaction ID",
      "tron_call_token": "Call TRC-10 token",
      "tron_call_token_desc": "Token transfer during contract interaction",
      "tron_call_token_value_desc":
          "The amount of a TRC-10 token during contract interaction",
      "default_address": "Default address",
      "tron_owner_contract": "Owner address of contract",
      "tron_owner_contract_desc":
          "in multi-sig transaction, this may be different from the account address",
      "insufficient_balance": "Insufficient balance",
      "instructions": "Instructions",
      "simulate_transaction": "Simulate transaction",
      "transaction_simulation_failed": "Transaction simulation failed.",
      "transaction_simulation_success": "Transaction simulation success.",
      "transaction_simulate_please_wait":
          "Simulating transaction. Please wait.",
      "transaction_simulation_failed_retry":
          "Transaction simulation failed. Tap to retry",
      "transactions": "Transactions",
      "multiple_transaction_desc":
          "Multiple transaction requests detected. Please review each transaction before submitting.",
      "signing_transaction_please_wait": "Signing transaction. Please wait.",
      "send_transactions": "Send transactions",
      "sign_transactions": "Sign transactions",
      "total_transaction_fee": "Total transaction fee",
      "fee_estimate_failed": "Fee estimation failed",
      "total_transaction_const": "Total transaction cost",
      "change_balance": "Change balance",
      "solana_change_balance_desc":
          "Remaining balance after transaction submission.",
      "solana_change_balance_desc2":
          "In a multiple transaction request with the same owner, the balance change applies only to this instruction and does not affect previous or subsequent simulations.",
      "message_amount": "Message amount",
      "amount_of_ton_message": "Amount of TON Linked to the Message",
      "transaction_messages": "Transaction messages",
      "ton_tx_message_details": "TON transaction message details.",
      "jetton_info": "Jetton info",
      "jetton_transfer_amount": "Jetton transfer amount",
      "content_of_payload": "The content of payload.",
      "payload_deserialize_failed":
          "Failed to deserialize and access the payload content.",
      "unknown_payload_desc":
          "Unknown payload detected. Some payloads may have full access to contracts. Only accept Web3 transactions from trusted sites.",
      "deploy_contract": "Deploy contract",
      "initialization_state": "Initialization state",
      "encrypted_message": "Encrypted message",
      "use_wallet_id": "Use Wallet id",
      "ton_v5_wallet_desc":
          "The Wallet ID may resemble a Sub Wallet ID, but it follows a different serialization concept. To understand this better, you should read about version 5.",
      "wallet_id": "Wallet ID",
      "unknow_jetton_owner": "Unknown Jetton Owner",
      "sign_message_private_key":
          "The message should be signed using account private key.",
      "sign_message_private_key_desc":
          "Sign Message: Warning! The message you're about to sign could contain anything, including transactions. We cannot validate the contents of the message. Only proceed if you fully trust the request. Otherwise, you may risk losing your funds.",
      "signing_request": "Signing request",
      "eth_sendTransaction": "Send Transaction",
      "personal_sign": "Personal Sign",
      "eth_signTypedData": "Sign Typed Data",
      "eth_signTypedData_v3": "Sign Typed Data V3",
      "eth_signTypedData_v4": "Sign Typed Data V4",
      "eth_requestAccounts": "Request Accounts",
      "wallet_addEthereumChain": "Add Ethereum Chain",
      "wallet_switchEthereumChain": "Switch Ethereum Chain",
      "solana_sendTransaction": "Send Transaction",
      "solana_sendAllTransactions": "Send All Transactions",
      "solana_signAllTransactions": "Sign All Transactions",
      "solana_signMessage": "Sign Message",
      "solana_signTransaction": "Sign Transaction",
      "solana_requestAccounts": "Request Accounts",
      "ton_signMessage": "Sign Message",
      "ton_sendTransaction": "Send Transaction",
      "ton_signTransaction": "Sign Transaction",
      "ton_requestAccounts": "Request Accounts",
      "tron_signTransaction": "Sign Transaction",
      "tron_signMessageV2": "Sign Message",
      "tron_requestAccounts": "Request Accounts",
      "muxed_address": "Muxed address",
      "pubkey_address": "Public key address",
      "stellar_muxed_address_desc":
          "a new type of Stellar account that makes it easy to map a single Stellar address to multiple users.",
      "id": "Id",
      "enter_stellar_muxed_id_desc":
          "The Id must be a value between 0 and 2^64-1.",
      "uint64_validator": "The ___1__ must be a value between 0 and 2^64-1.",
      "recipient_account_active": "The recipient account is active.",
      "recipient_account_inactive": "The recipient account is inactive.",
      "retrieve_account_activity_failed":
          "Failed to retrieve account activity.",
      "32bytes_hex_validator_desc":
          "The value must be a valid 32-byte hexadecimal string.",
      "text_max_validator": "Text must be ___1__ characters max.",
      "add_stellar_memo_type_desc":
          "Please choose the type of Stellar memo to add to the transaction.",
      "stellar_memo_text_desc":
          "Memo can be up to 28 characters. Note: the text is deserialized using UTF-8 encoding.",
      "stellar_memo": "Stellar transaction memo",
      "stellar_memo_desc":
          "Stellar offers different memo types for transactions, each designed for a specific purpose.",
      "stellar_memo_desc2":
          "If no memo is needed, select '___1__' and use '___2__' to confirm.",
      "stellar": "Stellar",
      "stellar_starting_balance_desc":
          "The starting balance for a non-active account must reach ___1__ XLM.",
      "submit_transaction_error": "Transaction submission error. ___1__",
      "submit_transaction_failed": "Transaction submission failed.",
      "fee_zero_validator_desc": "Transaction fee must not be zero.",
      "tap_to_add_new_operation":
          "Tap to add a new operation to the transaction",
      "change_trust": "Change trust",
      "asset_type": "Asset type",
      "stellar_invalid_asset4_validator":
          "Invalid asset code: must contain 1 to 4 alphanumeric characters (a-z, A-Z, 0-9).",
      "stellar_invalid_asset12_validator":
          "Invalid asset code: must contain 5 to 12 alphanumeric characters (a-z, A-Z, 0-9).",
      "asset_issue_address_validator":
          "Cannot use the contract address as the asset issuer address.",
      "setup_asset": "Setup asset",
      "asset": "Asset",
      "pool_id": "Pool ID",
      "stellar_liquidity_pool_id_desc":
          "Stellar Liquidity Pool ID: A unique 32-byte hash representing the liquidity pool asset, used for facilitating decentralized trading between two assets on the Stellar network.",
      "tap_to_select_or_create_asset": "Tap to select or create an asset",
      "pick_an_asset": "Pick an asset",
      "change_trust_desc":
          "The Stellar changeTrust operation lets an account establish, modify, or remove trust lines for an asset. This is necessary before holding or transacting with non-native assets like tokens issued by other accounts.",
      "modify_trust_line_desc":
          "Please select an asset to modify the trust line.",
      "change_trust_limit":
          "the maximum amount of an asset that an account is willing to trust",
      "limit": "Limit",
      "setup_amount": "Setup amount",
      "stellar_change_trust_limit_zero_desc":
          "A limit of zero means the trust line is removed.",
      "payment": "Payment",
      "stellar_payment_desc":
          "The Stellar payment operation sends a specified amount of an asset from one account to another, supporting both XLM and tokens.",
      "select_stellar_payment_assets_desc":
          "Please select the asset you want to transfer.",
      "create_assets": "Create an asset.",
      "send_asset": "Send asset",
      "stellar_path_receive_send_asset_desc":
          "The asset being sent by the sender. It is the currency or token that will be deducted from the sender's account and converted into the recipient's desired asset.",
      "stellar_path_receive_destination_desc":
          "The account that will receive the payment. This is the recipient's address, who will receive the destination asset.",
      "send_max": "Send max",
      "stellar_path_receive_send_max_desc":
          "The maximum amount of the Send asset that the sender is willing to pay. The actual amount sent may be less, but it will never exceed this limit. If the network can't convert the Send asset into the destination asset within this maximum, the operation will fail.",
      "destination_asset": "Destination asset",
      "stellar_path_receive_dest_asset_desc":
          "The asset that the recipient will receive. This is the currency or token that the operation aims to deliver to the destination account, after any necessary conversions from the send asset",
      "destination_amount": "Destination amount",
      "stellar_path_receive_dest_amount_desc":
          "The exact amount of destination asset that the recipient will receive. This value is guaranteed by the operation, meaning the recipient will always receive this specified amount if the transaction succeeds",
      "stellar_path_payment_strict_receive_desc":
          "This operation allows the sender to specify the exact amount the recipient will receive, while the network calculates the amount of the sending asset needed, up to a specified maximum. If the conversion cannot be completed within the limit, the operation fails",
      "stellar_path_payment_strict_receive": "Path Payment Strict Receive",
      "stellar_path_receive_path_desc":
          "A list of intermediate assets used for converting the send_asset to the dest_asset. These assets serve as hops in the payment path, allowing the network to find the best conversion route if no direct trade exists between the two assets. This field is optional.",
      "path_already_exist": "The path already exists.",
      "stellar_path_send_send_asset_desc":
          "The asset being sent from the sender's account. It is the currency or token that will be deducted from the sender’s balance and converted into the desired asset for the recipient.",
      "stellar_path_receive_send_amount_desc":
          "The exact amount of the sendAsset that the sender will transfer. This amount is fixed, and the operation will convert it into the recipient's desired asset, regardless of how much the recipient ends up receiving.",
      "send_amount": "Send amount",
      "stellar_path_send_destination_desc":
          "The account that will receive the payment. This field specifies the recipient's address, indicating where the converted asset will be sent once the transaction is completed.",
      "stellar_path_send_dest_asset_desc":
          "The asset that the recipient will receive. This specifies the currency or token that the operation aims to deliver to the destination account after converting from the sendAsset",
      "stellar_path_send_dest_min_desc":
          "The minimum amount of destination asset that the recipient must receive. If the conversion from send asset does not result in at least this specified amount, the operation will fail to ensure that the recipient is adequately compensated.",
      "stellar_path_send_path_desc":
          "A list of intermediate assets used to facilitate the conversion from sendAsset to destAsset. This optional field allows the network to find the best conversion route through multiple assets if a direct trade between the two assets is not available.",
      "minimum_destination_amount": "Minimum Destination Amount",
      "stellar_path_payment_strict_send": "Path Payment Strict Send",
      "stellar_path_payment_strict_send_desc":
          "This operation allows the sender to specify an exact amount of a sending asset to convert into a desired destination asset. The operation guarantees a minimum amount of the destination asset to be received by the recipient, and if the conversion cannot be completed to meet this requirement, the operation will fail.",
      "create_an_account": "Create an account.",
      "stellar_create_account_operation_desc":
          "This operation is used to create a new Stellar account by specifying the account's destination and funding it with an initial balance. It requires the source account to have sufficient funds to cover the minimum balance requirement and transaction fees. Once executed, the new account becomes active on the Stellar network.",
      "starting_balance": "Starting balance",
      "stellar_create_account_starting_balance_desc":
          "The initial amount of Lumens (XLM) to fund the newly created account. This value must meet the minimum balance requirement set by the Stellar network, ensuring that the account remains active.",
      "transaction_operation": "Transaction operation",
      "stellar_account_inactive_desc":
          "The destination account is inactive. Be sure to include a Create Account operation; otherwise, the transaction will fail.",
      "assets_not_found_in_account":
          "We couldn't detect any assets in your account",
      "account_is_active": "the account is already active.",
      "time_bound": "Time bound (Maximum time)",
      "stellar_time_bound_desc":
          "Specifies a time window for when a Stellar transaction is valid. Without it, the transaction never expires.",
      "stellar_time_bound_auto_desc":
          "The timebound (maximum time) will be set to 1 minute before the transaction is signed.",
      "stellar_time_bound_none_desc":
          "The time bound for the transaction will not be set.",
      "time_bound_type": "Type of timebound",
      "expiration_time": "Expiration time",
      "expiration_block": "Expiration block",
      "stellar_time_bound_max_time_desc":
          "The latest ledger time by which the transaction must be included. If the transaction is not confirmed by this time, it will be rejected.",
      "tap_to_choose_data": "Tap to choose a date.",
      "setup_time_bound": "Setup time bound",
      "time_is_insufficient": "The entered time is insufficient.",
      "manual": "Manual",
      "auto": "Auto",
      "selling": "Selling",
      "stellar_manage_sell_offer_selling":
          "The asset you are offering to sell in exchange for another asset.",
      "stellar_manage_sell_offer_amount":
          "The total quantity of the selling asset that you want to offer in the exchange.",
      "buying": "Buying",
      "stellar_manage_sell_offer_buying":
          "The asset you want to receive in exchange for the asset you're selling.",
      "price": "Price",
      "stellar_manage_sell_offer_price":
          "The rate at which you are willing to sell the selling asset in terms of the buying asset, expressed as the amount of the buying asset you receive for each unit of the selling asset.",
      "offer_id": "Offer id",
      "stellar_manage_sell_offer_offer_id":
          "A unique identifier for the offer. An OfferID of 0 indicates that a new offer will be created, while a non-zero OfferID indicates that an existing offer will be updated.",
      "setup_price": "Setup price",
      "tap_to_setup_price": "Tap to setup price",
      "exchange_entred_price_desc": "You will receive ___1__ for each ___2__.",
      "exchange_entred_price_buy_desc": "You will pay ___1__ for each ___2__.",
      "setup_offer_id": "Setup offer id",
      "different_selling_from_buying_validator_desc":
          "The buying asset must be different from the selling asset.",
      "stellar_manage_sell_offer": "Manage sell offer",
      "stellar_manage_sell_offer_desc":
          "is an operation in the Stellar network that allows users to create, update, or delete a sell offer for a specific asset. This operation is primarily used in the context of trading assets on the Stellar decentralized exchange (DEX).",
      "stellar_manage_buy_offer_selling":
          "The asset you are offering to sell in exchange for another asset.",
      "stellar_manage_buy_offer_buy_amount":
          "The amount of the asset you wish to purchase.",
      "stellar_manage_buy_offer_buying":
          "The asset you want to acquire in exchange for the selling asset.",
      "stellar_manage_buy_offer_price":
          "The exchange rate at which you are willing to buy the asset, expressed as a fraction.",
      "stellar_manage_buy_offer": "Manage buy offer",
      "stellar_manage_buy_offer_desc":
          "is an operation in Stellar that allows users to create, update, or delete a buy order for an asset, specifying the asset to acquire, the selling asset, the amount to buy, and the price.",
      "stellar_web3_signing_operations_desc":
          "Please ensure you fully understand each operation before signing the transaction.",
      "transaction_version": "Transaction version",
      "version_1": "Version 1",
      "fee_bump_transaction": "Fee bump transaction",
      "stellar_requestAccounts": "Request Accounts",
      "stellar_signTransaction": "Sign Transaction",
      "stellar_signMessage": "Sign Message",
      "stellar_sendTransaction": "Send transaction",
      "create_passive_sell_offer": "Create Passive Sell Offer",
      "set_options": "Set Options",
      "allow_trust": "Allow Trust",
      "account_merge": "Account Merge",
      "inflation": "Inflation",
      "manage_data": "Manage Data",
      "bump_sequence": "Bump Sequence",
      "create_claimable_balance": "Create Claimable Balance",
      "claim_claimable_balance": "Claim Claimable Balance",
      "begin_sponsoring_future_reserves": "Begin Sponsoring Future Reserves",
      "end_sponsoring_future_reserves": "End Sponsoring Future Reserves",
      "revoke_sponsorship": "Revoke Sponsorship",
      "clawback": "Clawback",
      "clawback_claimable_balance": "Clawback Claimable Balance",
      "set_trust_line_flags": "Set Trust Line Flags",
      "liquidity_pool_deposit": "Liquidity Pool Deposit",
      "liquidity_pool_withdraw": "Liquidity Pool Withdraw",
      "invoke_host_function": "Invoke Host Function",
      "extend_footprint_ttl": "Extend Footprint TTL",
      "restore_footprint": "Restore Footprint",
      "low": "Low",
      "medium": "Medium",
      "accessibility": "Accessibility",
      "stellar_low_operation_desc": "low-risk operation.",
      "stellar_medium_operation_desc": "Medium-risk operation.",
      "stellar_high_operation_desc": "High-risk operation.",
      "source_account": "Source account",
      "stellar_high_operation_desc2":
          "High-risk operation. Please ensure you fully understand this operation before proceeding, as you may lose funds or control of your account.",
      "soroban_data": "Soroban data",
      "fee_source": "Fee source",
      "secret_key": "Secret key",
      "stellar_base32_secret_key_validator":
          "Invalid Stellar secret key. The key must be a 56-character Base32 string.",
      "stellar_key_conversion": "Stellar key conversion",
      "stellar_key_conversion_desc":
          "Convert a Stellar Base32 secret key into an Ed25519 private key for secure cryptographic operations on the Stellar network.",

      "stellar_base32_secret_key_desc2":
          "Please enter a valid Stellar Base32 secret key.",
      "solana_key_conversion": "Solana key conversion",
      "solana_key_conversion_desc":
          "Convert a Solana Base58 keypair into an Ed25519 private key for secure cryptographic operations on the Solana network.",
      "solana_base58_secret_key_validator":
          "Invalid Solana keypair. The key must be at least an 88-character Base58 string.",
      "solana_base58_secret_key_desc2":
          "Please enter a valid Solana Base58 keypair.",
      "sub_address": "SubAddress",
      "xmr_sub_address_desc":
          "A Monero subaddress is a unique, privacy-enhancing address derived from a main wallet address, allowing users to segregate funds without revealing their main address.",
      "major_index": "Major index",
      "minor_index": "Minor index",
      "sync_options": "Sync options",
      "monero_sync_options_desc":
          "Options for synchronizing Monero accounts by fetching unspent transaction outputs (UTXOs).",
      "monero_wallet_rpc_sync_desc":
          "Monero Wallet RPC synchronization option.",
      "monero_wallet_rpc_sync_desc1":
          "sends a request to your wallet and retrieves all incoming and outgoing transfers to synchronize with the current state.",
      "wallet_rpc_url": "Wallet RPC endpoint URL",
      "wallet_rpc_url_desc":
          "Enter your Wallet RPC endpoint URL, including the port if applicable.",
      "endpoint_url": "Endpoint URL",
      "sync_now": "Sync now",
      "monero_wallet_transaction_sync_desc":
          "Transaction synchronization option.",
      "monero_wallet_transaction_sync_desc2":
          "Synchronize your wallet's current state with its transaction history by providing your transaction IDs. We will retrieve and validate your unspent transactions.",
      "enter_transaction_ids_desc":
          "Enter your transaction IDs, Each transaction ID must be 64 hexadecimal characters and separated by spaces.",
      "transaction_ids": "Transaction IDs",
      "enter_transaction_ids_validator":
          "Please enter at least one transaction ID to begin synchronization.",
      "enter_transaction_ids_validator2":
          "Some of the provided transaction IDs are not valid 32-byte hexadecimal strings",
      "some_transaction_missing":
          "Certain transactions appear to be missing. Please ensure they are valid and accessible.",
      "page_required_address":
          "At least one active address is required to access the requested page.",
      "page_required_multisig_address":
          "Multi-signature address is required to access the requested page.",
      "duplicate_transaction_ids_detected":
          "Duplicate transaction IDs detected.",
      "invalid_daemon_repsone": "Invalid daemon response",
      "monero_empty_outputs_desc":
          "We did not find any outputs for your accounts in these transactions.",
      "output_has_already_spent": "The output has already been spent.",
      "output_is_ready_to_spent": "The output is ready to be spent.",
      "payment_information": "Payment informations.",
      "monero_payment_synced_desc":
          "The following payments are already synced with your accounts.",
      "sync_more": "Sync more",
      "monero_tx_integrated_address_alert":
          "Integrated addresses cannot be used in a transaction with multiple recipients.",
      "failed_to_unlock_output": "Failed to unlock the output.",
      "output_is_not_ready_for_spending":
          "The output is not yet ready for spending.",
      "show_proofs": "Show proofs",
      "proof": "Proof",
      "invalid_daemon_distribution_response":
          "Invalid daemon output Distribution response.",
      "generate_rct_faild":
          "Failed to generate Ring Confidential Transaction (RCT)",
      "monero_utxo_lake_of_confirmatins_desc":
          "Lack of confirmations. UTXOs must have at least 10 confirmations before they can be spent.",
      "account_tx_detected_desc":
          "Account transaction detected. Tap to proceed.",
      "monero_block_height_sync_desc":
          "Synchronizing transactions from a specified block height.",
      "monero_block_height_sync_desc2":
          "Synchronize your wallet's current state by specifying a start and end block height.",
      "monero_block_height_sync_desc3":
          "This process may take significant time, especially for ranges spanning millions of blocks, potentially a day or longer. Ensure you accurately set the start and end block heights to include all relevant transactions.",
      "start_at_block": "Start at block",
      "end_at_block": "End at block",
      "monero_rct_block_validator":
          "Wallet supports RCT Transactions only from block ___1__ onward.",
      "end_block_number_validator":
          "End block must be greater than start block.",
      "submiting_sync_process": "Submitting synchronization process.",
      "select_accounts_for_syncing": "Select the accounts you want to sync.",
      "primary_address": "Primary address",
      "addresses": "Addresses",
      "at_least_one_account_required": "At least one address is required.",
      "monero_invalid_end_block_height_validator":
          "The end block is greater than the current block height.",
      "tap_to_add_account": "Tap to add a new account.",
      "wallet_rpc": "Wallet RPC",
      "block": "Block",
      "invalid_url": "Invalid url format.",
      "key_derivation_disabled_desc": "Derivation disabled for this key type",
      "monero_fetching_Wallet_available_transfers":
          "Fetching wallet available transfers. Please wait.",
      "monero_wallet_rpc_sync_desc2":
          "The default Monero Wallet RPC URL ends with 'json_rpc'. Please ensure you have entered the correct URL.",
      "monero_wallet_rpc_sync_no_tx_found_desc":
          "No incoming transactions were found for your current account or subaccounts",
      "wallet_rpc_different_account_response_desc":
          "Monero wallet returned an account that does not match any of your wallet accounts.",
      "monero_fetching_wallet_addresses":
          "Fetching wallet addresses. Please wait.",
      "monero_wallet_rpc_safty_interacting_desc":
          "For safety when interacting with Wallet RPC, ensure that you enable the '--restricted-rpc' option when running the Wallet RPC.",
      "sync_information": "Sync Information",
      "view_account_block_sync": "View account block sync information",
      "current_block_height": "Current block height",
      "fetched_blocks": "Fetched blocks",
      "create_token": "Create token",
      "compressed_public_key": "Compressed public key",
      "generatare_from_compressed_public_key":
          "Generate from the compressed public key.",
      "public_key_required_derive_address":
          "Public key needed to derive the address",
      "add_to_address": "Add to addresses",
      "account_tokens": "Account tokens",
      "choose_payment_currency": "Choose Payment Currency",
      "xrp_create_token_desc":
          "Ensure the token does not already exist. If you attempt to create a token that already exists in your account with the same issuer and currency, the existing token will be selected instead.",
      "ripple_provider_network_id_validator":
          "The Network id is incompatible with the current network.",
      "api_url": "API URL",
      "spl_token_invalid_associated_account_address":
          "The destination address does not have an associated token account for the specified SPL token.",
      "system_program": "System program",
      "spl_token": "SPL-Token",
      "spl_token2022": "SPL-Token2022",
      "solana_spl_token_required_public_key":
          "Sending tokens to an inactive account requires a valid public key instead of a PDA address.",
      "cardano_enter_pool_id_desc":
          "Enter the unique ID of your stake pool for delegation.",
      "setup_pool_id": "Setup pool ID",
      "cardano_pool_id_validator": "Please enter a valid Cardano pool ID.",
      "signer_account_does_not_exists":
          "The Signer account has not been found.",
      "reward_address": "Reward address",
      "cardano_network_magic_validator":
          "The network magic is incompatible with the current network.",
      "assets_balance_not_supported_desc":
          "The current version of the wallet does not support or validate asset metadata, and the balance only accepts whole numbers (no decimals).",
      "pick_token": "Pick token",
      "requested_chain_differs":
          "The requested chain differs from your wallet's chain.",
      "mainnet": "Mainnet",
      "chain_type": "Chain type",
      "select_cosmos_chain_type_desc":
          "Please select the chain type to retrieve all related chains.",
      "retrieving_chains": "Retrieving chains. Please wait.",
      "import_manually": "Import manually",
      "chain_not_found_import_manually_desc":
          "We couldn't find the chain with the provided name. Please import it manually.",
      "select_network_to_import_desc": "Select the network you want to import.",
      "fee_token": "Fee token",
      "denom": "Denom",
      "token_demination_desc": "Please enter the token denomination",
      "key_alg": "Key algorithm",
      "cosmos_key_alg_desc":
          "Algorithm used for key generation and transaction signing",
      "cosmos_key_alg_desc2":
          "Unable to verify the network key algorithm. Ensure the selected key algorithm is correct before continuing. An incorrect selection may generate an invalid address and result in permanent loss of funds.",
      "cosmos_unknown_key_algorithm_desc":
          "Unknown network key algorithm. Continuing with an incorrect algorithm may generate an invalid address and result in permanent loss of funds. Continue?",
      "verify_key_algorithm": "Verify Key Algorithm",
      "native_token": "Native token",
      "enter_tendermint_rpc_desc":
          "Enter the Tendermint RPC URL of the chain for interaction.",
      "unsupported_network_key_alg":
          "The network's key algorithm is not supported.",
      "import_network_experimental_feature_desc":
          "This feature is experimental. Please carefully verify all information about the chain before importing it into your wallet.",
      "cosmis_fee_limit_desc":
          "Specify the maximum gas units for this transaction on the Cosmos blockchain.",
      "invalid_token_exponent": "Invalid token exponent.",
      "tap_to_setup_native_token": "Tap to set up the native token.",
      "fee_tokens": "Fee tokens",
      "tap_to_add_new_fee_token": "Tap to add a new fee token",
      "token_name": "Token name",
      "token_decimal_max18_validator":
          "Token decimals must be between 0 and 18.",
      "setup_token": "Setup token",
      "remove_token_from_fee_token_list_desc":
          "Remove token from the fee tokens list?",
      "at_least_one_fee_token_required": "At least one fee token is required.",
      "network_token_required": "The network's native token is required.",
      "cosmos_update_token_desc":
          "Ensure the token denomination and decimals are entered correctly; otherwise, the import operation will fail.",
      "cosmos_fee_token_desc":
          "The token is used for paying fees. In most networks, this is the native token.",
      "select_key_algorithm_desc": "Please select a key algorithm.",
      "min_gas_price": "Min gas price",
      "avarage_gas_price": "Avarage gas price",
      "high_gas_price": "High gas price",
      "comsos_gas_price_desc":
          "This field is multiplied by the transaction gas limit to calculate the transaction fee.",
      "gas_price_validator":
          "Please enter a valid gas price as a double value.",
      "stellar_asset_trust_path_limit_exceeded":
          "Asset trust path limit exceeded.",
      "stellar_destination_lacks_trust_path":
          "The destination lacks a trust path for this token.",
      "tx_submit_response_failed_desc":
          "Failed to submit the transaction response. Please check the block explorer for details.",
      "seed_phrase": "Seed Phrase",
      "external_keys": "External keys",
      "activity": "Activity",
      "transaction": "Transaction",
      "monero_mnemonic": "Monero Mnemonic",
      "generate_monero_private_key":
          "Generate a private key from your Monero mnemonic.",
      "monero_mnemonic_desc":
          "The Monero network uses its algorithm to generate private keys from mnemonics. You can create or import a Monero mnemonic, convert it to a private key, and import it into your wallet.",
      "monero_menonic_validator":
          "Please enter your mnemonic phrase below, consisting of 12, 13, 24, or 25 words, separated by spaces.",
      "addresses_and_initial_sync_block":
          "The addresses and the initial sync block",
      "default_chain_sync": "Default chain synchronization",
      "requested_synchronizations": "Requested synchronizations ___1__",
      "available_synchronizations": "Available synchronizations",
      "faliled_blocks": "Failed blocks",
      "stream_closed_desc":
          "Cannot access the stream. it has already been closed",
      "stream_does_not_exists": "Stream does not exist.",
      "canceled": "Canceled",
      "paused": "Paused",
      "synced": "Synced",
      "process": "In Process",
      "pending": "Pending",
      "invalid_or_unsuported_dgiest_auth":
          "Invalid or unsuported Digest Authentication headers.",
      "username": "Username",
      "realm": "Realm",
      "maintain_monero_wallet_rpc_connection": "Maintain Wallet RPC Connection",
      "store_wallet_rpc_connection":
          "Your Wallet RPC information is stored to assist in syncing accounts, UTXOs, and transactions.",
      "already_connected_to_monero_wallet_rpc":
          "You are already connected to the Monero Wallet RPC.",
      "disconnect_from_wallet_rpc": "Disconnect from the Wallet RPC.",
      "disconnect_from_monero_wallet_rpc_desc":
          "The Wallet RPC information will be removed from your account. Are you sure you want to proceed?",
      "no_acitve_provider": "No provider is currently active.",
      "spend_public_key": "Spend public key",
      "view_public_key": "View public key",
      "spend_private_key": "Spend private key",
      "view_private_key": "View private key",
      "transaction_not_found": "Transaction not found.",
      "generate_transaction_proof": "Generate transaction proof",
      "choose_account_received_payment":
          "Choose the account that received the payment.",
      "monero_tx_proof_message_desc":
          "The message of the proof, if provided, is essential for verification.",
      "setup_message": "Setup message",
      "invalid_transaction_id":
          "Invalid transaction ID. the transaction ID must be a 32-byte hexadecimal string.",
      "monero_tx_proof_desc3":
          "Monero generates a transaction proof to verify payment details using the transaction ID, address, and an optional message.",
      "transaction_proof": "Transaction Proof",
      "payment_transaction_id": "The transaction ID of the payment.",
      "generating_proof_please_wait": "Generating proof. Please wait.",
      "verify_transaction_proof": "Verify transaction proof",
      "monero_verify_proof_desc":
          "Monero verifies a transaction proof using the transaction ID, recipient address, optional message, and the provided proof signature",
      "signature": "Signature",
      "monero_proof_validator":
          "Invalid Monero proof. the proof must start with 'InProofV2' or 'OutProofV2'",
      "message_of_the_proof": "The message of the proof",
      "verify": "Verify",
      "verification_failed_no_amount_received":
          "Verification failed. No amount received in this transaction.",
      "spent_in_pool": "Spent in pool",
      "data_casting_failed": "Data conversion unsuccessful",
      "cosmos_enter_hrp_desc":
          "Enter the network address prefix (HRP), or leave blank to determine it from the RPC.",
      "enter_network_hrp_validator": "Please enter a valid network HRP.",
      "address_prefix_hrp": "Address prefix (HRP)",
      "unable_to_retrieve_hrp":
          "Unable to retrieve HRP from RPC. Please provide it.",
      "different_network_hrp":
          "Invalid HRP. The network returned a different HRP.",
      "add_new_network": "Add new ___1__ network",
      "http_api_url": "HTTP API URL",
      "json_rpc_solidity_url": "JSON RPC URL(EVM)",
      "paste_your_backup_here": "Paste your backup data here",
      "constants": "Constants",
      "access_network_constants": "Access network constants.",
      "retrieving_constants_please_wait": "Retrieving Constants, please wait",
      "storages": "Storages",
      "query_network_storages": "Query network storages",
      "query_again": "Query again",
      "retrieving_data_please_wait": "Retrieving data, please wait",
      "get_storages": "Query Storages",
      "inputs_not_needed": "Inputs not needed.",
      "bytes": "Bytes",
      "invalid_hex_validator":
          "Invalid hex format. Please enter the value in hexadecimal format",
      "invalid_hex_length":
          "The hexadecimal value must be a ___1__-character string (___2__ bytes).",
      "runtime_apis": "Runtime API's",
      "interact_with_substrate_network_run_time_api":
          "Interact with network runtime API's.",
      "call_api": "Call API",
      "call_again": "Call again",
      "tap_to_create_object": "Tap to create ___1__ object.",
      "create_extrinsic": "Create Extrinsic",
      "create_and_sign_extrinsic": "Create and sign extrinsic",
      "create_payload": "Create payload",
      "address_decoder": "Address decoder",
      "utf8_encoder": "UTF-8 encoder",
      "spec_version": "Spec Version",
      "bytes_tools": "Bytes tools",
      "bytes_tools_desc":
          "Bytes Tools: Convert hex bytes to addresses or compute hashes from them",
      "convert": "Convert",
      "finaliz_block_era": "Finaliz Block and Era",
      "finaliz_block": "Finaliz Block",
      "genesis_hash": "Genesis hash",
      "era": "Era",
      "quick_era": "Era: Validated for approximately 150 blocks.",
      "substrate_quick_block_access": "Quick block access",
      "serialized_data": "Serialized Data",
      "serialized_call": "Serialized Call",
      "payload_info": "Payload info",
      "some_input_not_filled": "Some inputs are not filled.",
      "extrinsic": "Extrinsic",
      "payload": "Payload",
      "fake_extrinsic_signature_desc":
          "The extrinsic contains a fake signature. The actual signature is added to the extrinsic when it is submitted.",
      "token_decimal_maxn_validator":
          "Token decimals must be between 0 and ___1__.",
      "unsuported_network_metadata": "Unsuported network metadata.",
      "extrinsic_encoding_failed": "Extrinsic encoding failed.",
      "websocket_authenticated_unsuported_desc":
          "The provided authentication method is incompatible with WebSocket connections.",
      "ss58_prefix": "SS58 Prefix",
      "substrate_disable_transfer_option_desc":
          "Unable to find the transfer_allow_death and transfer_keep_alive methods. The transfer option will be disabled.",
      "substrate_unsuported_account_template_desc":
          "Unsupported account template. The account balance will always display as zero.",
      "add_or_updating_wallet_network":
          "Add or updating wallet network. please wait.",
      "page_not_found": "Page not found.",
      "web3_retrieval_requirment": "Web3 Retrieval Requirements. please wait.",
      "number_to_decimal": "10^___1__ (___2__)",
      "update_metadata": "Update metadata",
      "substrate_update_metadata_desc":
          "The client has requested an update to your network metadata.",
      "invalid_spec_version": "Invalid spec version.",
      "select_provider_to_use":
          "Please select one of the providers you want to use when interacting chain",
      "keep_unlock": "Keep unlock",
      "wallet_lock_timer_desc":
          "The wallet will be locked after ___1__ seconds",
      "web3_permission": "Web3 Application Permission",
      "aptos_select_provider_desc":
          "Choose a network service for Full Node and GraphQL interaction.",
      "full_node": "Full Node",
      "graphql": "GraphQL",
      "leak_of_gas_token_desc":
          "Your account doesn't have enough Gas tokens to cover the fee.",
      "threshold_validator":
          "The threshold value must range between ___1__ and ___2__.",
      "setup_multisig_address": "Setup multisig address",
      "multisig_address": "Multisig address",
      "multisig_address_desc":
          "Multisig addresses enhance security by requiring multiple approvals for transactions, reducing the risk of unauthorized access.",
      "mutlisig_address_alert":
          "All options on this page are crucial. Missing any details or altering the account order may pose risks. Please fill them out carefully.",
      "multisig_address_weight_desc":
          "Address weight in a multi-sig determines its voting power for transaction approvals",
      "address_weight_validator":
          "Invalid address weight. It must be between ___1__ and ___2__ ",
      "invalid_signature": "Invalid signature.",
      "insufficient_signatures": "Insufficient signatures.",
      "exceeded_multisig_maximum_publickey":
          "Exceeded the maximum allowed public keys for a multisig account.",
      "multisig_address_infos": "Multisig address info",
      "address_info": "Address info",
      "invalid_account": "Invalid account.",
      "locking_script": "Locking Script",
      "at_least_n_account_required": "At least ___1__ address is required.",
      "aptos_required_signature_validator":
          "The required signature value must range between ___1__ and ___2__.",
      "aptos_required_signature_validator2":
          "The number of accounts must meet the specified required signature.",
      "required_signature": "Required signature",
      "required_signature_desc":
          "the number of signatures required to confirm the transaction",
      "aptos_mutli_ed25519_key_type_validator":
          "A MultiED25519 account can only be generated using an ED25519 public key.",
      "key_scheme": "Key scheme",
      "invalid_key_scheme": "Invalid key scheme.",
      "transaction_content": "Transaction content",
      "transaction_owner": "Transaction owner",
      "transaction_fee_payer": "Transaction fee payer",
      "secondary_signer_addresses": "Secondary signer addresses",
      "simulate_content": "Simulate content",
      "no_web3_activities": "No Web3 activities available.",
      "remove_activities": "Remove activities.",
      "delete_all_activities_desc": "Delete all application activities.",
      "delete_all_activities_desc2":
          "Delete all application activities? This action cannot be undone",
      "balance_changes": "Balance changes",
      "client_closed_durning_request":
          "The connection between the client and wallet was lost during the request.",
      "sui_key_conversion": "Sui key conversion",
      "sui_key_conversion_desc":
          "Convert a Sui Bech32 secret key into an private key for secure cryptographic operations on the Sui network.",
      "aptos_key_conversion_desc":
          "Convert a Aptos AIP-80 secret key into an private key for secure cryptographic operations on the Aptos network.",
      // AIP-80
      "invalid_sui_secret_key": "Invalid Sui secret key.",
      "sui_bech32_secret_key_desc2":
          "Please enter a valid Sui Bech32 secret key. The key must start with 'suiprivkey'.",
      "n_style": "___1__ style",
      "aptos_key_conversion": "Aptos key conversion",
      "aptos_aip80_private_key_desc2":
          "Please enter a valid Aptos AIP-80 private key.  The key must start with 'ed25519-priv-' or 'secp256k1-priv-'",
      "invalid_aptos_private_key": "Invalid Aptos private key.",
      "messages": "Messages",
      "message_bytes": "Message bytes",
      "message_content": "Message content",
      "cosmos_gas_limit_desc":
          "The maximum amount of computational units the transaction can consume before it fails.",
      "fee_amount": "Fee amount",
      "log": "Log",
      "events": "Events",
      "key": "Key",
      "value": "Value",
      "tap_to_show_events": "Tap to show events.",
      "messages_response": "Messages response",
      "tap_to_show_response": "Tap to response.",
      "ibc_transfer": "IBC Transfer",
      "destination_chain": "Destination chain",
      "cosmos_destination_chain_dest":
          "Please select the destination chain. If the specified network doesn't exist, import the chain into the wallet first.",
      "select_token_for_transfer": "Select a token for transfer",
      "ibc_desc":
          "IBC enables secure communication and token transfers between blockchains",
      "transfer_token": "Transfer token",
      "tap_to_select_token": "Tap to select token",
      "update_unknown_token_metadata_desc":
          "Unknown token metadata. Please update all token details, including decimals, name, and symbol, before adding it to your wallet.",
      "channel_id_required": "Channel id is required.",
      "ibc_channel_desc":
          "An IBC channel ID identifies a communication channel between two Cosmos blockchains.",
      "channel_id": "Channel ID",
      "ibc_channel_validator":
          "Invalid IBC channel ID. It should be in the format 'channel-{number}'",
      "cosmos_chains": "Cosmos chains",
      "ibc_retrieval_requirements": "IBC Retrieval Requirements",
      "source_chain": "Source chain",
      "save_channel_id": "Save channel ID",
      "channel_name": "Channel name",
      "channel_id_saved": "Channel ID has been saved.",
      "channel_name_desc": "Enter the channel name to retrieve its ID easily",
      "pick_channel": "Pick channel",
      "saved_channels": "Saved channels",
      "check_channel_connection": "Check channel connection",
      "check_channel_connection_desc":
          "Verify the connection between the source and destination chain",
      "channel_not_found": "Channel not found.",
      "ibc_channel_incorrect_state":
          "Connection failed: Source channel is not in an open state.",
      "checking_chain_channel_id_connection":
          "Checking ___1__ Ibc channel connection. please wait.",
      "ibc_source_destination_version_mismatch":
          "Version mismatch between source and destination channels.",
      "transaction_timeout": "Transaction timeout",
      "list_of_transfers": "List of transfers",
      "tap_to_add_new_transfer": "Tap to add new transfer",
      "your_account_inputs": "Your accounts inputs",
      "total_input_amounts": "Total input amounts",
      "script": "Script",
      "bitcoin_modifiable_sighash_warning":
          "A modifiable SIGHASH type detected! Your transaction outputs can be altered, potentially allowing all your UTXO balance to be spent.",
      "inputs_from_your_accounts": "Inputs from your accounts",
      "amount_will_be_returned_back_to_account":
          "The amount will be returned to your account",
      "tap_to_choose_utxos": "Tap to choose UTXOs.",
      "choose_utxos": "Choose UTXOs",
      'issued_at': "Issued at",
      "nonce": "Nonce",
      "not_before": "Not before",
      "request_id": "Request ID",
      "statement": "Statement",
      "resources": "Resources",
      'sign_in_data': "Sig-In Data",
      'support_by_application': "Support by application",
      "unsupported_by_application": "Unsupported by application",
      "some_required_field_not_filled": "Some required fields are not filled",
      "back_to_previous_page": "Back to previous page",
      "all_entered_information_will_be_lost":
          "All entered information will be lost.",
      "http_connection_closed": "The connection to the server was closed.",
      "swap": "Swap",
      "format_exception": "The data format is invalid.",
      "timeout_exception": "The operation took too long and timed out.",
      "socket_exception":
          "Network error. Please check your internet connection.",
      "http_exception": "There was a problem with the HTTP request.",
      "range_error": "A value is out of the allowed range.",
      "argument_error": "An invalid argument was provided.",
      "state_error":
          "The operation couldn’t be performed in the current state.",
      "unimplemented_error": "This feature hasn’t been implemented yet.",
      "unsupported_error": "This operation is not supported.",
      "assertion_error": "An internal assertion failed.",
      "cast_error": "A value couldn’t be cast to the expected type.",
      "type_error": "An unexpected type was used.",
      "api_connection_failed": "API connection failed.",

      /// swap
      'no_token_found': "Token not found.",

      "routes": "Routes",
      "fees": "Fees",
      "no_swap_route_found": "No swap route was found for the selected tokens.",
      "swap_now": "Swap Now",
      "connect": "Connect",
      "disconnect": "Disconnect",
      "source": "Source",
      "destionation": "Destination",
      "token": "Token",
      "input": "Input",
      "function": "Function",
      "contract_intraction": "Contract interaction",
      "channel_information": "Channel Information",
      "channel": "Channel",
      "route": "Route",

      "tap_to_review_fees": "Tap to review fees",

      "tolerance": "Tolerance",
      "max_tolerance": "Max Tolerance",
      "max_tolerance_desc":
          "Only show routes with a slippage below this threshold. This setting is applied only when market prices for both the source and destination assets are available.",
      "lowest_expected_amount": "Lowest Expected Amount",
      "market_price_unavailable": "Market price unavailable",
      "expected_swap_duration": "Expected swap duration",
      "sign_and_send_transaction": "Sign and broadcast",
      "networks": "Networks",
      "generating_transaction": "Generating transaction",
      "signing_transaction": "Signing Transaction",
      "broadcasting_transaction": "Broadcasting transaction",
      "complete": "Complete",
      "close_swap_page_desc":
          "A swap is currently in progress. Do you really want to leave this page?",
      "close_page": "Close page",
      "wallets": "Wallets",
      "transaction_confirmation_failed": "Transaction confirmation failed.",
      "mint_account_not_found": "Mint account not found.",
      "invalid_mint_account_owner": "Invalid mint account owner.",
      "network_client_initialize_failed":
          "Network client initialization failed.",
      "source_accounts": "Source accounts",
      "invalid_swap_information": "Invalid swap route information.",
      "bitcoin_account_must_spend":
          "The ___1__ must spend at least one UTXO in this transaction.",
      "invalid_swap_asset": "Invalid swap asset.",
      "remark": "Remark",
      "data": "Data",
      "testnets": "Testnets",
      "page_retrieval_requirment": "Page Retrieval Requirements",
      "failed": "Failed",
      "ton_address_is_freez_desc":
          "Your TON address is currently frozen. This wallet does not support the unfreeze feature. Please use the official TON tools to unfreeze your account.",
      "custom_key_derivation_desc":
          "Key derivation path. If using a custom path, be sure to record it securely—losing it could result in loss of access to your address and funds.",
      "cannot_send_transfer_to_your_self":
          "can't send the transfer to yourself",
      "op_return_length_validator":
          "Transactions are limited to a maximum of ___1__ bytes in the OP_RETURN output.",
      "tap_to_generate_transaction_proof": "Tap to Generate transaction proof",
      "transaction_input_exceeds_16_desc":
          "Transaction input limit exceeded: only 16 UTXOs allowed.",
      "transaction_output_exceeds_16_desc":
          "Transaction output limit exceeded: only 16 recipients allowed.",
      "connecting_to_network": "Connecting to network",
      "remove_transaction_from_account":
          "Remove transaction from Your Account?",
      "remove_transaction": "Remove transaction",
      "manage_your_account_contacts": "Manage your account contacts.",
      "remove_contact_from_account": "Remove contact from Your Account?",
      "remove_contact": "Remove contact",
      "add_new_contact_desc":
          "Contacts must have a unique name and address within an account. Otherwise, a 'Contact already exists' error will be shown.",
      "tabs": "Tabs",
      "client_permission_have_been_updated":
          "Client permissions have been updated",
      "remove_histories": "Remove histories",
      "remove_all_histories": "Remove all histories?",
      "remove_bookmarks": "Remove bookmarks",
      "remove_all_bookmarks": "Remove all bookmarks?",
      "webview": "WebView",
      "enable_webview_application": "Enable webview application",
      "enable_swap_application": "Enable swap application",
      "invalid_chain_state": "Operation not allowed: invalid chain state.",
      "sync_network": "Sync network",
      "monero_sync_block_desc":
          "Fetching blockchain data to synchronize Monero accounts",
      "monero_sync_block_desc6":
          "Multiple requests with the same range are not allowed.",
      "monero_sync_block_desc3":
          "This option only works with one Monero network at the same time",
      "monero_sync_block_desc4":
          "This option creates a request starting from the current network block and begins syncing from that point. You can also create multiple requests for specific block ranges.",
      "monero_sync_block_desc5":
          "Enable this feature only if your account is active. It consumes significant internet bandwidth and CPU resources. Changing this option will disable all processes on the previous network. Use the none option if there is no activity on any Monero network.",

      "monero_create_block_request_desc":
          "To create requests for specific block ranges, you must switch to the currently active network.",
      "tap_to_create_new_request": "Tap to create a new request",
      "sync_request": "Sync request",
      "block_height_already_exists":
          "A request already exists within this block height range.",
      "sync_account_with_blockchain_data": "Sync account with blockchain data",
      "chain_synchronization_disabled_desc":
          "Synchronization is not active for the current chain.",
      "remove_sync_block_request_from_account":
          "Remove sync block request from Your Account?",
      "removing_request_please_wait": "Removing request. please wait",
      "fetching_current_block_data": "Fetching current block data",
      "swap_settings": "Swap settings",
      "at_least_one_provider_must_enabled":
          "At least one service provider must be enabled.",
      "tolerance_disabled": "Tolerance disabled",
      "invalid_cardano_address_details": "Invalid cardano address details.",
      "initialize_app_failed": "initialize app failed. unknown context",
      "open_in_new_tab": "Open in new tab",
      "open_as_popup": "Open as popup",
      "opn_in_side_panel": "Open in side panel",
      "duplicate_wallet_instance": "Duplicate Wallet Instance",
      "duplicate_wallet_instance_alert":
          "A wallet is already open in another instance.",
      "manage_network_service_providers": "Manage network service providers",
      "unsuported_backup_version": "Unsuported backup version",
      "imported_key_derivation_not_allowed":
          "Key derivation is not supported for imported keys.",

      "invalid_key_derivation": "Invalid key derivation.",
      "press_back_button_twice": "Press the back button twice to exit the app.",
      "account_index": "Account index",
      "wallet_version": "Wallet version",
      "type": "Type",
      "sub_or_wallet_id": "Sub/Wallet Id",
      "muxed_id": "Muxed id",
      "base_address": "Base address",
      "sessions": "Sessions",
      "loading_sessions_please_wait":
          "Loading WalletConnect sessions. Please wait.",
      "remove_session": "Remove session",
      "remove_session_desc":
          "Are you sure you want to remove this session? All associated activity will be deleted.",
      "session_has_been_removed": "Session has been removed.",
      "clear_dapp_permissions": "Clear DApp Permissions",
      "reset_dapp_desc":
          "Delete all application permissions and activities? This action cannot be undone",
      "application_updated": "Application has been updated.",
      "application_removed": "Application has been removed.",
      "backup_options": "Backup Options",
      "backup_options_desc":
          "Choose the wallet sections you'd like to back up.",
      "mnemonic_seed_hd_wallet_elements":
          "Mnemonic, seed, and other HD wallet elements",
      "encrypted": "Encrypted",
      "non_encrypted": "Non-Encrypted",
      "select_network_for_backup": "Select the network for backup.",
      "setup_chains": "Setup chains",
      "networks_and_addresses": "Networks and addresses",
      "use_current_wallet_password": "Use current wallet password",
      "use_new_password": "Use new password",
      "unsupported_swap_asset": "Unsuported swap asset.",

      /// wc
      "invalid_pairing_url": "Invalid pairing url.",
      "unsuported_pairing_url": "Unsuported pairing url.",
      "unsuported_wc_method":
          "Wallet does not support the required pairing methods.",
      "pairing_canceled_by_dapp": "Pairing channel canceled by the client.",
      "unsuported_required_namespace": "Unsupported required namespaces.",
      "wc_internal_error": "An error occurred during the request",
      "wc_publis_message_timeout":
          "Failed to publish message: request timed out.",
      "wc_message_replaced": "Failed to publish message: message replaced.",
      "wc_client_request_timed_out": "Client request timed out.",
      "pairing_request_timeout": "Pairing request timed out.",

      "enable_wallet_connect": "Enable wallet connect",
      "disable": "Disable",
      "no_network_connection": "No network connection",
      "pairing_url": "Pairing url",
      "pairing_please_wait": "Pairing. Please wait",
      "pair_with_new_client": "Pair with New Client",
      "enter_pairing_url_for_connect": "Enter the pairing URL to connect.",
      "wallet_connect_management": "WalletConnect Management",
      "manage_and_pair": "Manage and pair",
      "tap_to_pair_with_new_client": "Tap to pair with a new client.",
      "wallet_management": "Wallet Management",
      "wallet_management_desc": "Switch or create new wallet",
      "swap_setting_desc": "Configure providers and networks",
      "connection_terminated": "The connection to the server was terminated",
      "dapps_management": "DApps Management",
      "dapps_permissions": "DApps Permissions",
      "invalid_backup_options": "Invalid backup options",

      "loading_applications_please_wait": "Loading applications. Please wait",
      "dapps_management_desc": "Manage DApps permissions",
      "generate_backup_desc2":
          "Warning: Only a backup of the currently active wallet will be generated. If you have multiple wallets, make sure to switch to each wallet individually and generate a backup for each one.",
      "web3_dapp_update_permission_alert":
          "This application requires at least one authorized account on the following network(s): ___1__. If you update the permissions without providing the required accounts, the request will be rejected. Do you want to update permissions and reject the request?",
      "unable_to_verify_page_origin": "Unable to verify the page's origin.",
      "page_didnot_work_as_expected":
          "The page didn’t work as expected. Please reload.",
      "client_disabled_desc":
          "Client is disabled. All requests will be blocked.",
      "field_is_required": "___1__ is required.",
      "transaction_fee_has_been_updated": "Transaction fee has been updated.",
      "at_least_one_recipient_required": "At least one recipient required.",
      "some_amount_fields_not_filled": "Some amounts fields not filled.",
      "some_required_fields_not_filled": "Some required fields not filled.",
      "amount_required_for_create_account":
          "An amount is required to create the account.",
      "send_to_self_not_allowed":
          "Sending XRP to your own address is not allowed.",
      "add_jetton_to_transfer": "Add a jetton to transfer",
      "message_setting_updated": "Message settings have been updated.",
      "jetton_transfer_options": "Jetton transfer options",
      "storage_fee": "Storage fee",
      "gas_fee": "Gas fee",
      "action_fee": "Action fee",
      "simulate_transaction_fee_failed": "Failed to simulate transaction fee.",
      "no_delegated_resources_found": "No delegated resources found.",
      "field_filled_incorrectly": "The field ___1__ is filled incorrectly.",
      "maximum_item_for_field":
          "A maximum of ___1__ items is allowed for ___2__",
      "add_stellar_new_operation_desc":
          "Please fill in all operation fields to add them to the transaction.",
      "skip_create_operations": "Skip operations?",
      "skip_operations_desc": "Do you want to skip creating operations?",
      "enter_valid_address_validator": "Please enter a valid ___1__ address.",
      "convert_address_to_bytes": "Encode address as hexadecimal bytes.",
      "transaction_expired": "Transaction has been expired.",
      "setup_transfer": "Setup transfer",
      "add_cosmos_new_ibc_transfer_desc":
          "Please fill in all transfer fields to add them to the transaction.",
      "skip_transfer_desc": "Do you want to skip creating transfer?",
      "skip_transfer": "Skip creating transfer?",
      "transaction_submission_error": "Transaction submission failed: ___1__",
      "amount_must_be_greater_than_zero":
          "The amount must be greater than zero",
      "sending_token_to_non_bitcoin_cash_token_address_desc":
          "You are sending a Bitcoin Cash token to a non-Bitcoin Cash token address",
      "sending_large_bch_to_token_address_desc":
          "You are sending a large BCH amount to a Bitcoin Cash token address",
      "tap_to_create_burn_operation": "Tap to create burn operation",
      "tokens_burn_in_transaction_desc":
          "Tokens will be burned in this transaction.",
      "update_utxo_durning_build_transaction_desc":
          "Select all desired UTXOs before building the transaction. Modifying UTXOs during the process may discard your changes.",
      "n_item_selected": "___1__ item selected.",
      "ton_jetton_transfer_ton_amount_desc":
          "This amount is used to process the Jetton transfer. Any remaining amount will be returned to your account. If you want to transfer both TON and Jettons to the recipient address, please use the 'Forward Amount' option.",
      "creating_transaction": "Creating transaction. Please wait",
      "broadcast_to_the_network_please_wait":
          "Broadcast to the network. Please wait",
      "text": "Text",
      "total_selected_amount": "Total selected amount",
      "ripple_choose_token_for_trust_path": "Choose Token for Trust Path",
      "trust_line_limit": "Trust line limit",
      "token_to_offer": "Token to offer",
      "offer_amount": "Offer amount",
      "request_has_been_processed_successfully":
          "The request has been processed successfully.",
      "substrate_keep_alive_min_desc":
          "Insufficient balance: the KeepAlive method requires your account to keep at least ___1__ after fees and transfer.",
      "account_will_be_deactivated_after_transaction":
          "Your account will be deactivated after this transaction.",
      "wallet_data_verification_failed":
          "Wallet data is invalid or corrupted. Verification failed.",
      "transaction_confirmed_in_block": "Transaction confirmed in block",
      "unable_to_confirm_transaction":
          "Unable to confirm transaction status – please check again later",
      "transaction_submission_failed": "Transaction submission failed",

      "database_initialization_failed_desc":
          "Database initialization failed. unsupported format or missing files.",
      "block_tracking_per_thread": "Block Tracking per Thread",
      "generate_public_key": "Generate public key",
      "generating_public_key_please_wait": "Generating public key. Please wait",
      "base_credential": "Base credential",
      "stake_credential": "Stake credential",
      "tap_to_chose_or_create_public_key":
          "Tap to choose or create a public key",
      "at_least_n_public_keys_required": "At least ___1__ public keys required",
      "fill_out_base_address_credential":
          "Fill out the form for your base address credential",
      "fill_out_base_address_stake_credential":
          "Fill out the form for your base address stake credential",
      "choose_public_key_or_generate_new_on":
          "Choose a public key from your account or generate a new one",
      "credential_type": "Credential type",
      "reference_script": "Reference script",
      "at_least_ada_for_collateral":
          "at least ___1__ ADA required for collateral.",
      "ada_max_collateral_amount_desc":
          "Collateral above 25.5 ADA is unnecessary — excess will be locked and at risk.",
      "ada_min_collateral_amount_desc":
          "At least 2 ADA is required for collateral",
      "ada_multi_asset_utxo_not_allowed_for_collateral":
          "Multi-asset UTXOs are not allowed for collateral.",
      "select_collateral_utxos_desc":
          "Only UTXOs from the account you’ve connected to this client can be used. Multi-asset and multisig account UTXOs are not allowed. To proceed, select a suitable ADA-only UTXO in your account and then submit the request.",
      "transaction_inputs": "Transaction inputs",
      "transaction_outputs": "Transaction outputs",
      "signers": "Signers",
      "withdrawals": "Withdrawals",
      "plutus": "Plutus",
      "native_scripts": "Native scripts",
      "metadata": "Metadata",
      "votes": "Votes",
      "vote": "Vote",
      "account_input": "Account input",
      "reference_input": "Reference inputs",
      "collateral_input": "Collateral input",
      "web3_ada_bip32_public_key_request_desc":
          "The client is requesting access to your account’s BIP32 public key.",
      "storage_is_not_available": "Storage is not available.",
      "subwallet": "Sub Wallet",
      "mainwallet": "Main Wallet",
      "type_of_mnemonic": "Type of mnemonic",
      "bip39": "BIP-39",
      "bip39_mnemonic_desc":
          "BIP39 Mnemonic: Use a standard BIP39 mnemonic. allow derivation",
      "monero_mnemonic_desc2":
          "Monero Mnemonic: Monero-compatible mnemonic. no derivation.",
      "ton_mnemonic_desc2":
          "Ton Mnemonic: TON-compatible mnemonic, no derivation.",
      "monero": "Monero",
      "ton": "Ton",
      "mnemonic_passphrase_desc":
          "Extra security feature: adds a secret phrase to your mnemonic.",
      "generating_mnemonic_please_wait": "Generating mnemonic. Please wait",
      "verifying_mnemonic_please_wait": "Verifying mnemonic. Please wait",
      "count_of_mnemonic_word": "Count of mnemonic word",

      "invalid_bip39_mnemonic_words_length":
          "Please enter a valid 12, 15, 18, 21, or 24-word mnemonic phrase with space.",
      "invalid_monero_mnemonic_words_length":
          "Please enter a valid 12, 13, 24 or 25-word Monero mnemonic phrase with space.",
      "invalid_ton_mnemonic_words_length":
          "Please enter a valid 8 to 40-word Ton mnemonic phrase with space.",
      "invalid_mnemonic_desc":
          "Invalid mnemonic phrase. One or more words are missing or incorrect.",
      "validate_backup_content": "Validate backup content",
      "review_backup": "Review backup",
      "sub_wallet_name": "Sub wallet name",
      "enter_sub_wallet_name": "Enter a name for the subwallet",
      "sub_wallet_import_to_current_main_wallet_desc":
          "This subwallet will be added to your current main wallet.",
      "setup_wallet_please_wait": "Setup wallet. Please wait",
      "wallet_has_been_imported": "The wallet has been successfully imported.",
      "input_you_wallet_password": "Input your wallet password",
      "choose_your_mnemonic_type": "Choose your mnemonic type",
      "setup_mnemonic": "Setup mnemonic",
      "security_tips": "Security Tips",
      "agree_to_terms": "Agree to Terms",
      "delete_main_wallet_desc":
          "Do you want to delete the main wallet? All sub-wallets will also be removed.",
      "delete_sub_wallet_desc": "Do you want to delete the sub wallet?",
      "delete_wallet_alert":
          "Warning: This action will remove all accounts and related wallets. Ensure you have a backup before proceeding.",
      "string": "String",
      "true": "true",
      "false": "false",
      "generate_address_desc": "Establishing a single-signature address",

      "invalid_derivation_path": "Invalid key derivation path.",
      "invalid_web3_account_data": "Invalid Web3 account data.",
      "invalid_wallet_transaction_data": "Invalid wallet transaction data.",
      "invalid_price_format": "Invalid price format",
      "socket_connection_failed":
          "Socket connection failed: unable to establish communication with the server.",
      "unexpected_request_data": "Unexpected request data",
      "invalid_request_url": "Invalid request url",
      "tap_to_add_a_subwallet": "Tap to add a subwallet",
      "invalid_account_utxo": "Invalid account utxo",
      "sources": "Sources",
      "invalid_credential":
          "Invalid authentication data: received unexpected credential format.",
      "authenticate": "Authenticate",
      "enable_device_authentication": "Enable Device Authentication",
      "enable_device_authentication_desc":
          "Unlock with Face ID, Touch ID, or passkey after first password login",
      "weak": "Weak",
      "strong": "Strong",
      "auth_failed": "Authentication failed.",
      "unexpected_error": "An unexpected error during process.",
      "tranaction_received": "Transaction Received",
      "incomig_transaction_wallet_unlock_desc":
          "Please unlock your wallet to process incoming transactions.",
      "unlocking_transaction_please_wait": "Unlocking transaction. Please wait",
      "monero_successful_unlock_tx_desc":
          "Unlock successful. transactions have been unlocked and merged into your account.",
      "no_biometric_enrolled": "No biometric enrolled",
      "no_error_found": "No error found.",
      "transaction_state_warning_desc":
          "There are warnings with this transaction. Do you want to continue?",
      "invalid_file_content_desc":
          "The file appears to be invalid or corrupted.",
      "failed_to_read_content": "Failed to read file content.",
      "tab_to_choose_backup_file": "Tab to select backup file",
      "file_save_failed": "File save failed.",
      "invalid_backup_content":
          "Invalid backup. wrong password or corrupted backup",
      "invalid_backup_encoding": "Invalid backup encoding.",
      "verify_backup_desc": "Regenerating each address for verification.",
      "verify_backup": "Verify backup",
      "create_network_please_wait": "Create network. Please wait",
      "multisig_account": "Multi Signature account",
      "please_choose_a_multisig_account":
          "Please choose a multi-signature account",
      "multisig_call_data": "Multisig Call Data",
      "multisig_call_hash": "Multisig Call Hash",
      "multisig_call_data_desc":
          "Encoded call information for multisig execution",
      "multisig_call_hash_desc":
          "Unique hash identifying the multisig call payload",
      "timepoint": "Timepoint",
      "transaction_timepoint": "Transaction timepoint",
      "substrate_timepoint_desc": "Timepoint of the initial approval call.",
      "transaction_weight": "Transaction weight",
      "transaction_weight_const": "Transaction weight cost",
      "ref_time": "Ref time",
      "weight_ref_time_desc": "Estimated execution time",
      "proof_size": "Proof Size",
      "weight_proof_size_desc": "Storage proof data size",
      "setup_weight": "Setup weight",
      "type_of_call_data": "Type of call data",
      "failed_to_decode_call_data": "Failed to decode call data",
      "call": "Call",
      "hash": "Hash",
      "call_data": "Call data",
      "call_data_desc": "Multisig call hash or encoded payload",
      "transaction_not_ready_for_execution":
          "Transaction is not ready for ___1__ execution.",
      "your_account_approved_transaction":
          "Your account has already approved this transaction.",
      "transaction_ready_for_execution":
          "Transaction is ready for ___1__ execution.",
      "choose_signer_address": "Choose a signer",
      "transaction_state_not_ready": "Transaction state is not ready.",
      "invalid_multisig_transaction_data":
          "Invalid multi-signature transaction data",
      "substrate_chose_signer_desc":
          "Choose a signer, and make sure the address you select isn’t a multisig one.",
      "retrieving_transacton_condition":
          "Retrieving transaction condition. Please Wait.",
      "multisig_transactions": "Multi-signature transactions",
      "multisig_transaction": "Multi-signature transaction",
      "n_approvals_required": "As ___1__ approvals are required",
      "ready_for_execution": "Ready for execution",
      "substrate_multisig_deposit_desc":
          "Minimum funds locked for this multisig approval.",
      "account_not_found_in_connected_wallet":
          "Account not found in your connected wallet",
      "substrate_select_multisig_operation_desc":
          "Select an action you’d like to take for this transaction.",
      "choose_a_signer_to_continue": "Please choose a signer to continue.",
      "new_transaction": "New transaction",
      "latest_operation": "Latest operation",
      "multisig_operations": "Multi-signature operation",
      "substrate_multisig_operations_create_desc":
          "Operations for creating and approving multisig transactions.",
      "substrate_multisig_transaction_desc":
          "Manage multisig approvals and signatures in Substrate transactions.",
      "unsupported_current_network_feature":
          "This feature is not available on the current network.",
      "unsupported_multisig_account_operation":
          "The ___1__ operation is not supported for this multisig account.",
      "aprrove_transaction": "Approve transaction",
      "client_is_not_initialized": "Client is not initialized.",
      "transaction_fee_token": "Transaction fee token",
      "choose_token_for_fee_payment": "Choose token for fee payment.",
      "transaction_dry_run_failed": "Transaction dry run execution failed.",
      "convert_fee_amount_failed_to_token":
          "Unable to convert fee amount to ___1__ token.",
      "total_number_of_signers_must_reach_threshold":
          "The number of signers must reach the threshold.",
      "no_xcm_available_route_desc":
          "No available XCM routes between the current network and any wallet networks.",
      "no_transfable_asset_found": "No transferable assets found.",
      "tap_to_choose_destination": "Tap to choose a destination",
      "destination_network": "Destination network",
      "choose_network_transfer_to_desc":
          "Choose the network you want to transfer to",
      "transfers": "Transfers",
      "transfer_multiple_reserve_chains_not_allowed":
          "Transferring assets with multiple reserve chains is not allowed.",
      "destination_fee": "Destination fee",
      "choose_token_for_fee_on_destination_desc":
          "Choose the token you want to pay fees with on the destination chain",
      "no_tokens_available_for_paying_fees_destination_desc":
          "No tokens available for paying fees on the destination chain.",
      "failed_to_calculate_destination_fee":
          "Failed to calculate destination fee.",
      "dry_run_local_destination_desc":
          "Dry-run results for local and destination transaction execution.",
      "unknown_token": "Unknown token",
      "unknown_network": "Unknown network",
      "unsupport_simulation":
          "Transaction simulation is not supported on this network",
      "xcm_deliveries_fee": "XCM Deliveries fee",
      "xcm_simulation_failed_desc":
          "XCM simulation failed to complete successfully.",
      "enable_disable_service_provider_desc":
          "Enable or disable the service provider for the current network.",
      "toggle_between_available_protocols":
          "Toggle between available service protocols (HTTP, WSS, etc.)",
      "available_network_providers": "Available network providers",
      "import_provider": "Import provider",
      "unavailable_token_management_on_this_network":
          "Token management unavailable on this network",
      "eth_chain_not_found_send_transaction_desc":
          "___1__ Ethereum chain not found. Please add it to your wallet before sending transaction.",
      "missing_ethereum_account":
          "Account missing on ___1__ chain. Verify your current address is on Ethereum.",
      "xcm_transfer": "XCM Transfer",
      "transaction_not_detected_on_the_destination_network_desc":
          "Transaction not detected on the destination network within the monitoring period.",
      "transaction_execution_failed_on_destination_network":
          "Transaction execution failed on the destination network.",
      "transaction_execution_successfully_on_destination_network":
          "Transaction executed successfully on the destination network.",
      "tracking_transaction_on_destination_network_please_wait":
          "Tracking transaction on the destination network. Please wait.",
      "transaction_tracking_failed_on_destination_network":
          "Transaction tracking failed on the destination network due to an unexpected error",
      "account_requires_min_n_balance":
          "Account requires a minimum balance of ___1__",
      "local_asset_transfer_disabled_desc":
          "Local asset transfers are currently disabled for this network.",
      "before_you_continue": "Before You Continue",
      "xcm_condition_dryrun_required_desc":
          "If your selected network supports a Dry Run, please make sure all connected chains pass the Dry Run successfully before submitting.",
      "xcm_condition_no_dryrun_desc":
          "If the destination chain doesn’t support Dry Run or you’re unsure, try sending a small test amount first before transferring more.",
      "xcm_condition_token_inactive_desc":
          "Check that your token is available and active on the destination network.",
      "xcm_condition_partial_validation_desc":
          "While we do our best to verify transaction details, not everything can be fully validated automatically.",
      "xcm_condition_network_uncertainty_desc":
          "Network conditions and token states can change — we can’t guarantee every transfer will succeed.",
      "create_xcm_transaction": "Create XCM transaction",
      "got_it_dont_show_again": "Got it, don’t show again",
      "xcm_transfer_desc":
          "Transfer assets between parachains using Cross-Consensus Messaging (XCM)",

      "substrate_multisig_same_network_desc":
          "All signers must belong to the same Substrate network to generate a valid multisig address.",
      "substrate_multisig_eth_incompatible_desc":
          "If your Substrate network uses an Ethereum-style backup or mirror, this multisig address cannot be used on the Ethereum side.",

      "substrate_multisig_cannot_validate_all_desc":
          "While we verify most details, not all configurations can be validated automatically. Please double-check your signer list and threshold.",

      "substrate_multisig_network_uncertainty_desc":
          "Make sure the selected network supports multisig operations compatible with Substrate’s default multisig behavior.",
      "switching_account_please_wait": "Switching account. Please wait.",
      "tor": "Tor",
      "enable_disable_tor_service_desc":
          "Enable or disable tor service for selected provider.",
      "tor_service_error_desc": "Failed to start the Tor service.",
      "tor_service": "Tor service",

      /// net sdk errors
      "net_sdk_tls_handshake_failed":
          "TLS handshake failed. Secure connection could not be established.",
      "net_sdk_network_connection_failed":
          "Network connection failed. Unable to reach the server.",
      "net_sdk_tor_connection_failed":
          "Tor network connection failed. Unable to route through Tor.",
      "net_sdk_socket_closed":
          "Socket closed unexpectedly during communication.",

      "net_sdk_http2_connection_failed":
          "HTTP/2 connection failed. Transport layer could not establish session.",

      "net_sdk_invalid_request_parameters":
          "Invalid request parameters provided. Please check inputs.",
      "net_sdk_invalid_config_parameters":
          "Invalid configuration parameters detected.",
      "net_sdk_transport_not_found":
          "Requested transport mechanism not found or unsupported.",
      "net_sdk_sdk_not_initialized":
          "SDK not initialized. Initialize before making requests.",
      "net_sdk_sdk_already_initialized":
          "SDK is already initialized. Multiple initialization is not allowed.",
      "net_sdk_sdk_initialization_failed":
          "SDK initialization failed. Check configuration and dependencies.",
      "net_sdk_request_timeout":
          "Request timed out while waiting for a response.",
      "net_sdk_invalid_tor_config": "Invalid Tor configuration provided.",
      "net_sdk_tor_initialization_failed": "Tor client initialization failed.",
      "net_sdk_tor_client_not_initialized":
          "Tor client is not initialized. Start Tor before use.",
      "net_sdk_internal_sdk_error": "Internal SDK error occurred.",
      "net_sdk_tor_config_not_initialized": "Tor config not initialized.",

      "net_sdk_invalid_sdk_config": "Invalid SDK configuration.",
      "net_sdk_unknown_response": "Received unknown or unrecognized response.",
      "net_sdk_unsupported_feature": "Requested feature is not supported.",
      "net_sdk_closed": "SDK instance is closed and cannot process requests.",
      "net_sdk_connection_closed":
          "Connection was closed before operation completed.",
      "net_sdk_invalid_content_error":
          "The response content format was invalid and could not be parsed.",

      ///
      "service_internal_error":
          "An internal error occurred while processing the service request.",

      "connect_only_through_tor": "Connect only through the Tor network.",
      "tor_not_supported_on_this_platform":
          "This platform doesn’t support Tor (.onion) addresses.",
      "only_work_through_tor_network":
          ".onion addresses only work through the Tor network.",
      "selected_service_required_tor_nework":
          "Selected service only work through the Tor network.",
      "tor_service_error_desc2":
          "Something went wrong while enabling the Tor service. Please disable it to connect to the node.",
      "unsupported_platform": "Unsupported platform",
      "database_unexpected_error":
          "An unexpected error occurred during the database operation",
      "path_unexpected_error":
          "Unexpected error during app path initialization.",
      "service_alraedy_running": "Service already running.",
      "invalid_api_state": "Invalid API state.",
      "invalid_app_config_resources": "Invalid app config resources.",

      ///
      "invalid_new_address_configuration":
          "Invalid new address request configuration.",
      "zcash_address_derivation_index_out_of_range":
          "Unable to derive new address. diversifier index out of range.",
      "zcash_transparent_address_derivation_index_out_of_range":
          "Unable to derive new transparent address. sapling derived diversifier index out of range.",
      "address_derivation_mode": "Address derivation mode",
      "standard": "Standard",
      "zcash_standard_derivation_desc":
          "Following zcash ZIP-32 address derivation.",
      "zcash_custom_derivation_desc":
          "Custom ZIP-32 path, diversifier and etc,",
      "zcash_transparent_derivation_desc": "Only generate transparent address.",
      "transparent": "Transparent",
      "unified_address": "Unified address",
      "zcash_select_address_protocols_desc":
          "Select the address types to add to your unified address.",
      "orchard": "Orchard",
      "orchard_desc": "Newest zcash protocol, shieled and focused on privacy",
      "sapling": "Sapling",
      "sapling_desc": "Wide range supported, shieled and focused on privacy",
      "transparent_desc": "No-shild, easy to use and manage assets.",
      "unsupported_protocol_on_this_platform":
          "Unsupported protocol on this platform.",
      "at_least_one_sapling_orchard_required":
          "At least one sapling or orchard required.",
      "path_must_exactly_at_n_level":
          "Derivation path must exactly at ___1__ level.",
      "zip32_derivation_path": "ZIP-32 derivation path",
      "bip32_derivation_path": "BIP-32 derivation path",
      "scope": "Scope",
      "external": "External",
      "internal": "Internal",
      "transparent_address_type": "Transparent address type",
      "generate_multisignature_address_desc":
          "Generate transparent Multi-signature address",
      "address_does_not_contains_any_transparent_addr":
          "Address does not cointains any transparent address.",
      "diversifier_index": "Diversifier index",
      "index": "Index",
      "diversifier_strategy": "Diversifier strategy",
      "sapling_diversifier_strategy":
          "Attempt to try find sapling aiversifier index and then apply to orchard.",
      "disable_sapling_diversifier_strategy_desc":
          "The generate address will be failed, if sapling does not pass address generation with current index.",
      "transparent_diversifier_strategy_multisig_desc":
          "Diversifier index does not effect on transparent multisig address.",
      "transparent_diversifier_strategy_desc":
          "Diversifier index will be applied on transparent BIP-32 path at address level.",
      "diversifier_index_validator_desc":
          "Invalid diversifier index. index must be a valid non-negative number.",
      "diversifier_index_validator_desc2": "Index is to large.",
      "auto_diversifier_index": "Auto diversifier index",
      "auto_diversifier_index_desc":
          "Auto increment current index to find a valid one.",
      "followng_sapling_diversifier_role": "Following sapling diversifier role",
      "followng_sapling_diversifier_role_desc":
          "Derive address with sapling diversifier configuration.",
      "unsupported_derivation_increament": "Unsupported derivation increament.",
      "bip32_index_out_of_range": "BIP-32 index out of range.",
      "custom_derivation_with_following_sapling_role_desc":
          "Customize derivation with following sapling role can only applied on account level and new path (change/address) level will be replaced by sapling role.",
      "got_it": "Got it",
      "sapling_role_can_only_applied_on_account_level_path":
          "Sapling role can only applied on account level path.",
      "orchard_upgrade": "Orchard upgrade",
      "derive_new_unified_address": "Derive a new unified address.",
      "zcash_address_derivation_bad_sapling_diversifier":
          "Unable to derive new sapling address. bad diversifier index.",
      "custom_zip32_path_desc": "Tap to insert custom ZIP-32 derivation path.",
      "custom_bip32_path_desc": "Tap to insert custom BIP-32 derivation path.",
      "zcash_derivation_scope_desc": "Address derivation scope.",
      "diversifier_index_of_address": "Diversifier index of address.",
      "diversifier_index_sapling_desc":
          "For sapling. diversifier index must be acceptable by address generation proccess. we recommended select auto generation for that to find a valid index.",
      "sapling_upgrade": "Sapling upgrade",
      "derive_new_sapling_payment_address":
          "Derive a new sapling payment address.",
      "extended_full_view_key": "Extended full viewing key",
      "full_viewing_key": "Full viewing key",
      "diversifiable_full_viewing_key": "Diversifiable full viewing key",
      "multisig_keys_view": "Multi-signature derivation keys",
      "transparent_type_n": "Transparent (___1__)",
      "unified_full_viewing_key": "Unified full viewing key.",
      "unified_incoming_viewing_key": "Unified incoming viewing key",
      "keys": "keys",
      "account_keys": "Account keys",
      "orchard_spend_key": "Orchard spend key",
      "sapling_extended_spend_key": "Sapling extended spending key",
      "unified_full_spend_key": "Unified full spend key.",
      "extended_key": "Extended key",
      "invalid_encoded_key_data": "Invalid encoded key data.",
      "sapling_spend_key": "Sapling spend key",
      "different_backup_type_detected": "Different backup type detected.",
      "import_key_name_validator":
          "Key name must be between 3 and 20 characters long.",
      "unsupported_address_type": "Unsupported address type",
      "address_generation_failed": "Address generation failed.",
      "chain_loging_request_desc":
          "Network requested loging for continue procceses.",
      "invalid_storage_operation_parameters":
          "Invalid storage operation parameters.",
      "wallet_already_initialized": "Wallet already initialized.",
      "failed_to_fetch_sapling_parameters":
          "Failed to fetch sapling parameters.",
      "invalid_signing_parameters": "Invalid signing parameters.",
      // "isolate_terminated_error": "Isolate terminated.",
      "message_canceled": "Message canceled.",
      "memo_attached_to_transparent_output":
          "This memo will be attached in transparent output.",
      "missing_account_merkle_state": "Missing account merkle state.",
      "unified": "Unified",
      "transparent_p2pkh": "Transparent(P2PKH)",
      "transparent_p2sh": "Transparent(P2SH)",

      "transparent_p2ms": "Transparent(P2MS)",
      "protocols_addresses": "Protocols addresses",

      "add_a_new_contact": "Add a new contact",
      "generate_ripple_x_addreess": "Generate ripple X-address",
      "generate_ripple_x_addreess_desc":
          "Generate a ripple X-address from classic address and tag.",
      "enter_a_valid_ripple_classic_address":
          "Please enter a valid ripple classic address.",
      "address_not_supported_on_this_platform":
          "Address not supported on this platform.",
      "protocol_not_supported": "Protocol not supported on this platform.",
      "invalid_service_configuration": "Invalid service configuration.",
      "external_wallet": "External wallet",
      "connect_to_external_wallet":
          "Connect to an external OnChain wallet app.",
      "wallet_pairing": "Wallet pairing",
      "wallet_pairing_desc":
          "Please scan the QR code or enter the pairing link below.",
      "pairing_link": "Pairing link",
      "socket_is_not_initialized": "Socket has not been initialized.",
      "validate_pairing_id_desc": "Please enter a valid pairing id.",
      "bad_client_state": "Bad client state",
      "input_main_wallet_password": "Enter your main wallet password.",
      "validating_main_wallet_content_desc":
          "Validating main wallet content. Please enter your main wallet password below.",
      "review_wallet": "Review wallet",
      "wrong_wallet_password": "Invalid wallet password.",
      "invalid_pairing_content": "Invalid pairing content",
      "internal_error_during_pairing":
          "An internal error occurred while processing pairing request.",
      "external_wallet_connection_already_exists":
          "External wallet connection already exists.",
      "external_wallet_authentication_failed":
          "External wallet authentication failed.",
      "pairing_wallet_desc": "Pairing wallet. please wait.",
      "pairing_complete_successfully":
          "Pairing has been complete successfully.",
      "client_not_found": "Client not found.",
      "bad_publish_message_status": "Bad publish message status.",
      "to_many_wallet_connections": "Too many wallet connections.",
      "no_active_service_provider": "No active service provider.",
      "too_many_web3_client": "Too many web3 clients.",
      "publish_message_error": "An error occurred during publish message",
      "topic_subscription_timeout":
          "Failed to subscribe to topic: request timed out.",
      "pairing_disconnected": "Pairing disconnected.",
      "login_request_timeout": "Login request timeout.",
      "wallet_context_not_available": "Wallet context not available",
      "login_request_rejected": "Login request rejected.",
      "provider_not_found": "Provider not found.",
      "failed_to_parse_response_content": "Failed to parse response content.",
      "service_provider_changed": "Service provider changed.",
      "invalid_service_request": "Invalid service request.",
      "token_not_found": "Token not found.",
      "account_name_is_to_large": "Account name is too large.",
      "contact_does_not_exists": "Contact does not exists.",
      "bad_account_syncing_configuration": "Bad account syncing configuration.",
      "invalid_network_provider_configuration":
          "Invalid network provider configuration.",
      "invalid_provider_authentication_configuration":
          "Invalid provider authentication configuration.",
      "provider_already_exists": "Provider already exists.",
      "enable_tor_feature": "Enable tor feature.",
      "disable_tor_feature": "Disable tor feature.",
      "update_authentication": "Update authentication",
      "unsupported_authentication_by_protocol":
          "This protocol does not support authentication.",
      "provider_url": "Provider url",
      "worker_message_not_found": "Worker message not found.",
      "tor_connecting_please_wait": "Connecting to tor service. Please wait.",
      "provider_validation_failed_desc":
          "Provider validation failed: Returned data does not match the expected network configuration.",
      "connected": "Connected",
      "auto_connection": "Auto-connect",
      "auto_service_connection_desc":
          "Automatically find and connect to the best available service.",
      "provider_settings": "Provider settings",
      "client_disposed": "Client disposed.",
      "select_zcash_protocol": "Select Zcash Protocol",
      "select_zcash_protocol_desc":
          "Choose a protocol to generate your Zcash address",
      "address_configuration": "Address configuration",
      "address_configuration_desc":
          "Please carefully fill in the following address generation settings.",
      "protocol_activiation_height_validator":
          "Activation height cannot precede the protocol upgrade height.",
      "address_protocol_activiation_height_validator":
          "Activation height must be greater than or equal to the address protocol update height: ___1__",
      "activation_height_grather_than_network_height_desc":
          "Activation height cannot be greater than the current network height: ___1__",
      "new_account": "New Account",
      "enable_activation_height_desc":
          "Define as new or set activation height.",
      "setup_activation_height_desc":
          "Enter the activation height (first received funds). Incorrect values may cause missing transactions or longer sync time.",
      "block_height": "Block height",
      "failed_to_retrieve_block_height":
          "Unable to retrieve current block height.",
      "invalid_activation_height":
          "Invalid activation height. Height must not be greater than the current height.",
      "update_account_configuration_please_wait":
          "Update account configuration. Please wait.",
      "an_error_during_block_scanning":
          "An error occurred during block scanning.",
      "tap_to_create_block_synchronization_request":
          "Tap to create a new block synchronization request.",
      "only_sheild_account_allowed": "Only shield accounts allowed.",
      "start_block_for_synchronization": "Start Block for Synchronization",
      "end_block_for_synchronization": "End Block for Synchronization",
      "synchronization_request": "Synchronization Request",
      "update_synchronization_network": "Update synchronization network",
      "no_active_account": "No active account.",
      "select_network_to_enable_synchronization":
          "Select a network to enable synchronization.",
      "disable_synchronization": "Disable synchronization.",
      "only_one_network_synchronization_desc":
          "Only one network can be synchronized at a time.",
      "reset_syncronization_state": "Reset Synchronization state.",
      "reset_syncronization_state_desc":
          "Be careful when resetting the synchronization state—this will remove all account UTXOs, and synchronization will restart from the current chain height.",
      "block_must_be_lower_than_current_block":
          "The provided block must be lower than the current block.",
      "block_synchronization_canceled": "Block synchronization canceled",
      "latest_status": "Latest status",
      "syncing_status": "Syncing status",
      "processing_progress": "Processing progress",
      "no_active_processing": "No active processing",
      "sync_not_complete_pending_utxos_will_be_removed":
          "Sync not complete. Pending UTXOs from this request will be removed.",
      "request_host_does_not_match_connected_host":
          "Request host does not match connected host",
      "checking_sapling_configruration_parameters":
          "Checking Sapling configuration parameters",
      "sapling_parameters_verification_failed":
          "Sapling parameter verification failed",
      "download_sapling_parameters_desc":
          "Sapling ___1__ parameters are missing. Do you want to download the ___2__ MB parameter file?",
      "spend": "Spend",
      "output": "Output",
      "download": "Download",
      "sapling_parameters": "Sapling parameters",
      "download_sapling_parameters_please_wait":
          "Download sapling parameters. Please wait",
      "syncing": "Syncing",
      "n_address_configuration": "___1__ address configuration.",
      "duplicate_recipients_detected": "Duplicate recipients detected.",
      "current_account_address": "Current account address",
      "ethereum_address": "Ethereum address",

      "transaction_required_syncing_desc":
          "To generate a transaction, syncing with the current chain is required.",
      "account_utxos_not_synced_desc":
          "Account not fully synced. Spending UTXOs may fail or show incorrect balance.",
      "zcash_signing_internal_error_failed_to_build_utxo_merkle":
          "Zcash internal signing error: UTXO Merkle tree construction failed.",
      "zcash_signing_internal_error_construct_liberary":
          "Zcash internal signing error: Failed to construct zcash liberary.",
      "zcash_signing_internal_error_unexpected":
          "Zcash internal signing error: Unexpected error occurred.",
      "reset_sync_select_addresses": "Select addresses to reset sync state",
      "tap_to_select_address": "Tap to select address",
      "invalid_height_validator_desc": "Invalid block height.",
      "monero_proof_generation_failed_desc":
          "Proof generation failed: your account has not received any funds.",
      "utxo_already_spent": "UTXO already spent",
      "no_related_account_utxos": "No related account UTXOs found",
      "an_error_during_export_transaction_utxos":
          "An error occurred while exporting transaction UTXOs.",
      "import_utxos": "Import UTXOs.",
      "import_utoxs_from_transaction_ids": "Import UTXOs from transaction IDs.",
      "utxo_successfully_imported_to_your_account":
          "UTXO successfully imported to your account.",
      "transactions_and_utxos_status": "Transactions and UTXOs status",
      "no_related_account_found": "No related account found.",
      "wallet_rpc_synchronization": "Wallet rpc synchronization.",
      "synchronization_with_monero_wallet_rpc":
          "Synchronization with monero wallet rpc.",
      "utxo_cannot_be_spent_until_block_height":
          "UTXO cannot be spent until block height ___1__.",
      "utxo_cannot_be_spent_until_timestamp":
          "UTXO cannot be spent until timestamp ___1__",
      "create_synchronization_request": "Create synchronization request",
      "create_synchronization_request_desc":
          "Create a synchronization request for your accounts between specified blocks.",
      "transparent_memos": "Transparent memos",
      "utxo_restricted_by_tx_privacy_desc":
          "This UTXO cannot be used due to privacy restrictions.",
      "unknown_timelock_status": "UTXO timelock status is unknown",
      "utxos_confirmed": "UTXO confirmed.",
      "utxo_will_unlock_after_n_block":
          "UTXO will unlock after ___1__ more block confirmation.",
      "utxo_will_unlock_after_n_time": "UTXO will unlock after ___1__.",
      "n_days": "___1__ days.",
      "n_hours": "___1__ hours.",
      "n_minutes": "___1__ minutes.",
      "utxos_is_not_confirmed_yet": "UTXO is not confirmed yet.",
      "coinbase": "Coinbase",
      "at_n": "At ___1__",
      "zcash_select_all_utxos_failed_desc":
          "Some UTXO selections failed due to privacy restrictions, disable synchronization or unconfirmed status.",
      "no_available_utxos_found": "No available UTXOs found.",
      "spending_sheild_utxos_synchronization_required_desc":
          "Spending shielded UTXOs requires a fully synchronized account",
      "utxo_timelock": "UTXO Timelock",
      "utxo_timelock_desc":
          "Restrict when coins can be spent using either block height or time-based conditions",
      "utxo_timelock_based_time_desc":
          "Funds become spendable after a time delay",
      "utxo_timelock_based_blocks_desc":
          "Funds become spendable after a number of blocks",
      "utxo_time_based_lock": "Time-based lock",
      "utxo_time_based_lock_desc":
          "Lock coins using elapsed time instead of block height",
      "utxo_lock_duration_minutes": "Lock duration (minutes)",
      "utxo_lock_height_blocks": "Lock height (blocks)",
      "utxo_lock_helper_minutes_n_desc":
          "Maximum: ___1__. values are rounded to 8-minute intervals.",
      "utxo_lock_helper_blocks_n_desc": "Maximum: ___1__ blocks",
      "utxo_setup_time_lock": "Setup timelock.",
      "tap_to_setup_timelock": "Tap to setup timelock.",
      "locktime_must_between_0_n_blocks":
          "Locktime must be between 0 and ___1__ blocks.",
      "locktime_must_between_0_n_minutes":
          "Locktime must be between 0 and ___1__ minutes.",
      "n_blocks": "___1__ blocks",
      "crypto_features_disabled": "Crypto features are disabled",
      "required_service_is_disabled": "Required service is disabled.",
      "failed_to_connect_to_crypto_service":
          "Failed to connect to the crypto service.",
      "crypto_operation_canceled": "Crypto operation was canceled.",
      "crypto_service_request_timeout": "Crypto service request timed out.",
      "mising_database_liberary": "Missing database liberary.",
      "connection_already_closed": "Connection already closed.",
      "resource_not_supported":
          "This resource is not supported in the current environment.",
      "missing_chrome_api": "Missing chrome api.",
      "choose_a_permission": "Choose a permission",
      "select_all_utxos_failed_due_unconfirmation_desc":
          "Some UTXO selections failed due unconfirmed status.",
      "confirmations": "Confirmations",
      "at": "At",
      "utxos_has_been_updated": "Utxos has been updated.",
      "data_checksum_mismatch": "Data checksum mismatch",
      "missing_sapling_parameters": "Missing sapling parameters.",
      "failed_read_file_content_due_platform_error":
          "Failed to read file contents due to a platform error",
      "pick_file": "Pick file",
      "verify_sapling_parameters_please_wait":
          "verify sapling parameters. Please wait",
      "links": "Links",
      "mempool": "Mempool",
      "basechain": "BaseChain",
      "masterchain": "MasterChain",
      "workchain": "WorkChain",
      "ton_workchain_desc":
          "Basechain is recommended for lower transaction costs and wider compatibility",

      "outgoing_message_limit_exceeded": "Outgoing message limit exceeded",
      "duplicate_output_addresses_not_allowed":
          "Duplicate output addresses are not allowed",
      "forward_symbol": "___1__ --> ___2__",
      "port_id": "Port id",
      "enter_a_valid_port_id": "Please enter a valid port id.",
      "channels": "Channels",
      "no_channel_found": "No channel found.",
      "tap_to_choose_channel": "Tap to choose a channel",
      "save_channel": "Save Channel",
      "save_channel_desc": "Would you like to save this channel for next time?",
      "fee_token_not_found": "Fee token not found.",
      "service_out_of_sync": "Service is out of sync",
      "swap_source_chain_provider_connection_error":
          "Source chain connection failed. Please verify the chain provider is connected."

      // "n_minutes": "___1__ minutes"
    }
  };
}

extension ExtTranslate on String {
  static Map<APPLocale, Map<String, String>> get localization =>
      Localization.languages;
  String get find => localization[APPLocale.en]?[this] ?? this;
}
