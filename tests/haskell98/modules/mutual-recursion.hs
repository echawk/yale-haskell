-- Mutually recursive modules (MutualA, MutualB; GHC's .hs-boot file is
-- not read): their units become one
module Main (main) where
import MutualA
import MutualB

main :: IO ()
main = print (size (Node 1 (Forest [Node 2 (Forest []), Node 3 (Forest [Node 4 (Forest [])])])))
