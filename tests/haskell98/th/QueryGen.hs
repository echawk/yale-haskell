{-# LANGUAGE TemplateHaskell #-}
module QueryGen where
import Language.Haskell.TH
import Language.Haskell.TH.Syntax
info :: Q Exp
info = do
  loc <- location
  th <- isExtEnabled TemplateHaskell
  gadts <- isExtEnabled GADTs
  t <- lookupTypeName "Maybe"
  v <- lookupValueName "map"
  c <- lookupValueName "Just"
  n <- lookupValueName "noSuchThing"
  stringE (unwords [loc_module loc, show (fst (loc_start loc)), show th, show gadts,
                    maybe "-" nameBase t, maybe "-" nameBase v, maybe "-" nameBase c, show n])
