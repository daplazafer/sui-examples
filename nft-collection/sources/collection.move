module nftcollection::collection {
    use std::string::{Self, String};
    use std::vector;
    use sui::url::{Self, Url};
    use sui::object::{Self, ID, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use sui::event;
    use sui::pay;
    use sui::vec_set::{Self as set, VecSet as Set};
    use nftcollection::time_lock::{Self as lock, TimeLock as Lock};
    
    // ===== Collection parameters =====
    const COLLECTION_NAME: vector<u8> = b"NftNameHere";
    const MAX_SUPPLY: u64 = 100;
    const PRICE: u64 = 100000000;  
    const PRICE_WHITELIST: u64 = 100000000;
    const RELEASE_DATE: u64 = 1669237165;
    const RELEASE_DATE_WHITELIST: u64 = 1669233565;
    const URL_PREFIX: vector<u8> = b"ipfs://";
    const COLLECTION_URI: vector<u8> = b"bafybeiaetnhmscuk6nqdnk4lvh6lxeadehfo342pszyqdodqoodtld77v4/";
    const NFT_FILE_FORMAT: vector<u8> = b".png";
    const UNREVEALED_NFT_NAME: vector<u8> = b"???";
    const UNREVEALED_URL: vector<u8> = b"bafybeifqbhntp3ghp4vwrma3xivy5mkwlt3ljfiebr5zaewetjk72c4thu/INCOGNITA.png";
    const WHITELIST: vector<address> = vector[];
    
    const ESoldOut: u64 = 0;
    const ECollectionNotReleasedYet: u64 = 1;
    const ECollectionAlreadyReleased: u64 = 2;
    const ESenderNotInWhitelist: u64 = 3;
    const ENoCoins: u64 = 4;
    const ENftAlreadyRevealed: u64 = 5;

    struct NftNameHereCap has key, store {
        id: UID,
    }

    struct NftNameHereCollection has key {
        id: UID,
        owner: address,
        minted: u64,
        price: u64,
        price_whitelist: u64,
        release: Lock,
        release_whitelist: Lock,
        whitelist: Set<address>,
    }

    struct NftNameHereNft has key, store {
        id: UID,
        name: String,
        url: Url,
        seed: u64,
        revealed: bool,
    }

    struct NftNameHereNftMinted has copy, drop {
        id: ID,
        creator: address,
    }

    fun init(ctx: &mut TxContext) {
        transfer::transfer(NftNameHereCap {
            id: object::new(ctx)
        }, tx_context::sender(ctx));
        transfer::share_object(NftNameHereCollection {
            id: object::new(ctx),
            owner: tx_context::sender(ctx),
            minted: 0,
            price: PRICE,
            price_whitelist: PRICE_WHITELIST,
            release: lock::new(RELEASE_DATE),
            release_whitelist: lock::new(RELEASE_DATE_WHITELIST),
            whitelist: new_set<address>(WHITELIST),
        });
    }

    /// Mint an nft
    public entry fun mint(
        collection: &mut NftNameHereCollection, 
        sui_balance: vector<Coin<SUI>>, 
        ctx: &mut TxContext
    ) {
        assert!(collection.minted < MAX_SUPPLY, ESoldOut);

        assert!(lock::is_locked(collection.release_whitelist, ctx), ECollectionNotReleasedYet);
        let price = collection.price;
        let user_whitelisted = set::contains(&collection.whitelist, &tx_context::sender(ctx));
        if(!lock::is_locked(collection.release, ctx)) {
            assert!(user_whitelisted, ESenderNotInWhitelist);
            price = collection.price_whitelist;
        }; 

        pay(sui_balance, price, collection.owner, ctx);

        let nft = NftNameHereNft {
            id: object::new(ctx),
            name: string::utf8(UNREVEALED_NFT_NAME),
            url: url(vector[URL_PREFIX, UNREVEALED_URL]),
            seed: collection.minted,
            revealed: false,
        };

        event::emit(NftNameHereNftMinted { 
            id: object::uid_to_inner(&nft.id),
            creator: tx_context::sender(ctx),
        });

        transfer::transfer(nft, tx_context::sender(ctx));

        collection.minted = collection.minted + 1;

        if (user_whitelisted) set::remove(&mut collection.whitelist, &tx_context::sender(ctx));
    }

    /// Reveal an nft
    public entry fun reveal(
        nft: &mut NftNameHereNft
    ) {
        assert!(!nft.revealed, ENftAlreadyRevealed);

        nft.name  = string::utf8(COLLECTION_NAME);
        nft.url = url(vector[URL_PREFIX, COLLECTION_URI, int_to_bytes(nft.seed), NFT_FILE_FORMAT]);
        nft.revealed = true;
    }

    /// Add addresses to whitelist
    public entry fun add_to_whitelist(
        _: &NftNameHereCap, 
        collection: &mut NftNameHereCollection,
        addresses: vector<address>
    ) {
        while(!vector::is_empty(&addresses)) {
            set::insert(&mut collection.whitelist, vector::pop_back(&mut addresses));
        };
    }

    fun int_to_bytes(int: u64): vector<u8>{
        let bytes = vector::empty<u8>();
        while (int / 10 > 0){
            let rem = int%10;
            vector::push_back(&mut bytes, (rem+48 as u8));
            int = int/10;
        };
        vector::push_back(&mut bytes, (int+48 as u8));
        vector::reverse(&mut bytes);
        bytes
    }

    fun pay<T>(coins: vector<Coin<T>>, price: u64, recipient: address, ctx: &mut TxContext) {
        assert!(vector::length(&coins) > 0, ENoCoins);

        let coin = vector::pop_back(&mut coins);
        while(!vector::is_empty(&coins)) coin::join(&mut coin, vector::pop_back(&mut coins));
        vector::destroy_empty(coins);
        pay::split_and_transfer<T>(&mut coin, price, recipient, ctx);
        transfer::transfer(coin, tx_context::sender(ctx));
    }

    fun url(parts: vector<vector<u8>>): Url{
        vector::reverse(&mut parts);
        let builder = vector::empty<u8>();
        while(!vector::is_empty(&parts)) {
            let part = vector::pop_back(&mut parts);
            vector::append(&mut builder, part);
        };
        vector::destroy_empty(parts);
        url::new_unsafe_from_bytes(builder)
    }

    fun new_set<T: copy + drop>(elements: vector<T>): Set<T> {
        let set = set::empty<T>();
        while(!vector::is_empty(&elements)) {
            set::insert(&mut set, vector::pop_back(&mut elements));
        };
        set
    }
}