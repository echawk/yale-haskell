-- Multi-parameter constraints generalized for local and mutually recursive
-- bindings without signatures.
module Main where
class TM tm t | tm -> t where
  next :: tm -> (t, tm)
  left :: tm -> Int
newtype S = S String
instance TM S Char where
  next (S (c:cs)) = (c, S cs)
  left (S s) = length s

takeWhileTM :: TM tm t => (t -> Bool) -> tm -> ([t], tm)
takeWhileTM f = loop []
  where loop res acs
          | left acs == 0 = (reverse res, acs)
          | otherwise = case next acs of
              (c, cs) | f c -> loop (c:res) cs
                      | otherwise -> (reverse res, acs)

-- unsigned and mutually recursive
countA s = if left s == 0 then 0 else case next s of (_, r) -> 1 + countB r
countB s = if left s == 0 then 0 else case next s of (_, r) -> countA r

main :: IO ()
main = do
  print (fst (takeWhileTM (/= ' ') (S "hello world")))
  print (countA (S "abcde"))
