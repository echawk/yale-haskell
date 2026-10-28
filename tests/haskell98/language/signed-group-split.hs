-- A group's bindings without signatures are generalized in their own
-- groups, a signed binding's uses no dependency (H98 4.5.1; GHC's
-- tyConsOfType: go_s, using the signed go, is polymorphic in Foldable).
import qualified Data.Map as M

type NameEnv a = M.Map String a
plusNameEnv :: NameEnv a -> NameEnv a -> NameEnv a
plusNameEnv = M.union
emptyNameEnv :: NameEnv a
emptyNameEnv = M.empty
unitNameEnv :: String -> a -> NameEnv a
unitNameEnv = M.singleton

data Ty = TyVarTy Int | TyConApp String [Ty] | AppTy Ty Ty | CastTy Ty Co | CoercionTy Co
data Co = Refl Int Ty | TyConAppCo Int String [Co] | AppCo Co Co | UnivCo Prov Int Ty Ty
        | SymCo Co | AxiomRuleCo Int [Co]
data Prov = UnsafeCoerceProv | PhantomProv Co

coreView :: Ty -> Maybe Ty
coreView _ = Nothing

tyConsOfType :: Ty -> NameEnv String
tyConsOfType ty
  = go ty
  where
     go :: Ty -> NameEnv String
     go ty | Just ty' <- coreView ty = go ty'
     go (TyVarTy {})               = emptyNameEnv
     go (TyConApp tc tys)          = go_tc tc `plusNameEnv` go_s tys
     go (AppTy a b)                = go a `plusNameEnv` go b
     go (CastTy ty co)             = go ty `plusNameEnv` go_co co
     go (CoercionTy co)            = go_co co

     go_co (Refl _ ty)             = go ty
     go_co (TyConAppCo _ tc args)  = go_tc tc `plusNameEnv` go_cos args
     go_co (AppCo co arg)          = go_co co `plusNameEnv` go_co arg
     go_co (UnivCo p _ t1 t2)      = go_prov p `plusNameEnv` go t1 `plusNameEnv` go t2
     go_co (SymCo co)              = go_co co
     go_co (AxiomRuleCo _ cs)      = go_cos cs

     go_prov UnsafeCoerceProv    = emptyNameEnv
     go_prov (PhantomProv co)    = go_co co

     go_s tys     = foldr (plusNameEnv . go)     emptyNameEnv tys
     go_cos cos   = foldr (plusNameEnv . go_co)  emptyNameEnv cos

     go_tc tc = unitNameEnv tc tc

main = print (M.keys (tyConsOfType (TyConApp "T" [CastTy (TyVarTy 1) (TyConAppCo 0 "K" [Refl 0 (TyConApp "U" [])])])))
