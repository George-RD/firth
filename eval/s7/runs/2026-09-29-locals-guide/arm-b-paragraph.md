Prefer names to stack shuffling. Open each word's body with a `locals`
block that names every input, in the stack effect's order, and write the
rest of the word with those names. Do not arrange values with `dup`,
`drop`, `swap` or `dip`, and do not use Forth words such as `over`, `rot`,
`nip` or `tuck`, which Firth does not define. Inside the block you do not
need them: use a name again instead of `dup`, leave a name unused instead
of `drop`, and write names in the order an operation needs them instead of
`swap`. Names can be used inside quotations and `if` branches. To name a
value computed partway through a word, open another block on it, as in
`a a prim * locals { s } { s b prim + s prim + }`, or pass it to a helper
word whose body opens its own `locals` block.
