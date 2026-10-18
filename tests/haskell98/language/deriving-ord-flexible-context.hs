-- deriving Ord for fields on applications (f a b, g a b): Eq from the
-- given Ord (f a b) (bifunctors' Product)
data Product f g a b = Pair (f a b) (g a b) deriving (Eq, Ord, Show)
main :: IO ()
main = print (Pair (1,2) (Left 3) < Pair (1,2) (Right 0 :: Either Int Int), max (Pair (1,2) (Left 3)) (Pair (1,2) (Right 4) :: Product (,) Either Int Int))
