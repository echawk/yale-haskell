{-# LANGUAGE TemplateHaskell #-}
module DeclGen (mkConst, deriveDescribe, Describe(..)) where
import Language.Haskell.TH

class Describe a where
  describeIt :: a -> String

-- name :: Int; name = value
mkConst :: String -> Integer -> Q [Dec]
mkConst n v = do
  let nm = mkName n
  s <- sigD nm (conT ''Int)
  d <- valD (varP nm) (normalB (litE (integerL v))) []
  return [s, d]

-- instance Describe T where describeIt x = case x of C1 .. -> "C1/arity"; ...
deriveDescribe :: Name -> Q [Dec]
deriveDescribe t = do
  TyConI (DataD _ _ _ _ cons _) <- reify t
  x <- newName "x"
  let one c = let (n, k) = conInfo c
              in match (conP n (replicate k wildP))
                       (normalB (stringE (nameBase n ++ "/" ++ show k))) []
  d <- instanceD (cxt []) (appT (conT ''Describe) (conT t))
         [funD 'describeIt [clause [varP x] (normalB (caseE (varE x) (map one cons))) []]]
  return [d]
  where conInfo (NormalC n fs) = (n, length fs)
        conInfo (RecC n fs) = (n, length fs)
        conInfo _ = (mkName "?", 0)
