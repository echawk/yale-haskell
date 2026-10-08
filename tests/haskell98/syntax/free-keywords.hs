-- Haskell 98 reserves fewer words than Haskell 1.2: hiding, renaming,
-- to, interface, qualified and as are ordinary identifiers, and hiding
-- still works in an import declaration.
import List hiding (insert)

insert :: Int
insert = 7

main :: IO ()
main = print (renaming + to + interface + hiding + qualified + as + insert)
  where renaming = 1
        to = 2
        interface = 3
        hiding = 4
        qualified = 5
        as = 6
