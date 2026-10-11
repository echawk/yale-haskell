-- ExistentialQuantification: hidden dictionaries, used across modules (ExistShapes.hs).
{-# LANGUAGE ExistentialQuantification #-}
import ExistShapes

data Circle = Circle Double
data Square = Square Double

instance Shape Circle where
  area (Circle r) = 3 * r * r
  name _ = "circle"

instance Shape Square where
  area (Square s) = s * s
  name _ = "square"

same :: Showy t -> (t, String)
same (Showy t a b) = (t, show a ++ (if a == b then "==" else "/=") ++ show b)
same (Plain t) = (t, "plain")

main :: IO ()
main = do
  let shapes = [AnyShape (Circle 1), AnyShape (Square 2)]
  mapM_ (putStrLn . describe) shapes
  print (sum (map area' shapes))
  print (map same [Showy 'x' (1 :: Int) 1, Showy 'y' "a" "b", Plain 'z'])
