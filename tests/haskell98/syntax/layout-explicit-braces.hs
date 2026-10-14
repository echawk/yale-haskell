-- An explicit { opens an explicit layout context (the Report's L pushes
-- 0): inside a record's braces a line in column 1 is not a new
-- declaration, so the closing } may start a line (husk-scheme does this).
data Point = Point {
  px :: Int
, py :: Int
}

data Shape = Circle { centre :: Point, radius :: Int }
           | Box {
  corner :: Point
, size :: Int
}
  deriving Show

instance Show Point where
  show p = "(" ++ show (px p) ++ "," ++ show (py p) ++ ")"

origin :: Point
origin = Point {
  px = 0
, py = 0
}

main :: IO ()
main = do
  print (Circle { centre = origin, radius = 2 })
  print (Box {
corner = origin { px = 3 }
, size = 4
})
