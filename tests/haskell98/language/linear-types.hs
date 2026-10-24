-- LinearTypes: a %1 -> b, a %m -> b and a ⊸ b are a -> b (multiplicities
-- are not checked).
{-# LANGUAGE LinearTypes, UnicodeSyntax, KindSignatures, DataKinds #-}
import GHC.Types (Multiplicity(..))
swap :: (a, b) %1 -> (b, a)
swap (x, y) = (y, x)
app :: (a %m -> b) -> a %m -> b
app f x = f x
idL :: a ⊸ a
idL x = x
many :: a %'Many -> a
many x = x
main = print (swap (1::Int, 'c'), app idL (2::Int), many 'z')
