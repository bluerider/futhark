-- Simplest interesteing loop - factorial function.
-- ==
-- input {
--   10
-- }
-- output {
--   3628800
-- }
fun main(n: int): int =
  loop (x = 1) = for i < n do
    x * (i + 1)
  in x