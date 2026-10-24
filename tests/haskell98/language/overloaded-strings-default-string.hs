-- OverloadedStrings: an ambiguous IsString defaults to String, as GHC's
-- (Agda's throwError "..." in an ExceptT that exceptToMaybeT drops).
{-# LANGUAGE OverloadedStrings #-}
module Main where

import Control.Monad.Except
import Control.Monad.Trans.Maybe

look :: Int -> IO (Maybe Int)
look n = runMaybeT $ exceptToMaybeT $ do
  when (n < 0) $ throwError "negative"
  x <- maybeToExceptT "not found" $ MaybeT $ return (if n > 10 then Nothing else Just n)
  return (x * 2)

main :: IO ()
main = do
  look 3 >>= print
  look (-1) >>= print
  look 11 >>= print
