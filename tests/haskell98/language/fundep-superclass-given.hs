{-# LANGUAGE MultiParamTypeClasses, FunctionalDependencies, FlexibleContexts, FlexibleInstances, ScopedTypeVariables #-}
-- A variable only the signature's context mentions (c), decided by a
-- superclass's functional dependency (LLIO's, not LLP's), keeps its
-- dictionaries when a local binding's constraint is matched with the
-- given (process-extras' run' and doOutput)
module Main (main) where

class LL full item | full -> item where
  toL :: full -> [item]
instance LL [a] a where
  toL = id

class LL full item => LLIO full item | full -> item
instance LLIO [a] a

class LLIO t c => LLP t c
instance LLP [a] a

class D c where
  dot :: c
instance D Char where
  dot = '.'

dotsOf :: (LLP t c, D c) => t -> String
dotsOf x = map (const '.') (toL x)

countEq :: (LLP t c, Eq c) => t -> Int
countEq x = case toL x of
  [] -> 0
  (y : ys) -> length (filter (== y) ys)

class (LLP t c, D c, Eq c, Monad m) => R t c m

instance R String Char IO

run' :: forall m t c. R t c m => t -> m (String, Int)
run' t = return (go t)
  where
    go :: t -> (String, Int)
    go x = (dotsOf x, countEq x)

main :: IO ()
main = run' "abca" >>= print
