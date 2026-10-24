-- ExtendedLiterals: 42#Int8 and the like.
{-# LANGUAGE ExtendedLiterals, MagicHash #-}
import GHC.Exts
main = print (I# 42#Int, I# (-7#Int64), W# 0xff#Word)
