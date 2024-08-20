program fourier_interest.aleo;

struct InterestModelConfig:
    multiplierPerBlock as u128;
    baseRatePerBlock as u128;
    jumpMultiplierPerBlock as u128;
    kink as u128;

struct Interest:
    totalBorrows as u64;
    totalReserves as u64;
    borrowIndex as u128;
    accrualBlockNumber as u32;


mapping config:
	key as boolean.public;
	value as InterestModelConfig.public;


mapping interests:
	key as address.public;
	value as Interest.public;


function update_rate_model:
    input r0 as u128.private;
    input r1 as u128.private;
    input r2 as u128.private;
    input r3 as u128.private;
    is.eq self.caller aleo18j4szh5gt8qxe0tyt4eu0js70hkqhas0uzcrcxk2uwg4yadkqvzqy7qlj4 into r4;
    assert.eq r4 true;
    cast 2102400u32 into r5 as u128;
    div r0 r5 into r6;
    mul r1 1_000_000_000_000_000_000u128 into r7;
    cast 2102400u32 into r8 as u128;
    mul r8 r3 into r9;
    div r7 r9 into r10;
    cast 2102400u32 into r11 as u128;
    div r2 r11 into r12;
    async update_rate_model r6 r10 r12 r3 into r13;
    output r13 as fourier_interest.aleo/update_rate_model.future;

finalize update_rate_model:
    input r0 as u128.public;
    input r1 as u128.public;
    input r2 as u128.public;
    input r3 as u128.public;
    cast r1 r0 r2 r3 into r4 as InterestModelConfig;
    set r4 into config[true];








function accure_interest:
    input r0 as u64.private;
    async accure_interest self.caller r0 into r1;
    output r1 as fourier_interest.aleo/accure_interest.future;

finalize accure_interest:
    input r0 as address.public;
    input r1 as u64.public;
    cast 0u64 0u64 1_000_000_000_000_000_000u128 0u32 into r2 as Interest;
    get.or_use interests[r0] r2 into r3;
    get config[true] into r4;
    is.eq r3.totalBorrows 0u64 into r5;
    cast r1 into r6 as u128;
    cast r3.totalBorrows into r7 as u128;
    cast r3.totalReserves into r8 as u128;
    mul r7 1_000_000_000_000_000_000u128 into r9;
    add r6 r7 into r10;
    sub r10 r8 into r11;
    div r9 r11 into r12;
    ternary r5 0u128 r12 into r13;
    lt r13 r4.kink into r14;
    mul r13 r4.multiplierPerBlock into r15;
    div r15 1_000_000_000_000_000_000u128 into r16;
    add r16 r4.baseRatePerBlock into r17;
    mul r4.kink r4.multiplierPerBlock into r18;
    div r18 1_000_000_000_000_000_000u128 into r19;
    add r19 r4.baseRatePerBlock into r20;
    sub r13 r4.kink into r21;
    mul r21 r4.jumpMultiplierPerBlock into r22;
    div r22 1_000_000_000_000_000_000u128 into r23;
    add r23 r20 into r24;
    ternary r14 r17 r24 into r25;
    lte r25 5_000_000_000_000u128 into r26;
    assert.eq r26 true;
    sub block.height r3.accrualBlockNumber into r27;
    cast 0u64 0u64 0u128 block.height into r28 as Interest;
    set r28 into interests[r0];



