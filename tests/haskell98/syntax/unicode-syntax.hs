{-# LANGUAGE UnicodeSyntax, RankNTypes #-}
idf ∷ ∀ a. a → a
idf x = x
class C a where c ∷ a → String
instance (Show a) ⇒ C [a] where c = show
main ∷ IO ()
main = do
  x ← return (idf 3 :: Int)
  putStrLn (c [x])
