{-# LANGUAGE ScopedTypeVariables #-}
data NE a = NE a [a] deriving Show

withNE :: r -> (NE a -> r) -> [a] -> r
withNE z _ [] = z
withNE _ k (x : xs) = k (NE x xs)

f :: forall a. () => NE a -> (NE [a], [NE a])
f (NE x s0) = (p0, p1)
  where
    p0 :: NE [a]
    p0@(NE _ p0s) = forSure [s0, x : s0]
    p1 :: [NE a]
    p1 = map forSure p0s
    forSure = withNE (error "empty") id

main :: IO ()
main = print (f (NE 'a' "b"))
