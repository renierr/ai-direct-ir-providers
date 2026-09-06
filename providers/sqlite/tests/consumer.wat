;; Conformance consumer: open data/test.db through the provider, create a
;; table, insert one row with bound params, read it back, check the value.
;; Prints OK on success, FAIL otherwise; tests/run.sh also verifies the
;; database file with the native sqlite3 CLI.
;;
;; Memory map (17 pages): 0x200 write result, 0x300 open result,
;;   0x320 exec result, 0x340 close result, 0x5000 params list,
;;   0x1000..0x2000 named segments, 0x40000+ canonical ABI bump allocation
;;
;; Canonical ABI notes (all discriminants in memory are u8):
;; - result<u32,string> at R: disc R, ok u32 at R+4, err ptr/len at R+4/R+8
;; - result<result-set,string> at R: disc R, columns ptr/len at R+4/R+8,
;;   rows ptr/len at R+12/R+16
;; - value variant in memory, stride 16: disc u8 at +0, payload at +8
;;   (int-val=0 i64, real-val=1 f64, text-val=2 ptr+len, blob-val=3 ptr+len)

(component
  ;; @wasi stdout pages=17 heap=0x40000
  ;; @data 0x1000..0x2000

  ;; Provider types use the emitter's eq-export pattern (air/src/wit.rs):
  ;; an imported instance may not define nominal types inline, so each
  ;; declares locally and exports the equality; signatures reference the
  ;; exported id. `air` forwards the funcs by name; the types only have
  ;; to agree with the provider's WIT, which they do verbatim.
  (import "ai-direct:sqlite/store@0.1.0" (instance $s
    (type $value-l (variant
      (case "int-val" s64) (case "real-val" f64)
      (case "text-val" string) (case "blob-val" (list u8)) (case "null-val")))
    (export "value" (type $value-x (eq $value-l)))
    (type $row-l (record (field "values" (list $value-x))))
    (export "row" (type $row-x (eq $row-l)))
    (type $result-set-l (record
      (field "columns" (list string)) (field "rows" (list $row-x))))
    (export "result-set" (type $result-set-x (eq $result-set-l)))
    (export "open" (func (param "path" string) (result (result u32 (error string)))))
    (export "exec" (func (param "handle" u32) (param "sql" string)
      (param "params" (list $value-x)) (result (result $result-set-x (error string)))))
    (export "close" (func (param "handle" u32) (result (result (error string)))))))
  (alias export $s "open" (func $open))
  (alias export $s "exec" (func $exec))
  (alias export $s "close" (func $close))
  (core func $open-l (canon lower (func $open) (memory $memory) (realloc $realloc)))
  (core func $exec-l (canon lower (func $exec) (memory $memory) (realloc $realloc)))
  (core func $close-l (canon lower (func $close) (memory $memory) (realloc $realloc)))
  (core instance $prov
    (export "open" (func $open-l))
    (export "exec" (func $exec-l))
    (export "close" (func $close-l)))

  (core module $main
    (import "env" "memory" (memory 17))
    (import "wasi" "get-stdout" (func $get_stdout (result i32)))
    (import "wasi" "write" (func $write (param i32 i32 i32 i32)))
    (import "provider" "open" (func $open (param i32 i32 i32)))
    (import "provider" "exec" (func $exec (param i32 i32 i32 i32 i32 i32)))
    (import "provider" "close" (func $close (param i32 i32)))

    (global $handle (mut i32) (i32.const 0))
    (data $ok "OK\n")
    (data $fail "FAIL\n")

    (func $print (param $ptr i32) (param $len i32)
      (call $write (call $get_stdout) (local.get $ptr) (local.get $len)
        (i32.const 0x200))
      (drop (i32.load (i32.const 0x200))))

    (func $fail (result i32)
      (call $print (global.get $fail.ptr) (global.get $fail.len))
      (i32.const 1))

    ;; ok==0 and discriminant==0, else FAIL.
    (func $check (param $ret i32) (result i32)
      (i32.load8_u (local.get $ret)))

    (func (export "run") (result i32)
      (local $rows i32) (local $nrows i32)
      (local $vals i32) (local $nvals i32)
      ;; open("data/test.db")
      (call $open (global.get $path.ptr) (global.get $path.len) (i32.const 0x300))
      (if (call $check (i32.const 0x300)) (then (return (call $fail))))
      (global.set $handle (i32.load (i32.const 0x304)))
      ;; CREATE TABLE
      (call $exec (global.get $handle)
        (global.get $create.ptr) (global.get $create.len)
        (i32.const 0) (i32.const 0) (i32.const 0x320))
      (if (call $check (i32.const 0x320)) (then (return (call $fail))))
      ;; params = [text-val("hello"), int-val(42)]
      (i32.store (i32.const 0x5000) (i32.const 2))
      (i32.store (i32.const 0x5008) (global.get $hello.ptr))
      (i32.store (i32.const 0x500C) (global.get $hello.len))
      (i32.store (i32.const 0x5010) (i32.const 0))
      (i64.store (i32.const 0x5018) (i64.const 42))
      ;; INSERT
      (call $exec (global.get $handle)
        (global.get $insert.ptr) (global.get $insert.len)
        (i32.const 0x5000) (i32.const 2) (i32.const 0x320))
      (if (call $check (i32.const 0x320)) (then (return (call $fail))))
      ;; SELECT
      (call $exec (global.get $handle)
        (global.get $select.ptr) (global.get $select.len)
        (i32.const 0) (i32.const 0) (i32.const 0x320))
      (if (call $check (i32.const 0x320)) (then (return (call $fail))))
      ;; one row, one int column, value 42
      (local.set $rows (i32.load (i32.const 0x32C)))
      (local.set $nrows (i32.load (i32.const 0x330)))
      (if (i32.ne (local.get $nrows) (i32.const 1))
        (then (return (call $fail))))
      (local.set $vals (i32.load (local.get $rows)))
      (local.set $nvals (i32.load (i32.add (local.get $rows) (i32.const 4))))
      (if (i32.ne (local.get $nvals) (i32.const 1))
        (then (return (call $fail))))
      (if (i32.load8_u (local.get $vals)) (then (return (call $fail))))
      (if (i64.ne (i64.load (i32.add (local.get $vals) (i32.const 8)))
            (i64.const 42))
        (then (return (call $fail))))
      ;; close
      (call $close (global.get $handle) (i32.const 0x340))
      (if (call $check (i32.const 0x340)) (then (return (call $fail))))
      (call $print (global.get $ok.ptr) (global.get $ok.len))
      (i32.const 0))

    (data $path "data/test.db")
    (data $hello "hello")
    (data $create "CREATE TABLE kv(k TEXT, v INTEGER)")
    (data $insert "INSERT INTO kv VALUES (?, ?)")
    (data $select "SELECT v FROM kv"))

  (core instance $app (instantiate $main
    (with "env" (instance $mem))
    (with "wasi" (instance $wasi))
    (with "provider" (instance $prov))))
  (func $run (result (result)) (canon lift (core func $app "run")))
  (instance $run-i (export "run" (func $run)))
  (export "wasi:cli/run@0.2.12" (instance $run-i))
)
