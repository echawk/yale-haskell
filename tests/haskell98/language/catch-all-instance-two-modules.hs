-- Two modules' catch-all instances of one class (uniplate's Uniplate a
-- in .Data and .Typeable), loaded together: each module uses its own.
import CatchAllDupB
import CatchAllDupC

main :: IO ()
main = do
  putStrLn (bShow 1)
  putStrLn (cConst 'x')
