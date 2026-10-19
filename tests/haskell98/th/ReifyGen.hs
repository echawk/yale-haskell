{-# LANGUAGE TemplateHaskell #-}
module ReifyGen (conNames, describe) where
import Language.Haskell.TH

conNames :: Name -> Q Exp
conNames t = do
  info <- reify t
  case info of
    TyConI (DataD _ _ _ _ cons _) -> listE [stringE (nameBase (conName c)) | c <- cons]
    TyConI (NewtypeD _ _ _ _ c _) -> listE [stringE (nameBase (conName c))]
    _ -> fail ("not a data type: " ++ show t)
  where conName (NormalC n _) = n
        conName (RecC n _) = n
        conName _ = mkName "?"

describe :: Name -> Q Exp
describe n = reify n >>= stringE . pprint
