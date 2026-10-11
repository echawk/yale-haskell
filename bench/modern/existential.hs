-- ExistentialQuantification and RankNTypes: a list of 300000 shapes
-- of different types behind a class, summed by dictionary dispatch,
-- and a rank-2 traversal.
{-# LANGUAGE ExistentialQuantification, RankNTypes #-}
class Shape a where
  area :: a -> Double
  sides :: a -> Int

data Circle = Circle Double
data Rect = Rect Double Double
data Tri = Tri Double Double Double

instance Shape Circle where { area (Circle r) = 3.0 * r * r; sides _ = 0 }
instance Shape Rect where { area (Rect w h) = w * h; sides _ = 4 }
instance Shape Tri where
  area (Tri a b c) = let s = (a + b + c) / 2 in sqrt (s * (s - a) * (s - b) * (s - c))
  sides _ = 3

data AnyShape = forall s. Shape s => AnyShape s

mk :: Int -> AnyShape
mk i = case i `mod` 3 of
  0 -> AnyShape (Circle (fromIntegral (i `mod` 10)))
  1 -> AnyShape (Rect (fromIntegral (i `mod` 7)) 2)
  _ -> AnyShape (Tri 3 4 5)

applyBoth :: (forall s. Shape s => s -> Double) -> AnyShape -> Double
applyBoth f (AnyShape s) = f s

main :: IO ()
main = do
  let shapes = map mk [1 .. 300000]
  print (round (sum [area s | AnyShape s <- shapes]) :: Int)
  print (sum [sides s | AnyShape s <- shapes])
  print (round (sum (map (applyBoth (\s -> area s + fromIntegral (sides s))) shapes)) :: Int)
