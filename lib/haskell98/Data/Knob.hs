-- Data.Knob (knob): memory-backed files.  A Knob holds bytes; a handle on
-- it reads or writes them as a file would, as text in UTF-8
-- (src/base/base-runtime.lisp).
module Data.Knob (Knob, newKnob, getContents, setContents,
                  newFileHandle, withFileHandle) where

import Prelude hiding (getContents)
import BasePrims (KnobObj, primKnobNew, primKnobContents, primKnobSet, primKnobHandle)
import IOBase (Handle(Handle))
import System.IO (IOMode(..), hClose)
import Control.Monad.IO.Class (MonadIO(liftIO))
import Control.Exception (bracket)
import Data.ByteString.Internal (ByteString(BS))

newtype Knob = Knob KnobObj

newKnob :: MonadIO m => ByteString -> m Knob
newKnob (BS s) = liftIO (fmap Knob (primKnobNew s))

getContents :: MonadIO m => Knob -> m ByteString
getContents (Knob k) = liftIO (fmap BS (primKnobContents k))

setContents :: MonadIO m => Knob -> ByteString -> m ()
setContents (Knob k) (BS s) = liftIO (primKnobSet k s)

newFileHandle :: MonadIO m => Knob -> String -> IOMode -> m Handle
newFileHandle (Knob k) name mode = liftIO (fmap Handle (primKnobHandle k name m))
  where m = case mode of
              ReadMode -> 0
              WriteMode -> 1
              AppendMode -> 2
              ReadWriteMode -> 3

withFileHandle :: MonadIO m => Knob -> String -> IOMode -> (Handle -> IO a) -> m a
withFileHandle k name mode act = liftIO (bracket (newFileHandle k name mode) hClose act)
