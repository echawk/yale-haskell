-- Literal patterns: negative integers, floating-point, characters,
-- strings, large Integer literals and the unit pattern.
module Main where

sign :: Int -> String
sign (-1) = "minus one"
sign 0    = "zero"
sign _    = "other"

half :: Double -> String
half 0.5 = "a half"
half _   = "not a half"

vowel :: Char -> Bool
vowel 'a' = True
vowel 'e' = True
vowel 'i' = True
vowel 'o' = True
vowel 'u' = True
vowel _   = False

huge :: Integer -> Bool
huge 100000000000000000000 = True
huge _                     = False

unit :: () -> String
unit () = "unit"

out :: String
out = unlines [ unwords (map sign [-1, 0, 1])
              , half 0.5 ++ ", " ++ half 0.25
              , filter vowel "programming language"
              , show (huge (10 ^ 20), huge 5)
              , unit () ]

main = appendChan stdout out abort done
