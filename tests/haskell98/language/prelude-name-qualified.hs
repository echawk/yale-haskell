-- Defining a Prelude name (H98 5.5.2): Main.x is the module's own, and
-- Prelude.x the Prelude's, both usable.
filter :: Int
filter = 3

main :: IO ()
main = do
  print (Main.filter + 1)
  print (Prelude.filter even [1 .. 10])
