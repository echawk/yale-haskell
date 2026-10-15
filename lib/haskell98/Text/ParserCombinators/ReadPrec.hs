{-# LANGUAGE CPP, RankNTypes #-}
-- Text.ParserCombinators.ReadPrec -- ported from Hugs's packages/base/Text/ParserCombinators/ReadPrec.hs, with the
-- instances base adds since (Functor, Applicative, Alternative,
-- MonadFail).  Hugs's file carries:
--
--   Copyright   :  (c) The University of Glasgow 2002
--   License     :  BSD-style (see the file libraries/base/LICENSE)
--
--   The Glasgow Haskell Compiler License
--
--   Copyright 2004, The University Court of the University of Glasgow.
--   All rights reserved.
--
--   Redistribution and use in source and binary forms, with or without
--   modification, are permitted provided that the following conditions
--   are met:
--
--   - Redistributions of source code must retain the above copyright
--   notice, this list of conditions and the following disclaimer.
--
--   - Redistributions in binary form must reproduce the above copyright
--   notice, this list of conditions and the following disclaimer in the
--   documentation and/or other materials provided with the distribution.
--
--   - Neither name of the University nor the names of its contributors
--   may be used to endorse or promote products derived from this
--   software without specific prior written permission.
--
--   THIS SOFTWARE IS PROVIDED BY THE UNIVERSITY COURT OF THE UNIVERSITY
--   OF GLASGOW AND THE CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
--   WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
--   MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
--   IN NO EVENT SHALL THE UNIVERSITY COURT OF THE UNIVERSITY OF GLASGOW
--   OR THE CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
--   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
--   LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
--   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
--   THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
--   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
--   OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

module Text.ParserCombinators.ReadPrec
  ( 
  ReadPrec,      -- :: * -> *; instance Functor, Monad, MonadPlus
  
  -- * Precedences
  Prec,          -- :: *; = Int
  minPrec,       -- :: Prec; = 0

  -- * Precedence operations
  lift,          -- :: ReadP a -> ReadPrec a
  prec,          -- :: Prec -> ReadPrec a -> ReadPrec a
  step,          -- :: ReadPrec a -> ReadPrec a
  reset,         -- :: ReadPrec a -> ReadPrec a

  -- * Other operations
  -- | All are based directly on their similarly-named 'ReadP' counterparts.
  get,           -- :: ReadPrec Char
  look,          -- :: ReadPrec String
  (+++),         -- :: ReadPrec a -> ReadPrec a -> ReadPrec a
  (<++),         -- :: ReadPrec a -> ReadPrec a -> ReadPrec a
  pfail,         -- :: ReadPrec a
  choice,        -- :: [ReadPrec a] -> ReadPrec a

  -- * Converters
  readPrec_to_P, -- :: ReadPrec a       -> (Int -> ReadP a)
  readP_to_Prec, -- :: (Int -> ReadP a) -> ReadPrec a
  readPrec_to_S, -- :: ReadPrec a       -> (Int -> ReadS a)
  readS_to_Prec, -- :: (Int -> ReadS a) -> ReadPrec a
  )
 where


import Text.ParserCombinators.ReadP
  ( ReadP
  , ReadS
  , readP_to_S
  , readS_to_P
  )

import qualified PreludeModern as M
import qualified Text.ParserCombinators.ReadP as ReadP
  ( get
  , look
  , (+++), (<++)
  , pfail
  )

import Control.Monad( MonadPlus(..) )
#ifdef __GLASGOW_HASKELL__
import GHC.Num( Num(..) )
import GHC.Base
#endif

-- ---------------------------------------------------------------------------
-- The readPrec type

newtype ReadPrec a = P { unP :: Prec -> ReadP a }

-- Functor, Monad, MonadPlus

instance Functor ReadPrec where
  fmap h (P f) = P (\n -> fmap h (f n))

instance Monad ReadPrec where
  return x  = P (\_ -> return x)
  fail s    = P (\_ -> fail s)
  P f >>= k = P (\n -> do a <- f n; let P f' = k a in f' n)
  
instance MonadPlus ReadPrec where
  mzero = pfail
  mplus = (+++)

-- precedences
  
type Prec = Int

minPrec :: Prec
minPrec = 0


instance M.Applicative ReadPrec where
  pure x = P (\_ -> return x)
  mf <*> mx = mf >>= \f -> fmap f mx

instance M.Alternative ReadPrec where
  empty = pfail
  (<|>) = (+++)

instance M.MonadFail ReadPrec where
  fail s = P (\_ -> fail s)

-- ---------------------------------------------------------------------------
-- Operations over ReadPrec

lift :: ReadP a -> ReadPrec a
-- ^ Lift a precedence-insensitive 'ReadP' to a 'ReadPrec'.
lift m = P (\_ -> m)

step :: ReadPrec a -> ReadPrec a
-- ^ Increases the precedence context by one.
step (P f) = P (\n -> f (n+1))

reset :: ReadPrec a -> ReadPrec a
-- ^ Resets the precedence context to zero.
reset (P f) = P (\n -> f minPrec)

prec :: Prec -> ReadPrec a -> ReadPrec a
-- ^ @(prec n p)@ checks whether the precedence context is 
--   less than or equal to @n@, and
--
--   * if not, fails
--
--   * if so, parses @p@ in context @n@.
prec n (P f) = P (\c -> if c <= n then f n else ReadP.pfail)

-- ---------------------------------------------------------------------------
-- Derived operations

get :: ReadPrec Char
-- ^ Consumes and returns the next character.
--   Fails if there is no input left.
get = lift ReadP.get

look :: ReadPrec String
-- ^ Look-ahead: returns the part of the input that is left, without
--   consuming it.
look = lift ReadP.look

(+++) :: ReadPrec a -> ReadPrec a -> ReadPrec a
-- ^ Symmetric choice.
P f1 +++ P f2 = P (\n -> f1 n ReadP.+++ f2 n)

(<++) :: ReadPrec a -> ReadPrec a -> ReadPrec a
-- ^ Local, exclusive, left-biased choice: If left parser
--   locally produces any result at all, then right parser is
--   not used.
P f1 <++ P f2 = P (\n -> f1 n ReadP.<++ f2 n)

pfail :: ReadPrec a
-- ^ Always fails.
pfail = lift ReadP.pfail

choice :: [ReadPrec a] -> ReadPrec a
-- ^ Combines all parsers in the specified list.
choice ps = foldr (+++) pfail ps

-- ---------------------------------------------------------------------------
-- Converting between ReadPrec and Read

readPrec_to_P :: ReadPrec a -> (Int -> ReadP a)
readPrec_to_P (P f) = f

readP_to_Prec :: (Int -> ReadP a) -> ReadPrec a
readP_to_Prec f = P f

readPrec_to_S :: ReadPrec a -> (Int -> ReadS a)
readPrec_to_S (P f) n = readP_to_S (f n)

readS_to_Prec :: (Int -> ReadS a) -> ReadPrec a
readS_to_Prec f = P (\n -> readS_to_P (f n))
