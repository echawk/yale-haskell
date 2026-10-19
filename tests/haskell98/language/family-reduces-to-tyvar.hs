{-# LANGUAGE TypeFamilies #-}
class C m where
  type E m
  get :: m -> E m
newtype Box a = Box a
instance C (Box a) where
  type E (Box a) = a
  get (Box x) = x
showE :: (Show a) => Box a -> String
showE b = show (get b)
eqE :: (Eq a) => Box a -> a -> Bool
eqE b y = get b == y
main = do
  putStrLn (showE (Box (3 :: Int)))
  print (eqE (Box 'x') 'x')
