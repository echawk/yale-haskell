-- A one-parameter class instance with a multi-parameter context.
module Main where
class TM tm t | tm -> t where
  next :: tm -> Maybe (t, tm)
newtype P tm t a = P (tm -> [(a, tm)])
run :: P tm t a -> tm -> [(a, tm)]
run (P p) = p
class Fails f where
  failWith :: String -> f a
instance TM tm t => Fails (P tm t) where
  failWith _ = P (\ s -> case next s of
                           Nothing -> []
                           Just _ -> [])
item :: TM tm t => P tm t t
item = P (\ s -> case next s of
                   Nothing -> []
                   Just (c, s') -> [(c, s')])
newtype S = S String
instance TM S Char where
  next (S (c:cs)) = Just (c, S cs)
  next (S []) = Nothing
orFail :: Fails f => Bool -> f a -> f a
orFail b p = if b then p else failWith "no"
main :: IO ()
main = do
  print (map fst (run item (S "xy")))
  print (length (run (orFail False item) (S "xy")), map fst (run (orFail True item) (S "z")))
