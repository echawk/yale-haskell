-- GHC's Num has no Eq or Show superclass: under --modern-prelude an
-- instance Num F without Eq F or Show F compiles (their methods are
-- errors here, where GHC rejects their use at compile time).

newtype F = F (Int -> Int)
instance Num F where
  F f + F g = F (\x -> f x + g x)
  F f * F g = F (\x -> f x * g x)
  abs (F f) = F (abs . f)
  signum (F f) = F (signum . f)
  fromInteger n = F (const (fromInteger n))
  negate (F f) = F (negate . f)

apply :: F -> Int -> Int
apply (F f) = f

main :: IO ()
main = do
  print (apply (F (* 2) + 3) 10)
  print (apply (sum [F (+ 1), 2, F negate]) 5)
