-- ==
-- error:
fun f(t: ([]int,*[]int)): int =
  let (a,b) = t
  let b[0] = 1337 in
  a[0]

fun main(b: *[]int): int =
  let a = b in
  -- Should fail, because 'a' and 'b' are aliased, yet the 'b' part of
  -- the tuple is consumed.
  f((a,b))