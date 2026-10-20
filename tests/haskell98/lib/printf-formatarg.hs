import Text.Printf
newtype Name = Name String
instance PrintfArg Name where
  formatArg (Name s) = formatString ("<" ++ s ++ ">")
main = do
  printf "%s|%8s|%-6s|%.3s|%d\n" (Name "ab") (Name "cd") (Name "e") (Name "fghij") (42 :: Int)
