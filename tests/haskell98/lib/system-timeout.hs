import System.Timeout
main = do
  a <- timeout 1000000 (return 'x')
  b <- timeout 0 (return 'y')
  c <- timeout (-1) (return 'z')
  print (a, b, c)
