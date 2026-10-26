{-# LANGUAGE RankNTypes #-}
-- Data.Data (base): "Scrap your boilerplate" generic programming.  The
-- class Data, its folds and maps over a value's immediate subterms, and
-- the representations of constructors (Constr) and types (DataType).
-- deriving Data writes gfoldl, gunfold, toConstr and dataTypeOf
-- (derived/derived-instances.mumble).  Every type is Typeable already.
module Data.Data (
    module Data.Typeable,
    Data(gfoldl, gunfold, toConstr, dataTypeOf, dataCast1, dataCast2,
         gmapT, gmapQl, gmapQr, gmapQ, gmapQi, gmapM, gmapMp, gmapMo),
    DataType, mkDataType, mkIntType, mkFloatType, mkCharType, mkNoRepType,
    dataTypeName, DataRep(AlgRep, IntRep, FloatRep, CharRep, NoRep),
    dataTypeRep, repConstr, isAlgType, dataTypeConstrs, indexConstr,
    maxConstrIndex, isNorepType,
    Constr, ConIndex, Fixity(Prefix, Infix), mkConstr, mkConstrTag,
    mkIntegralConstr, mkRealConstr, mkCharConstr, constrType,
    ConstrRep(AlgConstr, IntConstr, FloatConstr, CharConstr), constrRep,
    constrFields, constrFixity, constrIndex, showConstr, readConstr,
    tyconUQname, tyconModule, fromConstr, fromConstrB, fromConstrM
  ) where

import Data.Typeable
import Data.Functor.Identity (Identity(Identity, runIdentity))
import Data.Functor.Const (Const(Const))
import Data.List.NonEmpty (NonEmpty((:|)))
import Data.Int (Int8, Int16, Int32, Int64)
import Data.Word (Word8, Word16, Word32, Word64)
import Data.Ratio (Ratio, (%), numerator, denominator)
import Control.Monad (MonadPlus(mzero, mplus))

class Typeable a => Data a where
  gfoldl :: (forall d b. Data d => c (d -> b) -> d -> c b)
         -> (forall g. g -> c g) -> a -> c a
  gfoldl _ z = z

  gunfold :: (forall b r. Data b => c (b -> r) -> c r)
          -> (forall r. r -> c r) -> Constr -> c a

  toConstr :: a -> Constr

  dataTypeOf :: a -> DataType

  dataCast1 :: Typeable t => (forall d. Data d => c (t d)) -> Maybe (c a)
  dataCast1 _ = Nothing

  dataCast2 :: Typeable t => (forall d e. (Data d, Data e) => c (t d e))
            -> Maybe (c a)
  dataCast2 _ = Nothing

  gmapT :: (forall b. Data b => b -> b) -> a -> a
  gmapT f x0 = runIdentity (gfoldl (\(Identity c) x -> Identity (c (f x))) Identity x0)

  gmapQl :: (r -> r' -> r) -> r -> (forall d. Data d => d -> r') -> a -> r
  gmapQl o r f x0 = getConstQ (gfoldl (\c x -> ConstQ (getConstQ c `o` f x)) (\_ -> ConstQ r) x0)

  gmapQr :: (r' -> r -> r) -> r -> (forall d. Data d => d -> r') -> a -> r
  gmapQr o r0 f x0 = unQr (gfoldl (\(Qr c) x -> Qr (\r -> c (f x `o` r))) (\_ -> Qr id) x0) r0

  gmapQ :: (forall d. Data d => d -> u) -> a -> [u]
  gmapQ f = gmapQr (:) [] f

  gmapQi :: Int -> (forall d. Data d => d -> u) -> a -> u
  gmapQi i f x = case gfoldl (\(Qi n q) a -> Qi (n + 1) (if i == n then Just (f a) else q))
                             (\_ -> Qi 0 Nothing) x of
                   Qi _ q -> maybe (error "Data.Data.gmapQi: index out of range") id q

  gmapM :: Monad m => (forall d. Data d => d -> m d) -> a -> m a
  gmapM f = gfoldl (\c x -> do { c' <- c; x' <- f x; return (c' x') }) return

  gmapMp :: MonadPlus m => (forall d. Data d => d -> m d) -> a -> m a
  gmapMp f x = unMp (gfoldl k z x) >>= \(x', b) -> if b then return x' else mzero
    where z g = Mp (return (g, False))
          k (Mp c) y = Mp (c >>= \(h, b) ->
                             (f y >>= \y' -> return (h y', True))
                             `mplus` return (h y, b))

  gmapMo :: MonadPlus m => (forall d. Data d => d -> m d) -> a -> m a
  gmapMo f x = unMp (gfoldl k z x) >>= \(x', b) -> if b then return x' else mzero
    where z g = Mp (return (g, False))
          k (Mp c) y = Mp (c >>= \(h, b) ->
                             if b then return (h y, b)
                                  else (f y >>= \y' -> return (h y', True))
                                       `mplus` return (h y, b))

-- the functors the folds above run in
newtype ConstQ r a = ConstQ { getConstQ :: r }
newtype Qr r a = Qr { unQr :: r -> r }
data Qi q a = Qi Int (Maybe q)
newtype Mp m x = Mp { unMp :: m (x, Bool) }

-- Constructors and data types

data DataType = DataType { tycon :: String, datarep :: DataRep }
  deriving Show

data Constr = Constr { conrep :: ConstrRep, constring :: String,
                       confields :: [String], confixity :: Fixity,
                       datatype :: DataType }

instance Show Constr where
  showsPrec _ c = showString (constring c)

-- equal if their representations are
instance Eq Constr where
  c == c' = constrRep c == constrRep c'

data DataRep = AlgRep [Constr] | IntRep | FloatRep | CharRep | NoRep
  deriving (Eq, Show)

data ConstrRep = AlgConstr ConIndex | IntConstr Integer
               | FloatConstr Rational | CharConstr Char
  deriving (Eq, Show)

type ConIndex = Int

data Fixity = Prefix | Infix deriving (Eq, Show)

dataTypeName :: DataType -> String
dataTypeName = tycon

dataTypeRep :: DataType -> DataRep
dataTypeRep = datarep

constrType :: Constr -> DataType
constrType = datatype

constrRep :: Constr -> ConstrRep
constrRep = conrep

repConstr :: DataType -> ConstrRep -> Constr
repConstr dt cr = case (dataTypeRep dt, cr) of
  (AlgRep cs, AlgConstr i) -> cs !! (i - 1)
  (IntRep, IntConstr i) -> mkIntegralConstr dt i
  (FloatRep, FloatConstr f) -> mkRealConstr dt f
  (CharRep, CharConstr c) -> mkCharConstr dt c
  _ -> error "Data.Data.repConstr: The given ConstrRep does not fit to the given DataType."

mkDataType :: String -> [Constr] -> DataType
mkDataType str cs = DataType { tycon = str, datarep = AlgRep cs }

mkConstrTag :: DataType -> String -> Int -> [String] -> Fixity -> Constr
mkConstrTag dt str idx fields fix =
  Constr { conrep = AlgConstr idx, constring = str, confields = fields,
           confixity = fix, datatype = dt }

mkConstr :: DataType -> String -> [String] -> Fixity -> Constr
mkConstr dt str fields fix = mkConstrTag dt str idx fields fix
  where idx = case [i | (c, i) <- zip (dataTypeConstrs dt) [1 ..], showConstr c == str] of
                (i : _) -> i
                [] -> error ("Data.Data.mkConstr: couldn't find constructor " ++ str)

dataTypeConstrs :: DataType -> [Constr]
dataTypeConstrs dt = case datarep dt of
  AlgRep cons -> cons
  _ -> error ("Data.Data.dataTypeConstrs is not supported for "
              ++ dataTypeName dt ++ ", as it is not an algebraic data type.")

constrFields :: Constr -> [String]
constrFields = confields

constrFixity :: Constr -> Fixity
constrFixity = confixity

showConstr :: Constr -> String
showConstr = constring

readConstr :: DataType -> String -> Maybe Constr
readConstr dt str = case dataTypeRep dt of
  AlgRep cons -> case filter ((== str) . showConstr) cons of
                   (c : _) -> Just c
                   [] -> Nothing
  IntRep -> case reads str of
              [(i, "")] -> Just (mkPrimCon dt str (IntConstr i))
              _ -> Nothing
  FloatRep -> case reads str :: [(Double, String)] of
                [(f, "")] -> Just (mkPrimCon dt str (FloatConstr (toRational f)))
                _ -> Nothing
  CharRep -> case reads str of
               [(c, "")] -> Just (mkPrimCon dt str (CharConstr c))
               _ -> Nothing
  NoRep -> Nothing

isAlgType :: DataType -> Bool
isAlgType dt = case datarep dt of
  AlgRep _ -> True
  _ -> False

indexConstr :: DataType -> ConIndex -> Constr
indexConstr dt idx = case datarep dt of
  AlgRep cs -> cs !! (idx - 1)
  _ -> error ("Data.Data.indexConstr is not supported for "
              ++ dataTypeName dt ++ ", as it is not an algebraic data type.")

constrIndex :: Constr -> ConIndex
constrIndex con = case constrRep con of
  AlgConstr idx -> idx
  _ -> error ("Data.Data.constrIndex is not supported for "
              ++ dataTypeName (constrType con) ++ ", as it is not an algebraic data type.")

maxConstrIndex :: DataType -> ConIndex
maxConstrIndex dt = case dataTypeRep dt of
  AlgRep cs -> length cs
  _ -> error ("Data.Data.maxConstrIndex is not supported for "
              ++ dataTypeName dt ++ ", as it is not an algebraic data type.")

mkIntType, mkFloatType, mkCharType, mkNoRepType :: String -> DataType
mkIntType = mkPrimType IntRep
mkFloatType = mkPrimType FloatRep
mkCharType = mkPrimType CharRep
mkNoRepType str = DataType { tycon = str, datarep = NoRep }

mkPrimType :: DataRep -> String -> DataType
mkPrimType dr str = DataType { tycon = str, datarep = dr }

mkPrimCon :: DataType -> String -> ConstrRep -> Constr
mkPrimCon dt str cr = Constr { datatype = dt, conrep = cr, constring = str,
                               confields = error "Data.Data.confields",
                               confixity = error "Data.Data.confixity" }

mkIntegralConstr :: (Integral a, Show a) => DataType -> a -> Constr
mkIntegralConstr dt i = case datarep dt of
  IntRep -> mkPrimCon dt (show i) (IntConstr (toInteger i))
  _ -> error ("Data.Data.mkIntegralConstr is not supported for "
              ++ dataTypeName dt ++ ", as it is not an Integral data type.")

mkRealConstr :: (Real a, Show a) => DataType -> a -> Constr
mkRealConstr dt f = case datarep dt of
  FloatRep -> mkPrimCon dt (show f) (FloatConstr (toRational f))
  _ -> error ("Data.Data.mkRealConstr is not supported for "
              ++ dataTypeName dt ++ ", as it is not a Real data type.")

mkCharConstr :: DataType -> Char -> Constr
mkCharConstr dt c = case datarep dt of
  CharRep -> mkPrimCon dt (show c) (CharConstr c)
  _ -> error ("Data.Data.mkCharConstr is not supported for "
              ++ dataTypeName dt ++ ", as it is not an Char data type.")

isNorepType :: DataType -> Bool
isNorepType dt = case datarep dt of
  NoRep -> True
  _ -> False

-- the unqualified and module parts of a qualified type constructor name
tyconUQname :: String -> String
tyconUQname x = case break (== '.') x of
  (_, '.' : rest) -> tyconUQname rest
  _ -> x

tyconModule :: String -> String
tyconModule x = case break (== '.') x of
  (_, "") -> ""
  (a, '.' : rest) -> let m = tyconModule rest
                     in if m == "" then a else a ++ '.' : m

-- Building values from constructors

fromConstr :: Data a => Constr -> a
fromConstr = fromConstrB (error "Data.Data.fromConstr")

fromConstrB :: Data a => (forall d. Data d => d) -> Constr -> a
fromConstrB f = runIdentity . gunfold (\c -> Identity (runIdentity c f)) Identity

fromConstrM :: (Monad m, Data a) => (forall d. Data d => m d) -> Constr -> m a
fromConstrM f = gunfold (\c -> c >>= \g -> f >>= \x -> return (g x)) return

-- Instances for base's types

boolDataType :: DataType
boolDataType = mkDataType "Bool" [falseConstr, trueConstr]
falseConstr, trueConstr :: Constr
falseConstr = mkConstrTag boolDataType "False" 1 [] Prefix
trueConstr = mkConstrTag boolDataType "True" 2 [] Prefix

instance Data Bool where
  toConstr False = falseConstr
  toConstr True = trueConstr
  gunfold _ z c = case constrIndex c of
    1 -> z False
    2 -> z True
    _ -> error "Data.Data.gunfold: Bool"
  dataTypeOf _ = boolDataType

charType :: DataType
charType = mkCharType "Prelude.Char"

instance Data Char where
  toConstr x = mkCharConstr charType x
  gunfold _ z c = case constrRep c of
    CharConstr x -> z x
    _ -> error "Data.Data.gunfold: Char"
  dataTypeOf _ = charType

-- the primitive numeric types, by their integral or real representation
intUnfold :: Num a => (a -> c a) -> Constr -> c a
intUnfold z c = case constrRep c of
  IntConstr x -> z (fromIntegral x)
  _ -> error ("Data.Data.gunfold: Constructor " ++ show c ++ " is not of type "
              ++ dataTypeName (constrType c))

floatUnfold :: Fractional a => (a -> c a) -> Constr -> c a
floatUnfold z c = case constrRep c of
  FloatConstr x -> z (fromRational x)
  _ -> error ("Data.Data.gunfold: Constructor " ++ show c ++ " is not of type "
              ++ dataTypeName (constrType c))

intType, integerType, wordType, int8Type, int16Type, int32Type, int64Type,
  word8Type, word16Type, word32Type, word64Type, floatType, doubleType :: DataType
intType = mkIntType "Prelude.Int"
integerType = mkIntType "Prelude.Integer"
wordType = mkIntType "Prelude.Word"
int8Type = mkIntType "Data.Int.Int8"
int16Type = mkIntType "Data.Int.Int16"
int32Type = mkIntType "Data.Int.Int32"
int64Type = mkIntType "Data.Int.Int64"
word8Type = mkIntType "Data.Word.Word8"
word16Type = mkIntType "Data.Word.Word16"
word32Type = mkIntType "Data.Word.Word32"
word64Type = mkIntType "Data.Word.Word64"
floatType = mkFloatType "Prelude.Float"
doubleType = mkFloatType "Prelude.Double"

instance Data Int where
  toConstr = mkIntegralConstr intType
  gunfold _ z = intUnfold z
  dataTypeOf _ = intType
instance Data Integer where
  toConstr = mkIntegralConstr integerType
  gunfold _ z = intUnfold z
  dataTypeOf _ = integerType
instance Data Word where
  toConstr = mkIntegralConstr wordType
  gunfold _ z = intUnfold z
  dataTypeOf _ = wordType
instance Data Int8 where
  toConstr = mkIntegralConstr int8Type
  gunfold _ z = intUnfold z
  dataTypeOf _ = int8Type
instance Data Int16 where
  toConstr = mkIntegralConstr int16Type
  gunfold _ z = intUnfold z
  dataTypeOf _ = int16Type
instance Data Int32 where
  toConstr = mkIntegralConstr int32Type
  gunfold _ z = intUnfold z
  dataTypeOf _ = int32Type
instance Data Int64 where
  toConstr = mkIntegralConstr int64Type
  gunfold _ z = intUnfold z
  dataTypeOf _ = int64Type
instance Data Word8 where
  toConstr = mkIntegralConstr word8Type
  gunfold _ z = intUnfold z
  dataTypeOf _ = word8Type
instance Data Word16 where
  toConstr = mkIntegralConstr word16Type
  gunfold _ z = intUnfold z
  dataTypeOf _ = word16Type
instance Data Word32 where
  toConstr = mkIntegralConstr word32Type
  gunfold _ z = intUnfold z
  dataTypeOf _ = word32Type
instance Data Word64 where
  toConstr = mkIntegralConstr word64Type
  gunfold _ z = intUnfold z
  dataTypeOf _ = word64Type
instance Data Float where
  toConstr = mkRealConstr floatType
  gunfold _ z = floatUnfold z
  dataTypeOf _ = floatType
instance Data Double where
  toConstr = mkRealConstr doubleType
  gunfold _ z = floatUnfold z
  dataTypeOf _ = doubleType

ratioConstr :: Constr
ratioConstr = mkConstr ratioDataType ":%" [] Infix
ratioDataType :: DataType
ratioDataType = mkDataType "GHC.Real.Ratio" [ratioConstr]

instance (Data a, Integral a) => Data (Ratio a) where
  gfoldl k z r = z (%) `k` numerator r `k` denominator r
  toConstr _ = ratioConstr
  gunfold k z c | constrIndex c == 1 = k (k (z (%)))
  gunfold _ _ _ = error "Data.Data.gunfold(Ratio)"
  dataTypeOf _ = ratioDataType

nilConstr, consConstr :: Constr
nilConstr = mkConstr listDataType "[]" [] Prefix
consConstr = mkConstr listDataType "(:)" [] Infix
listDataType :: DataType
listDataType = mkDataType "Prelude.[]" [nilConstr, consConstr]

instance Data a => Data [a] where
  gfoldl _ z [] = z []
  gfoldl f z (x : xs) = z (:) `f` x `f` xs
  toConstr [] = nilConstr
  toConstr (_ : _) = consConstr
  gunfold k z c = case constrIndex c of
    1 -> z []
    2 -> k (k (z (:)))
    _ -> error "Data.Data.gunfold(List)"
  dataTypeOf _ = listDataType
  dataCast1 f = gcast1 f
  gmapT _ [] = []
  gmapT f (x : xs) = f x : f xs
  gmapQ _ [] = []
  gmapQ f (x : xs) = [f x, f xs]
  gmapM _ [] = return []
  gmapM f (x : xs) = f x >>= \x' -> f xs >>= \xs' -> return (x' : xs')

nothingConstr, justConstr :: Constr
nothingConstr = mkConstr maybeDataType "Nothing" [] Prefix
justConstr = mkConstr maybeDataType "Just" [] Prefix
maybeDataType :: DataType
maybeDataType = mkDataType "Prelude.Maybe" [nothingConstr, justConstr]

instance Data a => Data (Maybe a) where
  gfoldl _ z Nothing = z Nothing
  gfoldl f z (Just x) = z Just `f` x
  toConstr Nothing = nothingConstr
  toConstr (Just _) = justConstr
  gunfold k z c = case constrIndex c of
    1 -> z Nothing
    2 -> k (z Just)
    _ -> error "Data.Data.gunfold(Maybe)"
  dataTypeOf _ = maybeDataType
  dataCast1 f = gcast1 f

ltConstr, eqConstr, gtConstr :: Constr
ltConstr = mkConstr orderingDataType "LT" [] Prefix
eqConstr = mkConstr orderingDataType "EQ" [] Prefix
gtConstr = mkConstr orderingDataType "GT" [] Prefix
orderingDataType :: DataType
orderingDataType = mkDataType "Prelude.Ordering" [ltConstr, eqConstr, gtConstr]

instance Data Ordering where
  gfoldl _ z LT = z LT
  gfoldl _ z EQ = z EQ
  gfoldl _ z GT = z GT
  toConstr LT = ltConstr
  toConstr EQ = eqConstr
  toConstr GT = gtConstr
  gunfold _ z c = case constrIndex c of
    1 -> z LT
    2 -> z EQ
    3 -> z GT
    _ -> error "Data.Data.gunfold(Ordering)"
  dataTypeOf _ = orderingDataType

leftConstr, rightConstr :: Constr
leftConstr = mkConstr eitherDataType "Left" [] Prefix
rightConstr = mkConstr eitherDataType "Right" [] Prefix
eitherDataType :: DataType
eitherDataType = mkDataType "Prelude.Either" [leftConstr, rightConstr]

instance (Data a, Data b) => Data (Either a b) where
  gfoldl f z (Left a) = z Left `f` a
  gfoldl f z (Right a) = z Right `f` a
  toConstr (Left _) = leftConstr
  toConstr (Right _) = rightConstr
  gunfold k z c = case constrIndex c of
    1 -> k (z Left)
    2 -> k (z Right)
    _ -> error "Data.Data.gunfold(Either)"
  dataTypeOf _ = eitherDataType
  dataCast2 f = gcast2 f

tuple0Constr :: Constr
tuple0Constr = mkConstr tuple0DataType "()" [] Prefix
tuple0DataType :: DataType
tuple0DataType = mkDataType "Prelude.()" [tuple0Constr]

instance Data () where
  toConstr () = tuple0Constr
  gunfold _ z c | constrIndex c == 1 = z ()
  gunfold _ _ _ = error "Data.Data.gunfold(unit)"
  dataTypeOf _ = tuple0DataType

tuple2Constr :: Constr
tuple2Constr = mkConstr tuple2DataType "(,)" [] Infix
tuple2DataType :: DataType
tuple2DataType = mkDataType "Prelude.(,)" [tuple2Constr]

instance (Data a, Data b) => Data (a, b) where
  gfoldl f z (a, b) = z (,) `f` a `f` b
  toConstr (_, _) = tuple2Constr
  gunfold k z c | constrIndex c == 1 = k (k (z (,)))
  gunfold _ _ _ = error "Data.Data.gunfold(tup2)"
  dataTypeOf _ = tuple2DataType
  dataCast2 f = gcast2 f

tuple3Constr :: Constr
tuple3Constr = mkConstr tuple3DataType "(,,)" [] Infix
tuple3DataType :: DataType
tuple3DataType = mkDataType "Prelude.(,,)" [tuple3Constr]

instance (Data a, Data b, Data c) => Data (a, b, c) where
  gfoldl f z (a, b, c) = z (,,) `f` a `f` b `f` c
  toConstr (_, _, _) = tuple3Constr
  gunfold k z c | constrIndex c == 1 = k (k (k (z (,,))))
  gunfold _ _ _ = error "Data.Data.gunfold(tup3)"
  dataTypeOf _ = tuple3DataType

tuple4Constr :: Constr
tuple4Constr = mkConstr tuple4DataType "(,,,)" [] Infix
tuple4DataType :: DataType
tuple4DataType = mkDataType "Prelude.(,,,)" [tuple4Constr]

instance (Data a, Data b, Data c, Data d) => Data (a, b, c, d) where
  gfoldl f z (a, b, c, d) = z (,,,) `f` a `f` b `f` c `f` d
  toConstr (_, _, _, _) = tuple4Constr
  gunfold k z c = case constrIndex c of
    1 -> k (k (k (k (z (,,,)))))
    _ -> error "Data.Data.gunfold(tup4)"
  dataTypeOf _ = tuple4DataType

tuple5Constr :: Constr
tuple5Constr = mkConstr tuple5DataType "(,,,,)" [] Infix
tuple5DataType :: DataType
tuple5DataType = mkDataType "Prelude.(,,,,)" [tuple5Constr]

instance (Data a, Data b, Data c, Data d, Data e) => Data (a, b, c, d, e) where
  gfoldl f z (a, b, c, d, e) = z (,,,,) `f` a `f` b `f` c `f` d `f` e
  toConstr (_, _, _, _, _) = tuple5Constr
  gunfold k z c = case constrIndex c of
    1 -> k (k (k (k (k (z (,,,,))))))
    _ -> error "Data.Data.gunfold(tup5)"
  dataTypeOf _ = tuple5DataType

tuple6Constr :: Constr
tuple6Constr = mkConstr tuple6DataType "(,,,,,)" [] Infix
tuple6DataType :: DataType
tuple6DataType = mkDataType "Prelude.(,,,,,)" [tuple6Constr]

instance (Data a, Data b, Data c, Data d, Data e, Data f) => Data (a, b, c, d, e, f) where
  gfoldl f z (a, b, c, d, e, g) = z (,,,,,) `f` a `f` b `f` c `f` d `f` e `f` g
  toConstr (_, _, _, _, _, _) = tuple6Constr
  gunfold k z c = case constrIndex c of
    1 -> k (k (k (k (k (k (z (,,,,,)))))))
    _ -> error "Data.Data.gunfold(tup6)"
  dataTypeOf _ = tuple6DataType

tuple7Constr :: Constr
tuple7Constr = mkConstr tuple7DataType "(,,,,,,)" [] Infix
tuple7DataType :: DataType
tuple7DataType = mkDataType "Prelude.(,,,,,,)" [tuple7Constr]

instance (Data a, Data b, Data c, Data d, Data e, Data f, Data g) => Data (a, b, c, d, e, f, g) where
  gfoldl f z (a, b, c, d, e, g, h) = z (,,,,,,) `f` a `f` b `f` c `f` d `f` e `f` g `f` h
  toConstr (_, _, _, _, _, _, _) = tuple7Constr
  gunfold k z c = case constrIndex c of
    1 -> k (k (k (k (k (k (k (z (,,,,,,))))))))
    _ -> error "Data.Data.gunfold(tup7)"
  dataTypeOf _ = tuple7DataType

nonEmptyConstr :: Constr
nonEmptyConstr = mkConstr nonEmptyDataType ":|" [] Infix
nonEmptyDataType :: DataType
nonEmptyDataType = mkDataType "GHC.Base.NonEmpty" [nonEmptyConstr]

instance Data a => Data (NonEmpty a) where
  gfoldl f z (a :| as) = z (:|) `f` a `f` as
  toConstr _ = nonEmptyConstr
  gunfold k z c | constrIndex c == 1 = k (k (z (:|)))
  gunfold _ _ _ = error "Data.Data.gunfold(NonEmpty)"
  dataTypeOf _ = nonEmptyDataType
  dataCast1 f = gcast1 f

identityConstr :: Constr
identityConstr = mkConstr identityDataType "Identity" ["runIdentity"] Prefix
identityDataType :: DataType
identityDataType = mkDataType "Data.Functor.Identity.Identity" [identityConstr]

instance Data a => Data (Identity a) where
  gfoldl f z (Identity a) = z Identity `f` a
  toConstr _ = identityConstr
  gunfold k z c | constrIndex c == 1 = k (z Identity)
  gunfold _ _ _ = error "Data.Data.gunfold(Identity)"
  dataTypeOf _ = identityDataType
  dataCast1 f = gcast1 f

constConstr :: Constr
constConstr = mkConstr constDataType "Const" ["getConst"] Prefix
constDataType :: DataType
constDataType = mkDataType "Data.Functor.Const.Const" [constConstr]

instance (Data a, Typeable b) => Data (Const a b) where
  gfoldl f z (Const a) = z Const `f` a
  toConstr _ = constConstr
  gunfold k z c | constrIndex c == 1 = k (z Const)
  gunfold _ _ _ = error "Data.Data.gunfold(Const)"
  dataTypeOf _ = constDataType

proxyConstr :: Constr
proxyConstr = mkConstr proxyDataType "Proxy" [] Prefix
proxyDataType :: DataType
proxyDataType = mkDataType "Data.Proxy.Proxy" [proxyConstr]

instance Typeable t => Data (Proxy t) where
  gfoldl _ z Proxy = z Proxy
  toConstr Proxy = proxyConstr
  gunfold _ z c | constrIndex c == 1 = z Proxy
  gunfold _ _ _ = error "Data.Data.gunfold(Proxy)"
  dataTypeOf _ = proxyDataType
