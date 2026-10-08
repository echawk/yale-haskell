-- An omitted (non-strict) field is bottom: selecting it is a runtime
-- error after the output before it.
data T = T { a :: Int, b :: Int }

main = do
  let t = T { a = 1 }
  print (a t)
  print (b t)
