module coinflip::casino {
    use std::vector;
    use sui::transfer;
    use sui::object::{Self, UID};
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::tx_context::{Self, TxContext};
    use sui::event;
    
    const DEFAULT_FEE: u64 = 10;
    const MAX_FEE: u64 = 20;

    const EInsufficientFunds: u64 = 0;
    const EInsufficientCasinoBalance: u64 = 1;
    const EFeePercentageLimitExceeded: u64 = 2;

    struct CasinoCap has key {
        id: UID,
    }

    struct Casino has key {
        id: UID,
        fee: u64,
        balance: Balance<SUI>,
    }

    struct CoinFlipResult has copy, drop {
        win_condition: bool,
    }
    
    fun init(ctx: &mut TxContext) {
        transfer::transfer(CasinoCap {
            id: object::new(ctx),
        }, tx_context::sender(ctx));
        transfer::share_object(Casino {
            id: object::new(ctx),
            fee: DEFAULT_FEE,
            balance: balance::zero(),
        })
    }

    public entry fun flip(
        casino: &mut Casino, 
        coins: vector<Coin<SUI>>, 
        bet: u64,
        ctx: &mut TxContext,
    ) {
        if(win_condition(ctx)) {
            let fee = (casino.fee * 100) / bet;
            let net_worth = bet - fee; 
            transfer_in(casino, coins, fee, ctx);
            transfer_out(casino, net_worth, ctx);
        } else { 
            transfer_in(casino, coins, bet, ctx);
        };

        event::emit(CoinFlipResult { 
            win_condition: win_condition(ctx),
        });
    }

    public entry fun collect_profits(
        _: &CasinoCap, 
        casino: &mut Casino, 
        amount: u64, 
        ctx: &mut TxContext
    ) {
        transfer_out(casino, amount, ctx);    
    }

    public entry fun transfer_balance(
        _: &CasinoCap, 
        casino: &mut Casino, 
        coins: vector<Coin<SUI>>, 
        amount: u64, 
        ctx: &mut TxContext
    ) {
        transfer_in(casino, coins, amount, ctx);
    }

    // TODO: remove
    public entry fun give_cap(
        _: &CasinoCap, 
        new_cap_address: address, 
        ctx: &mut TxContext
    ) {
        transfer::transfer(CasinoCap {
            id: object::new(ctx),
        }, new_cap_address);
    }

    public entry fun change_fee(_: &CasinoCap, casino: &mut Casino, new_fee: u64) {
        assert!(new_fee <= MAX_FEE, EFeePercentageLimitExceeded);

        casino.fee = new_fee;
    }

    fun transfer_in(casino: &mut Casino, coins: vector<Coin<SUI>>, amount: u64, ctx: &mut TxContext) {
        assert!(vector::length(&coins) > 0, EInsufficientFunds);

        let coin = vector::pop_back(&mut coins);
        while(!vector::is_empty(&coins)) coin::join(&mut coin, vector::pop_back(&mut coins));
        vector::destroy_empty(coins);
        assert!(coin::value(&coin) >= amount, EInsufficientFunds);

        let balance = coin::balance_mut(&mut coin);

        let paid = balance::split(balance, amount);
        balance::join(&mut casino.balance, paid);

        if(coin::value(&coin) == 0) {
            coin::destroy_zero(coin);
        } else {
            transfer::transfer(coin, tx_context::sender(ctx));
        };  
    }

    fun transfer_out(casino: &mut Casino, amount: u64, ctx: &mut TxContext) {
        assert!(balance::value(&casino.balance) >= amount, EInsufficientCasinoBalance);

        let to_collect = coin::take(&mut casino.balance, amount, ctx);
        transfer::transfer(to_collect, tx_context::sender(ctx))  
    }

    fun win_condition(ctx: &mut TxContext): bool {
        tx_context::epoch(ctx) % 2 == 0
    }
}