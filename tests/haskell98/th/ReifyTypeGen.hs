{-# LANGUAGE TemplateHaskell #-}
module ReifyTypeGen where
import Language.Haskell.TH
r :: Q Exp
r = do
  a <- reify (mkName "Int")
  b <- reifyType 'Just
  stringE (take 15 (show a) ++ " / " ++ pprint b)
