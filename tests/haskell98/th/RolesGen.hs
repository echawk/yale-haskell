{-# LANGUAGE TemplateHaskell #-}
-- RolesGen: reifyRoles and reifyConStrictness as strings (the
-- reify-roles-strictness test).
module RolesGen (rolesOf, strictnessOf) where

import Language.Haskell.TH

rolesOf :: Name -> Q Exp
rolesOf n = reifyRoles n >>= stringE . show

strictnessOf :: Name -> Q Exp
strictnessOf n = reifyConStrictness n >>= stringE . show
