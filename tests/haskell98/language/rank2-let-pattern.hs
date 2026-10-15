{-# LANGUAGE RankNTypes #-}
-- A let pattern binding of a polytype field (Hugs's ReadP's >>=).
newtype C a = C (forall r. (a -> r) -> r)
bindC :: C a -> (a -> C b) -> C b
bindC (C m) f = C (\k -> m (\a -> let C m' = f a in m' k))
runC :: C a -> a
runC (C m) = m id
main = print (runC (C (\k -> k 20) `bindC` \x -> C (\k -> k (x + 1))), runC (C ($ "s")))
