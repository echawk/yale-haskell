-- Debug.Trace (base), for Yale Haskell's Haskell 98 dialect.  Messages go
-- to standard error.
module Debug.Trace (trace, traceShow, traceShowId, traceId, traceM, traceShowM, traceIO) where

import IO (hPutStrLn, stderr)
import ForeignPrims (primUnsafePerformIO)

traceIO :: String -> IO ()
traceIO msg = hPutStrLn stderr msg

trace :: String -> a -> a
trace msg x = primUnsafePerformIO (traceIO msg >> return x)

traceId :: String -> String
traceId s = trace s s

traceShow :: Show a => a -> b -> b
traceShow = trace . show

traceShowId :: Show a => a -> a
traceShowId x = trace (show x) x

traceM :: Monad m => String -> m ()
traceM msg = trace msg (return ())

traceShowM :: (Show a, Monad m) => a -> m ()
traceShowM = traceM . show
