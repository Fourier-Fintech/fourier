import credits.aleo;
import fourier_oracle.aleo;
import fourier_interest.aleo;
program fourier_proxy.aleo;


struct Interest:
    totalBorrows as u64;
    totalReserves as u64;
    borrowIndex as u128;
    accrualBlockNumber as u32;

struct BorrowSnapshot:
    principal as u64;
    interestIndex as u64;


mapping account:
	key as address.public;
	value as u64.public;


mapping account_borrows:
	key as address.public;
	value as BorrowSnapshot.public;


function supply:
    input r0 as u64.private;
    call credits.aleo/transfer_public_as_signer aleo18j4szh5gt8qxe0tyt4eu0js70hkqhas0uzcrcxk2uwg4yadkqvzqy7qlj4 r0 into r1;
    call fourier_interest.aleo/accure_interest r0 into r2;
    async supply r2 r1 self.caller r0 into r3;
    output r3 as fourier_proxy.aleo/supply.future;

finalize supply:
    input r0 as fourier_interest.aleo/accure_interest.future;
    input r1 as credits.aleo/transfer_public_as_signer.future;
    input r2 as address.public;
    input r3 as u64.public;
    get.or_use account[aleo18j4szh5gt8qxe0tyt4eu0js70hkqhas0uzcrcxk2uwg4yadkqvzqy7qlj4] 0u64 into r4;
    await r0;
    get fourier_interest.aleo/interests[aleo18j4szh5gt8qxe0tyt4eu0js70hkqhas0uzcrcxk2uwg4yadkqvzqy7qlj4] into r5;
    is.eq r5.accrualBlockNumber block.height into r6;
    assert.eq r6 true;
    await r1;
    cast r3 into r7 as u128;
    mul r7 1_000_000_000_000_000_000u128 into r8;
    div r8 2_000_000_000_000u128 into r9;
    cast r9 into r10 as u64;
    get.or_use account[r2] 0u64 into r11;
    add r11 r10 into r12;
    set r12 into account[r2];




function withdraw:
    input r0 as u64.private;
    call fourier_interest.aleo/accure_interest 0u64 into r1;
    call credits.aleo/transfer_public aleo18j4szh5gt8qxe0tyt4eu0js70hkqhas0uzcrcxk2uwg4yadkqvzqy7qlj4 r0 into r2;
    async withdraw r1 r2 self.caller r0 into r3;
    output r3 as fourier_proxy.aleo/withdraw.future;

finalize withdraw:
    input r0 as fourier_interest.aleo/accure_interest.future;
    input r1 as credits.aleo/transfer_public.future;
    input r2 as address.public;
    input r3 as u64.public;
    await r0;
    get fourier_interest.aleo/interests[aleo18j4szh5gt8qxe0tyt4eu0js70hkqhas0uzcrcxk2uwg4yadkqvzqy7qlj4] into r4;
    is.eq r4.accrualBlockNumber block.height into r5;
    assert.eq r5 true;
    cast r3 into r6 as u128;
    mul r6 1_000_000_000_000_000_000u128 into r7;
    div r7 2_000_000_000_000u128 into r8;
    cast r8 into r9 as u64;
    await r1;
    get.or_use account[r2] 0u64 into r10;
    gte r10 r9 into r11;
    assert.eq r11 true;
    sub r10 r9 into r12;
    set r12 into account[r2];

