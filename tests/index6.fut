-- Test simple indexing of an array with a type that is not 32 bits.
-- ==
-- input {
--   [4i8,3i8,2i8,1i8,0i8]
--   1
-- }
-- output {
--   3i8
-- }

fun main(a: []i8, i: int): i8 =
  a[i]