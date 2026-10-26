-- A statement that begins with a skipped pragma ({-# SCC f #-} stmt,
-- commonmark's) is at the pragma's column for the layout.
main = do
  x <- return 3
  {-# SCC foo #-} print x
  let y = {-# SCC "bar" #-} x + 1
  print y
