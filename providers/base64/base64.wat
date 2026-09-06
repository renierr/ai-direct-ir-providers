;; Base64 provider, RFC 4648 section 4. Memory: inputs are borrowed from the
;; caller; output uses the component's bump heap at 0x1000 onward.
(component
  (core module $m
    (memory (export "memory") 1)
    (global $bump (mut i32) (i32.const 0x1000))
    (data (i32.const 0x100) "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/")

    (func $alloc (param $n i32) (result i32)
      (local $p i32)
      (local.set $p (global.get $bump))
      (global.set $bump (i32.add (global.get $bump) (local.get $n)))
      (local.get $p))

    (func (export "cabi_realloc") (param i32 i32 i32 i32) (result i32)
      (call $alloc (local.get 3)))

    (func $digit (param $n i32) (result i32)
      (i32.load8_u (i32.add (i32.const 0x100) (local.get $n))))

    ;; encode(ptr, len) -> retptr. Return area [ptr, len] is at 0x800.
    (func (export "encode") (param $ptr i32) (param $len i32) (result i32)
      (local $out i32) (local $at i32) (local $to i32)
      (local $a i32) (local $b i32) (local $c i32)
      (local.set $out (call $alloc
        (i32.mul (i32.div_u (i32.add (local.get $len) (i32.const 2)) (i32.const 3)) (i32.const 4))))
      (local.set $to (local.get $out))
      (block $done (loop $groups
        (br_if $done (i32.ge_u (local.get $at) (local.get $len)))
        (local.set $a (i32.load8_u (i32.add (local.get $ptr) (local.get $at))))
        (local.set $b (if (result i32) (i32.lt_u (i32.add (local.get $at) (i32.const 1)) (local.get $len))
          (then (i32.load8_u (i32.add (local.get $ptr) (i32.add (local.get $at) (i32.const 1))))) (else (i32.const 0))))
        (local.set $c (if (result i32) (i32.lt_u (i32.add (local.get $at) (i32.const 2)) (local.get $len))
          (then (i32.load8_u (i32.add (local.get $ptr) (i32.add (local.get $at) (i32.const 2))))) (else (i32.const 0))))
        (i32.store8 (local.get $to) (call $digit (i32.shr_u (local.get $a) (i32.const 2))))
        (i32.store8 (i32.add (local.get $to) (i32.const 1)) (call $digit
          (i32.or (i32.shl (i32.and (local.get $a) (i32.const 3)) (i32.const 4)) (i32.shr_u (local.get $b) (i32.const 4)))))
        (i32.store8 (i32.add (local.get $to) (i32.const 2)) (if (result i32)
          (i32.lt_u (i32.add (local.get $at) (i32.const 1)) (local.get $len))
          (then (call $digit (i32.or (i32.shl (i32.and (local.get $b) (i32.const 15)) (i32.const 2)) (i32.shr_u (local.get $c) (i32.const 6)))))
          (else (i32.const 61))))
        (i32.store8 (i32.add (local.get $to) (i32.const 3)) (if (result i32)
          (i32.lt_u (i32.add (local.get $at) (i32.const 2)) (local.get $len))
          (then (call $digit (i32.and (local.get $c) (i32.const 63)))) (else (i32.const 61))))
        (local.set $at (i32.add (local.get $at) (i32.const 3)))
        (local.set $to (i32.add (local.get $to) (i32.const 4)))
        (br $groups)))
      (i32.store (i32.const 0x800) (local.get $out))
      (i32.store (i32.const 0x804) (i32.sub (local.get $to) (local.get $out)))
      (i32.const 0x800)))
  (core instance $i (instantiate $m))
  (alias core export $i "memory" (core memory $mem))
  (alias core export $i "cabi_realloc" (core func $realloc))
  (func $encode (param "text" string) (result string)
    (canon lift (core func $i "encode") (memory $mem) (realloc $realloc)))
  (instance $codec (export "encode" (func $encode)))
  (export "ai-direct:base64/codec@0.1.0" (instance $codec))
)
