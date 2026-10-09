-- base's instances for functions (the reader monad) in --modern-prelude.
main :: IO ()
main = do
  print (((+1) <$> (*2)) 5, ((+) <*> (*10)) 3, (do { a <- (+1); b <- (*2); return (a+b) }) 4)
  print ((show <> const "!") 7)
