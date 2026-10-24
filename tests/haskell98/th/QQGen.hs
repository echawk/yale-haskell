{-# LANGUAGE TemplateHaskell #-}
module QQGen (str, fmt, defs) where
import Language.Haskell.TH
import Language.Haskell.TH.Quote

-- the text as a String literal
str :: QuasiQuoter
str = QuasiQuoter
  { quoteExp = litE . stringL
  , quotePat = litP . stringL
  , quoteType = const (fail "str: no types")
  , quoteDec = const (fail "str: no declarations") }

-- "Hello #{name}!": the variables in #{ } interpolated
fmt :: QuasiQuoter
fmt = QuasiQuoter { quoteExp = go, quotePat = undefined, quoteType = undefined, quoteDec = undefined }
  where
    go s = case break (== '#') s of
      (pre, '#' : '{' : rest) ->
        let (v, rest') = break (== '}') rest
        in [| pre ++ $(varE (mkName v)) ++ $(go (drop 1 rest')) |]
      (pre, []) -> litE (stringL pre)
      (pre, c : rest) -> [| pre ++ [c] ++ $(go rest) |]

-- "a b c": a = 1, b = 2, c = 3
defs :: QuasiQuoter
defs = QuasiQuoter { quoteExp = undefined, quotePat = undefined, quoteType = undefined
                   , quoteDec = \s -> return [ ValD (VarP (mkName n)) (NormalB (LitE (IntegerL i))) []
                                             | (n, i) <- zip (words s) [1 ..] ] }
