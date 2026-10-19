-- Data.Functor.Classes: Read1 by its ReadPrec method or its ReadS one.
import Data.Functor.Classes
import Text.Read (readPrec, readListPrec)
newtype Box a = Box a deriving Show
instance Read1 Box where
  liftReadPrec rp _ = fmap Box rp
main = do
  print (readsPrec1 0 "5" :: [(Box Int, String)])
  print (fst (head (liftReadsPrec readsPrec readList 0 "Just 3" :: [(Maybe Int, String)])))
