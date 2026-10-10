-- A portable stand-in for nofib's spectral/hartel/Fast2haskell.hs (which
-- tools/conformance/nofib.py puts where the programs #include it): the
-- original does its bit operations with GHC's unboxed primitives
-- (GHC.Prim, I#, and#); here they are Data.Bits'.

import Data.Complex;
import Data.Array;
import Data.Bits;

type Complex_type = Complex Double;
type Array_type b = Array Int b;
type Assoc_type a = (Int,a);
type Descr_type = (Int,Int);

abortstr str = error ("abort:" ++ str);

delay x = abortstr "delay not implemented";

fix :: (x -> x) -> x;
fix f = fix_f where {fix_f = f fix_f};

force x = x; -- error "force not implemented"

iff :: Bool -> x -> x -> x;
iff b x y = if b then x else y;

iffrev :: x -> x -> Bool -> x;
iffrev y x b = if b then x else y;

miraseq :: x -> y -> y;
miraseq x y = seq_const y x;  -- x should be marked #STRICT
seq_const x y = x;

pair :: [x] -> Bool;
pair [] = False;
pair x = True;

entier :: Double -> Double;
entier x = fromIntegral (floor x);

land_i :: Int -> Int -> Int;
land_i x y = x .&. y;

lnot_i :: Int -> Int;
lnot_i x = complement x;

lor_i :: Int -> Int -> Int;
lor_i x y = x .|. y;

lshift_i :: Int -> Int -> Int;
lshift_i x y = shiftL x y;

-- a logical shift, as GHC's shiftRL# on the 64-bit word
rshift_i :: Int -> Int -> Int;
rshift_i x y = if x >= 0 then shiftR x y
               else fromInteger (shiftR (toInteger x + 2 ^ (64 :: Int)) y);

write x = abortstr "write not implemented";

descr :: Int -> Int -> Descr_type;
descr l u = (l,u);

destr_update :: Array_type x -> Int -> x -> Array_type x;
destr_update ar i x = ar // [(i,x)];

indassoc :: Assoc_type x -> Int;
indassoc (i,v) = i;

lowbound :: Descr_type -> Int;
lowbound (l,u) = l;

tabulate :: (Int -> x) -> Descr_type -> Array_type x;
tabulate f (l,u) = array (l,u) [(i, f i) | i <- [l..u]];

upbound :: Descr_type -> Int;
upbound (l,u) = u;

update :: Array_type x -> Int -> x -> Array_type x;
update ar i x = ar // [(i,x)];

valassoc :: Assoc_type x -> x;
valassoc (i,v) = v;
