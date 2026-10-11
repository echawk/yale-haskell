-- Data.Void (base)
module Data.Void (Void, absurd, vacuous) where

data Void

instance Eq Void where _ == _ = True
instance Ord Void where compare _ _ = EQ
instance Show Void where show = absurd

absurd :: Void -> a
absurd v = v `seq` error "Data.Void.absurd"

vacuous :: Functor f => f Void -> f a
vacuous = fmap absurd
