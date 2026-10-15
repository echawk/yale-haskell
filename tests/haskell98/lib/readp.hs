-- Text.ParserCombinators.ReadP and ReadPrec (Hugs's, with base's instances).
import Text.ParserCombinators.ReadP
import qualified Text.ParserCombinators.ReadPrec as RP
import Data.Char (isDigit, isAlpha)
import Control.Applicative ((<|>))

num :: ReadP Int
num = read <$> munch1 isDigit

expr :: ReadP Int
expr = chainl1 term ((+) <$ char '+')
  where term = chainl1 (num <|> between (char '(') (char ')') expr) ((*) <$ char '*')

main :: IO ()
main = do
  print (readP_to_S expr "2*(3+4)+1")
  print (readP_to_S (sepBy (munch1 isAlpha) (char ',') <* eof) "ab,cd,e")
  print (readP_to_S (string "ab" <++ string "a") "abc", readP_to_S (gather num) "12x")
  print (readP_to_S (manyTill get (string "--")) "xy--z", readP_to_S (option 0 num) "q")
  print (RP.readPrec_to_S (RP.lift num RP.+++ RP.pfail) 0 "42")
