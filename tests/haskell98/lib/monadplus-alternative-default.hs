-- An instance of MonadPlus without methods: base's defaults, mzero = empty
-- and mplus = (<|>) (Control.Arrow's MonadPlus (Kleisli m a) called error).
import Control.Applicative
import Control.Monad
import Control.Arrow
newtype P a = P { runP :: String -> [(a, String)] }
instance Functor P where fmap f (P p) = P (\s -> [(f a, r) | (a, r) <- p s])
instance Applicative P where
  pure x = P (\s -> [(x, s)])
  P f <*> P a = P (\s -> [(g x, r2) | (g, r1) <- f s, (x, r2) <- a r1])
instance Monad P where P p >>= k = P (\s -> concat [runP (k a) r | (a, r) <- p s])
instance Alternative P where
  empty = P (const [])
  P a <|> P b = P (\s -> a s ++ b s)
instance MonadPlus P
item :: P Char
item = P (\s -> case s of { c : cs -> [(c, cs)]; [] -> [] })
main :: IO ()
main = do
  print (runP (item `mplus` return 'z') "ab", runP (mzero :: P Char) "ab")
  print (runKleisli (Kleisli (\x -> [x, x + 1]) `mplus` mzero) (1 :: Int))
