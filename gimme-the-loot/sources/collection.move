module nftcollection::collection {
    // Replace 'NftNameHere' in file with your CollectionName in CammelCase
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
    
    // ===== Collection parameters =====
    const COLLECTION_NAME: vector<u8> = b"NftNameHere";
    const MAX_SUPPLY: u64 = 100;
    // 1 SUI = 1000000000
    const PRICE: u64 = 500000000; // Current price 0.5 SUI
    const PRICE_WHITELIST: u64 = 200000000; // Current price 0.2 SUI
    const RELEASE_EPOCH: u64 = 0;
    const NFT_DESCRIPTION: vector<u8> = b"NftNameHere Nft";
    const CREATOR: vector<u8> = b"NftNameHere Team";
    const COLLECTION_WEBSITE: vector<u8> = b"https://www.NftNameHere.com";
    const URL_PREFIX: vector<u8> = b"ipfs://";
    const COLLECTION_URI: vector<u8> = b"bafybeiaetnhmscuk6nqdnk4lvh6lxeadehfo342pszyqdodqoodtld77v4/"; // use '/' at the end!
    const NFT_FILE_FORMAT: vector<u8> = b".png";
    const UNREVEALED_NFT_NAME: vector<u8> = b"???";
    const UNREVEALED_NFT_DESCRIPTION: vector<u8> = b"Ready to reveal";
    const UNREVEALED_URL: vector<u8> = b"bafybeifqbhntp3ghp4vwrma3xivy5mkwlt3ljfiebr5zaewetjk72c4thu/INCOGNITA.png";
    const WHITELIST: vector<address> = vector[];

    const ESoldOut: u64 = 0;
    const ECollectionAlreadyReleased: u64 = 1;
    const ESenderNotInWhitelist: u64 = 2;
    const ENoCoins: u64 = 3;
    const ENftAlreadyRevealed: u64 = 4;

    struct NftNameHereCap has key, store {
        id: UID,
    }

    struct NftNameHereCollection has key {
        id: UID,
        owner: address,
        minted: u64,
        max_supply: u64,
        price: u64,
        price_whitelist: u64,
        release: u64,
        whitelist: Set<address>,
    }

    struct NftNameHereNft has key, store {
        id: UID,
        name: String,
        description: String,
        creator: String,
        website: Url,
        seed: u64,
        revealed: bool,
        img_url: Url,
        url: Url,
        image_url: Url
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
            max_supply: MAX_SUPPLY,
            price: PRICE,
            price_whitelist: PRICE_WHITELIST,
            release: RELEASE_EPOCH,
            whitelist: new_set<address>(WHITELIST),
        });
    }

    public entry fun mint_with_multiple(
        collection: &mut NftNameHereCollection, 
        sui_balance: vector<Coin<SUI>>, 
        ctx: &mut TxContext,
    ) {
        let coin = join_coins(sui_balance);
        mint(collection, coin, ctx);
    }

    public entry fun mint(
        collection: &mut NftNameHereCollection, 
        sui_balance: Coin<SUI>, 
        ctx: &mut TxContext,
    ) {
        assert!(collection.minted < collection.max_supply, ESoldOut);

        let (sender_whitelisted, price) = get_price(collection, ctx);

        pay(sui_balance, price, collection.owner, ctx);

        let nft = NftNameHereNft {
            id: object::new(ctx),
            name: string::utf8(UNREVEALED_NFT_NAME),
            description: string::utf8(UNREVEALED_NFT_DESCRIPTION),
            creator: string::utf8(CREATOR),
            website: url(vector[COLLECTION_WEBSITE]),
            seed: collection.minted,
            revealed: false,
            img_url: url(vector[URL_PREFIX, UNREVEALED_URL]),
            image_url: url(vector[URL_PREFIX, UNREVEALED_URL]),
            url: url(vector[URL_PREFIX, UNREVEALED_URL]),
        };

        event::emit(NftNameHereNftMinted { 
            id: object::uid_to_inner(&nft.id),
            creator: tx_context::sender(ctx),
        });

        transfer::transfer(nft, tx_context::sender(ctx));

        collection.minted = collection.minted + 1;

        if (sender_whitelisted) set::remove(&mut collection.whitelist, &tx_context::sender(ctx));
    }

    public entry fun reveal(
        nft: &mut NftNameHereNft,
    ) {
        assert!(!nft.revealed, ENftAlreadyRevealed);

        let prefix = string::utf8(b"#");
        string::insert(&mut prefix ,0 , string::utf8(COLLECTION_NAME));
        let new_name = string::utf8(int_to_bytes(nft.seed));
        string::insert(&mut new_name, 0, prefix);
        nft.name  = new_name;
        nft.description  = string::utf8(NFT_DESCRIPTION);
        nft.url = url(vector[URL_PREFIX, COLLECTION_URI, int_to_bytes(nft.seed), NFT_FILE_FORMAT]);
        nft.img_url = url(vector[URL_PREFIX, COLLECTION_URI, int_to_bytes(nft.seed), NFT_FILE_FORMAT]);
        nft.image_url = url(vector[URL_PREFIX, COLLECTION_URI, int_to_bytes(nft.seed), NFT_FILE_FORMAT]);
        nft.revealed = true;
    }

    public entry fun add_to_whitelist_multiple(
        cap: &NftNameHereCap, 
        collection: &mut NftNameHereCollection,
        addresses_to_add: vector<address>,
        ctx: &mut TxContext,
    ) {
        while(!vector::is_empty(&addresses_to_add)) {
            add_to_whitelist(cap, collection, vector::pop_back(&mut addresses_to_add), ctx);
        };
    }

    public entry fun add_to_whitelist(
        _: &NftNameHereCap, 
        collection: &mut NftNameHereCollection,
        address_to_add: address,
        ctx: &mut TxContext,
    ) {
        assert!(collection.release < tx_context::epoch(ctx), ECollectionAlreadyReleased);

        set::insert(&mut collection.whitelist, address_to_add);
    }

    public entry fun set_release(
        _: &NftNameHereCap, 
        collection: &mut NftNameHereCollection,
        epoch: u64,
        ctx: &mut TxContext,
    ) {
        assert!(collection.release < tx_context::epoch(ctx), ECollectionAlreadyReleased);

        collection.release = epoch;
    }

    public entry fun is_whitelisted(
        collection: &mut NftNameHereCollection, 
        ctx: &mut TxContext
    ): bool {
        tx_context::epoch(ctx) <= collection.release
    }

    fun get_price(collection: &mut NftNameHereCollection, ctx: &mut TxContext): (bool, u64) { 

        let sender_whitelisted = false;
        let price = collection.price;

        if(collection.release > tx_context::epoch(ctx)) {
            sender_whitelisted = set::contains(&collection.whitelist, &tx_context::sender(ctx));
            assert!(sender_whitelisted, ESenderNotInWhitelist);
            price = collection.price_whitelist;
        };

        (sender_whitelisted, price)
    }

    fun int_to_bytes(int: u64): vector<u8> {
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

    fun join_coins<T>(coins: vector<Coin<T>>): Coin<T> {
        assert!(vector::length(&coins) > 0, ENoCoins);

        let coin = vector::pop_back(&mut coins);
        while(!vector::is_empty(&coins)) coin::join(&mut coin, vector::pop_back(&mut coins));
        vector::destroy_empty(coins);
        coin
    }

    fun pay<T>(coin: Coin<T>, price: u64, recipient: address, ctx: &mut TxContext) {
        pay::split_and_transfer<T>(&mut coin, price, recipient, ctx);
        transfer::public_transfer(coin, tx_context::sender(ctx));
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
        let new_set = set::empty<T>();
        while(!vector::is_empty(&elements)) {
            set::insert(&mut new_set, vector::pop_back(&mut elements));
        };
        new_set
    }
}