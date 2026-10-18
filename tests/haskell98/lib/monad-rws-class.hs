{-# LANGUAGE FlexibleContexts #-}
-- mtl's MonadRWS: a multi-parameter class with no methods whose
-- superclasses are multi-parameter classes (MonadReader r m, ...)
import Control.Monad.RWS
step :: MonadRWS Int [String] Int m => m ()
step = do { r <- ask; s <- get; tell [show (r + s)]; put (s * 2) }
main :: IO ()
main = print (runRWS (step >> step) 10 1)
