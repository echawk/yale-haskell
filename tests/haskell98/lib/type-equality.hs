{-# LANGUAGE GADTs, TypeOperators #-}
-- Data.Type.Equality: :~:, a GADT whose result type is an operator's
-- application, and gcastWith's ((a ~ b) => r) argument
import Data.Type.Equality
data Ty a where
  TInt :: Ty Int
  TBool :: Ty Bool
instance TestEquality Ty where
  testEquality TInt TInt = Just Refl
  testEquality TBool TBool = Just Refl
  testEquality _ _ = Nothing
cast' :: Ty a -> Ty b -> a -> Maybe b
cast' ta tb x = fmap (\r -> castWith r x) (testEquality ta tb)
main :: IO ()
main = do
  print (cast' TInt TInt 3, cast' TInt TBool 3, sym (Refl :: Int :~: Int))
  print (castWith (trans Refl Refl) 'c', gcastWith (Refl :: Bool :~: Bool) True)
