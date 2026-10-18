-- deriving Read (and Eq, Ord, Show) for a field on an application of a
-- type variable (bifunctors' Flip): Read (p b a) in the derived helpers
newtype Flip p a b = Flip { runFlip :: p b a } deriving (Eq, Ord, Show, Read)
main :: IO ()
main = do
  print (Flip (1, 'a') == Flip (1, 'a'), Flip (Left 3 :: Either Int Char))
  print (read "Flip {runFlip = (1,'x')}" :: Flip (,) Char Int)
