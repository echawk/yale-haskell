module PreludeTuple where

{-#Prelude#-}  -- Indicates definitions of compiler prelude symbols

import PreludeTuplePrims

-- This module contains support routines which handle tuple instances.
-- These are based on a implementation level data type which represents
-- general tuples and a data type to hold the set of dictionaries which
-- are associated with the tuple.

-- Each of these functions takes the tupledicts as the first argument.
-- Force all of these functions to take strict arguments because they'll
-- never be called with 0-length tuples anyway.

-- The following primitives operate on tuples.  

--  tupleSize :: TupleDicts -> Int
--  tupleSel :: Tuple -> Int -> Int -> a
--  dictSel :: TupleDicts -> method -> Int -> a
--  listToTuple :: [a] -> Tuple

-- Eq functions

tupleEq :: TupleDicts -> Tuple -> Tuple -> Bool
{-#  tupleEq :: Strictness("S,S,S") #-}
tupleEq dicts x y = tupleEq1 0 where
  tupleEq1 i | i == size = True
             | otherwise =
                  ((dictSel (cmpEq dicts i)) x' y') && tupleEq1 (i+1)
     where
        x' = tupleSel x i size
        y' = tupleSel y i size
  size = tupleSize dicts

cmpEq x y = x == y

tupleNeq dicts x y = not (tupleEq dicts x y)

-- Ord functions

tupleLe :: TupleDicts -> Tuple -> Tuple -> Bool
{-#  tupleLe :: Strictness("S,S,S") #-}
tupleLe dicts x y = tupleLe1 0 where
  tupleLe1 i | i == size = False
             | (dictSel (cmpLs dicts i)) x' y' = True
	     | (dictSel (ordEq dicts i)) x' y' = tupleLe1 (i+1)
	     | otherwise = False
      where
        x' = tupleSel x i size
        y' = tupleSel y i size
  size = tupleSize dicts

cmpLs x y = x < y

ordEq :: Ord a => a -> a -> Bool
ordEq x y = x == y

tupleLeq :: TupleDicts -> Tuple -> Tuple -> Bool
{-#  tupleLeq :: Strictness("S,S,S") #-}
tupleLeq dicts x y = tupleLeq1 0 where
  tupleLeq1 i | i == size = True
             | (dictSel (cmpLs dicts i)) x' y' = True
	     | (dictSel (ordEq dicts i)) x' y' = tupleLeq1 (i+1)
	     | otherwise = False
      where
        x' = tupleSel x i size
        y' = tupleSel y i size
  size = tupleSize dicts

tupleGe :: TupleDicts -> Tuple -> Tuple -> Bool
tupleGe d x y = tupleLe d y x

tupleGeq :: TupleDicts -> Tuple -> Tuple -> Bool
tupleGeq d x y = tupleLeq d y x

tupleMax,tupleMin :: TupleDicts -> Tuple -> Tuple -> Tuple
tupleMax d x y = if tupleGe d x y then x else y
tupleMin d x y = if tupleLe d x y then x else y

-- Ix functions

tupleRange :: TupleDicts -> (Tuple,Tuple) -> [Tuple]
{-#  tupleRange :: Strictness("S,S") #-}

tupleRange dicts (x,y) = map listToTuple (tupleRange' 0) where
  tupleRange' i | i == size = [[]]
                | otherwise =
                   [(i1 : i2) | i1 <- r, i2 <- tupleRange' (i+1)]
      where
        x' = tupleSel x i size
        y' = tupleSel y i size
        r = (dictSel (range' dicts i)) (x',y')
  size = tupleSize dicts

range' x = range x

tupleIndex :: TupleDicts -> (Tuple,Tuple) -> Tuple -> Int
{-#  tupleIndex :: Strictness("S,S,S") #-}

tupleIndex dicts (low,high) n = tupleIndex' (size-1) where
  size = tupleSize dicts
  tupleIndex' i | i == 0 = i'
                | otherwise = i' + r' * (tupleIndex' (i-1))
   where
    low' = tupleSel low i size
    high' = tupleSel high i size
    n' = tupleSel n i size
    i' = (dictSel (index' dicts i)) (low',high') n'
    r' = (dictSel (rangeSize' dicts i)) (low',high')

index' x = index x

rangeSize' x = rangeSize x

tupleRangeSize :: TupleDicts -> (Tuple,Tuple) -> Int
{-#  tupleRangeSize :: Strictness("S,S") #-}
tupleRangeSize dicts b@(l,h)
  | null (tupleRange dicts b) = 0
  | otherwise                 = tupleIndex dicts b h + 1

tupleInRange :: TupleDicts -> (Tuple,Tuple) -> Tuple -> Bool
{-#  tupleInRange :: Strictness("S,S,S") #-}
tupleInRange dicts (low,high) n = tupleInRange' 0 where
  size = tupleSize dicts
  tupleInRange' i | i == size = True
                  | otherwise = (dictSel (inRange' dicts i)) (low',high') n'
		                && tupleInRange' (i+1)
   where
    low' = tupleSel low i size
    high' = tupleSel high i size
    n' = tupleSel n i size
   
inRange' x = inRange x

-- Show and Read functions

tupleReadsPrec :: TupleDicts -> Int -> ReadS Tuple

tupleReadsPrec dicts p = readParen False
                          (\s -> map ( \ (t,w) -> (listToTuple t,w))
			             (tRP' s 0))
    where
      size = tupleSize dicts
      tRP' s i | i == 0 = [(t':t,w) |
                             ("(",s1) <- lex s,
                             (t',s2) <- nextItem s1,
                             (t,w) <- tRP' s2 (i+1)]
               | i == size = [([],w) | (")",w) <- lex s]
               | otherwise =
                        [(t':t,w) | 
                             (",",s1) <- lex s,
                             (t',s2) <- nextItem s1,
                             (t,w) <- tRP' s2 (i+1)]
       where
        nextItem s = (dictSel (reads dicts i)) s

tupleShowsPrec :: TupleDicts -> Int -> Tuple -> ShowS

tupleShowsPrec dicts p tuple =  
  showChar '(' . tSP' 0
    where
      size = tupleSize dicts
      tSP' i | i == (size-1) =
                 showTup . showChar ')'
             | otherwise =
                 showTup . showChar ',' . tSP' (i+1)
        where
          showTup = (dictSel (shows dicts i)) (tupleSel tuple i size)
                                    
tupleReadList :: TupleDicts -> ReadS [Tuple]

tupleReadList dicts =
                  readParen False (\r -> [pr | ("[",s)	<- lex r,
					       pr	<- readl s])
	          where readl  s = [([],t)   | ("]",t)  <- lex s] ++
				   [(x:xs,u) | (x,t)    <- tupleReads s,
					       (xs,u)   <- readl' t]
			readl' s = [([],t)   | ("]",t)  <- lex s] ++
			           [(x:xs,v) | (",",t)  <- lex s,
					       (x,u)	<- tupleReads t,
					       (xs,v)   <- readl' u]
                        tupleReads s = tupleReadsPrec dicts 0 s

tupleShowList :: TupleDicts -> [Tuple] -> ShowS

tupleShowList dicts [] = showString "[]"
tupleShowList dicts (x:xs)
		= showChar '[' . showsTuple x . showl xs
		  where showl []     = showChar ']'
			showl (x:xs) = showChar ',' . showsTuple x
			                               . showl xs
                        showsTuple x = tupleShowsPrec dicts 0 x

tupleShow :: TupleDicts -> Tuple -> String

tupleShow dicts x = tupleShowsPrec dicts 0 x ""

-- Ord: compare (the method added by H98)

tupleCompare :: TupleDicts -> Tuple -> Tuple -> Ordering
{-#  tupleCompare :: Strictness("S,S,S") #-}
tupleCompare dicts x y = tupleCompare1 0 where
  tupleCompare1 i | i == size = EQ
                  | otherwise =
                      case (dictSel (cmpCompare dicts i)) x' y' of
                        EQ -> tupleCompare1 (i+1)
                        r  -> r
      where
        x' = tupleSel x i size
        y' = tupleSel y i size
  size = tupleSize dicts

cmpCompare :: Ord a => a -> a -> Ordering
cmpCompare x y = compare x y

-- Bounded (H98)

tupleMinBound, tupleMaxBound :: TupleDicts -> Tuple
tupleMinBound dicts = listToTuple (tMin 0) where
  tMin i | i == size = []
         | otherwise = dictSel (minBound' dicts i) : tMin (i+1)
  size = tupleSize dicts
tupleMaxBound dicts = listToTuple (tMax 0) where
  tMax i | i == size = []
         | otherwise = dictSel (maxBound' dicts i) : tMax (i+1)
  size = tupleSize dicts

minBound', maxBound' :: Bounded a => a
minBound' = minBound
maxBound' = maxBound
