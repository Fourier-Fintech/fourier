/// From JumpRateModelV2

program fourier_interest.aleo {
    const OWNER: address = aleo18j4szh5gt8qxe0tyt4eu0js70hkqhas0uzcrcxk2uwg4yadkqvzqy7qlj4;

    const BASE: u128 = 1_000_000_000_000_000_000u128; // 100%

    const BORROW_RATE_MAX: u128 = 5_000_000_000_000u128; // 0.0005%

    const BLOCKS_PER_YEAR: u32 = 2102400u32; // TODO(replace to aleo block time)

    // TODO: add reserveFactorMantissa
    mapping config: bool => InterestModelConfig;

    struct InterestModelConfig {
        multiplierPerBlock: u128,
        baseRatePerBlock: u128,
        jumpMultiplierPerBlock: u128,
        kink: u128,
    }

    /// Token => Interest
    mapping interests: address => Interest;

    struct Interest {
        totalBorrows: u64,
        totalReserves: u64,
        borrowIndex: u128,
        accrualBlockNumber: u32,
    }

    async transition update_rate_model (base_rate_per_year: u128, multiplier_per_block: u128, jump_multiplier_per_block: u128, kink: u128) -> Future {
        assert(self.caller == OWNER);

        let base_rate_per_year_: u128 = base_rate_per_year / BLOCKS_PER_YEAR as u128;
        let multiplier_per_block_: u128 = (multiplier_per_block * BASE) / (BLOCKS_PER_YEAR as u128 * kink);
        let jump_multiplier_per_block_: u128 = jump_multiplier_per_block / BLOCKS_PER_YEAR as u128;

        return update_finalize(base_rate_per_year_, multiplier_per_block_, jump_multiplier_per_block_, kink);
    }

    async function update_finalize (base: u128, multiplier: u128, jump: u128, kink: u128) {
        let config_: InterestModelConfig = InterestModelConfig {
            multiplierPerBlock: multiplier,
            baseRatePerBlock: base,
            jumpMultiplierPerBlock: jump,
            kink: kink,
        };

        Mapping::set(config, true, config_);
    }

    async transition accure_interest (cashPrior: u64) -> Future {
        return accure_interest_finalize(self.caller, cashPrior);
    }

    async function accure_interest_finalize (caller: address, cashPrior: u64) {
        let interst: Interest = Mapping::get_or_use(interests, caller, Interest {
            totalBorrows: 0u64,
            totalReserves: 0u64,
            borrowIndex: BASE,
            accrualBlockNumber: 0u32,
        });

        let current_block_number: u32 = block.height;
        let borrowPrior: u64 = interst.totalBorrows;
        let reservesPrior: u64 = interst.totalReserves;
        let borrowIndexPrior: u128 = interst.borrowIndex;

        let cfg: InterestModelConfig = Mapping::get(config, true);

        let borrow_rate: u128 = get_borrow_rate(cashPrior, borrowPrior, reservesPrior, cfg);

        assert(borrow_rate <= BORROW_RATE_MAX);

        let block_delta: u32 = current_block_number - interst.accrualBlockNumber;

        /*
         * Calculate the interest accumulated into borrows and reserves and the new index:
         *  simpleInterestFactor = borrowRate * blockDelta
         *  interestAccumulated = simpleInterestFactor * totalBorrows
         *  totalBorrowsNew = interestAccumulated + totalBorrows
         *  totalReservesNew = interestAccumulated * reserveFactor + totalReserves
         *  borrowIndexNew = simpleInterestFactor * borrowIndex + borrowIndex
        */
        // TODO
        // let simple_interest_factor: u128 = borrow_rate * ((block_delta as u128) * BASE);
        // let interest_accumulated: u128 = simple_interest_factor * borrowPrior as u128 / BASE;
        // let total_borrows_new: u64 = ((interest_accumulated + borrowPrior as u128) / BASE) as u64;
        // let total_reserves_new: u64 = ((interest_accumulated * cfg.reserveFactor / BASE) + reservesPrior as u128) as u64;
        // let borrow_index_new: u128 = simple_interest_factor * borrowIndexPrior / BASE + borrowIndexPrior;

        Mapping::set(interests, caller, Interest {
            totalBorrows: 0u64,
            totalReserves: 0u64,
            borrowIndex: 0u128,
            accrualBlockNumber: current_block_number,
        });
    }

    inline utilization_rate (cash: u64, borrows: u64, reserves: u64) -> u128 {
        if borrows == 0u64 {
            return 0u128;
        }

        let cash_scaled: u128 = cash as u128;
        let borrows_scaled: u128 = borrows as u128;
        let reserves_scaled: u128 = reserves as u128;

        return borrows_scaled * BASE / (cash_scaled + borrows_scaled - reserves_scaled);
    }

    inline get_borrow_rate(cash: u64, borrows: u64, reserves: u64, cfg: InterestModelConfig) -> u128 {
        let util: u128 = utilization_rate(cash, borrows, reserves);

        if util < cfg.kink {
            return ((util * cfg.multiplierPerBlock) / BASE) + cfg.baseRatePerBlock;
        } else {
            let normal_rate: u128 = ((cfg.kink * cfg.multiplierPerBlock) / BASE) + cfg.baseRatePerBlock;
            let excess_util: u128 = util - cfg.kink;
            return ((excess_util * cfg.jumpMultiplierPerBlock) / BASE) + normal_rate;
        }
    }

    inline get_supply_rate (cash: u64, borrows: u64, reserves: u64, reserve_factor:u128, cfg: InterestModelConfig) -> u128 {
        let one_minus_reserve_factor: u128 = BASE - reserve_factor;
        let borrow_rate: u128 = get_borrow_rate(cash, borrows, reserves, cfg);
        let rate_to_pool: u128 = borrow_rate * one_minus_reserve_factor / BASE;
        return utilization_rate(cash, borrows, reserves) * rate_to_pool / BASE;
    }
}
