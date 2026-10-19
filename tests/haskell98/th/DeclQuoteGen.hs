{-# LANGUAGE TemplateHaskell #-}
module DeclQuoteGen where
import Language.Haskell.TH

-- a data type, an instance and functions, from one quote
colours :: Q [Dec]
colours = [d|
  data Colour = Red | Green | Blue deriving (Show, Eq)
  next :: Colour -> Colour
  next Red = Green
  next Green = Blue
  next Blue = Red
  instance Semigroup Colour where
    a <> b = if a == b then a else next a
  |]

-- getter functions for a record type, by reify (a lens-like generator)
mkGetters :: Name -> Q [Dec]
mkGetters t = do
  TyConI (DataD _ _ _ _ [RecC con fields] _) <- reify t
  fmap concat (mapM (\(f, _, _) -> do
    x <- newName "x"
    let g = mkName ("get" ++ nameBase f)
    sequence [funD g [clause [varP x] (normalB (appE (varE f) (varE x))) []]])
    fields)
