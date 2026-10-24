{-# LANGUAGE TemplateHaskell #-}
module ReifyMaybeGen where
import Language.Haskell.TH
r :: Q Exp
r = do
  a <- reify (mkName "Maybe")
  b <- reifyType 'Just
  stringE (take 15 (show a) ++ " / " ++ pprint b)
