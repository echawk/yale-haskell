-- hiding (T): a bare type name hides the type (and a constructor named
-- T), not the type's other constructors (H98 5.3.1)
module Main (main) where
import qualified HideTypeA as A
import HideTypeA hiding (Color, Shape)

f :: A.Color -> A.Shape
f Red = Circle 1
f Green = A.Shape

main :: IO ()
main = print (map f [Red, Green])
