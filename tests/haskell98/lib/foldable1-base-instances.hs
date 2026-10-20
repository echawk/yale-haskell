{-# LANGUAGE TypeOperators #-}
import qualified Data.Foldable1 as F1
import Data.List.NonEmpty (NonEmpty(..))
import Data.Complex
import Data.Functor.Compose
import Data.Functor.Reverse
import GHC.Generics
main = do
  print (F1.toNonEmpty (1 :+ 2 :: Complex Double))
  print (F1.toNonEmpty (Compose (('a' :| "b") :| [('c' :| "")])), F1.head (Reverse (1 :| [2, 3 :: Int])))
  print (F1.toNonEmpty (Par1 'p' :*: Rec1 ('q' :| "r")))
