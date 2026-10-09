-- take is as lazy as the Report's definition: take 0 xs never looks at
-- xs, and take n stops after the nth element without demanding the
-- list beyond it.
main :: IO ()
main = do
  print (take 0 (undefined :: [Int]))
  print (take 3 (1 : 2 : 3 : undefined :: [Int]))
  print (take 2 [1 ..])
  print (length (take 5 (nubish [1, 2, 3, 4, 5] ++ undefined)))
  print (take 4 (cycle "ab"))
  where nubish xs = xs
