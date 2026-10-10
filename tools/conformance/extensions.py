#!/usr/bin/env python3
"""Probe GHC language extensions and modern-base idioms in Yale Haskell.

    tools/conformance/extensions.py [-v] [NAME ...]

Each probe is a small program (PROBES below) run with
`yale-haskell --haskell98 --modern-prelude` and compared with GHC's output
(runghc, cached in build/conformance/extensions/).  Prints pass / FAIL
per probe and a total; -v shows the first lines of a failure's output.
"""

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
}


def ghc_output(name, path):
    cache = os.path.join(OUT, name + '.ghc')
    if os.path.exists(cache):
        with open(cache, 'rb') as f:
            return f.read()
    r = subprocess.run(['runghc', path], capture_output=True, timeout=300)
    if r.returncode != 0:
        sys.exit('GHC fails on probe %s:\n%s' % (name, r.stderr.decode()))
    with open(cache, 'wb') as f:
        f.write(r.stdout)
    return r.stdout


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
        want = ghc_output(name, path)
        r = subprocess.run([YALE, '--haskell98', '--modern-prelude', path],
                           capture_output=True, timeout=300, cwd=OUT)
        if r.returncode == 0 and r.stdout == want:
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
