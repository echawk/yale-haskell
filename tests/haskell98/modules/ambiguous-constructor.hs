-- An unqualified use of a data constructor two imports export is ambiguous: rejected.
import AmbConA
import AmbConB

main :: IO ()
main = case Alt 1 of
  OnlyA -> putStrLn "a"
  _ -> putStrLn "other"
