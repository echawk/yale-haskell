-- Equality constraints written ~~ (heterogeneous) and qualified (Eq.~~).
{-# LANGUAGE TypeOperators, GADTs #-}
import qualified Data.Type.Equality as Eq
class C a where c :: a -> String
instance a ~ Int => C [a] where c _ = "ints"
instance (a Eq.~~ Bool) => C (Maybe a) where c _ = "maybe bool"
main = putStrLn (c [1]) >> putStrLn (c (Just True))
