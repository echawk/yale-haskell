{-# LANGUAGE StandaloneDeriving, DeriveGeneric #-}
-- Data.Void (base)
module Data.Void (Void, absurd, vacuous) where

import GHC.Generics (Generic)

data Void

-- (random's instance Finite Void, by its generic default)
deriving instance Generic Void

instance Eq Void where _ == _ = True
instance Ord Void where compare _ _ = EQ
instance Show Void where show = absurd

absurd :: Void -> a
absurd v = v `seq` error "Data.Void.absurd"

vacuous :: Functor f => f Void -> f a
vacuous = fmap absurd
