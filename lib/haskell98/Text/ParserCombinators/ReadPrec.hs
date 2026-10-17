{-# LANGUAGE CPP #-}
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

--
-- In Yale Haskell a ReadPrec is the Prelude's (PreludeCore: the type of
-- base's Read methods readPrec and readListPrec), a reader given the
-- precedence: Int -> ReadS a.  The operations are Hugs's, over that
-- representation; lift and the converters go through ReadP.

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

import PreludeCore (ReadPrec(MkReadPrec))
import Text.ParserCombinators.ReadP
  ( ReadP
  , readP_to_S
  , readS_to_P
  )
import qualified PreludeModern as M
import Control.Monad( MonadPlus(..) )

infixr 5 +++, <++

unP :: ReadPrec a -> Prec -> ReadS a
unP (MkReadPrec f) = f

instance Functor ReadPrec where
  fmap h (MkReadPrec f) = MkReadPrec (\n s -> [ (h a, s') | (a, s') <- f n s ])

instance Monad ReadPrec where
  return x  = MkReadPrec (\_ s -> [(x, s)])
  fail _    = pfail
  MkReadPrec f >>= k = MkReadPrec (\n s -> [ r | (a, s') <- f n s, r <- unP (k a) n s' ])

instance MonadPlus ReadPrec where
  mzero = pfail
  mplus = (+++)

instance M.Applicative ReadPrec where
  pure x = return x
  mf <*> mx = mf >>= \f -> fmap f mx

instance M.Alternative ReadPrec where
  empty = pfail
  (<|>) = (+++)

instance M.MonadFail ReadPrec where
  fail _ = pfail

type Prec = Int

minPrec :: Prec
minPrec = 0

lift :: ReadP a -> ReadPrec a
lift m = MkReadPrec (\_ -> readP_to_S m)

step :: ReadPrec a -> ReadPrec a
step (MkReadPrec f) = MkReadPrec (\n -> f (n + 1))

reset :: ReadPrec a -> ReadPrec a
reset (MkReadPrec f) = MkReadPrec (\_ -> f minPrec)

prec :: Prec -> ReadPrec a -> ReadPrec a
prec n (MkReadPrec f) = MkReadPrec (\c -> if c <= n then f n else const [])

get :: ReadPrec Char
get = MkReadPrec (\_ s -> case s of
                            (c : cs) -> [(c, cs)]
                            []       -> [])

look :: ReadPrec String
look = MkReadPrec (\_ s -> [(s, s)])

(+++) :: ReadPrec a -> ReadPrec a -> ReadPrec a
MkReadPrec f1 +++ MkReadPrec f2 = MkReadPrec (\n s -> f1 n s ++ f2 n s)

-- left-biased: the second only where the first finds nothing
(<++) :: ReadPrec a -> ReadPrec a -> ReadPrec a
MkReadPrec f1 <++ MkReadPrec f2 = MkReadPrec (\n s -> case f1 n s of
                                                         [] -> f2 n s
                                                         rs -> rs)

pfail :: ReadPrec a
pfail = MkReadPrec (\_ _ -> [])

choice :: [ReadPrec a] -> ReadPrec a
choice ps = foldr (+++) pfail ps

readPrec_to_P :: ReadPrec a -> (Int -> ReadP a)
readPrec_to_P (MkReadPrec f) n = readS_to_P (f n)

readP_to_Prec :: (Int -> ReadP a) -> ReadPrec a
readP_to_Prec f = MkReadPrec (\n -> readP_to_S (f n))

readPrec_to_S :: ReadPrec a -> (Int -> ReadS a)
readPrec_to_S (MkReadPrec f) = f

readS_to_Prec :: (Int -> ReadS a) -> ReadPrec a
readS_to_Prec f = MkReadPrec f
