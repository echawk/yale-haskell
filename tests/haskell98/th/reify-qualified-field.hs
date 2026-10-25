-- A field type named through a qualified import (pandoc-types' Meta's
-- M.Map Text MetaValue, which aeson's deriveJSON reifies): reify gives
-- its global name, which reifies in turn.
{-# LANGUAGE TemplateHaskell #-}
import Language.Haskell.TH
import qualified Data.Map as M

data T = T (M.Map Int Bool)

$(do TyConI (DataD _ _ _ _ [NormalC _ [(_, AppT (AppT (ConT m) _) _)]] _) <- reify ''T
     info <- reify m
     let kind = case info of TyConI _ -> "type"; _ -> "other"
     return [FunD (mkName "fieldType") [Clause [] (NormalB (LitE (StringL (nameBase m ++ " " ++ kind)))) []]])

main :: IO ()
main = putStrLn fieldType
