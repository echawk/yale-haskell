-- A signature variable only its context mentions, through a given
-- family equality: ce of (ConOfAbs a ~ [ce], Pretty ce) => a -> m
-- String (Agda's prettyAs), in its body and at a use.
{-# LANGUAGE TypeFamilies, FlexibleContexts, GADTs #-}
module Main where

class ToConcrete a where
  type ConOfAbs a
  toConcrete :: a -> ConOfAbs a

newtype Names = Names [Int]
instance ToConcrete Names where
  type ConOfAbs Names = [String]
  toConcrete (Names xs) = map show xs

class Pretty a where pretty :: a -> String
instance Pretty Char where pretty c = [c]
instance Pretty a => Pretty [a] where pretty = concatMap pretty

abstractToConcrete :: (ToConcrete a, Monad m) => a -> m (ConOfAbs a)
abstractToConcrete = return . toConcrete

prettyAs :: (ToConcrete a, ConOfAbs a ~ [ce], Pretty ce, Monad m) => a -> m String
prettyAs x = unwords . map pretty <$> abstractToConcrete x

prettyAs' :: (ToConcrete a, ConOfAbs a ~ [ce], Pretty ce, Monad m) => a -> m String
prettyAs' = prettyAs

main :: IO ()
main = prettyAs (Names [1, 2]) >>= putStrLn >> prettyAs' (Names [3]) >>= putStrLn
