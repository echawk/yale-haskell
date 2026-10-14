-- Data.Fixed (base): div', mod' and divMod' for any Real, and
-- fixed-precision numbers (Fixed E2 = Centi, ...).  Resolutions are the
-- types E0 .. E12; HasResolution's method takes a proxy of the type.
module Data.Fixed (
    div', mod', divMod',
    Fixed(MkFixed), HasResolution(resolution), showFixed,
    E0, Uni, E1, Deci, E2, Centi, E3, Milli, E6, Micro, E9, Nano, E12, Pico
  ) where

div' :: (Real a, Integral b) => a -> a -> b
div' n d = floor (toRational n / toRational d)

divMod' :: (Real a, Integral b) => a -> a -> (b, a)
divMod' n d = (f, n - fromIntegral f * d)
  where f = div' n d

mod' :: Real a => a -> a -> a
mod' n d = n - fromInteger f * d
  where f = div' n d

newtype Fixed a = MkFixed Integer deriving (Eq, Ord)

class HasResolution a where
  resolution :: p a -> Integer

data E0
data E1
data E2
data E3
data E6
data E9
data E12

instance HasResolution E0 where resolution _ = 1
instance HasResolution E1 where resolution _ = 10
instance HasResolution E2 where resolution _ = 100
instance HasResolution E3 where resolution _ = 1000
instance HasResolution E6 where resolution _ = 1000000
instance HasResolution E9 where resolution _ = 1000000000
instance HasResolution E12 where resolution _ = 1000000000000

type Uni = Fixed E0
type Deci = Fixed E1
type Centi = Fixed E2
type Milli = Fixed E3
type Micro = Fixed E6
type Nano = Fixed E9
type Pico = Fixed E12

res :: HasResolution a => Fixed a -> Integer
res = resolution

instance HasResolution a => Num (Fixed a) where
  MkFixed a + MkFixed b = MkFixed (a + b)
  MkFixed a - MkFixed b = MkFixed (a - b)
  fa@(MkFixed a) * MkFixed b = MkFixed (div (a * b) (res fa))
  negate (MkFixed a) = MkFixed (negate a)
  abs (MkFixed a) = MkFixed (abs a)
  signum fa@(MkFixed a) = MkFixed (signum a * res fa)
  fromInteger i = r
    where r = MkFixed (i * res r)

instance HasResolution a => Real (Fixed a) where
  toRational fa@(MkFixed a) = toRational a / toRational (res fa)

instance HasResolution a => Fractional (Fixed a) where
  fa@(MkFixed a) / MkFixed b = MkFixed (div (a * res fa) b)
  recip fa@(MkFixed a) = MkFixed (div (res fa * res fa) a)
  fromRational r = f
    where f = MkFixed (floor (r * toRational (res f)))

instance HasResolution a => RealFrac (Fixed a) where
  properFraction a = (i, a - fromIntegral i)
    where i = truncate (toRational a)
  truncate = truncate . toRational
  round = round . toRational
  ceiling = ceiling . toRational
  floor = floor . toRational

instance HasResolution a => Show (Fixed a) where
  showsPrec p n = showParen (p > 6 && n < 0) (showString (showFixed False n))

showFixed :: HasResolution a => Bool -> Fixed a -> String
showFixed chopZeros fa@(MkFixed a)
  | a < 0 = '-' : showFixed chopZeros (MkFixed (negate a) `asTypeOf` fa)
  | otherwise = show i ++ frac
  where r = res fa
        (i, d) = divMod a r
        digits = length (show r) - 1
        ds = let s = show d in replicate (digits - length s) '0' ++ s
        ds' = if chopZeros then reverse (dropWhile (== '0') (reverse ds)) else ds
        frac = if digits == 0 || null ds' then "" else '.' : ds'
