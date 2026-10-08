-- Two imports with different entities named f (report 5.5.2): legal,
-- as long as f is used qualified.
import AmbA
import AmbB

main :: IO ()
main = do
  putStrLn AmbA.f
  putStrLn AmbB.f
  print (onlyA + onlyB)
