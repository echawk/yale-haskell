{-# LANGUAGE GADTs, RankNTypes, ScopedTypeVariables #-}
data Mag a b t where
  Pure :: t -> Mag a b t
  Map :: (x -> t) -> Mag a b x -> Mag a b t
  Ap :: Mag a b (t -> u) -> Mag a b t -> Mag a b u
  One :: a -> Mag a b b

smash :: forall p t a b c. (a -> (b, c))
      -> (forall x. Mag a x (t x))
      -> (t b, t c)
smash p m = go m m
  where
    go :: forall x y. Mag a b x -> Mag a c y -> (x, y)
    go (Pure t) (Pure u) = (t, u)
    go (Map f x) (Map g y) = let (a, b) = go x y in (f a, g b)
    go (Ap fs xs) (Ap gs ys) = let { (f, g) = go fs gs; (x, y) = go xs ys } in (f x, g y)
    go (One x) (One _) = p x
    go _ _ = error "impossible"

main :: IO ()
main = print (smash (\n -> (n + 1, show n)) (Map (\v -> [v]) (One (3 :: Int))))
