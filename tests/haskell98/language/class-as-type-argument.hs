{-# LANGUAGE ConstraintKinds, KindSignatures, MultiParamTypeClasses, FlexibleInstances, FlexibleContexts #-}
import Data.Kind (Type, Constraint)

class Named (c :: Type -> Constraint) where cname :: proxy c -> String
data P (c :: Type -> Constraint) = P
instance Named Show where cname _ = "Show"
instance Named Eq where cname _ = "Eq"

main :: IO ()
main = putStrLn (cname (P :: P Show) ++ cname (P :: P Eq))
