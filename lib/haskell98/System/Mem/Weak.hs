-- System.Mem.Weak (base): weak pointers, over SBCL's (BasePrims.hi).  A
-- Weak v holds its value as long as it is itself alive, and tells whether
-- its key still is.  Finalizers run only through finalize: the garbage
-- collector's would run on SBCL's finalizer thread, and Yale Haskell's
-- runtime has one (network's sockets close when closed, not when lost).
module System.Mem.Weak (
    Weak, mkWeak, deRefWeak, finalize, mkWeakPtr, addFinalizer, mkWeakPair
  ) where

import BasePrims

-- (Data.IORef imports this module, for mkWeakIORef: the finalizer is in
-- the runtime's cell)
data Weak v = Weak WeakObj v (Ref (Maybe (IO ())))

mkWeak :: k -> v -> Maybe (IO ()) -> IO (Weak v)
mkWeak k v fin = do
  w <- primWeakPtr k
  r <- primNewRef fin
  return (Weak w v r)

deRefWeak :: Weak v -> IO (Maybe v)
deRefWeak (Weak w v _) = do
  alive <- primWeakAlive w
  return (if alive then Just v else Nothing)

-- runs the finalizer, once
finalize :: Weak v -> IO ()
finalize (Weak _ _ r) = do
  fin <- primReadRef r
  primWriteRef r Nothing
  maybe (return ()) id fin

mkWeakPtr :: k -> Maybe (IO ()) -> IO (Weak k)
mkWeakPtr k fin = mkWeak k k fin

addFinalizer :: key -> IO () -> IO ()
addFinalizer k fin = mkWeakPtr k (Just fin) >> return ()

mkWeakPair :: k -> v -> Maybe (IO ()) -> IO (Weak (k, v))
mkWeakPair k v fin = mkWeak k (k, v) fin
