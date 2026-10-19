-- A class's associated type family is exported and imported with C(..).
{-# LANGUAGE TypeFamilies #-}
import AssocFamilyExport (Container(..))
firstElem :: Container f => f -> Elem f
firstElem = head . toL
main = print (firstElem (insert (1 :: Int) empty :: [Int]))
