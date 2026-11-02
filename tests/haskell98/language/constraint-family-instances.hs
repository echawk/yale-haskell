{-# LANGUAGE TypeFamilies, ConstraintKinds #-}
import Data.Kind (Constraint)
import qualified Data.Map as Map

class BiPolyMap map where
  type BPMKeyConstraint map key :: Constraint
  mapKeysWith :: (BPMKeyConstraint map k1, BPMKeyConstraint map k2)
              => (v -> v -> v) -> (k1 -> k2) -> map k1 v -> map k2 v

instance BiPolyMap Map.Map where
  type BPMKeyConstraint Map.Map key = Ord key
  mapKeysWith = Map.mapKeysWith

type family Both a :: Constraint
type instance Both a = (Show a, Eq a)

both :: Both a => a -> a -> String
both x y = show x ++ show (x == y)

main :: IO ()
main = do
  print (Map.toList (mapKeysWith (+) (`div` 2) (Map.fromList [(1, 1), (2, 2), (3, 3 :: Int)]) :: Map.Map Int Int))
  putStrLn (both 'a' 'b')
