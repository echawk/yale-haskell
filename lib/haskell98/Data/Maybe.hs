-- Data.Maybe: the Haskell 2010 library module (Report 2010, Part II), for Yale
-- Haskell's Haskell 98 dialect.  It re-exports the Haskell 98 module Maybe
-- and the Prelude names the 2010 Report lists, plus what 2010 added.
module Data.Maybe (
    maybe,
    isJust, isNothing, fromJust, fromMaybe, listToMaybe, maybeToList,
    catMaybes, mapMaybe
  ) where

import Maybe
