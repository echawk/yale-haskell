{-# LANGUAGE TemplateHaskell #-}
module TypeGen (pairOf, ty) where
import Language.Haskell.TH
import Language.Haskell.TH.Quote

-- (t, t)
pairOf :: Q Type -> Q Type
pairOf t = [t| ($t, $t) |]

-- [ty|Int Bool|]: Int -> Bool -> IO ()
ty :: QuasiQuoter
ty = QuasiQuoter
  { quoteType = \s -> foldr (\n r -> [t| $(conT (mkName n)) -> $r |]) [t| IO () |] (words s)
  , quoteExp = undefined, quotePat = undefined, quoteDec = undefined }
