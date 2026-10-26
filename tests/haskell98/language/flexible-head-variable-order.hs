-- A flexible instance's variables in the order its head first names them,
-- also when a later argument repeats them (lucid's With (HtmlT m a ->
-- HtmlT m a), whose Functor m was taken as Functor a).
{-# LANGUAGE FlexibleInstances #-}
newtype H m a = H (m a)
class With a where
  with :: a -> Int -> a
instance Functor m => With (H m a) where
  with (H x) _ = H (fmap id x)
instance Functor m => With (H m a -> H m a) where
  with f _ = \i -> case f i of H x -> H (fmap id x)
mk :: Applicative m => Int -> H m a -> H m a
mk n = with (\x -> x) n
main = case (mk 3 (H (Just (1::Int))) :: H Maybe Int) of H v -> print v
