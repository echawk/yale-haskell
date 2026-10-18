-- deriving with a field on an application of a type variable (f a, [f a]):
-- the inferred context Eq (f a), as GHC infers it
newtype Wrap f a = Wrap (f a) deriving (Eq, Ord, Show)
data Two f g a = Two (f a) (g a) [f a] deriving (Eq, Show)
main :: IO ()
main = do
  print (Wrap (Just 3) == Wrap (Just 3), Wrap [1] < Wrap [2 :: Int], Wrap (Right 'x' :: Either Int Char))
  print (Two (Just 1) [2] [Nothing, Just 3] == Two (Just 1) [2] [Nothing, Just (3 :: Int)], Two [True] (Just False) [])
