-- An export list naming C.x exports x (parser-combinators).
import QExpB

main :: IO ()
main = print (choice [other, 1])
