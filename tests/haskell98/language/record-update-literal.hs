{-# LANGUAGE GeneralizedNewtypeDeriving #-}
module Main where
newtype Offset = O Int deriving (Eq, Ord, Num, Show)
data E r = Const { offset :: Offset } | Rigid { rigid :: r, offset :: Offset } | Flex { flex :: r, offset :: Offset } deriving Show
f :: E r -> Maybe (E r)
f c = do
  case c of
    a@Flex{} -> return (a { offset = 0 })
    _ -> Nothing
main = print (f (Flex 'x' 3 :: E Char))
