-- GHC.TypeNats (base): type-level naturals, the names and classes only.
-- Yale Haskell has no type-level literals, so KnownNat has no instances
-- for them; programs can define instances for their own types.
module GHC.TypeNats (
    Nat, Natural, KnownNat(natSing), SNat, natVal, fromSNat
  ) where

import Numeric.Natural (Natural)

type Nat = Natural

newtype SNat n = UnsafeSNat Natural

instance Show (SNat n) where
  showsPrec p (UnsafeSNat n) = showParen (p > 10) (showString "SNat @" . showsPrec 11 n)

class KnownNat n where
  natSing :: SNat n

fromSNat :: SNat n -> Natural
fromSNat (UnsafeSNat n) = n

natVal :: KnownNat n => proxy n -> Natural
natVal p = fromSNat (sing p)
  where sing :: KnownNat n => proxy n -> SNat n
        sing _ = natSing
