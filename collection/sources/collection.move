module collection::collection {
    use sui::object::{Self, ID, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use std::vector;
    use sui::url::{Self, Url};
    use std::ascii::{Self, String};
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::event;
    
    // Collection parameters
    const MAX_SUPPLY: u64 = 100;
    const PRICE: u64 = 100000000;  
    const COLLECTION_NAME: vector<u8> = b"Test collection name";
    const COLLECTION_DESCRIPTION: vector<u8> = b"Test collection description";
    const URI: vector<u8> = b"bafybeiaetnhmscuk6nqdnk4lvh6lxeadehfo342pszyqdodqoodtld77v4";
    const NFT_FORMAT: vector<u8> = b".png";
    const MINT_REVEALED: bool = false;
    const UNREVEALED_COLLECTION_NAME: vector<u8> = b"???";
    const UNREVEALED_COLLECTION_DESCRIPTION: vector<u8> = b"Ready to be revealed";
    const UNREVEALED_URI: vector<u8> = b"bafybeifqbhntp3ghp4vwrma3xivy5mkwlt3ljfiebr5zaewetjk72c4thu";
    const UNREVEALED_NFT: vector<u8> = b"INCOGNITA";
    const UNREVEALED_NFT_FORMAT: vector<u8> = b".png";
    //--

    const URI_PREFIX: vector<u8> = b"ipfs://";
    
    const ESOLD_OUT: u64 = 0;
    const EINSUFFICIENT_FUNDS: u64 = 1;
    const EALREADY_REVEALED: u64 = 2;

    struct Nft has key, store {
        id: UID,
        name: String,
        description: String,
        seed: u64,
        revealed: bool,
        url: Url,
    }

    struct CollectionSupplier has key {
        id: UID,
        counter: u64,
        price: u64,
        balance: Balance<SUI>,
    }

    struct CollectionOwner has key, store {
        id: UID,
    }

    struct NftMinted has copy, drop {
        id: ID,
        creator: address,
    }

    fun init(ctx: &mut TxContext) {
        transfer::transfer(CollectionOwner {
            id: object::new(ctx),
        }, tx_context::sender(ctx));
        transfer::share_object(CollectionSupplier {
            id: object::new(ctx),
            counter: 0,
            price: PRICE,
            balance: balance::zero()
        });
    }

    public entry fun mint(supplier: &mut CollectionSupplier, payment: &mut Coin<SUI>, ctx: &mut TxContext) {
        assert!(supplier.counter < MAX_SUPPLY, ESOLD_OUT);
        assert!(coin::value(payment) >= supplier.price, EINSUFFICIENT_FUNDS);

        // Make payment
        let coin_balance = coin::balance_mut(payment);
        let paid = balance::split(coin_balance, supplier.price);
        balance::join(&mut supplier.balance, paid);

        // Increase nft counter
        supplier.counter = supplier.counter + 1;

        // Emit event
        let id = object::new(ctx);
        let sender = tx_context::sender(ctx);
        event::emit(NftMinted { 
            id: object::uid_to_inner(&id),
            creator: sender,
        });

        // Create nft
        let nft = Nft {
            id: id,
            name: ascii::string(UNREVEALED_COLLECTION_NAME),
            description: ascii::string(UNREVEALED_COLLECTION_DESCRIPTION),
            seed: supplier.counter,
            revealed: false,
            url: build_url(URI_PREFIX, UNREVEALED_URI, UNREVEALED_NFT, UNREVEALED_NFT_FORMAT),
        };
        if (MINT_REVEALED) { reveal(&mut nft); };

        // Send nft to sender
        transfer::transfer(nft, sender);
    }

    public entry fun reveal(nft: &mut Nft) {
        assert!(nft.revealed == false, EALREADY_REVEALED);

        nft.name  = ascii::string(COLLECTION_NAME);
        nft.description = ascii::string(COLLECTION_DESCRIPTION);
        nft.url = build_url(URI_PREFIX, URI, u64_to_vector(nft.seed), NFT_FORMAT);
        nft.revealed = true;
    }

    public entry fun set_price(_: &CollectionOwner, supplier: &mut CollectionSupplier, price: u64) {
        supplier.price = price;
    }

    public entry fun collect_profits(_: &CollectionOwner, supplier: &mut CollectionSupplier, ctx: &mut TxContext) {

        let amount = balance::value(&supplier.balance);
        let profits = coin::take(&mut supplier.balance, amount, ctx);

        transfer::transfer(profits, tx_context::sender(ctx))
    }

    fun build_url(url_prefix: vector<u8>, uri: vector<u8>, nft_name: vector<u8>, nft_format: vector<u8>): Url {
        let url_builder: vector<u8> = vector::empty<u8>();
        vector::append(&mut url_builder, url_prefix);
        vector::append(&mut url_builder, uri);
        vector::append(&mut url_builder, b"/");
        vector::append(&mut url_builder, nft_name); 
        vector::append(&mut url_builder, nft_format);
        url::new_unsafe_from_bytes(url_builder)
    }

    fun u64_to_vector(num: u64): vector<u8>{
        let vec = vector::empty();
        while (num/10 > 0){
            let rem = num%10;
            vector::push_back(&mut vec, (rem+48 as u8));
            num = num/10;
        };
        vector::push_back(&mut vec, (num+48 as u8));
        vector::reverse(&mut vec);
        vec
    }
}