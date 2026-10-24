{-# LANGUAGE TemplateHaskell #-}
module ReifyTyconGen where
import Language.Haskell.TH
r :: Q Exp
r = do
  t <- reifyType 'Just
  let ForallT _ _ (AppT (AppT ArrowT _) (AppT (ConT m) _)) = t
  i <- reify m
  stringE (take 30 (show i))
