//! The canonical ABI shape of `ai-direct:text-width/width@0.1.0`.
//!
//! `columns: func(text: string) -> u32` lowers to `(ptr, len) -> i32` with the
//! caller allocating the string through `cabi_realloc`, so the export below is
//! the whole component boundary. `wasm-tools component embed` finds it by
//! name, which is why the name carries the interface and its version.

#![no_std]

use unicode_width::UnicodeWidthStr;

#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    core::arch::wasm32::unreachable()
}

/// Enough for any label a terminal will show, and the only memory the guest
/// string is written into. A bump pointer is the right allocator here because
/// an instance answers one call at a time and the harness drops it after.
const HEAP_SIZE: usize = 1 << 16;
static mut HEAP: [u8; HEAP_SIZE] = [0; HEAP_SIZE];
static mut BUMP: usize = 0;

#[no_mangle]
pub unsafe extern "C" fn cabi_realloc(
    _old: *mut u8,
    _old_size: usize,
    align: usize,
    new: usize,
) -> *mut u8 {
    let base = &raw mut HEAP as *mut u8;
    let start = (BUMP + align - 1) & !(align - 1);
    BUMP = start + new;
    base.add(start)
}

/// Widths are additive over a run of text, so the stripped text is measured in
/// fixed-size pieces rather than assembled in one allocation. `VISIBLE` is
/// only ever flushed on a character boundary, so no scalar is split; the one
/// thing a split can lose is an emoji sequence that straddles a flush, which
/// no terminal label of this length contains.
const VISIBLE: usize = 512;

#[export_name = "ai-direct:text-width/width@0.1.0#columns"]
pub unsafe extern "C" fn columns(ptr: *const u8, len: usize) -> u32 {
    let bytes = core::slice::from_raw_parts(ptr, len);
    // The canonical ABI validated this as UTF-8 before the call; a component
    // may not receive a `string` that is not.
    let Ok(text) = core::str::from_utf8(bytes) else {
        return 0;
    };

    let mut buffer = [0u8; VISIBLE];
    let mut filled = 0usize;
    let mut total = 0u32;
    let flush = |buffer: &[u8], filled: &mut usize, total: &mut u32| {
        if let Ok(part) = core::str::from_utf8(&buffer[..*filled]) {
            *total += UnicodeWidthStr::width(part) as u32;
        }
        *filled = 0;
    };

    let mut chars = text.chars().peekable();
    while let Some(c) = chars.next() {
        if c == '\x1b' && chars.peek() == Some(&'[') {
            chars.next();
            // An ANSI CSI sequence ends at one byte in 0x40..=0x7e, usually
            // `m`. Everything up to and including it occupies no column.
            for next in chars.by_ref() {
                if ('\x40'..='\x7e').contains(&next) {
                    break;
                }
            }
            continue;
        }
        if filled + c.len_utf8() > VISIBLE {
            flush(&buffer, &mut filled, &mut total);
        }
        c.encode_utf8(&mut buffer[filled..]);
        filled += c.len_utf8();
    }
    flush(&buffer, &mut filled, &mut total);
    total
}
