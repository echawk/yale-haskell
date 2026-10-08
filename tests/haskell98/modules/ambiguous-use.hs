-- An unqualified use of a name two imports define is ambiguous: rejected.
import AmbA
import AmbB

main :: IO ()
main = putStrLn f
