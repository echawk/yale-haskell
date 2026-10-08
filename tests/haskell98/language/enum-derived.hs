-- Derived Enum (Haskell 98 section 10.2): succ, pred, toEnum,
-- fromEnum, and enumerations from, then and to constructors.
module Main where
import Dialogue (stdout, appendChan, done, abort)

data Day = Mon | Tue | Wed | Thu | Fri | Sat | Sun deriving (Eq, Ord, Enum)

name :: Day -> String
name d = case fromEnum d of
           n -> take 3 (drop (3 * n) "MonTueWedThuFriSatSun")

names :: [Day] -> String
names = unwords . map name

out :: String
out = unlines [ names [Wed ..]
              , names [Mon, Wed ..]
              , names [Tue .. Fri]
              , names [Sun, Fri .. Mon]
              , names [succ Mon, pred Sun, toEnum 3]
              , show (map fromEnum [Mon, Sun]) ]

main = appendChan stdout out abort done
