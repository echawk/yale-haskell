-- ScopedTypeVariables: the signature's forall scopes over where bindings
-- without signatures (minBound :: i), which are not generalized over i.
{-# LANGUAGE ScopedTypeVariables #-}
bounded :: forall i. (Integral i, Bounded i) => Integer -> Maybe i
bounded n
  | n < lo || n > hi = Nothing
  | otherwise = Just (fromInteger n)
  where
    lo = toInteger (minBound :: i)
    hi = toInteger (maxBound :: i)

radix :: forall a. RealFloat a => a -> Integer
radix _ = r
  where r = floatRadix (undefined :: a)

main = print (bounded 300 :: Maybe Int, radix (1 :: Double))
