module collection::collection {
    use std::ascii::{Self, String};
    use sui::object::{Self, ID, UID};
    use sui::url::Url;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::sui::SUI;
    use sui::coin::Coin;
    use sui::event;
    use collection::utils;
    use collection::payments;

    // ===== Collection parameters =====

    const MAX_SUPPLY: u64 = 100;
    const PRICE: u64 = 100000000;  
    const COLLECTION_NAME: vector<u8> = b"Test";
    const COLLECTION_URI: vector<u8> = b"bafybeiaetnhmscuk6nqdnk4lvh6lxeadehfo342pszyqdodqoodtld77v4";
    const NFT_FORMAT: vector<u8> = b"png";
    const MINT_REVEALED: bool = false;

    // Avoid this if MINT_REVEALED is true
    const UNREVEALED_COLLECTION_NAME: vector<u8> = b"???";
    const UNREVEALED_COLLECTION_URI: vector<u8> = b"bafybeifqbhntp3ghp4vwrma3xivy5mkwlt3ljfiebr5zaewetjk72c4thu";
    const UNREVEALED_NFT: vector<u8> = b"INCOGNITA";
    const UNREVEALED_NFT_FORMAT: vector<u8> = b"png";

    // =================================

    const URL_PREFIX: vector<u8> = b"ipfs://";
    
    const ESOLD_OUT: u64 = 0;
    const EALREADY_REVEALED: u64 = 1;

    struct NftCollectionCap has key, store {
        id: UID,
    }

    struct NftName has key, store {
        id: UID,
        name: String,
        url: Url,
        seed: u64,
        revealed: bool,
    }

    struct NftCollection has key {
        id: UID,
        owner: address,
        counter: u64,
        price: u64,
    }

    struct NftMinted has copy, drop {
        id: ID,
        creator: address,
    }

    fun init(ctx: &mut TxContext) {
        transfer::transfer(NftCollectionCap {
            id: object::new(ctx)
        }, tx_context::sender(ctx));
        transfer::share_object(NftCollection {
            id: object::new(ctx),
            owner: tx_context::sender(ctx),
            counter: 0,
            price: PRICE,
        });
    }

    public entry fun mint(supplier: &mut NftCollection, payment: vector<Coin<SUI>>, ctx: &mut TxContext) {
        
        // Check availability
        assert!(supplier.counter < MAX_SUPPLY, ESOLD_OUT);

        // Make payment
        payments::pay(payment, supplier.price, supplier.owner, ctx);

        // Increase collection supply counter
        supplier.counter = supplier.counter + 1;

        // Emit event
        let id = object::new(ctx);
        let sender = tx_context::sender(ctx);
        event::emit(NftMinted { 
            id: object::uid_to_inner(&id),
            creator: sender,
        });

        // Create the nft
        let nft = NftName {
            id: id,
            name: ascii::string(UNREVEALED_COLLECTION_NAME),
            url: utils::build_url(URL_PREFIX, UNREVEALED_COLLECTION_URI, UNREVEALED_NFT, UNREVEALED_NFT_FORMAT),
            seed: supplier.counter,
            revealed: false,
        };
        if (MINT_REVEALED) reveal(&mut nft);

        // Send nft to sender
        transfer::transfer(nft, sender);
    }

    public entry fun reveal(nft: &mut NftName) {
        assert!(!nft.revealed, EALREADY_REVEALED);

        nft.name  = ascii::string(COLLECTION_NAME);
        nft.url = utils::build_url(URL_PREFIX, COLLECTION_URI, utils::u64_to_vector(nft.seed), NFT_FORMAT);
        nft.revealed = true;
    }

    public entry fun set_price(_: &NftCollectionCap, supplier: &mut NftCollection, price: u64) {
        supplier.price = price;
    }
}