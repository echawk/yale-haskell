-- Defining a top-level name that the implicitly imported Prelude also
-- exports is legal; only an unqualified use would be ambiguous, so
-- the program refers to its own definition as Main.lookup
-- (Haskell 98 section 5.5.2).
module Main where

lookup :: String
lookup = "my lookup"

out :: String
out = Main.lookup ++ "\n"

main = appendChan stdout out abort done
