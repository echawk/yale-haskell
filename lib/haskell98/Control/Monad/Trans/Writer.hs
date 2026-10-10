-- Control.Monad.Trans.Writer (transformers): the lazy writer monad.
module Control.Monad.Trans.Writer (
    WriterT(WriterT, runWriterT), Writer, runWriter, execWriter, execWriterT,
    mapWriterT, writer, tell, listen, pass, censor
  ) where

import Control.Monad.Trans.Writer.Lazy
