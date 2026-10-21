{-# LANGUAGE RecursiveDo #-}
module Main (main) where
import Control.Monad.Fix
import Control.Monad.Trans.RWS.Lazy (RWST, runRWST)
import qualified Control.Monad.Trans.State.Strict as S
import Control.Monad.Trans.Reader (ReaderT, runReaderT)
import Control.Monad.Trans.Maybe (MaybeT(..))
import Data.Functor.Identity




main :: IO ()
main = do
  let (xs, _, _) = runIdentity (runRWST (mfix (\xs -> return (1 : take 3 xs))) () () :: Identity ([Int], (), [Int]))
  print xs
  print (fst (runIdentity (S.runStateT (mfix (\ys -> return (2 : take 2 ys))) ())))
  zs <- runReaderT (mfix (\zs -> return (3 : take 1 zs))) ()
  print (zs :: [Int])
  Just ws <- runMaybeT (mfix (\ws -> return (4 : take 1 ws)))
  print (ws :: [Int])
