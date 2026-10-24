-- A given flexible constraint (Hilite (RenamingTo m)) is used,
-- not an instance for RenamingTo (Agda's FromAbstract).
{-# LANGUAGE FlexibleContexts, FlexibleInstances #-}
module Main where

class Hilite a where
  hilite :: a -> String

newtype RenamingTo a = RenamingTo a

data ImportedName' m n = ImportedModule m | ImportedName n

instance Hilite (RenamingTo Int) where
  hilite (RenamingTo i) = "int " ++ show i

instance Hilite (RenamingTo Bool) where
  hilite (RenamingTo b) = "bool " ++ show b

instance (Hilite (RenamingTo m), Hilite (RenamingTo n))
       => Hilite (RenamingTo (ImportedName' m n)) where
  hilite (RenamingTo x) = case x of
    ImportedModule m -> hilite (RenamingTo m)
    ImportedName   n -> hilite (RenamingTo n)

main :: IO ()
main = do
  putStrLn (hilite (RenamingTo (ImportedModule 3 :: ImportedName' Int Bool)))
  putStrLn (hilite (RenamingTo (ImportedName True :: ImportedName' Int Bool)))
