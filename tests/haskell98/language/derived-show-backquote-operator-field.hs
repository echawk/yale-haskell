-- derived Show/Read: an alphanumeric infix constructor is shown in
-- backquotes, and a record may have an operator field
infixl 6 `Plus`
data Op = Int `Plus` Int | N { (%%) :: Int } deriving (Show, Read, Eq)

main :: IO ()
main = do
  print (3 `Plus` 4)
  print (Just (3 `Plus` (-4)))
  print (N 5)
  print (read "3 `Plus` 4" :: Op)
  print (read (show (N (-2))) == N (-2))
  print ((read "Just (1 `Plus` 2)" :: Maybe Op) == Just (1 `Plus` 2))
