import GHC.Lexeme
main = print (map startsVarSym "+a:", map startsConSym ":+", startsVarId (head "x"), startsConId (head "X"))
