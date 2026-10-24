-- IsString [a] is base's (a ~ Char) => IsString [a]: a literal at an
-- undecided list type is a String (Agda's superscript).
{-# LANGUAGE OverloadedStrings #-}
module Main where

class Pretty a where pretty :: a -> String
instance Pretty Char where pretty c = [c]
instance Pretty a => Pretty [a] where pretty = concatMap pretty

prettyM :: (Applicative m, Pretty a) => a -> m String
prettyM = pure . pretty

superscript :: Applicative m => Int -> m String
superscript = prettyM . reverse . go where
  digit = ("0123456789" !!)
  go k | k < 10    = [digit k]
       | otherwise = digit (k `mod` 10) : go (k `div` 10)

main :: IO ()
main = superscript 1234 >>= putStrLn
