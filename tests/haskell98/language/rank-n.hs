-- RankNTypes: polymorphic arguments and fields (no contexts); runST's type.
{-# LANGUAGE RankNTypes #-}
import Control.Monad.ST
import Data.STRef

newtype Church = Church { runChurch :: forall a. (a -> a) -> a -> a }

zero, one :: Church
zero = Church (\_ z -> z)
one = Church (\s z -> s z)

suc :: Church -> Church
suc n = Church (\s z -> s (runChurch n s z))

add :: Church -> Church -> Church
add m n = Church (\s z -> runChurch m s (runChurch n s z))

toInt :: Church -> Int
toInt n = runChurch n (+ 1) 0

toStr :: Church -> String
toStr n = runChurch n ('S' :) "Z"

newtype S z s a = S { unS :: forall o. (a -> s -> ST z o) -> s -> ST z o }

runS :: S z s a -> s -> ST z (a, s)
runS m s = unS m (\a s' -> return (a, s')) s

getS :: S z s s
getS = S (\k s -> k s s)

putS :: s -> S z s ()
putS s = S (\k _ -> k () s)

bindS :: S z s a -> (a -> S z s b) -> S z s b
bindS m f = S (\k -> unS m (\a -> unS (f a) k))

both :: (forall x. [x] -> Int) -> ([Int], String) -> (Int, Int)
both f (xs, ys) = (f xs, f ys)

main :: IO ()
main = do
  let three = suc (add one (suc zero))
  print (toInt three, toStr three)
  print (runST (runS (getS `bindS` \n -> putS (n * 2) `bindS` \_ -> getS) 21))
  print (both length ([1, 2, 3], "ab"))
  print (runST (do { r <- newSTRef (0 :: Int); mapM_ (\i -> modifySTRef r (+ i)) [1 .. 10]; readSTRef r }))
