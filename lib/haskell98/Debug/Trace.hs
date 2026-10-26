-- Debug.Trace (base), for Yale Haskell's Haskell 98 dialect.  Messages go
-- to standard error.
module Debug.Trace (trace, traceShow, traceShowId, traceId, traceM, traceShowM, traceIO,
                    traceWith, traceShowWith, traceEvent, traceEventIO, traceMarker,
                    traceMarkerIO, traceStack, traceEventWith) where

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

traceWith :: (a -> String) -> a -> a
traceWith f a = trace (f a) a

traceShowWith :: Show b => (a -> b) -> a -> a
traceShowWith f = traceWith (show . f)

-- the eventlog's (there is none: nothing is written)
traceEvent :: String -> a -> a
traceEvent _ x = x

traceEventWith :: (a -> String) -> a -> a
traceEventWith _ x = x

traceEventIO :: String -> IO ()
traceEventIO _ = return ()

traceMarker :: String -> a -> a
traceMarker _ x = x

traceMarkerIO :: String -> IO ()
traceMarkerIO _ = return ()

-- (no call stack to add)
traceStack :: String -> a -> a
traceStack = trace
