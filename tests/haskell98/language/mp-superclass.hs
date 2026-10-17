-- A multi-parameter superclass (StateVar's HasUpdate) is accepted.
{-# LANGUAGE MultiParamTypeClasses, FunctionalDependencies, FlexibleInstances #-}
import Data.IORef
class HasSetter t a | t -> a where
  set :: t -> a -> IO ()
class HasSetter t b => HasUpdate t a b | t -> a b where
  update :: t -> (a -> b) -> IO ()
instance HasSetter (IORef a) a where
  set = writeIORef
instance HasUpdate (IORef a) a a where
  update r f = readIORef r >>= set r . f
main = do
  r <- newIORef (1 :: Int)
  update r (+ 41)
  readIORef r >>= print
