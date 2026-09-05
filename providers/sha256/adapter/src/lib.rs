#![no_std]
use sha2::{Digest, Sha256};

#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    core::arch::wasm32::unreachable()
}

const HEAP_SIZE: usize = 1 << 20;
static mut HEAP: [u8; HEAP_SIZE] = [0; HEAP_SIZE];
static mut BUMP: usize = 0;
static mut RET: [u32; 2] = [0; 2];

unsafe fn alloc(size: usize, align: usize) -> *mut u8 {
    let base = &raw mut HEAP as *mut u8;
    let start = (BUMP + align - 1) & !(align - 1);
    BUMP = start + size;
    base.add(start)
}

#[no_mangle]
pub unsafe extern "C" fn cabi_realloc(
    _old: *mut u8, _old_size: usize, align: usize, new: usize,
) -> *mut u8 {
    alloc(new, align)
}

unsafe fn digest_of(ptr: *const u8, len: usize) -> [u8; 32] {
    let mut h = Sha256::new();
    h.update(core::slice::from_raw_parts(ptr, len));
    h.finalize().into()
}

#[export_name = "ai-direct:sha256/digest@0.1.0#hash"]
pub unsafe extern "C" fn hash(ptr: *const u8, len: usize) -> *const u32 {
    let d = digest_of(ptr, len);
    let out = alloc(32, 1);
    core::ptr::copy_nonoverlapping(d.as_ptr(), out, 32);
    RET = [out as u32, 32];
    &raw const RET as *const u32
}

#[export_name = "ai-direct:sha256/digest@0.1.0#hash-hex"]
pub unsafe extern "C" fn hash_hex(ptr: *const u8, len: usize) -> *const u32 {
    let d = digest_of(ptr, len);
    let out = alloc(64, 1);
    for (i, b) in d.iter().enumerate() {
        const HEX: &[u8; 16] = b"0123456789abcdef";
        *out.add(i * 2) = HEX[(b >> 4) as usize];
        *out.add(i * 2 + 1) = HEX[(b & 15) as usize];
    }
    RET = [out as u32, 64];
    &raw const RET as *const u32
}
