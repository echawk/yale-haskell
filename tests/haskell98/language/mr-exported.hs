-- Monomorphism restriction, rule 2 (Haskell 98 section 4.5.5): a
-- restricted top-level binding is defaulted once type inference for
-- the module is complete, and may be exported ('module Main where'
-- exports everything).
module Main where
import Dialogue (stdout, appendChan, done, abort)

limit = 100

total = sum [1 .. limit]

main = appendChan stdout (show total ++ "\n") abort done
