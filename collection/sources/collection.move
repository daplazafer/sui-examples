module collection::collection {
    use std::ascii::{Self, String};
    use std::vector;
    use sui::url::Url;
    use sui::object::{Self, ID, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::sui::SUI;
    use sui::coin::Coin;
    use sui::event;
    use sui::vec_set::{Self as set, VecSet as Set};
    use utils::time_lock::{Self, TimeLock};
    use utils::utils;
    use utils::payments;
    
    // ===== Collection parameters =====

    const COLLECTION_NAME: vector<u8> = b"NftCollectionNameHere";
    const MAX_SUPPLY: u64 = 100;
    const PRICE: u64 = 100000000;  
    const PRICE_WHITELIST: u64 = 100000000;
    const RELEASE_DATE: u64 = 1669237165;
    const RELEASE_DATE_WHITELIST: u64 = 1669233565;
    
    const MINT_REVEALED: bool = false;

    const URI_PREFIX: vector<u8> = b"ipfs://";
    const COLLECTION_URI: vector<u8> = b"bafybeiaetnhmscuk6nqdnk4lvh6lxeadehfo342pszyqdodqoodtld77v4";
    const NFT_FILE_FORMAT: vector<u8> = b"png";
    const UNREVEALED_NFT_NAME: vector<u8> = b"???";
    const UNREVEALED_URI: vector<u8> = b"bafybeifqbhntp3ghp4vwrma3xivy5mkwlt3ljfiebr5zaewetjk72c4thu";
    const UNREVEALED_NFT_FILE_NAME: vector<u8> = b"INCOGNITA";
    const UNREVEALED_NFT_FILE_FORMAT: vector<u8> = b"png";

    // =================================
    
    const ESoldOut: u64 = 0;
    const ECollectionNotReleasedYet: u64 = 1;
    const ECollectionAlreadyReleasedForWhitelist: u64 = 2;
    const ECollectionAlreadyReleased: u64 = 3;
    const ESenderNotInWhitelist: u64 = 4;
    const ENftAlreadyRevealed: u64 = 5;

    struct NftCollectionNameHereCap has key, store {
        id: UID,
    }

    struct NftCollectionNameHere has key {
        id: UID,
        owner: address,
        counter: u64,
        price: u64,
        price_whitelist: u64,
        release: TimeLock,
        release_whitelist: TimeLock,
        whitelist: Set<address>,
    }

    struct NftNameHere has key, store {
        id: UID,
        name: String,
        url: Url,
        seed: String,
        revealed: bool,
    }

    struct NftNameHereMinted has copy, drop {
        id: ID,
        creator: address,
    }

    fun init(ctx: &mut TxContext) {
        transfer::transfer(NftCollectionNameHereCap {
            id: object::new(ctx)
        }, tx_context::sender(ctx));
        transfer::share_object(NftCollectionNameHere {
            id: object::new(ctx),
            owner: tx_context::sender(ctx),
            counter: 0,
            price: PRICE,
            price_whitelist: PRICE_WHITELIST,
            release: time_lock::new(RELEASE_DATE),
            release_whitelist: time_lock::new(RELEASE_DATE_WHITELIST),
            whitelist: set::empty(),
        });
    }

    public entry fun mint(collection: &mut NftCollectionNameHere, payment: vector<Coin<SUI>>, ctx: &mut TxContext) {

        // Check release status and calculate price
        time_lock::destroy(collection.release_whitelist, ctx);
        let price = collection.price;
        let user_whitelisted = set::contains(&collection.whitelist, &tx_context::sender(ctx));
        if(!time_lock::is_locked(collection.release, ctx)) {
            assert!(user_whitelisted, ESenderNotInWhitelist);
            price = collection.price_whitelist;
        };

        // Check nft availability
        assert!(collection.counter < MAX_SUPPLY, ESoldOut);

        // Make payment
        payments::pay(payment, price, collection.owner, ctx);

        // Increase collection supply counter
        collection.counter = collection.counter + 1;

        // Create the nft
        let nft = NftNameHere {
            id: object::new(ctx),
            name: ascii::string(UNREVEALED_NFT_NAME),
            url: utils::build_url(URI_PREFIX, UNREVEALED_URI, UNREVEALED_NFT_FILE_NAME, UNREVEALED_NFT_FILE_FORMAT),
            seed: utils::u64_to_string(collection.counter),
            revealed: false,
        };
        if (MINT_REVEALED) reveal(&mut nft);

        // Emit event
        event::emit(NftNameHereMinted { 
            id: object::uid_to_inner(&nft.id),
            creator: tx_context::sender(ctx),
        });

        // Send nft to sender
        transfer::transfer(nft, tx_context::sender(ctx));

        // Remove user from whitelist
        if (user_whitelisted) set::remove(&mut collection.whitelist, &tx_context::sender(ctx));
    }

    public entry fun reveal(nft: &mut NftNameHere) {
        assert!(!nft.revealed, ENftAlreadyRevealed);

        nft.name  = ascii::string(COLLECTION_NAME);
        nft.url = utils::build_url(URI_PREFIX, COLLECTION_URI, ascii::into_bytes(nft.seed), NFT_FILE_FORMAT);
        nft.revealed = true;
    }

    public entry fun add_to_whitelist(_: &NftCollectionNameHereCap, collection: &mut NftCollectionNameHere, addresses: vector<address>) {

        while(!vector::is_empty(&addresses)) {
            set::insert(&mut collection.whitelist, vector::pop_back(&mut addresses));
        };
    }
}