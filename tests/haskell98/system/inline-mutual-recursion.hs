-- Two functions marked INLINE that call each other (free's hoistAlt and
-- hoistAltF): one is a loop breaker, not inlined into the other pass
-- after pass.
{-# LANGUAGE GADTs, RankNTypes #-}
module Main where

data AltF f a where
  Ap     :: f a -> Alt f (a -> b) -> AltF f b
  Pure   :: a                     -> AltF f a

newtype Alt f a = Alt { alternatives :: [AltF f a] }

hoistAltF :: (forall a. f a -> g a) -> AltF f b -> AltF g b
hoistAltF _ (Pure a) = Pure a
hoistAltF f (Ap x y) = Ap (f x) (hoistAlt f y)
{-# INLINE hoistAltF #-}

hoistAlt :: (forall a. f a -> g a) -> Alt f b -> Alt g b
hoistAlt f (Alt as) = Alt (map (hoistAltF f) as)
{-# INLINE hoistAlt #-}

count :: Alt f b -> Int
count (Alt as) = sum (map c as)
  where c :: AltF f x -> Int
        c (Pure _) = 1
        c (Ap _ y) = 1 + count y

main = print (count (hoistAlt (\ (Just x) -> [x]) (Alt [Ap (Just 'c') (Alt [Pure id, Pure id]), Pure 'd'])))
