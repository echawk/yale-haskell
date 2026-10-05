-- A Show instance that defines only show, and one with showsPrec.
module Main where

data Colour = Red | Green

instance Show Colour where
  show Red   = "red"
  show Green = "green"

data V = V Int Int

instance Show V where
  showsPrec d (V x y) = showParen (d > 10) (showString "V " . showsPrec 11 x
                                            . showChar ' ' . showsPrec 11 y)

main = appendChan stdout (unlines [
  show [Red, Green],
  show (Just (V 1 (-2))),
  shows Green "!"
  ]) abort done
