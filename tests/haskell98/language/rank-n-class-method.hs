{-# LANGUAGE RankNTypes #-}
-- A class method with a rank-n argument (comonad's ComonadHoist cohoist)
newtype Id a = Id a
newtype T w a = T (w a)

class Hoist t where
  cohoist :: (Functor w, Functor v) => (forall x. w x -> v x) -> t w a -> t v a

instance Hoist T where
  cohoist f (T w) = T (f w)

unT :: T w a -> w a
unT (T w) = w

main :: IO ()
main = print (unT (cohoist (\(Just x) -> [x]) (T (Just 'a'))))
