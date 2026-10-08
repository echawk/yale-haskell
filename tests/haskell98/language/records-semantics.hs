-- Records (H98 Report 3.15): selectors as functions, construction with
-- missing fields, update of several fields and across constructors that
-- share a field, record patterns, C {} patterns for any constructor,
-- polymorphic and strict fields, nesting, and derived Read.
module Main where

data Shape = Circle { name :: String, radius :: Double }
           | Rect   { name :: String, w, h :: Double }
           | Dot
           deriving (Show, Read, Eq)

data Pair a b = Pair { pfst :: a, psnd :: !b } deriving (Show, Eq)

data Plain = Plain Int Bool deriving Show

data Outer = Outer { inner :: Pair Int Char, tag :: Int } deriving Show

area :: Shape -> Double
area Circle { radius = r } = 3 * r * r
area (Rect { w = x, h = y }) = x * y
area Dot {} = 0

isPlain :: Plain -> Bool
isPlain Plain {} = True

partial = Circle { name = "p" }

main = do
  let shapes = [Circle { name = "c", radius = 2 }, Rect { h = 3, w = 4, name = "r" }, Dot]
  print (map area shapes)
  print (map name (take 2 shapes))
  print (shapes !! 1) { name = "renamed", h = 10 }
  print [ s { name = "x" } | s <- take 2 shapes ]
  print (name partial)
  print (Pair { psnd = 'z', pfst = [1,2,3::Int] })
  print ((Pair 1 'a') { pfst = "poly" })
  let o = Outer { inner = Pair 1 'q', tag = 7 }
  print o { inner = (inner o) { psnd = 'r' } }
  print (isPlain (Plain 3 True))
  print (read "Rect {name = \"q\", w = 1.5, h = 2.0}" :: Shape)
  print ((read " ( Circle { name = \"z\" , radius = 1.0 } ) " :: Shape) == Circle "z" 1)
  print (map pfst [Pair 'a' True, Pair 'b' False])
