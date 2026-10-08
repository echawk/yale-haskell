-- A module may define a name it also imports (report 5.5.2); the
-- qualified names tell them apart.
import AmbA

f :: String
f = "Main.f"

main :: IO ()
main = do
  putStrLn Main.f
  putStrLn AmbA.f
  print onlyA
