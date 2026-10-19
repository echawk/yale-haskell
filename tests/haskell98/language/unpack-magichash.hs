-- {-#UNPACK#-} with no spaces under MagicHash (not a name UNPACK#).
{-# LANGUAGE MagicHash #-}
data T = T {-#UNPACK#-}!Int deriving Show
main = print (T 1)
