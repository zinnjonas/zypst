
#let p = plugin("zig-out/bin/zypst-example.wasm")

#{
  assert.eq(str(p.hello()), "Hello from zypst!")
  assert.eq(str(p.double_it(bytes("abc"))), "abcabc")
  assert.eq(str(p.concatenate(bytes("hello"), bytes("world"))), "hello*world")
  assert.eq(str(p.shuffle(bytes("s1"), bytes("s2"), bytes("s3"))), "s3-s1-s2")
  assert.eq(str(p.returns_ok()), "This is an `Ok`")

  let zig_json = p.get_place()
  assert.eq(str(zig_json), "{\"lat\":5.199766540527344e1,\"long\":-7.406870126724243e-1}")
  let (lat,) = json.decode(zig_json)
  [the lat = #lat]
  let new_pos = (lat: -7.406870126724243e-1, long: 5.199766540527344e1)
  linebreak()
  [the new lat = ]
  str(p.set_place(bytes(json.encode(new_pos, pretty: false))))
  // p.will_panic()  // Fails compilation
  // p.returns_err() // Fails compilation with an error message
}
