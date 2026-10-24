module Main where
import Control.Monad.Trans.Maybe
import Control.Monad.Trans.Except
main :: IO ()
main = do
  a <- runExceptT (maybeToExceptT "none" (MaybeT (return (Nothing :: Maybe Int))))
  b <- runExceptT (maybeToExceptT "none" (MaybeT (return (Just (3 :: Int)))))
  c <- runMaybeT (exceptToMaybeT (throwE "x" :: ExceptT String IO Int))
  print (a, b, c)
