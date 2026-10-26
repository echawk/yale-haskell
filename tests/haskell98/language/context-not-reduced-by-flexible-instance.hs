-- A context at a type is not reduced through a flexible instance at
-- another head (doctemplates' TemplateTarget [a] => .., HasChars [a]
-- beside instance HasChars [Char]).
{-# LANGUAGE FlexibleInstances, FlexibleContexts, MultiParamTypeClasses, UndecidableInstances, ConstraintKinds #-}
class HasChars a where
  lit :: a -> [a]
instance HasChars [Char] where
  lit s = [s]
type TT a = (HasChars a, Show a)
class TC a b where
  toVal :: b -> [a]
instance {-# OVERLAPPING #-} TT [a] => TC [a] [a] where
  toVal = lit
main = print (toVal "ab" :: [String])
