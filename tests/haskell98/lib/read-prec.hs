import Text.Read
import qualified Text.Read.Lex as L
import GHC.Read (paren, list, expectP, choose)

newtype CI = CI String deriving Show
instance Read CI where
  readPrec = fmap CI readPrec

data Color = Red | Green | Blue deriving Show
instance Read Color where
  readPrec = parens (choose [("Red", return Red), ("Green", return Green), ("Blue", return Blue)])
  readListPrec = readListPrecDefault

data P = P Int Int deriving Show
instance Read P where
  readPrec = parens (prec 10 (do
    Ident "P" <- lexP
    x <- step readPrec
    y <- step readPrec
    return (P x y)))

readPrec_ :: Read a => String -> Maybe a
readPrec_ = readMaybe

main = do
  print (read "\"hello\"" :: CI)
  print (read " ( Blue ) " :: Color, read "[Red,Green]" :: [Color])
  print (read "P 3 (-4)" :: P, readMaybe "P 1" :: Maybe P, read "[P 1 2, (P 3 4)]" :: [P])
  print (readMaybe "(Just (P 5 6))" :: Maybe (Maybe P))
  print (readEither "12x" :: Either String Int, readPrec_to_S (readPrec :: ReadPrec Int) 0 "7 rest")
