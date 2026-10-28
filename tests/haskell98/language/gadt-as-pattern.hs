-- An as-pattern over a GADT constructor: its variable has the
-- constructor's refined type (Hoopl's frontBiasBlock: b@BNil{} -> fb b).
{-# LANGUAGE GADTs #-}
data O
data C

data Block e x where
  BlockCO :: Int -> Block O O -> Block C O
  BNil    :: Block O O
  BCons   :: Int -> Block O O -> Block O O

f1 :: Block e x -> Block e x
f1 blk = case blk of
  BlockCO i b -> BlockCO i (fb b)
  BNil -> fb BNil
  BCons n b -> fb (BCons n b)
 where
  fb :: Block O O -> Block O O
  fb b = b

f2 :: Block e x -> Block e x
f2 blk = case blk of
  BlockCO i b -> BlockCO i (fb b)
  b@BNil{} -> fb b
  b@BCons{} -> fb b
 where
  fb :: Block O O -> Block O O
  fb b = b

f3 :: Block e x -> Block e x
f3 blk = case blk of
  b@BNil -> b
  b@(BCons _ _) -> BCons 0 b
  b -> b

size :: Block e x -> Int
size (BlockCO _ b) = 1 + size b
size BNil = 0
size (BCons _ b) = 1 + size b

main = print (size (f1 (BlockCO 1 (BCons 2 BNil))), size (f2 (BCons 3 BNil)), size (f3 (BCons 3 BNil)))
