-- The layout rule's parse-error(t): an operator in a do block's column
-- cannot continue the last statement, so it closes the block and applies
-- to the whole do expression (darcs writes `do ... `catch` h` this way).
import IO

act :: IO Int
act = do
  putStrLn "in the block"
  ioError (userError "boom")
  return 1
  `catch` \e -> do
  putStrLn ("handler: " ++ ioeGetErrorString e)
  return 2

total :: Maybe Int
total = do
  x <- Just 3
  return x
  >>= \y -> Just (y * 10)

-- ~ and - begin a statement (a lazy pattern, a negation), not an operator
pairs :: IO Int
pairs = do
  ~(a, b) <- return (1, 2)
  return (a + b)

main :: IO ()
main = do
  pairs >>= print
  n <- act
  print n
  print total
  print (do { [1, 2] } ++ [3])
