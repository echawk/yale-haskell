{-# LANGUAGE MultiParamTypeClasses, FunctionalDependencies, FlexibleContexts, FlexibleInstances, TypeFamilies #-}
-- An equality superclass, item ~ Item full (ListLike's): a signature with
-- the class knows Item full is item (process-extras' dotifyChunk)
module Main (main) where

type family Item l
type instance Item [a] = a

class Fromable l where
  fromL :: [Item l] -> l
instance Fromable [a] where
  fromL = id

class (Fromable full, item ~ Item full) => LL full item | full -> item where
  toL :: full -> [item]
instance LL [a] a where
  toL = id

class D c where
  dot :: c
instance D Char where
  dot = '.'

dots :: (LL text char, D char) => text -> text
dots t = fromL (map (const dot) (toL t))

main :: IO ()
main = putStrLn (dots "abc")
