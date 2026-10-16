-- A recursion deeper than the stack ends the program as GHC's does:
-- a message on stderr and exit status 2 (batch.mumble), not a Lisp
-- backtrace.
main :: IO ()
main = do
  putStrLn "before"
  print (foldr (+) 0 [1 .. 50000000 :: Integer])
