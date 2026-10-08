-- Superclasses: a class with an Eq superclass, functions that use the
-- superclass's methods given only the subclass constraint, and an
-- instance with a context.
module Main where
import Dialogue (stdout, appendChan, done, abort)

class (Eq a) => Named a where
  nameOf :: a -> String

data Animal = Cat | Dog | Cow

instance Eq Animal where
  Cat == Cat = True
  Dog == Dog = True
  Cow == Cow = True
  _   == _   = False

instance Named Animal where
  nameOf Cat = "cat"
  nameOf Dog = "dog"
  nameOf Cow = "cow"

instance (Named a) => Named [a] where
  nameOf xs = concat (map nameOf xs)

-- Uses (/=) from Eq, available through Named.
uniqueNames :: (Named a) => [a] -> [String]
uniqueNames []     = []
uniqueNames (x:xs) = nameOf x : uniqueNames (filter (/= x) xs)

out :: String
out = unlines [ unwords (uniqueNames [Cat, Dog, Cat, Cow, Dog])
              , unwords (uniqueNames [[Cat], [Dog, Cow], [Cat]]) ]

main = appendChan stdout out abort done
