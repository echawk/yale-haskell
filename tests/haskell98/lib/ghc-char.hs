import GHC.Char

main :: IO ()
main = do
  print (chr 65)
  print (eqChar 'a' 'a', neChar 'a' 'a')
