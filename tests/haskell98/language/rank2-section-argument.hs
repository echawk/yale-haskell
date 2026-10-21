{-# LANGUAGE RankNTypes #-}
module Main (main) where
import Data.Functor.Identity
import Data.Functor.Const

type Lens' o i = forall f. Functor f => (i -> f i) -> o -> f o

infixl 8 ^.
(^.) :: o -> Lens' o i -> i
o ^. l = getConst (l Const o)

set :: Lens' o i -> i -> o -> o
set l x o = runIdentity (l (\_ -> Identity x) o)

_1 :: Lens' (a, b) a
_1 f (a, b) = fmap (\a' -> (a', b)) (f a)

get2 :: Lens' o i -> o -> i
get2 l o = o ^. l

upd :: Lens' o i -> i -> o -> o
upd l i o = set l i o

sec :: Lens' o i -> o -> i
sec l = (^. l)

main :: IO ()
main = print (get2 _1 (1 :: Int, 'x'), upd _1 5 (1 :: Int, 'x'), sec _1 (2 :: Int, 'y'))
