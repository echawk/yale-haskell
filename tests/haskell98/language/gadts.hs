-- GADTs and DataKinds: constructors with refined result types, matched
-- in clauses and case expressions; existential constructors with a
-- context; length-indexed vectors.
{-# LANGUAGE GADTs, DataKinds, KindSignatures, RankNTypes #-}

data Expr a where
  IntE  :: Int -> Expr Int
  BoolE :: Bool -> Expr Bool
  Add   :: Expr Int -> Expr Int -> Expr Int
  Mul   :: Expr Int -> Expr Int -> Expr Int
  If    :: Expr Bool -> Expr a -> Expr a -> Expr a
  Eq    :: Expr Int -> Expr Int -> Expr Bool
  Pair  :: Expr a -> Expr b -> Expr (a, b)
  Fst   :: Expr (a, b) -> Expr a
  Neg   :: Expr Int -> Expr Int

eval :: Expr a -> a
eval (IntE n) = n
eval (BoolE b) = b
eval (Add a b) = eval a + eval b
eval (Mul a b) = eval a * eval b
eval (If c t e) = if eval c then eval t else eval e
eval (Eq a b) = eval a == eval b
eval (Pair a b) = (eval a, eval b)
eval (Fst p) = fst (eval p)
eval (Neg e) = negate (eval e)

size :: Expr a -> Int
size e = case e of
  IntE _ -> 1
  BoolE _ -> 1
  Add a b -> 1 + size a + size b
  Mul a b -> 1 + size a + size b
  If c t f -> 1 + size c + size t + size f
  Eq a b -> 1 + size a + size b
  Pair a b -> 1 + size a + size b
  Fst p -> 1 + size p
  Neg a -> 1 + size a

-- an existential constructor with a context, in GADT syntax
data Showable where
  MkShowable :: Show a => a -> Showable

instance Show Showable where
  show (MkShowable x) = show x

-- a GADT that is an ordinary type
data Box a where
  Box :: a -> Box a

unbox :: Box a -> a
unbox (Box x) = x

data Nat = Z | S Nat

data Vec (n :: Nat) a where
  VNil  :: Vec 'Z a
  VCons :: a -> Vec n a -> Vec ('S n) a

vhead :: Vec ('S n) a -> a
vhead (VCons x _) = x

vtail :: Vec ('S n) a -> Vec n a
vtail (VCons _ xs) = xs

vmap :: (a -> b) -> Vec n a -> Vec n b
vmap _ VNil = VNil
vmap f (VCons x xs) = VCons (f x) (vmap f xs)

vzip :: Vec n a -> Vec n b -> Vec n (a, b)
vzip VNil VNil = VNil
vzip (VCons x xs) (VCons y ys) = VCons (x, y) (vzip xs ys)

vtoList :: Vec n a -> [a]
vtoList VNil = []
vtoList (VCons x xs) = x : vtoList xs

main :: IO ()
main = do
  let e = If (Eq (IntE 2) (Add (IntE 1) (IntE 1))) (Mul (IntE 6) (IntE 7)) (IntE 0)
  print (eval e, size e)
  print (eval (Pair (BoolE True) (Neg (IntE 5))), eval (Fst (Pair (IntE 9) (BoolE False))))
  print [MkShowable (1 :: Int), MkShowable "two", MkShowable (Just True)]
  print (unbox (Box 'x'))
  let v = VCons 1 (VCons 2 (VCons (3 :: Int) VNil))
  print (vhead v, vhead (vtail v), vtoList (vmap (* 10) v))
  print (vtoList (vzip v (vmap show v)))
