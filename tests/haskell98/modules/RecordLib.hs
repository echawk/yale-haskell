module RecordLib (Config(..), Point(Point, px), defaultConfig, origin) where

data Config = Config { verbose :: Bool, level :: Int, label :: String }
              deriving Show

data Point = Point { px, py :: Int } deriving Show

defaultConfig = Config { verbose = False, level = 1, label = "default" }

origin = Point 0 0
