{-# LANGUAGE MagicHash #-}
-- GHC.Generics: URec's unboxed representations, prec, Associativity
import GHC.Generics
import GHC.Exts
main :: IO ()
main = do
  print (isTrue# (uInt# (UInt 3 :: UInt ()) ==# 3), prec Prefix, prec (Infix LeftAssociative 6))
  print (isTrue# (eqChar# (uChar# (UChar 'a' :: UChar ())) 'a'), [minBound .. maxBound :: Associativity])
