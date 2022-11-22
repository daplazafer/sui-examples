module collection::payments {
    use sui::coin;
    use sui::transfer;
    use sui::pay;
    use sui::tx_context::{Self, TxContext};
    use std::vector;

    const ENoCoins: u64 = 0;

    public fun pay<T>(coins: vector<coin::Coin<T>>, price: u64, recipient: address, ctx: &mut TxContext) {
        assert!(vector::length(&coins) > 0, ENoCoins);

        let coin = vector::pop_back(&mut coins);
        pay::join_vec(&mut coin, coins);
        pay::split_and_transfer<T>(&mut coin, price, recipient, ctx);
        transfer::transfer(coin, tx_context::sender(ctx));
    }
}