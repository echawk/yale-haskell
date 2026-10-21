{-# LANGUAGE ConstraintKinds, TypeFamilies, DataKinds, UndecidableInstances, UndecidableSuperClasses, FlexibleInstances, FlexibleContexts #-}
import Data.Kind (Constraint)
type Checked a = (Show a, IsOk a 'True)
type family IsOk a (b :: Bool) :: Constraint where
  IsOk a 'True = ()
class Checked a => Pretty a
instance Checked a => Pretty a
p :: Pretty a => a -> String
p = show
main :: IO ()
main = putStrLn (p (Just 'x'))
