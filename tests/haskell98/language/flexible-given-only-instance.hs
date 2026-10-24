-- A given flexible constraint (Hilite (RenamingTo m)) is used,
-- not an instance for RenamingTo (Agda's FromAbstract).
{-# LANGUAGE FlexibleContexts, FlexibleInstances #-}
module Main where

class Hilite a where
  hilite :: a -> String

newtype RenamingTo a = RenamingTo a

instance Hilite (RenamingTo Int) where
  hilite (RenamingTo i) = "int " ++ show i

f :: Hilite (RenamingTo m) => m -> String
f m = hilite (RenamingTo m)

main :: IO ()
main = putStrLn (f (3::Int))
