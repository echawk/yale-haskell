-- Field labels across modules: Config(..) exports the fields with the
-- type, so they work as selectors and in construction, update and
-- patterns; Point(Point, px) exports one field but not py.
module Main where

import RecordLib

describe :: Config -> String
describe Config { label = l, level = n } = l ++ "@" ++ show n

py = "not RecordLib's py"

main = do
  print defaultConfig { verbose = True, level = 3 }
  putStrLn (describe defaultConfig { label = "custom" })
  print (map level [defaultConfig, Config { verbose = True, level = 9, label = "" }])
  print (px origin, origin { px = 5 })
  putStrLn py
