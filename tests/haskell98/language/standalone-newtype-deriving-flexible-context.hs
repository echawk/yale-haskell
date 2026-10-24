-- A standalone newtype deriving keeps its declared context, flexible
-- constraints too (Agda's AbsToConT's Null).
{-# LANGUAGE FlexibleContexts, FlexibleInstances, GeneralizedNewtypeDeriving, StandaloneDeriving #-}
module Main where

import Control.Monad.Reader

class Null a where
  empty :: a
  null :: a -> Bool

instance Null [a] where
  empty = []
  null = Prelude.null

instance (Null (m a), Monad m) => Null (ReaderT r m a) where
  empty = lift empty
  null = const False

newtype AbsToConT m a = AbsToCon { unAbsToCon :: ReaderT Int m a }
  deriving (Functor, Applicative, Monad)

deriving instance (Monad m, Null (m String)) => Null (AbsToConT m String)

main :: IO ()
main = do
  print (Main.null (AbsToCon (return "x") :: AbsToConT [] String))
  print (runReaderT (unAbsToCon (empty :: AbsToConT [] String)) 0)
