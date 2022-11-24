module utils::time_lock {
    use sui::tx_context::{Self, TxContext};

    const EEpochNotYetEnded: u64 = 0;

    struct TimeLock has store, copy {
        epoch: u64
    }

    public fun new(epoch: u64) : TimeLock {
        TimeLock { epoch }
    }

    public fun is_locked(lock: TimeLock, ctx: &mut TxContext): bool {
        let TimeLock { epoch } = lock;
        tx_context::epoch(ctx) < epoch
    }

    public fun destroy(lock: TimeLock, ctx: &mut TxContext) {
        assert!(!is_locked(lock, ctx), EEpochNotYetEnded);
    }

    public fun epoch(lock: &TimeLock): u64 {
        lock.epoch
    }
}