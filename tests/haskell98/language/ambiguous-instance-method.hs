{-# LANGUAGE AllowAmbiguousTypes, TypeApplications, ScopedTypeVariables, MultiParamTypeClasses, FlexibleInstances #-}
data Fin
newtype K c = K c

class Card opts f where
  card :: Int

instance (Bounded c, Enum c) => Card Fin (K c) where
  card = fromEnum (maxBound :: c) + 1

main :: IO ()
main = print (card @Fin @(K Bool), card @Fin @(K Char))
