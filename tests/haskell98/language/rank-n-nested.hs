{-# LANGUAGE RankNTypes #-}
-- Polytypes inside polytypes, lambdas given for polytype arguments, and
-- f $ x with a polytype argument (profunctors' Copastro, Bazaar).
module Main where

-- a nested polytype that mentions the outer one's variable
newtype Co p a b = Co { runCo :: forall r. (forall x y. p x y -> r x y) -> r a b }

newtype Fn a b = Fn { appFn :: a -> b }

-- a lambda's argument used at two types
newtype Both = Both ((forall x. x -> [x]) -> (String, [Bool]))

-- a polytype with a context, given through $
newtype Wrap a = Wrap { unWrap :: forall r. Num r => r -> (a, r) }

-- a context and a nested polytype
newtype Ctx a = Ctx (forall r. Num r => (forall x. x -> x) -> r -> (a, r))

co :: p a b -> Co p a b
co p = Co $ \n -> n p

both :: Both
both = Both $ \n -> (n 'c', n True)

wrap :: a -> Wrap a
wrap a = Wrap $ \r -> (a, r + 1)

ctx :: a -> Ctx a
ctx a = Ctx (\n r -> (n a, n r + 1))

main :: IO ()
main = do
  print (appFn (runCo (co (Fn (+ 1))) (\(Fn f) -> Fn (f . f))) (40 :: Int))
  case both of Both f -> print (f (\x -> [x, x]))
  print (unWrap (wrap 'w') (3 :: Int))
  print (unWrap (wrap 'w') 2.5)
  case ctx 'c' of Ctx f -> print (f id (3 :: Int))
