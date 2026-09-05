;; Conformance consumer: measure stdin with the provider, print the column
;; count. Reading from stdin is what lets the test drive arbitrary text --
;; ASCII, wide CJK, combining marks and ANSI-styled labels -- from a shell
;; script and compare against a reference.
;;
;; A trailing newline is stripped, because the shell adds one and it is not
;; part of the text being measured.
;;
;; Memory map (5 pages): 0x200 write result, 0x400 read result,
;;   0x1000..0x2000 text, 0x10000..0x30000 input buffer,
;;   0x30000+ canonical ABI bump allocation

(component
  ;; @wasi stdin stdout pages=5 heap=0x30000
  ;; @data 0x1000..0x2000

  (import "ai-direct:text-width/width@0.1.0" (instance $w
    (export "columns" (func (param "text" string) (result u32)))))
  (alias export $w "columns" (func $columns))
  (core func $columns-l
    (canon lower (func $columns) (memory $memory) (realloc $realloc)))
  (core instance $prov (export "columns" (func $columns-l)))

  (core module $main
    (import "env" "memory" (memory 5))
    (import "wasi" "get-stdin" (func $get_stdin (result i32)))
    (import "wasi" "get-stdout" (func $get_stdout (result i32)))
    (import "wasi" "read" (func $read (param i32 i64 i32)))
    (import "wasi" "write" (func $write (param i32 i32 i32 i32)))
    ;; `u32` is a flat result, so unlike a `string` this needs no return area.
    (import "provider" "columns" (func $columns (param i32 i32) (result i32)))

    (global $BUF i32 (i32.const 0x10000))
    (global $CAP i32 (i32.const 0x1f000))
    (global $OUT i32 (i32.const 0x2000))
    (data $nl "\n")

    ;; Read stdin to end. Returns the byte count, or -1 on a read failure or
    ;; an input larger than the buffer. The read result is
    ;; `result<list<u8>, stream-error>`: 0x400 holds the outer discriminant,
    ;; 0x404/0x408 the list pointer and length on ok. On err, 0x404 holds the
    ;; stream-error case -- 1 is `closed`, the normal end of input.
    (func $read_all (result i32)
      (local $total i32) (local $n i32)
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

    ;; Write $n as decimal at $at, most significant digit first, and answer
    ;; the address just past the last digit.
    (func $digits (param $at i32) (param $n i32) (result i32)
      (local $end i32)
      (local.set $end
        (if (result i32) (i32.ge_u (local.get $n) (i32.const 10))
          (then (call $digits (local.get $at)
                  (i32.div_u (local.get $n) (i32.const 10))))
          (else (local.get $at))))
      (i32.store8 (local.get $end)
        (i32.add (i32.const 48) (i32.rem_u (local.get $n) (i32.const 10))))
      (i32.add (local.get $end) (i32.const 1)))

    (func (export "run") (result i32)
      (local $n i32) (local $len i32)
      (local.set $n (call $read_all))
      (if (i32.lt_s (local.get $n) (i32.const 0)) (then (return (i32.const 1))))
      ;; The shell's trailing newline is not part of the text.
      (if (i32.and (i32.gt_u (local.get $n) (i32.const 0))
            (i32.eq (i32.load8_u
                      (i32.add (global.get $BUF)
                        (i32.sub (local.get $n) (i32.const 1))))
                    (i32.const 10)))
        (then (local.set $n (i32.sub (local.get $n) (i32.const 1)))))
      (local.set $len
        (i32.sub
          (call $digits (global.get $OUT)
            (call $columns (global.get $BUF) (local.get $n)))
          (global.get $OUT)))
      (call $write (call $get_stdout)
        (global.get $OUT) (local.get $len) (i32.const 0x200))
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
