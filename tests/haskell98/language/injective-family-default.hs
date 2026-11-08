{-# LANGUAGE TypeFamilies, TypeFamilyDependencies, MultiParamTypeClasses, FlexibleContexts, FlexibleInstances, DefaultSignatures #-}
-- an injective associated type (TypeFamilyDependencies): random 1.3's
-- default uniformByteArrayM :: (RandomGen f, FrozenGen f m, g ~ MutableGen f m) => ..
-- finds f from g at an instance using the default
import Data.Kind (Type)

newtype Seed = Seed Int deriving Show
data SeedM = SeedM

class Monad m => Gen g m where
  next :: g -> m String
  default next :: (Show f, Frozen f m, g ~ Mutable f m) => g -> m String
  next g = modifyF g (\s -> (show s, s))

class Monad m => Frozen f m where
  type Mutable f m = (g :: Type) | g -> f
  modifyF :: Mutable f m -> (f -> (a, f)) -> m a

instance Frozen Seed IO where
  type Mutable Seed IO = SeedM
  modifyF _ k = return (fst (k (Seed 41)))

instance Gen SeedM IO

main :: IO ()
main = next SeedM >>= putStrLn
