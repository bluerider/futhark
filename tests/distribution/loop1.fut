-- Like loop0.fut, but the sequential loop also carries a scalar
-- variable that is not mapped.
--
-- ==
--
-- input {
--   [[[1,7],[9,4],[8,6]],
--    [[1,0],[6,4],[1,6]]]
-- }
-- output {
--   [[18, 17], [8, 10]]
--   [8, 8]
-- }
--
-- structure distributed { Map/DoLoop 0 }

fun main(a: [n][m][k]i32): ([n][k]i32,[n]i32) =
  let acc = replicate k 0
  let accnum = 1 in
  unzip(map (\(a_r: [m][k]i32): ([k]i32,i32)  ->
        loop((acc,accnum)) = for i < m do
          (map (+) acc (a_r[i]),
           accnum + accnum) in
        (acc, accnum)
     ) a)

-- Example of what we want - this is dead code.
fun main_distributed(a: [n][m][k]i32): ([n][k]i32,[n]i32) =
  let acc_expanded = replicate n (replicate k 0)
  let accnum_expanded = replicate n 1 in
  loop((acc_expanded,accnum_expanded)) = for i < m do
    unzip(map (\(acc: [k]i32) (accnum: i32) (a_r: [m][k]i32): ([k]i32,i32)  ->
                    (map (+) acc (a_r[i]),
                     accnum * accnum)
                 ) (acc_expanded) (accnum_expanded) a)
  in (acc_expanded,accnum_expanded)
