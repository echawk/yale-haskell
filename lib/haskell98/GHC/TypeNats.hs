-- GHC.TypeNats (base): type-level naturals, the names and classes only.
-- Yale Haskell has no type-level literals, so KnownNat has no instances
-- for them; programs can define instances for their own types.
{-# LANGUAGE FlexibleInstances, TypeFamilies, TypeOperators, DataKinds, UndecidableInstances, PolyKinds #-}
module GHC.TypeNats (
    Nat, Natural, KnownNat(natSing), SNat, natVal, fromSNat,
    KnownBits(bitsValue), BitsValue(..), type (+), Div, Mod, CmpNat
  ) where

import Numeric.Natural (Natural)
import PreludeCore (TypeNat, TypeB0, TypeB1, PromotedNil, PromotedCons)

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

-- A type-level natural literal is TypeNat of its binary digits, least
-- significant first (parser/type-parser.mumble's type-literal-bits).
newtype BitsValue bs = BitsValue Integer

class KnownBits bs where
  bitsValue :: BitsValue bs

instance KnownBits PromotedNil where
  bitsValue = BitsValue 0
-- (one instance for PromotedCons: one-parameter instances are by type
-- constructor; the digit is KnownBit's)
instance (KnownBit b, KnownBits bs) => KnownBits (PromotedCons b bs) where
  bitsValue = twice bitValue bitsValue

newtype BitValue b = BitValue Integer

class KnownBit b where
  bitValue :: BitValue b
instance KnownBit TypeB0 where
  bitValue = BitValue 0
instance KnownBit TypeB1 where
  bitValue = BitValue 1

twice :: BitValue b -> BitsValue bs -> BitsValue (PromotedCons b bs)
twice (BitValue b) (BitsValue n) = BitsValue (2 * n + b)

instance KnownBits bs => KnownNat (TypeNat bs) where
  natSing = natOf bitsValue

natOf :: BitsValue bs -> SNat (TypeNat bs)
natOf (BitsValue n) = UnsafeSNat (fromInteger n)

-- Type-level addition, on the binary digits: ripple carry.
infixl 6 +
type family (a :: Nat) + (b :: Nat) :: Nat where
  TypeNat a + TypeNat b = TypeNat (AddBits a b TypeB0)

type family AddBits as bs c where
  AddBits PromotedNil PromotedNil TypeB0 = PromotedNil
  AddBits PromotedNil PromotedNil TypeB1 = PromotedCons TypeB1 PromotedNil
  AddBits PromotedNil (PromotedCons b bs) c =
    AddBits (PromotedCons TypeB0 PromotedNil) (PromotedCons b bs) c
  AddBits (PromotedCons a as) PromotedNil c =
    AddBits (PromotedCons a as) (PromotedCons TypeB0 PromotedNil) c
  AddBits (PromotedCons a as) (PromotedCons b bs) c =
    PromotedCons (SumBit a b c) (AddBits as bs (CarryBit a b c))

type family SumBit a b c where
  SumBit TypeB0 TypeB0 c = c
  SumBit TypeB1 TypeB1 c = c
  SumBit a b TypeB0 = TypeB1
  SumBit a b TypeB1 = TypeB0

type family CarryBit a b c where
  CarryBit TypeB0 TypeB0 c = TypeB0
  CarryBit TypeB1 TypeB1 c = TypeB1
  CarryBit a b c = c

-- Not computed here: declared, so that they can be named (generic-data's
-- Compat re-exports Div); an application of one is a type of its own.
type family Div (a :: Nat) (b :: Nat) :: Nat
type family Mod (a :: Nat) (b :: Nat) :: Nat
type family CmpNat (a :: Nat) (b :: Nat) :: Ordering
