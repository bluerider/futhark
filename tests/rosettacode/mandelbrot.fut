-- Computes escapes for each pixel, but not the colour.
-- ==
-- input { 10 10 100 0.0f32 0.0f32 1.0f32 1.0f32 }
-- output {
--   [[100i32, 100i32, 100i32, 100i32, 100i32, 100i32, 100i32, 12i32, 17i32, 7i32],
--    [100i32, 100i32, 100i32, 100i32, 100i32, 100i32, 100i32, 8i32, 5i32, 4i32],
--    [100i32, 100i32, 100i32, 100i32, 100i32, 100i32, 11i32, 5i32, 4i32, 3i32],
--    [11i32, 100i32, 100i32, 100i32, 100i32, 100i32, 14i32, 5i32, 4i32, 3i32],
--    [6i32, 7i32, 30i32, 14i32, 8i32, 6i32, 14i32, 4i32, 3i32, 2i32],
--    [4i32, 4i32, 4i32, 5i32, 4i32, 4i32, 3i32, 3i32, 2i32, 2i32],
--    [3i32, 3i32, 3i32, 3i32, 3i32, 2i32, 2i32, 2i32, 2i32, 2i32],
--    [2i32, 2i32, 2i32, 2i32, 2i32, 2i32, 2i32, 2i32, 2i32, 1i32],
--    [2i32, 2i32, 2i32, 2i32, 2i32, 2i32, 2i32, 1i32, 1i32, 1i32],
--    [2i32, 2i32, 2i32, 2i32, 2i32, 1i32, 1i32, 1i32, 1i32, 1i32]]
-- }

default(f32)

type complex = (f32, f32)

fun dot(c: complex): f32 =
  let (r, i) = c
  in r * r + i * i

fun multComplex(x: complex, y: complex): complex =
  let (a, b) = x
  let (c, d) = y
  in (a*c - b * d,
      a*d + b * c)

fun addComplex(x: complex, y: complex): complex =
  let (a, b) = x
  let (c, d) = y
  in (a + c,
      b + d)

fun divergence(depth: int, c0: complex): int =
  loop ((c, i) = (c0, 0)) = while i < depth && dot(c) < 4.0 do
    (addComplex(c0, multComplex(c, c)),
     i + 1)
  in i

fun mandelbrot(screenX: int, screenY: int, depth: int, view: (f32,f32,f32,f32)): [screenX][screenY]int =
  let (xmin, ymin, xmax, ymax) = view
  let sizex = xmax - xmin
  let sizey = ymax - ymin
  in map (fn (x: int): [screenY]int  =>
           map  (fn (y: int): int  =>
                  let c0 = (xmin + (f32(x) * sizex) / f32(screenX),
                            ymin + (f32(y) * sizey) / f32(screenY))
                  in divergence(depth, c0))
                (iota screenY))
         (iota screenX)

fun main(screenX: int, screenY: int, depth: int, xmin: f32, ymin: f32, xmax: f32, ymax: f32): [screenX][screenY]int =
  mandelbrot(screenX, screenY, depth, (xmin, ymin, xmax, ymax))