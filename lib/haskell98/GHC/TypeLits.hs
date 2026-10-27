-- GHC.TypeLits (base): Yale Haskell does not check kinds, so Symbol and
-- Nat are usable as kinds.  Type-level literals ("foo", 3, 'c') are
-- PreludeCore's TypeSymbol, TypeNat and TypeChar over binary digits
-- (parser/type-parser.mumble), with KnownSymbol, KnownNat and KnownChar
-- instances.
{-# LANGUAGE FlexibleInstances, ExistentialQuantification, TypeFamilies, TypeOperators, DataKinds, PolyKinds, RankNTypes, ScopedTypeVariables #-}
module GHC.TypeLits (
    Symbol, Nat, Natural, KnownNat(natSing), natVal, SNat, fromSNat,
    KnownSymbol(symbolSing), symbolVal, SSymbol, fromSSymbol,
    withKnownNat, withSomeSNat, withKnownSymbol, withSomeSSymbol,
    KnownChar(charSing), charVal, SChar, fromSChar,
    ErrorMessage(..), TypeError, type (+), Div, Mod, CmpNat
  ) where

import Numeric.Natural (Natural)
import Unsafe.Coerce (unsafeCoerce)
import GHC.TypeNats (Nat, KnownNat(natSing), SNat, fromSNat, withKnownNat, withSomeSNat, KnownBits(bitsValue), BitsValue(..), type (+), Div, Mod, CmpNat)
import PreludeCore (TypeSymbol, TypeChar, PromotedNil, PromotedCons)

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

-- (as withKnownNat: KnownSymbol n's dictionary is an SSymbol n)
newtype WithKnownSymbol n r = WithKnownSymbol (KnownSymbol n => r)

withKnownSymbol :: forall n r. SSymbol n -> (KnownSymbol n => r) -> r
withKnownSymbol ss k = unsafeCoerce (WithKnownSymbol k :: WithKnownSymbol n r) ss

withSomeSSymbol :: forall r. String -> (forall s. SSymbol s -> r) -> r
withSomeSSymbol s k = k (UnsafeSSymbol s)

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

-- the characters of a TypeSymbol, each TypeChar of its code's digits
newtype CharsValue cs = CharsValue String

class KnownChars cs where
  charsValue :: CharsValue cs

instance KnownChars PromotedNil where
  charsValue = CharsValue ""
instance (KnownChar c, KnownChars cs) => KnownChars (PromotedCons c cs) where
  charsValue = consChar charSing charsValue

consChar :: SChar c -> CharsValue cs -> CharsValue (PromotedCons c cs)
consChar (UnsafeSChar c) (CharsValue s) = CharsValue (c : s)

instance KnownChars cs => KnownSymbol (TypeSymbol cs) where
  symbolSing = symbolOf charsValue

symbolOf :: CharsValue cs -> SSymbol (TypeSymbol cs)
symbolOf (CharsValue s) = UnsafeSSymbol s

instance KnownBits bs => KnownChar (TypeChar bs) where
  charSing = charOf bitsValue

charOf :: BitsValue bs -> SChar (TypeChar bs)
charOf (BitsValue n) = UnsafeSChar (toEnum (fromInteger n))

-- Custom type errors: the messages, used promoted ('Text "..."); a
-- TypeError has no equations, so the type stays as it is (the program is
-- rejected for it only when it does not type check otherwise).
infixl 6 :<>:
infixl 5 :$$:

data ErrorMessage
  = Text Symbol
  | forall t. ShowType t
  | ErrorMessage :<>: ErrorMessage
  | ErrorMessage :$$: ErrorMessage

type family TypeError (msg :: ErrorMessage) :: k
