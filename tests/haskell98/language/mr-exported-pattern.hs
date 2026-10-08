-- Monomorphism restriction rule 2 (Haskell 98 4.5.5): an exported
-- *pattern* binding is allowed but not generalised.  The components are
-- defaulted once module type inference is complete.  (Haskell 1.2
-- rejects exporting a restricted pattern binding; see mr-exported.)
module Main (first, second, main) where

(first, second) = (10 :: Int, 20 :: Int)

out :: String
out = show first ++ " " ++ show second ++ "\n"

main = appendChan stdout out abort done
