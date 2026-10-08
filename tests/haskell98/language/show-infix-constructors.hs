-- Derived Show for infix constructors uses their fixity to decide on
-- parentheses (Haskell 98 section 10.4).
module Main where
import Dialogue (stdout, appendChan, done, abort)

infixl 6 :+:
infixl 7 :*:

data E = Lit Int | E :+: E | E :*: E deriving Show

out :: String
out = unlines [ show (Lit 1 :+: Lit 2)
              , show ((Lit 1 :+: Lit 2) :*: Lit 3)
              , show (Lit 1 :+: Lit 2 :*: Lit 3)
              , show (Lit (-4) :*: Lit 5) ]

main = appendChan stdout out abort done
