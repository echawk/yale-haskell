-- Control.Monad.Writer (mtl): the lazy writer monad
module Control.Monad.Writer (
    MonadWriter(writer, tell, listen, pass), listens, censor,
    WriterT(WriterT, runWriterT), Writer, runWriter, execWriter, execWriterT,
    mapWriterT, MonadTrans(lift), MonadIO(liftIO), module Control.Monad,
    module Data.Monoid
  ) where

import Control.Monad.Writer.Class
import Control.Monad.Trans.Writer.Lazy (WriterT(WriterT, runWriterT), Writer,
    runWriter, execWriter, execWriterT, mapWriterT)
import Control.Monad.Trans.Class
import Control.Monad.IO.Class
import Control.Monad
import Data.Monoid
