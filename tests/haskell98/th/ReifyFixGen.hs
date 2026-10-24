{-# LANGUAGE TemplateHaskell #-}
module ReifyFixGen where
import Language.Haskell.TH
fixityOf :: Name -> Q Exp
fixityOf n = do
  f <- reifyFixity n
  i <- reify ''Int
  stringE (show f ++ " " ++ take 20 (show i))
