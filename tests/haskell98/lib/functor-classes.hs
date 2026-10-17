-- Data.Functor.Classes: Eq1/Ord1/Show1/Read1 and the binary classes.
import Data.Functor.Classes
import Data.Functor.Identity

newtype Fix f = Fix (f (Fix f))
instance Show1 f => Show (Fix f) where
  showsPrec d (Fix f) = showParen (d > 10) (showString "Fix " . liftShowsPrec showsPrec showList 11 f)
instance Eq1 f => Eq (Fix f) where
  Fix a == Fix b = liftEq (==) a b

data ListF a r = Nil | Cons a r deriving (Show, Eq)
instance Show a => Show1 (ListF a) where
  liftShowsPrec _ _ _ Nil = showString "Nil"
  liftShowsPrec sp _ d (Cons a r) = showsBinaryWith showsPrec sp "Cons" d a r
instance Eq a => Eq1 (ListF a) where
  liftEq _ Nil Nil = True
  liftEq eq (Cons a r) (Cons b s) = a == b && eq r s
  liftEq _ _ _ = False

main = do
  let l = Fix (Cons 1 (Fix (Cons (2 :: Int) (Fix Nil))))
  print l
  print (l == l, eq1 (Just 'a') (Just 'b'), compare1 [1,2] [1,3 :: Int])
  print (showsPrec1 11 (Just (3 :: Int)) "", showsPrec1 0 (Identity 'x') "")
  print (fst (head (readsPrec1 0 "Just 5" :: [(Maybe Int, String)])))
  print (showsPrec2 0 (Left 3 :: Either Int Bool) "", eq2 (1 :: Int, 'a') (1, 'a'))
