{-# LANGUAGE TemplateHaskell #-}
module ReifyClassGen where
import Language.Haskell.TH
cls :: Name -> Q Exp
cls n = do
  i <- reify n
  stringE (case i of
    ClassI (ClassD _ name tvs _ decs) insts -> nameBase name ++ " " ++ show (length tvs) ++ " methods " ++ show [nameBase m | SigD m _ <- decs] ++ " instances " ++ show (not (null insts))
    other -> take 60 (show other))
insts :: Name -> Q Type -> Q Exp
insts n t = do
  ty <- t
  is <- reifyInstances n [ty]
  stringE (show (length is))
