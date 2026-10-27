-- Case branches on a GADT whose results are functions of different
-- arities through a type family (Agda's opP: \x y -> for In, \y -> for
-- Pre, a value for Non): the optimizer hoists no more arguments out of
-- the branches than each takes.
{-# LANGUAGE GADTs, DataKinds, KindSignatures, TypeFamilies #-}
import Data.Kind (Type)
data NotationKind = InfixNotation | PrefixNotation | PostfixNotation | NonfixNotation
type family OperatorType (k :: NotationKind) (e :: Type) :: Type
type instance OperatorType 'InfixNotation   e = Maybe e -> Maybe e -> e
type instance OperatorType 'PrefixNotation  e = Maybe e -> e
type instance OperatorType 'PostfixNotation e = Maybe e -> e
type instance OperatorType 'NonfixNotation  e = e
data NK (k :: NotationKind) :: Type where
  In   :: NK 'InfixNotation
  Pre  :: NK 'PrefixNotation
  Post :: NK 'PostfixNotation
  Non  :: NK 'NonfixNotation

opP :: String -> NK k -> Maybe (OperatorType k String)
opP name kind = fmap (\r ->
  let app f = name ++ "(" ++ concat (f []) ++ ")" ++ r
  in case kind of
       In   -> \x y -> app (\es -> sh x : es ++ [sh y])
       Pre  -> \  y -> app (\es -> es ++ [sh y])
       Post -> \x   -> app (\es -> sh x : es)
       Non  ->         app (\es -> es)) (Just "!")
  where sh = maybe "_" id

main = do
  print (fmap (\f -> f (Just "a") (Just "b")) (opP "plus" In))
  print (fmap (\f -> f (Just "a")) (opP "neg" Pre))
  print (fmap (\f -> f (Just "a")) (opP "fact" Post))
  print (opP "nil" Non)
