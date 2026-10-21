module MutualB where
import {-# SOURCE #-} MutualA (Tree)
newtype Forest = Forest [Tree]
forestSize :: Forest -> Int
