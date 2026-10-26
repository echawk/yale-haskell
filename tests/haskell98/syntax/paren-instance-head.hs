-- Parenthesized instance heads (haskell-src-exts's Pretty instances).
class P a where
  p :: a -> String
data C l = C l
instance (P (C l)) where
  p _ = "C"
instance (Show a) => (P [a]) where
  p = show
main = putStrLn (p (C ())) >> putStrLn (p [1::Int])
