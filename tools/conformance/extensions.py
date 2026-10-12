#!/usr/bin/env python3
"""Probe GHC language extensions and modern-base idioms in Yale Haskell.

    tools/conformance/extensions.py [-v] [NAME ...]

Each probe is a small program (PROBES below) run with
`yale-haskell --haskell98 --modern-prelude` and compared with GHC's output
(runghc, cached in build/conformance/extensions/).  Prints pass / FAIL
per probe and a total; -v shows the first lines of a failure's output.
"""

import hashlib
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, 'build', 'conformance', 'extensions')
YALE = os.path.join(ROOT, 'bin', 'yale-haskell')

# name -> source.  The LANGUAGE pragma names what is probed.
PROBES = {
    # syntax
    'LambdaCase': '''{-# LANGUAGE LambdaCase #-}
f :: Int -> String
f = \\case { 0 -> "zero"; n | n < 0 -> "neg"; _ -> "other" }
main = mapM_ (putStrLn . f) [0, -1, 5]
''',
    'TupleSections': '''{-# LANGUAGE TupleSections #-}
main = print (map (,True) [1, 2 :: Int], map (1 :: Int,) "ab", map (,,'x') [()] <*> [5 :: Int])
''',
    'MultiWayIf': '''{-# LANGUAGE MultiWayIf #-}
f :: Int -> String
f x = if | x < 0 -> "neg" | x == 0 -> "zero" | otherwise -> "pos"
main = mapM_ (putStrLn . f) [-3, 0, 3]
''',
    'BangPatterns': '''{-# LANGUAGE BangPatterns #-}
go :: Int -> [Int] -> Int
go !acc [] = acc
go !acc (x:xs) = go (acc + x) xs
main = do
  let !y = go 0 [1 .. 100]
  print y
  print (let f !_ = "forced" in f (1 :: Int))
''',
    'BinaryLiterals': '''{-# LANGUAGE BinaryLiterals #-}
main = print (0b1011 :: Int, 0B11 :: Integer)
''',
    'NumericUnderscores': '''{-# LANGUAGE NumericUnderscores #-}
main = print (1_000_000 :: Int, 0xff_ff :: Int, 1_0.5e1 :: Double)
''',
    'InstanceSigs': '''{-# LANGUAGE InstanceSigs #-}
data T = T
instance Show T where
  show :: T -> String
  show T = "T!"
main = print T
''',
    'KindSignatures': '''{-# LANGUAGE KindSignatures #-}
data Box (f :: * -> *) a = Box (f a)
class Container (f :: * -> *) where empty :: f a
instance Container [] where empty = []
main = case Box (Just (1 :: Int)) of Box m -> print (m, length (empty :: [Int]))
''',
    'NamedFieldPuns': '''{-# LANGUAGE NamedFieldPuns #-}
data P = P { px :: Int, py :: Int } deriving Show
f :: P -> Int
f P{px, py} = px + py
mk :: Int -> Int -> P
mk px py = P{px, py}
main = print (f (P 1 2), mk 3 4)
''',
    'RecordWildCards': '''{-# LANGUAGE RecordWildCards #-}
data P = P { px :: Int, py :: Int } deriving Show
f :: P -> Int
f P{..} = px + py
g :: Int -> Int -> P
g px py = P{..}
main = print (f (g 1 2), g 5 6)
''',
    'GADTSyntax': '''{-# LANGUAGE GADTSyntax #-}
data M a where
  N :: M a
  J :: a -> M a
f :: M Int -> Int
f (J x) = x
f N = 0
main = print (f (J 5), f N)
''',
    'StandaloneDeriving': '''{-# LANGUAGE StandaloneDeriving #-}
data T = A | B
deriving instance Show T
deriving instance Eq T
main = print ([A, B], A == B)
''',
    'TypeApplications': '''{-# LANGUAGE TypeApplications #-}
main = print (read @Int "42", show @Double 1.5)
''',
    'EmptyCase': '''{-# LANGUAGE EmptyCase, EmptyDataDecls #-}
data Void
absurd :: Void -> a
absurd v = case v of {}
main = putStrLn "ok"
''',
    # types
    'ScopedTypeVariables': '''{-# LANGUAGE ScopedTypeVariables #-}
f :: forall a. Show a => [a] -> String
f xs = concatMap g xs where
  g :: a -> String
  g = show
main = putStrLn (f [1, 2 :: Int])
''',
    'RankNTypes': '''{-# LANGUAGE RankNTypes #-}
app :: (forall a. a -> a) -> (Int, Bool)
app f = (f 1, f True)
main = print (app id)
''',
    'RankNTypesContext': '''{-# LANGUAGE RankNTypes #-}
both :: (forall a. Show a => a -> String) -> (String, String)
both f = (f (1 :: Int), f True)
twice :: (forall a. Show a => a -> String) -> String
twice f = fst (both f) ++ snd (both f)
main = print (both show, twice (\\x -> show x ++ "."))
''',
    'ExistentialQuantification': '''{-# LANGUAGE ExistentialQuantification #-}
data S = forall a. Show a => S a
main = mapM_ (\\(S x) -> print x) [S (1 :: Int), S "two"]
''',
    'FlexibleInstances': '''{-# LANGUAGE FlexibleInstances #-}
class C a where c :: a -> String
instance C [Char] where c s = s
instance C (Maybe Int) where c m = show m
main = putStrLn (c "flex" ++ c (Just (1 :: Int)))
''',
    'FlexibleContexts': '''{-# LANGUAGE FlexibleContexts #-}
f :: Show [a] => [a] -> String
f = show
main = putStrLn (f [1, 2 :: Int])
''',
    'MultiParamSuperclass': '''{-# LANGUAGE MultiParamTypeClasses, FunctionalDependencies, FlexibleInstances #-}
class Monad m => MonadReader r m | m -> r where ask :: m r
newtype R r a = R (r -> a)
runR :: R r a -> r -> a
runR (R f) = f
instance Functor (R r) where fmap f (R g) = R (f . g)
instance Applicative (R r) where { pure x = R (const x); R f <*> R g = R (\\r -> f r (g r)) }
instance Monad (R r) where R g >>= k = R (\\r -> runR (k (g r)) r)
instance MonadReader r (R r) where ask = R id
twice :: MonadReader Int m => m Int
twice = do { x <- ask; return (2 * x) }
main = print (runR twice 21)
''',
    # deriving
    'DeriveFunctor': '''{-# LANGUAGE DeriveFunctor #-}
data T a = L | N (T a) a (T a) deriving (Show, Functor)
main = print (fmap (+ 1) (N L (1 :: Int) (N L 2 L)))
''',
    'DeriveFoldable': '''{-# LANGUAGE DeriveFoldable, DeriveTraversable, DeriveFunctor #-}
data T a = L | N (T a) a (T a) deriving (Show, Functor, Foldable, Traversable)
main = do
  print (sum (N L (3 :: Int) (N L 4 L)), length (N L 'a' L))
  print (traverse (\\x -> if x > 0 then Just x else Nothing) (N L (1 :: Int) L))
''',
    'DeriveNested': '''{-# LANGUAGE DeriveFunctor, DeriveFoldable, DeriveTraversable #-}
data W f a = W (f a) [a] (Maybe [a]) Int deriving (Functor, Foldable, Traversable)
showW :: Show a => W Maybe a -> String
showW (W m xs mm n) = show (m, xs, mm, n)
data P a = P a a | Q deriving (Show, Functor, Foldable, Traversable)
main = do
  let w = W (Just 1) [2, 3] (Just [4]) 9 :: W Maybe Int
  putStrLn (showW (fmap (* 10) w))
  print (sum w, length w, foldr (:) [] w)
  print (fmap showW (traverse (\\x -> if x > 0 then Right x else Left x) w))
  print (fmap show (P 1 (2 :: Int)), sum (P 3 (4 :: Int)), sequenceA (P [1, 2] [3 :: Int]))
''',
    'GeneralizedNewtypeDeriving': '''{-# LANGUAGE GeneralizedNewtypeDeriving #-}
newtype Age = Age Int deriving (Show, Eq, Ord, Num)
main = print (Age 3 + Age 4, Age 1 < Age 2)
''',
    # base: the Functor-Applicative-Monad hierarchy
    'MonadDefaultReturn': '''newtype I a = I a
instance Functor I where fmap f (I a) = I (f a)
instance Applicative I where { pure = I; I f <*> I a = I (f a) }
instance Monad I where I a >>= k = k a
run :: I a -> a
run (I a) = a
main = print (run (return 3 >>= \\x -> pure (x + 1)) :: Int)
''',
    'MonadImpliesFunctor': '''f :: Monad m => m Int -> m Int
f m = fmap (+ 1) m
main = f (return 1) >>= print
''',
    'MonadImpliesApplicative': '''f :: Monad m => Int -> m Int
f x = pure (x * 2) <* return ()
main = f 21 >>= print
''',

# --- GHC2021 members
'ImportQualifiedPost': '''{-# LANGUAGE ImportQualifiedPost #-}
import Data.Map qualified as M
import Data.List qualified
main = print (M.toList (M.fromList [(2, 'b'), (1, 'a')]), Data.List.sort [3, 1, 2 :: Int])
''',
'TypeOperators': '''{-# LANGUAGE TypeOperators #-}
data a :+: b = L a | R b deriving Show
type a + b = Either a b
f :: Int :+: Bool -> Int + Bool
f (L n) = Left n
f (R b) = Right b
main = print (f (L 3), f (R True), [L 1, R 'x' :: Int :+: Char])
''',
'ConstraintKinds': '''{-# LANGUAGE ConstraintKinds #-}
type ShowNum a = (Show a, Num a)
f :: ShowNum a => a -> String
f x = show (x + 1)
main = putStrLn (f (41 :: Int))
''',
'ConstrainedClassMethods': '''{-# LANGUAGE ConstrainedClassMethods #-}
class Container f where
  empty :: f a
  insert :: a -> f a -> f a
  member :: Eq a => a -> f a -> Bool
newtype Box a = Box [a]
instance Container Box where
  empty = Box []
  insert x (Box xs) = Box (x : xs)
  member x (Box xs) = x `elem` xs
main = print (member 2 (insert 2 (insert (1 :: Int) empty) :: Box Int))
''',
'EmptyDataDeriving': '''{-# LANGUAGE EmptyDataDeriving #-}
data Void deriving (Show, Eq, Ord)
main = print ([] :: [Void])
''',
'HexFloatLiterals': '''{-# LANGUAGE HexFloatLiterals #-}
main = print (0x1.8p1 :: Double, 0xFp-2 :: Double)
''',
'PostfixOperators': '''{-# LANGUAGE PostfixOperators #-}
(!) :: Integer -> Integer
(!) n = product [1 .. n]
main = print ((5 !), (20 !))
''',
'StandaloneKindSignatures': '''{-# LANGUAGE StandaloneKindSignatures #-}
import Data.Kind (Type)
type T :: Type -> Type
data T a = T a deriving Show
main = print (T 'x')
''',
'PolyKinds': '''{-# LANGUAGE PolyKinds #-}
data Proxy a = Proxy
f :: Proxy a -> String
f _ = "proxy"
main = putStrLn (f (Proxy :: Proxy Maybe) ++ f (Proxy :: Proxy Int))
''',
'DeriveGeneric': '''{-# LANGUAGE DeriveGeneric #-}
import GHC.Generics (Generic)
data P = P Int Bool deriving (Show, Generic)
main = print (P 1 True)
''',
'DeriveDataTypeable': '''{-# LANGUAGE DeriveDataTypeable #-}
import Data.Typeable
data P = P Int deriving (Show, Typeable)
main = print (typeOf (P 1), typeOf "s", typeOf (Just (1 :: Int)))
''',
'NamedWildCards': '''{-# LANGUAGE PartialTypeSignatures, NamedWildCards #-}
{-# OPTIONS_GHC -Wno-partial-type-signatures #-}
f :: _a -> _a
f x = x
g :: Int -> _
g n = show n
main = putStrLn (g (f 3))
''',
# --- outside GHC2021, common
'OverloadedStrings': '''{-# LANGUAGE OverloadedStrings #-}
import Data.String (IsString(..))
newtype Name = Name String deriving Show
instance IsString Name where fromString = Name
greet :: Name -> String
greet (Name n) = "hello " ++ n
main = do
  putStrLn (greet "world")
  print ("plain" :: String, length ("abc" :: String))
''',
'BlockArguments': '''{-# LANGUAGE BlockArguments #-}
import Control.Monad (forM_, when)
main = do
  forM_ [1, 2, 3 :: Int] \\i -> do
    when (i > 1) do
      print i
  print $ foldr (+) 0 do [1, 2, 3 :: Int]
''',
'ViewPatterns': '''{-# LANGUAGE ViewPatterns #-}
import Data.Char (toLower)
f :: String -> String
f (map toLower -> "yes") = "affirmative"
f (length -> n) = "length " ++ show n
main = mapM_ (putStrLn . f) ["YES", "nope"]
''',
'PatternSynonyms': '''{-# LANGUAGE PatternSynonyms #-}
pattern Zero :: Int
pattern Zero = 0
pattern Pair :: a -> b -> (a, b)
pattern Pair x y = (x, y)
f :: Int -> String
f Zero = "zero"
f _ = "other"
main = do
  putStrLn (f 0 ++ " " ++ f 5)
  let Pair a b = Pair 'x' True in print (a, b)
''',
'DerivingStrategies': '''{-# LANGUAGE DerivingStrategies, GeneralizedNewtypeDeriving #-}
newtype Age = Age Int
  deriving stock Show
  deriving newtype (Eq, Ord, Num)
main = print (Age 3 + Age 4, Age 1 < Age 2)
''',
'DeriveAnyClass': '''{-# LANGUAGE DeriveAnyClass, DefaultSignatures #-}
class Describe a where
  describe :: a -> String
  default describe :: Show a => a -> String
  describe x = "<" ++ show x ++ ">"
data Color = Red | Green deriving (Show, Describe)
main = mapM_ (putStrLn . describe) [Red, Green]
''',
'DerivingVia': '''{-# LANGUAGE DerivingVia #-}
import Data.Monoid (Sum(..))
newtype Score = Score Int
  deriving (Semigroup, Monoid) via (Sum Int)
  deriving Show via Int
main = print (mconcat [Score 1, Score 2, Score 3])
''',
'GADTs': '''{-# LANGUAGE GADTs #-}
data Expr a where
  IntE  :: Int -> Expr Int
  BoolE :: Bool -> Expr Bool
  Add   :: Expr Int -> Expr Int -> Expr Int
  If    :: Expr Bool -> Expr a -> Expr a -> Expr a
  Eq    :: Expr Int -> Expr Int -> Expr Bool
eval :: Expr a -> a
eval (IntE n) = n
eval (BoolE b) = b
eval (Add a b) = eval a + eval b
eval (If c t e) = if eval c then eval t else eval e
eval (Eq a b) = eval a == eval b
main = print (eval (If (Eq (IntE 2) (Add (IntE 1) (IntE 1))) (IntE 10) (IntE 20)))
''',
'TypeFamilies': '''{-# LANGUAGE TypeFamilies #-}
type family Elem c
type instance Elem [e] = e
class Collection c where
  cinsert :: Elem c -> c -> c
  ctoList :: c -> [Elem c]
instance Collection [a] where
  cinsert = (:)
  ctoList = id
main = print (ctoList (cinsert (1 :: Int) [2, 3]))
''',
'TypeFamiliesAssoc': '''{-# LANGUAGE TypeFamilies #-}
import qualified Data.Map as M
class Key k where
  data KMap k :: * -> *
  kempty :: KMap k v
  kinsert :: k -> v -> KMap k v -> KMap k v
  klookup :: k -> KMap k v -> Maybe v
instance Key Bool where
  data KMap Bool v = BM (Maybe v) (Maybe v)
  kempty = BM Nothing Nothing
  kinsert False v (BM _ t) = BM (Just v) t
  kinsert True v (BM f _) = BM f (Just v)
  klookup False (BM f _) = f
  klookup True (BM _ t) = t
main = print (klookup True (kinsert True "yes" kempty), klookup False (kinsert True "x" kempty))
''',
'DataKinds': '''{-# LANGUAGE DataKinds, KindSignatures, GADTs #-}
data Nat = Z | S Nat
data Vec (n :: Nat) a where
  VNil  :: Vec 'Z a
  VCons :: a -> Vec n a -> Vec ('S n) a
vhead :: Vec ('S n) a -> a
vhead (VCons x _) = x
vtoList :: Vec n a -> [a]
vtoList VNil = []
vtoList (VCons x xs) = x : vtoList xs
main = print (vhead (VCons 'a' VNil), vtoList (VCons 1 (VCons (2 :: Int) VNil)))
''',
'ParallelListComp': '''{-# LANGUAGE ParallelListComp #-}
main = print [(x, y) | x <- [1 :: Int ..] | y <- "abc"]
''',
'MonadComprehensions': '''{-# LANGUAGE MonadComprehensions #-}
f :: Maybe Int
f = [x + y | x <- Just 1, y <- Just 2]
main = print (f, [x | x <- Nothing :: Maybe Int])
''',
'RecursiveDo': '''{-# LANGUAGE RecursiveDo #-}
import Control.Monad.Fix
import Data.IORef
main = do
  rec r <- newIORef (length xs)
      let xs = [1, 2, 3 :: Int]
  readIORef r >>= print
  ys <- mdo { let { zs = 1 : map (* 2) zs }; return (take 5 zs) }
  print (ys :: [Int])
''',
'NegativeLiterals': '''{-# LANGUAGE NegativeLiterals #-}
main = print (abs -3 :: Int, map negate [-1, 2 :: Int])
''',
'NumDecimals': '''{-# LANGUAGE NumDecimals #-}
main = print (1e6 :: Integer, 2.5e3 :: Int)
''',
'OverloadedLists': '''{-# LANGUAGE OverloadedLists #-}
import qualified Data.Map as M
import qualified Data.Set as S
m :: M.Map Int Char
m = [(1, 'a'), (2, 'b')]
s :: S.Set Int
s = [3, 1, 2, 1]
main = print (M.toList m, S.toList s, [1, 2, 3] :: [Int])
''',
'DuplicateRecordFields': '''{-# LANGUAGE DuplicateRecordFields #-}
data Person = Person { name :: String, age :: Int } deriving Show
data Pet = Pet { name :: String } deriving Show
main = print (Person { name = "Ann", age = 3 }, Pet { name = "Rex" })
''',
'OverloadedRecordDot': '''{-# LANGUAGE OverloadedRecordDot #-}
data P = P { px :: Int, py :: Int }
data Box = Box { pos :: P, label :: String }
norm1 :: P -> Int
norm1 p = abs p.px + abs p.py
main = do
  let b = Box { pos = P 3 (-4), label = "b" }
  print (norm1 b.pos, b.label, map (.px) [P 1 2, P 5 6])
''',
'QuantifiedConstraints': '''{-# LANGUAGE QuantifiedConstraints, RankNTypes #-}
newtype Wrap f a = Wrap (f a)
instance (forall b. Show b => Show (f b), Show a) => Show (Wrap f a) where
  show (Wrap x) = "Wrap " ++ show x
main = print (Wrap (Just (3 :: Int)))
''',
'DefaultSignatures': '''{-# LANGUAGE DefaultSignatures #-}
class Pretty a where
  pretty :: a -> String
  default pretty :: Show a => a -> String
  pretty = show
instance Pretty Int
instance Pretty Bool where pretty b = if b then "yes" else "no"
main = putStrLn (pretty (3 :: Int) ++ " " ++ pretty True)
''',
'UndecidableInstances': '''{-# LANGUAGE FlexibleInstances, UndecidableInstances #-}
class Pretty a where pretty :: a -> String
instance Show a => Pretty a where pretty x = "<" ++ show x ++ ">"
main = putStrLn (pretty (3 :: Int) ++ pretty "s")
''',
'UndecidableInstancesMtl': '''{-# LANGUAGE FlexibleInstances, UndecidableInstances, MultiParamTypeClasses, FunctionalDependencies #-}
class Monad m => MonadLogger m where
  logMsg :: String -> m ()
newtype WriterIO a = WriterIO { runW :: IO a }
instance Functor WriterIO where fmap f (WriterIO m) = WriterIO (fmap f m)
instance Applicative WriterIO where
  pure = WriterIO . pure
  WriterIO f <*> WriterIO x = WriterIO (f <*> x)
instance Monad WriterIO where
  WriterIO m >>= k = WriterIO (m >>= runW . k)
instance MonadLogger WriterIO where
  logMsg s = WriterIO (putStrLn ("log: " ++ s))
newtype ReaderT r m a = ReaderT { runReaderT :: r -> m a }
instance Functor m => Functor (ReaderT r m) where
  fmap f (ReaderT g) = ReaderT (fmap f . g)
instance Applicative m => Applicative (ReaderT r m) where
  pure x = ReaderT (const (pure x))
  ReaderT f <*> ReaderT x = ReaderT (\\r -> f r <*> x r)
instance Monad m => Monad (ReaderT r m) where
  ReaderT m >>= k = ReaderT (\\r -> m r >>= \\a -> runReaderT (k a) r)
instance MonadLogger m => MonadLogger (ReaderT r m) where
  logMsg s = ReaderT (const (logMsg s))
ask :: Monad m => ReaderT r m r
ask = ReaderT return
app :: ReaderT String WriterIO Int
app = do { n <- ask; logMsg ("hello " ++ n); return (length n) }
main = runW (runReaderT app "world") >>= print
''',
'MagicHash': '''{-# LANGUAGE MagicHash #-}
import GHC.Exts
f :: Int -> Int
f (I# n) = I# (n +# 1#)
main = print (f 41)
''',
'UnboxedTuples': '''{-# LANGUAGE UnboxedTuples #-}
divMod' :: Int -> Int -> (# Int, Int #)
divMod' a b = (# a `div` b, a `mod` b #)
main = case divMod' 17 5 of (# q, r #) -> print (q, r)
''',
'Arrows': '''{-# LANGUAGE Arrows #-}
import Control.Arrow
addA :: Arrow a => a b Int -> a b Int -> a b Int
addA f g = proc x -> do
  y <- f -< x
  z <- g -< x
  returnA -< y + z
main = print (addA (+ 1) (* 2) 5)
''',
'TemplateHaskell': '''{-# LANGUAGE TemplateHaskell #-}
import Language.Haskell.TH
main = print $(litE (integerL (product [1 .. 10])))
''',
# --- base/library idioms
'LibText': '''import qualified Data.Text as T
import qualified Data.Text.IO as TIO
main = do
  let t = T.pack "Hello, World"
  TIO.putStrLn (T.toUpper t)
  print (T.length t, T.words (T.pack "a b  c"), T.splitOn (T.pack ",") (T.pack "x,y,z"))
''',
'LibByteString': '''import qualified Data.ByteString.Char8 as B
main = do
  let b = B.pack "hello bytes"
  B.putStrLn b
  print (B.length b, B.unpack (B.reverse b), B.readInt (B.pack "42 rest"))
''',
'LibMtl': '''import Control.Monad
import Control.Monad.State
import Control.Monad.Reader
import Control.Monad.Writer
counter :: State Int Int
counter = do { modify (+ 1); n <- get; when (n < 5) (void counter); gets (* 10) }
greet :: Reader String String
greet = asks ("hi " ++)
logw :: Writer [String] Int
logw = do { tell ["a"]; tell ["b"]; return 3 }
main = print (runState counter 0, runReader greet "bob", runWriter logw)
''',
'LibExceptions': '''import Control.Exception
import System.IO
main = do
  r <- try (evaluate (1 `div` (0 :: Int))) :: IO (Either ArithException Int)
  print r
  r2 <- try (throwIO (userError "boom")) :: IO (Either IOException ())
  print (either (const "caught") (const "no") r2)
  handle (\\(ErrorCall m) -> putStrLn ("error: " ++ m)) (evaluate (error "bad") >> return ())
  (putStrLn "body" >> return ()) `finally` putStrLn "finally"
''',
'LibConcurrent': '''import Control.Concurrent
import Control.Concurrent.MVar
main = do
  mv <- newEmptyMVar
  _ <- forkIO (putMVar mv (sum [1 .. 100 :: Int]))
  takeMVar mv >>= print
  c <- newMVar (0 :: Int)
  mapM_ (\\i -> modifyMVar_ c (return . (+ i))) [1 .. 10]
  readMVar c >>= print
''',
'LibMisc': '''import Data.List.NonEmpty (NonEmpty(..))
import qualified Data.List.NonEmpty as NE
import Data.Semigroup
import Data.Coerce (coerce)
import Data.Proxy
import Data.Void
import Text.Read (readMaybe)
import Data.Functor ((<&>), ($>))
import Data.Foldable (for_, traverse_, foldl')
import qualified Data.Sequence as Seq
main = do
  print (NE.head (1 :| [2, 3 :: Int]), sconcat (Max 3 :| [Max 7, Max (1 :: Int)]))
  print (coerce (Sum (3 :: Int)) :: Int, readMaybe "12" :: Maybe Int, readMaybe "x" :: Maybe Int)
  print (Just 3 <&> (+ 1), Just 'a' $> 'b', foldl' (+) 0 [1 .. 10 :: Int])
  for_ [1, 2 :: Int] print
  print (Seq.length (Seq.fromList "abc" Seq.|> 'd'))
''',
'LibSystem': '''import System.Exit
import System.Environment (getArgs, getProgName)
import System.IO
import Data.IORef
main = do
  hSetBuffering stdout NoBuffering
  hPutStrLn stderr "to stderr"
  args <- getArgs
  print args
  r <- newIORef (0 :: Int)
  modifyIORef' r (+ 5)
  readIORef r >>= print
  exitWith (ExitFailure 3)
''',
'OverlappingInstances': '''{-# LANGUAGE FlexibleInstances #-}
class Pretty a where
  pp :: a -> String
instance {-# OVERLAPPABLE #-} Pretty a => Pretty [a] where
  pp xs = "[" ++ concatMap pp xs ++ "]"
instance Pretty Char where
  pp c = [c]
instance Pretty String where
  pp s = show s
instance Pretty Int where
  pp = show
instance {-# OVERLAPPING #-} Pretty [Int] where
  pp xs = "ints:" ++ show (sum xs)
main = do
  putStrLn (pp "abc")
  putStrLn (pp [1, 2, 3 :: Int])
  putStrLn (pp [[1, 2], [3 :: Int]])
  putStrLn (pp ["x", "y"])
''',
'GNDThroughContext': '''{-# LANGUAGE GeneralizedNewtypeDeriving #-}
class Describe a where
  describe :: a -> String
  names :: [a] -> Int
instance Describe Char where
  describe c = [c]
  names = length
instance Describe a => Describe [a] where
  describe = concatMap describe
  names = length
newtype Name = Name String deriving (Eq, Show, Describe)
main = do
  putStrLn (describe (Name "abc"))
  print (names [Name "a", Name "b"], Name "x" == Name "x")
''',
'RecordPatternGuard': '''data S = Tentative { col :: Int } | Definitive { col :: Int }
f :: S -> String
f s | Tentative{} <- s, col s > 2 = "tentative"
    | Definitive{col = c} <- s = "definitive " ++ show c
    | otherwise = "other"
main = mapM_ (putStrLn . f) [Tentative 3, Tentative 1, Definitive 7]
''',
'CRLFSource': 'module Main where\r\n\r\nmain :: IO ()\r\nmain = do\r\n  let x = 1 :: Int\r\n  print (x + 1)\r\n  putStrLn "crlf"\r\n',
}


def ghc_output(name, path):
    """GHC's (stdout, exit code), cached by the probe's text; None if GHC
    cannot compile the probe."""
    with open(path, 'rb') as f:
        digest = hashlib.sha1(f.read()).hexdigest()[:12]
    cache = os.path.join(OUT, '%s-%s.ghc' % (name, digest))
    if os.path.exists(cache):
        with open(cache, 'rb') as f:
            code, _, out = f.read().partition(b'\n')
        return out, int(code)
    r = subprocess.run(['runghc', path], capture_output=True, timeout=300)
    if r.returncode == 1 and not r.stdout and b'error' in r.stderr:
        print('GHC cannot run probe %s:\n%s' % (name, r.stderr.decode()[:400]))
        return None
    with open(cache, 'wb') as f:
        f.write(b'%d\n' % r.returncode + r.stdout)
    return r.stdout, r.returncode


def main():
    args = sys.argv[1:]
    verbose = '-v' in args
    names = [a for a in args if a != '-v'] or list(PROBES)
    os.makedirs(OUT, exist_ok=True)
    passed = 0
    for name in names:
        path = os.path.join(OUT, name + '.hs')
        with open(path, 'w') as f:
            f.write(PROBES[name])
        ghc = ghc_output(name, path)
        if ghc is None:
            continue
        want, want_code = ghc
        try:
            r = subprocess.run([YALE, '--haskell98', '--modern-prelude', path],
                               capture_output=True, timeout=120, cwd=OUT)
        except subprocess.TimeoutExpired:
            print('FAIL  %-28s timed out' % name)
            continue
        if r.returncode == want_code and r.stdout == want:
            passed += 1
            print('pass  %s' % name)
        else:
            err = (r.stderr or r.stdout).decode('latin-1').strip().splitlines()
            print('FAIL  %-28s %s' % (name, (err[0] if err else 'wrong output')[:90]))
            if verbose:
                for line in err[1:6]:
                    print('        ' + line)
    print('%d of %d pass' % (passed, len(names)))


main()
