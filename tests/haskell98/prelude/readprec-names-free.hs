-- The Prelude does not export readPrec or ReadPrec: a program may use the names.
data ReadPrec = R Int deriving (Show, Read)
readPrec :: Int -> Int
readPrec = (+1)
main = print (readPrec 1, read "R 5" :: ReadPrec)
