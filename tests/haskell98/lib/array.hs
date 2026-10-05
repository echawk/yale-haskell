-- The Array library, with H98 (index, value) pair associations.
module Main where

import Array

squares :: Array Int Int
squares = array (1, 5) [(i, i * i) | i <- [1 .. 5]]

grid :: Array (Int, Int) Char
grid = listArray ((0, 0), (1, 2)) "abcdef"

fibs :: Array Int Integer
fibs = a where a = listArray (0, 30) (0 : 1 : [a ! (i - 1) + a ! (i - 2) | i <- [2 .. 30]])

main = appendChan stdout (unlines [
  show squares,
  show (squares ! 3, bounds squares, indices squares, elems squares),
  show (assocs grid, grid ! (1, 0), rangeSize (bounds grid)),
  show (squares // [(2, 0), (5, -1)]),
  show (accumArray (+) 0 (0, 3) [(0, 1), (3, 2), (0, 10)] :: Array Int Int),
  show (accum (flip (:)) (listArray (1, 2) ["", "z"]) [(1, 'a'), (2, 'b'), (1, 'c')] :: Array Int String),
  show (ixmap (1, 3) (\i -> 4 - i) (listArray (1, 3) "xyz") :: Array Int Char),
  show (fibs ! 30, squares == squares, squares < (squares // [(1, 2)])),
  show (Just (listArray (0, 1) [True, False] :: Array Int Bool)),
  show (read "array (0,1) [(0,'p'),(1,'q')]" :: Array Int Char)
  ]) abort done
