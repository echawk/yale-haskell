module Main where
import qualified Data.List as L
import Data.List.NonEmpty (NonEmpty(..))
main = print (L.maximumBy compare (1 :| [3,2::Int]), L.length (1 :| [2::Int]), L.foldl' (+) 0 (Just (3::Int)), L.find even (1 :| [2::Int]))
