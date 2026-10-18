{-# LANGUAGE TemplateHaskell #-}
-- TemplateHaskell's quoted names: 'f, 'C, '(op), ''T, built-in syntax.
-- (Yale Haskell's names keep its own modules: PreludeCore.Just.)
import Language.Haskell.TH
import qualified Data.Map as M

data T a = MkT a | a :+: Int
class C a where cm :: a -> Int
f :: Int -> Int
f = (+ 1)

main :: IO ()
main = do
  print ['f, 'map, 'M.insert, '(+), 'MkT, '(:+:), 'Just, 'True, '(:), '[], '(), '(,), '(,,)]
  print [''T, ''C, ''Maybe, ''Int, ''[], ''(), ''(,), ''M.Map, ''Show]
  print ('cm, nameBase 'f, nameModule ''Maybe, 'c', '\n', ''T == ''T, 'f == 'map)
