;; Conformance consumer: hash stdin with the provider, print the hex digest.
;; Reading from stdin is what lets the test compare against sha256sum for
;; arbitrary input, including the padding boundaries where SHA-256
;; implementations usually break.
;;
;; Memory map (17 pages): 0x200 write result, 0x300 hash result,
;;   0x400 read result, 0x10000..0x40000 input buffer,
;;   0x40000+ canonical ABI bump allocation

(component
  ;; @wasi stdin stdout pages=17 heap=0x40000
  ;; @data 0x1000..0x2000

  (import "ai-direct:sha256/digest@0.1.0" (instance $d
    (export "hash-hex" (func (param "data" (list u8)) (result string)))))
  (alias export $d "hash-hex" (func $hash-hex))
  (core func $hash-hex-l
    (canon lower (func $hash-hex) (memory $memory) (realloc $realloc)))
  (core instance $prov (export "hash-hex" (func $hash-hex-l)))

  (core module $main
    (import "env" "memory" (memory 17))
    (import "wasi" "get-stdin" (func $get_stdin (result i32)))
    (import "wasi" "get-stdout" (func $get_stdout (result i32)))
    (import "wasi" "read" (func $read (param i32 i64 i32)))
    (import "wasi" "write" (func $write (param i32 i32 i32 i32)))
    (import "provider" "hash-hex" (func $hash_hex (param i32 i32 i32)))

    (global $BUF i32 (i32.const 0x10000))
    (global $CAP i32 (i32.const 0x30000))
    (data $nl "\n")

    ;; Read stdin to end. Returns the byte count, or -1 on a read failure or
    ;; an input larger than the buffer.
    ;;
    ;; The read result is `result<list<u8>, stream-error>`: 0x400 holds the
    ;; outer discriminant, 0x404/0x408 the list pointer and length on ok. On
    ;; err, 0x404 holds the stream-error case -- 1 is `closed`, the normal end
    ;; of input, and 0 is a real failure.
    (func $read_all (result i32)
      (local $total i32) (local $n i32)
      (local.set $total (i32.const 0))
      (block $done
        (loop $more
          (call $read (call $get_stdin) (i64.const 4096) (i32.const 0x400))
          ;; Discriminants are u8: `i32.load` would read three bytes of
          ;; undefined padding along with the tag.
          (if (i32.load8_u (i32.const 0x400))
            (then
              (br_if $done
                (i32.eq (i32.load8_u (i32.const 0x404)) (i32.const 1)))
              (return (i32.const -1))))
          (local.set $n (i32.load (i32.const 0x408)))
          (br_if $done (i32.eqz (local.get $n)))
          (if (i32.gt_u (i32.add (local.get $total) (local.get $n))
                        (global.get $CAP))
            (then (return (i32.const -1))))
          (memory.copy
            (i32.add (global.get $BUF) (local.get $total))
            (i32.load (i32.const 0x404))
            (local.get $n))
          (local.set $total (i32.add (local.get $total) (local.get $n)))
          (br $more)))
      (local.get $total))

    (func (export "run") (result i32)
      (local $n i32)
      (local.set $n (call $read_all))
      (if (i32.lt_s (local.get $n) (i32.const 0)) (then (return (i32.const 1))))
      (call $hash_hex (global.get $BUF) (local.get $n) (i32.const 0x300))
      (call $write (call $get_stdout)
        (i32.load (i32.const 0x300)) (i32.load (i32.const 0x304))
        (i32.const 0x200))
      (call $write (call $get_stdout)
        (global.get $nl.ptr) (global.get $nl.len) (i32.const 0x200))
      (i32.load (i32.const 0x200))))

  (core instance $app (instantiate $main
    (with "env" (instance $mem))
    (with "wasi" (instance $wasi))
    (with "provider" (instance $prov))))
  (func $run (result (result)) (canon lift (core func $app "run")))
  (instance $run-i (export "run" (func $run)))
  (export "wasi:cli/run@0.2.12" (instance $run-i))
)
