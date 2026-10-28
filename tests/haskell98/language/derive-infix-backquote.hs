-- A derived Show/Read for a constructor declared infix with backquotes shows it between backquotes.
data V = Int `Foo` Int | Int :+: Int deriving (Show, Read, Eq)
infixl 6 `Foo`

main :: IO ()
main = do
  print (1 `Foo` 2)
  print (Just (3 `Foo` 4))
  print (1 :+: 2)
  print (read "5 `Foo` 6" :: V)
  print (read (show (7 `Foo` 8)) == 7 `Foo` 8)
