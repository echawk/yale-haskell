-- Instances giving only the Haskell 98 Report's minimal complete definitions:
-- the classes' defaults do the rest (Fractional's x / y = x * recip y).
import Data.Ix
newtype T = T Double deriving (Eq, Ord, Show)
instance Num T where
  T a + T b = T (a + b); T a * T b = T (a * b); T a - T b = T (a - b)
  abs (T a) = T (abs a); signum (T a) = T (signum a); fromInteger = T . fromInteger
instance Fractional T where
  fromRational = T . fromRational; recip (T a) = T (recip a)
instance Floating T where
  pi = T pi; exp (T a) = T (exp a); log (T a) = T (log a); sin (T a) = T (sin a)
  cos (T a) = T (cos a); asin (T a) = T (asin a); acos (T a) = T (acos a)
  atan (T a) = T (atan a); sinh (T a) = T (sinh a); cosh (T a) = T (cosh a)
  asinh (T a) = T (asinh a); acosh (T a) = T (acosh a); atanh (T a) = T (atanh a)
instance Real T where toRational (T a) = toRational a
instance RealFrac T where properFraction (T a) = let (n, f) = properFraction a in (n, T f)
instance RealFloat T where
  floatRadix (T a) = floatRadix a; floatDigits (T a) = floatDigits a
  floatRange (T a) = floatRange a; decodeFloat (T a) = decodeFloat a
  encodeFloat m e = T (encodeFloat m e); isNaN (T a) = isNaN a
  isInfinite (T a) = isInfinite a; isDenormalized (T a) = isDenormalized a
  isNegativeZero (T a) = isNegativeZero a; isIEEE (T a) = isIEEE a
data E = E0 | E1 | E2 deriving (Eq, Ord, Show)
instance Enum E where
  toEnum 0 = E0; toEnum 1 = E1; toEnum _ = E2
  fromEnum E0 = 0; fromEnum E1 = 1; fromEnum E2 = 2
instance Bounded E where minBound = E0; maxBound = E2
instance Ix E where
  range (a, b) = [a .. b]; index (a, _) x = fromEnum x - fromEnum a
  inRange (a, b) x = a <= x && x <= b
newtype I = I Int deriving (Eq, Ord, Show)
instance Num I where
  I a + I b = I (a + b); I a * I b = I (a * b); negate (I a) = I (negate a)
  abs (I a) = I (abs a); signum (I a) = I (signum a); fromInteger = I . fromInteger
instance Real I where toRational (I a) = toRational a
instance Enum I where toEnum = I; fromEnum (I a) = a
instance Integral I where
  quotRem (I a) (I b) = let (q, r) = quotRem a b in (I q, I r); toInteger (I a) = toInteger a
data Q = Q Int
instance Show Q where show (Q n) = "Q" ++ show n
instance Read Q where readsPrec _ s = [(Q n, r) | ("Q", t) <- lex s, (n, r) <- reads t]
newtype Box a = Box a
instance Functor Box where fmap f (Box a) = Box (f a)
instance Applicative Box where pure = Box; Box f <*> Box a = Box (f a)
instance Monad Box where Box a >>= f = f a
main = do
  print (T 1 / T 2, T 2 ** T 3, logBase (T 2) (T 8), tan (T 0), tanh (T 0), sqrt (T 4))
  print (truncate (T 2.5) :: Int, round (T 2.5) :: Int, ceiling (T 2.1) :: Int, floor (T 2.9) :: Int)
  print (exponent (T 8), significand (T 8), scaleFloat 2 (T 1), atan2 (T 1) (T 1))
  print (succ E0, pred E2, [E1 .. E2], [E2, E1 .. E0], rangeSize (E0, E2))
  print (div (I 7) (I 2), mod (I (-7)) (I 2), quot (I 7) (I 2), rem (I 7) (I 2), divMod (I (-7)) (I 2), even (I 2), odd (I 3), I 5 - I 2)
  print (Q 3, showsPrec 11 (Q 4) "", [Q 1, Q 2], (read "Q 5" :: Q) `seq` (), (read "[Q 1,Q 2]" :: [Q]) `seq` ())
  print (max (T 1) (T 2), min E0 E1, compare E1 E0, E0 < E1, E0 /= E1)
  case (Box 1 >> Box 2) of Box n -> print (n, case 3 <$ Box 'x' of Box m -> m)
