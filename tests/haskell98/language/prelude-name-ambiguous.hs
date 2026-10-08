-- A name both defined in the module and exported by the Prelude is
-- ambiguous when used unqualified (Haskell 98 section 5.5.2): rejected.
lookup :: String
lookup = "mine"

main :: IO ()
main = putStrLn (lookup ++ "!")
