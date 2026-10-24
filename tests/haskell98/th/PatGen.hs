{-# LANGUAGE TemplateHaskell #-}
module PatGen (pairP, nums) where
import Language.Haskell.TH
import Language.Haskell.TH.Quote

-- (a, b) binding the names given
pairP :: String -> String -> Q Pat
pairP a b = tupP [varP (mkName a), varP (mkName b)]

-- [nums|1 2 3|]: the list pattern [1, 2, 3], or the list
nums :: QuasiQuoter
nums = QuasiQuoter
  { quoteExp = listE . map (litE . integerL . read) . words
  , quotePat = listP . map (litP . integerL . read) . words
  , quoteType = undefined, quoteDec = undefined }
