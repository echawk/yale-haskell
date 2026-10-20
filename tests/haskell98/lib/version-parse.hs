import Data.Version
import Text.ParserCombinators.ReadP (readP_to_S)
main = print [ showVersion v | (v, "") <- readP_to_S parseVersion "2.2.5-rc1" ]
