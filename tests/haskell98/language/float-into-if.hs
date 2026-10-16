-- optimize.mumble's let-float-into-if: a binding used in the branches of
-- an if moves into them.  Laziness is kept: a binding that would fail is
-- not evaluated in a branch that does not use it, and one used in both
-- branches is computed only in the branch taken.
f :: Int -> [Int] -> [Int]
f x ys = let r = map (* 2) ys
         in if x > 0 then x : r else r

g :: Int -> Int
g x = let bad = error "evaluated" :: Int
      in if x > 0 then x else bad + 1

queens :: Int -> [[Int]]
queens n = go n
  where
    go 0 = [[]]
    go k = [q : qs | qs <- go (k - 1), q <- [1 .. n], safe q qs]
    safe q qs = and [q /= c && abs (q - c) /= d | (d, c) <- zip [1 ..] qs]

main :: IO ()
main = do
  print (f 1 [1, 2, 3], f 0 [4, 5])
  print (g 5)
  print (length (queens 8), head (queens 8))
