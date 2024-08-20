import credits.aleo;
import fourier_interest.aleo;
import fourier_oracle.aleo;

/// Aleo Fourier proxy
/// TODO: add controller verify
program fourier_proxy.aleo {
    mapping account: address => u64;
    const BASE: u128 = 1_000_000_000_000_000_000u128; // 100%
    const CONTRACT: address = aleo18j4szh5gt8qxe0tyt4eu0js70hkqhas0uzcrcxk2uwg4yadkqvzqy7qlj4; // TODO: replace with real address

    mapping account_borrows: address => BorrowSnapshot;

    struct BorrowSnapshot {
        principal: u64,
        interestIndex: u64,
    }

    // shadow fourier_interest.aleo.Interest
    struct Interest {
        totalBorrows: u64,
        totalReserves: u64,
        borrowIndex: u128,
        accrualBlockNumber: u32,
    }

    async transition supply (amount: u64) -> Future {
        // transfer in
        let transfer_contract: Future = credits.aleo/transfer_public_as_signer(CONTRACT, amount);
        let accure_interest: Future = fourier_interest.aleo/accure_interest(amount); // TODO: use cashPrior
        return supply_finalize(accure_interest, transfer_contract, self.caller, amount);
    }

    async function supply_finalize (f0: Future, f1: Future, caller: address, amount: u64) {
        let cash: u64 = Mapping::get_or_use(account, CONTRACT, 0u64); // TODO: use cashPrior
        // accure interest
        f0.await();

        let interst: Interest = Mapping::get(fourier_interest.aleo/interests, CONTRACT);
        assert(interst.accrualBlockNumber == block.height);

        // TODO: implement interest calculation
        let exchange_rate: u128 = 2_000_000_000_000u128;

        // transfer in
        f1.await();
        let mint_amount: u64 = (amount as u128 * BASE / exchange_rate) as u64;

        /// Mint FToken
        let balance: u64 = Mapping::get_or_use(account, caller, 0u64);
        Mapping::set(account, caller, balance + mint_amount);
    }

    async transition withdraw (amount: u64) -> Future {
        // accure interest
        let accure_interest: Future = fourier_interest.aleo/accure_interest(0u64); // TODO: use cashPrior
        // tranfer out
        let withdraw: Future = credits.aleo/transfer_public(CONTRACT, amount);
        return withdraw_finalize(accure_interest, withdraw, self.caller, amount);
    }

    async function withdraw_finalize (f0: Future, f1: Future, caller: address, amount: u64) {
        // accure interest
        f0.await();

        let exchange_rate: u128 = 2_000_000_000_000u128;
        let interest: Interest = Mapping::get(fourier_interest.aleo/interests, CONTRACT);
        assert(interest.accrualBlockNumber == block.height);
        let burn_token: u64 = (amount as u128 * BASE / exchange_rate) as u64;

        // transfer out
        f1.await();

        /// Burn FToken
        let balance: u64 = Mapping::get_or_use(account, caller, 0u64);
        assert(balance >= burn_token);
        Mapping::set(account, caller, balance - burn_token);
    }

    // TODO: implement borrow and repay and liquidate
}
