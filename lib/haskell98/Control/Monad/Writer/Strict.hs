-- Control.Monad.Writer.Strict (mtl): the strict writer monad
module Control.Monad.Writer.Strict (
    MonadWriter(writer, tell, listen, pass), listens, censor,
    WriterT(WriterT, runWriterT), Writer, runWriter, execWriter, execWriterT,
    mapWriterT, mapWriter, MonadTrans(lift), MonadIO(liftIO), module Control.Monad,
    module Data.Monoid
  ) where

import Control.Monad.Writer.Class
import Control.Monad.Trans.Writer.Strict (WriterT(WriterT, runWriterT), Writer,
    runWriter, execWriter, execWriterT, mapWriterT, mapWriter)
import Control.Monad.Trans.Class
import Control.Monad.IO.Class
import Control.Monad
import Data.Monoid
