-- Dialogue: Haskell 1.2 style I/O for Haskell 98 programs (a Yale Haskell
-- library, not part of Haskell 98).
--
-- The Haskell 1.2 Prelude provided stream-based I/O: a program was a
-- Dialogue, with continuation-passing requests on named channels
-- (appendChan stdout "text" abort done).  Yale Haskell's Haskell 98
-- Prelude still implements it (PreludeIO), but no longer exports it, as
-- the Haskell 98 Prelude defines none of these names.  Import this module
-- to use them; also exported are Yale Haskell's IO combinators thenIO,
-- thenIO_, seqIO, returnIO and doneIO (>>=, >>, return, return ()).
--
-- stdin, stdout, stderr and stdecho here are channel names (Strings),
-- not the Handles of the IO library.

module Dialogue (
    Dialogue(..), SuccCont(..), StrCont(..), StrListCont(..), FailCont(..),
    stdin, stdout, stderr, stdecho,
    readChan, appendChan, done, exit, abort, prints,
    thenIO, thenIO_, seqIO, returnIO, doneIO, SystemState, IOResult
  ) where

import PreludeIO
