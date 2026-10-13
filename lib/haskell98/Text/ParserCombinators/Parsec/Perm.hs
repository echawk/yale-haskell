-- parsec 3.1.18.0 (BSD licence, Text/LICENSE.parsec), for Yale Haskell.
{-# LANGUAGE Safe #-}

-----------------------------------------------------------------------------
-- |
-- Module      :  Text.ParserCombinators.Parsec.Perm
-- Copyright   :  (c) Paolo Martini 2007
-- License     :  BSD-style (see the LICENSE file)
--
-- Maintainer  :  derek.a.elkins@gmail.com
-- Stability   :  provisional
-- Portability :  portable
--
-- Parsec compatibility module
--
-----------------------------------------------------------------------------

module Text.ParserCombinators.Parsec.Perm
    ( PermParser,
      permute,
      (<||>),
      (<$$>),
      (<|?>),
      (<$?>)
    ) where

import Text.Parsec.Perm
