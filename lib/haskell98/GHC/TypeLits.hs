-- GHC.TypeLits (base), the names and classes only: Yale Haskell does
-- not check kinds, so Symbol and Nat are usable as kinds, and it has no
-- type-level literals ("foo", 3 in types), so KnownSymbol, KnownNat and
-- KnownChar have no instances for them; programs can define instances
-- for their own types.
module GHC.TypeLits (
    Symbol, Nat, Natural, KnownNat(natSing), natVal, SNat, fromSNat,
    KnownSymbol(symbolSing), symbolVal, SSymbol, fromSSymbol,
    KnownChar(charSing), charVal, SChar, fromSChar
  ) where

import Numeric.Natural (Natural)
import GHC.TypeNats (Nat, KnownNat(natSing), SNat, fromSNat)

data Symbol

natVal :: KnownNat n => proxy n -> Integer
natVal p = toInteger (fromSNat (sing p))
  where sing :: KnownNat n => proxy n -> SNat n
        sing _ = natSing

newtype SSymbol s = UnsafeSSymbol String

class KnownSymbol n where
  symbolSing :: SSymbol n

fromSSymbol :: SSymbol s -> String
fromSSymbol (UnsafeSSymbol s) = s

symbolVal :: KnownSymbol n => proxy n -> String
symbolVal p = fromSSymbol (sing p)
  where sing :: KnownSymbol n => proxy n -> SSymbol n
        sing _ = symbolSing

newtype SChar c = UnsafeSChar Char

class KnownChar n where
  charSing :: SChar n

fromSChar :: SChar c -> Char
fromSChar (UnsafeSChar c) = c

charVal :: KnownChar n => proxy n -> Char
charVal p = fromSChar (sing p)
  where sing :: KnownChar n => proxy n -> SChar n
        sing _ = charSing
