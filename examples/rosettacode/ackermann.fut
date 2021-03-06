-- http://rosettacode.org/wiki/Ackermann_function
-- ==
-- input { 0 0 } output { 1 }
-- input { 1 1 } output { 3 }
-- input { 0 3 } output { 4 }

fun ackermann(m: i32, n: i32): i32 =
  if m == 0 then n + 1
  else if n == 0 then ackermann(m-1, 1)
  else ackermann(m - 1, ackermann(m, n-1))

fun main(m: i32, n: i32): i32 = ackermann(m, n)
