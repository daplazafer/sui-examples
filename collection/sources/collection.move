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
    use utils::utils;
    use utils::payments;
    
    // ===== Collection parameters =====

    const COLLECTION_NAME: vector<u8> = b"NftCollectionNameHere";
    const MAX_SUPPLY: u64 = 100;
    const PRICE: u64 = 100000000;  
    const WHITELIST_PRICE: u64 = 100000000;
    const MINT_REVEALED: bool = false;

    const URI_PREFIX: vector<u8> = b"ipfs://";
    const COLLECTION_URI: vector<u8> = b"bafybeiaetnhmscuk6nqdnk4lvh6lxeadehfo342pszyqdodqoodtld77v4";
    const NFT_FILE_FORMAT: vector<u8> = b"png";
    const UNREVEALED_NFT_NAME: vector<u8> = b"???";
    const UNREVEALED_URI: vector<u8> = b"bafybeifqbhntp3ghp4vwrma3xivy5mkwlt3ljfiebr5zaewetjk72c4thu";
    const UNREVEALED_NFT_FILE_NAME: vector<u8> = b"INCOGNITA";
    const UNREVEALED_NFT_FILE_FORMAT: vector<u8> = b"png";

    // =================================
    
    const ESOLD_OUT: u64 = 0;
    const ECOLLECTION_NOT_RELEASED_YET: u64 = 1;
    const ECOLLECTION_ALREADY_RELEASED_FOR_WHITELIST: u64 = 2;
    const ECOLLECTION_ALREADY_RELEASED: u64 = 3;
    const ESENDER_NOT_IN_WHITELIST: u64 = 4;
    const ENFT_ALREADY_REVEALED: u64 = 5;

    struct NftCollectionNameHereCap has key, store {
        id: UID,
    }

    struct NftCollectionNameHere has key {
        id: UID,
        owner: address,
        counter: u64,
        price: u64,
        price_whitelist: u64,
        whitelist: Set<address>,
        released: bool,
        released_whitelist: bool,
    }

    struct NftNameHere has key {
        id: UID,
        name: String,
        uri: Url,
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
            price_whitelist: WHITELIST_PRICE,
            whitelist: set::empty(),
            released_whitelist: false,
            released: false,
        });
    }

    public entry fun mint(collection: &mut NftCollectionNameHere, payment: vector<Coin<SUI>>, ctx: &mut TxContext) {

        // Check release status and calculate price
        assert!(collection.released_whitelist, ECOLLECTION_NOT_RELEASED_YET);
        let price = collection.price;
        if(!collection.released) {
            assert!(set::contains(&collection.whitelist, &tx_context::sender(ctx)), ESENDER_NOT_IN_WHITELIST);
            price = collection.price_whitelist;
        };

        // Check nft availability
        assert!(collection.counter < MAX_SUPPLY, ESOLD_OUT);

        // Make payment
        payments::pay(payment, price, collection.owner, ctx);

        // Increase collection supply counter
        collection.counter = collection.counter + 1;

        // Create the nft
        let nft = NftNameHere {
            id: object::new(ctx),
            name: ascii::string(UNREVEALED_NFT_NAME),
            uri: utils::build_url(URI_PREFIX, UNREVEALED_URI, UNREVEALED_NFT_FILE_NAME, UNREVEALED_NFT_FILE_FORMAT),
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
        if(collection.released_whitelist && !collection.released) set::remove(&mut collection.whitelist, &tx_context::sender(ctx));
    }

    public entry fun reveal(nft: &mut NftNameHere) {
        assert!(!nft.revealed, ENFT_ALREADY_REVEALED);

        nft.name  = ascii::string(COLLECTION_NAME);
        nft.uri = utils::build_url(URI_PREFIX, COLLECTION_URI, ascii::into_bytes(nft.seed), NFT_FILE_FORMAT);
        nft.revealed = true;
    }

    public entry fun release_whitelist(_: &NftCollectionNameHereCap, collection: &mut NftCollectionNameHere) {
        assert!(!collection.released_whitelist, ECOLLECTION_ALREADY_RELEASED_FOR_WHITELIST);

        collection.released_whitelist = true;
    }

    public entry fun release(_: &NftCollectionNameHereCap, collection: &mut NftCollectionNameHere) {
        assert!(!collection.released, ECOLLECTION_ALREADY_RELEASED);

        collection.released_whitelist = true;
        collection.released = true;
        collection.whitelist = set::empty();
    }

    public entry fun add_to_whitelist(_: &NftCollectionNameHereCap, collection: &mut NftCollectionNameHere, addresses: vector<address>) {
        assert!(!collection.released_whitelist, ECOLLECTION_ALREADY_RELEASED);

        while(!vector::is_empty(&addresses)) {
            set::insert(&mut collection.whitelist, vector::pop_back(&mut addresses));
        };
    }

}