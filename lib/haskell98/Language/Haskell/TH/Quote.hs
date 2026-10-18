{-# LANGUAGE RankNTypes #-}
-- Language.Haskell.TH.Quote (template-haskell 2.24.0.0).
--
-- From GHC's sources, BSD licence (Language/Haskell/LICENSE.template-haskell),
-- (c) The University Court of the University of Glasgow:
--   template-haskell 2.24.0.0's Language/Haskell/TH/Quote.hs
--   ghc-internal 9.1401.0's GHC/Internal/TH/Quote.hs (QuasiQuoter)
-- Changes for Yale Haskell:
--   - QuasiQuoter is defined here; the imports.
module Language.Haskell.TH.Quote
  ( QuasiQuoter(..)
  , quoteFile
  -- * For backwards compatibility
  , dataToQa, dataToExpQ, dataToPatQ
  ) where

import Language.Haskell.TH.Syntax
import Language.Haskell.TH.Syntax (dataToQa, dataToExpQ, dataToPatQ)


-- | 'quoteFile' takes a 'QuasiQuoter' and lifts it into one that read
-- the data out of a file.  For example, suppose @asmq@ is an
-- assembly-language quoter, so that you can write [asmq| ld r1, r2 |]
-- as an expression. Then if you define @asmq_f = quoteFile asmq@, then
-- the quote [asmq_f|foo.s|] will take input from file @"foo.s"@ instead
-- of the inline text
quoteFile :: QuasiQuoter -> QuasiQuoter
quoteFile (QuasiQuoter { quoteExp = qe, quotePat = qp, quoteType = qt, quoteDec = qd })
  = QuasiQuoter { quoteExp = get qe, quotePat = get qp, quoteType = get qt, quoteDec = get qd }
  where
   get :: (String -> Q a) -> String -> Q a
   get old_quoter file_name = do { file_cts <- runIO (readFile file_name)
                                 ; addDependentFile file_name
                                 ; old_quoter file_cts }

data QuasiQuoter = QuasiQuoter {
    -- | Quasi-quoter for expressions, invoked by quotes like @lhs = $[q|...]@
    quoteExp  :: String -> Q Exp,
    -- | Quasi-quoter for patterns, invoked by quotes like @f $[q|...] = rhs@
    quotePat  :: String -> Q Pat,
    -- | Quasi-quoter for types, invoked by quotes like @f :: $[q|...]@
    quoteType :: String -> Q Type,
    -- | Quasi-quoter for declarations, invoked by top-level quotes
    quoteDec  :: String -> Q [Dec]
    }
