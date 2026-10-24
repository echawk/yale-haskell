{-# LANGUAGE TemplateHaskell, RankNTypes #-}
module LensGen (Lens, view, set, over, makeLenses) where
import Language.Haskell.TH
import Data.Functor.Identity
import Data.Functor.Const

type Lens s a = forall f. Functor f => (a -> f a) -> s -> f s

view :: ((a -> Const a a) -> s -> Const a s) -> s -> a
view l s = getConst (l Const s)

over :: ((a -> Identity a) -> s -> Identity s) -> (a -> a) -> s -> s
over l f = runIdentity . l (Identity . f)

set :: ((a -> Identity a) -> s -> Identity s) -> a -> s -> s
set l a = over l (const a)

-- for each field _x of the record type: x :: Lens T FieldType
makeLenses :: Name -> Q [Dec]
makeLenses tyName = do
  TyConI (DataD _ _ [] _ [RecC con fields] _) <- reify tyName
  concat <$> mapM (one con (map (\(f, _, _) -> f) fields)) fields
  where
    one con allFields (field, _, fieldTy) = case nameBase field of
      '_' : rest -> do
        let lensName = mkName rest
        f <- newName "f"
        s <- newName "s"
        x <- newName "x"
        vars <- mapM (\fl -> newName (drop 1 (nameBase fl))) allFields
        let rebuilt = foldl AppE (ConE con)
                        [ if fl == field then VarE x else VarE v | (fl, v) <- zip allFields vars ]
            body = LamE [VarP f, VarP s]
                     (CaseE (VarE s)
                       [Match (ConP con [] (map VarP vars))
                              (NormalB (InfixE (Just (LamE [VarP x] rebuilt))
                                               (VarE '(<$>))
                                               (Just (AppE (VarE f) (VarE (vars !! idx field))))))
                              []])
            idx fl = length (takeWhile (/= fl) allFields)
        sig <- sigD lensName [t| Lens $(conT tyName) $(return fieldTy) |]
        return [sig, ValD (VarP lensName) (NormalB body) []]
      _ -> return []
