module MutualB (Forest(..), forestSize) where
import MutualA (Tree, size)

newtype Forest = Forest [Tree]

forestSize :: Forest -> Int
forestSize (Forest ts) = sum (map size ts)
