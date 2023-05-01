module mintnft::mintnft {
    use std::string::{Self, String};
    use std::vector;
    use sui::url::{Self, Url};
    use sui::object::{Self, ID, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::event;
    
    // ===== Collection parameters =====
    const COLLECTION_NAME: vector<u8> = b"NftNameHere";
    const MAX_SUPPLY: u64 = 100;
    const NFT_DESCRIPTION: vector<u8> = b"NftNameHere Nft";
    const URL_PREFIX: vector<u8> = b"ipfs://";
    const COLLECTION_URI: vector<u8> = b"bafybeiaetnhmscuk6nqdnk4lvh6lxeadehfo342pszyqdodqoodtld77v4/";
    const NFT_FILE_FORMAT: vector<u8> = b".png";
    const UNREVEALED_NFT_NAME: vector<u8> = b"???";
    const UNREVEALED_NFT_DESCRIPTION: vector<u8> = b"Ready to reveal";
    const UNREVEALED_URL: vector<u8> = b"bafybeifqbhntp3ghp4vwrma3xivy5mkwlt3ljfiebr5zaewetjk72c4thu/INCOGNITA.png";

    const ESoldOut: u64 = 0;
    const ENftAlreadyRevealed: u64 = 4;

    struct NftNameHereCap has key, store {
        id: UID,
    }

    struct NftNameHereCollection has key {
        id: UID,
        owner: address,
        minted: u64,
    }

    struct NftNameHereNft has key, store {
        id: UID,
        name: String,
        description: String,
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
        });
    }

    public entry fun mint(
        collection: &mut NftNameHereCollection, 
        ctx: &mut TxContext,
    ) {
        assert!(collection.minted < MAX_SUPPLY, ESoldOut);

        let nft = NftNameHereNft {
            id: object::new(ctx),
            name: string::utf8(UNREVEALED_NFT_NAME),
            description: string::utf8(UNREVEALED_NFT_DESCRIPTION),
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
    }

    public entry fun reveal(
        nft: &mut NftNameHereNft,
    ) {
        assert!(!nft.revealed, ENftAlreadyRevealed);

        nft.name  = string::utf8(COLLECTION_NAME);
        nft.description  = string::utf8(NFT_DESCRIPTION);
        nft.url = url(vector[URL_PREFIX, COLLECTION_URI, int_to_bytes(nft.seed), NFT_FILE_FORMAT]);
        nft.revealed = true;
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
}