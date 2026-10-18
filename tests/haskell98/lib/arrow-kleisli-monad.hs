-- Control.Arrow: leftApp, ArrowMonad, and Kleisli's Functor through MonadPlus
import Control.Arrow
import Control.Applicative

newtype F a b = F (a -> b)
main :: IO ()
main = do
  print (leftApp (+1) (Left 3 :: Either Int Char), leftApp (+1) (Right 'x' :: Either Int Char))
  print (runKleisli (fmap (*2) (Kleisli (\x -> [x, x+1]))) 5)
  print (runKleisli ((,) <$> Kleisli Just <*> pure 'z') 1)
  print (runKleisli (Kleisli (\x -> [x]) <|> Kleisli (\x -> [x*10])) 2)
  print (runKleisli (Kleisli (\x -> Just (x+1)) >>= \a -> Kleisli (\x -> Just (a*x))) 3)
  let ArrowMonad m = do { a <- ArrowMonad (\() -> 4); b <- pure 5; return (a + b :: Int) }
  print (m ())
