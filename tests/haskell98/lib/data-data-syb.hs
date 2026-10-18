{-# LANGUAGE RankNTypes, ScopedTypeVariables #-}
-- Data.Data: hand-written instances, SYB's everywhere and everything
import Data.Data

data T = A Int Bool | B [Int] | C deriving Show

tConstrs :: [Constr]
tConstrs = [aC, bC, cC]
aC, bC, cC :: Constr
aC = mkConstr tDT "A" [] Prefix
bC = mkConstr tDT "B" [] Prefix
cC = mkConstr tDT "C" [] Prefix
tDT :: DataType
tDT = mkDataType "Main.T" tConstrs

instance Data T where
  gfoldl k z (A i b) = z A `k` i `k` b
  gfoldl k z (B is) = z B `k` is
  gfoldl _ z C = z C
  gunfold k z c = case constrIndex c of
    1 -> k (k (z A))
    2 -> k (z B)
    _ -> z C
  toConstr (A _ _) = aC
  toConstr (B _) = bC
  toConstr C = cC
  dataTypeOf _ = tDT

-- everywhere: bottom-up transformation
everywhere :: (forall a. Data a => a -> a) -> (forall a. Data a => a -> a)
everywhere f = go where
  go :: forall a. Data a => a -> a
  go = f . gmapT go

mkT :: (Typeable a, Typeable b) => (b -> b) -> a -> a
mkT f = case cast f of
  Just g -> g
  Nothing -> id

-- everything: a query over all subterms
everything :: forall r. (r -> r -> r) -> (forall a. Data a => a -> r) -> (forall a. Data a => a -> r)
everything k f = go where
  go :: forall a. Data a => a -> r
  go x = foldl k (f x) (gmapQ go x)

mkQ :: (Typeable a, Typeable b) => r -> (b -> r) -> a -> r
mkQ r q a = case cast a of
  Just b -> q b
  Nothing -> r

main :: IO ()
main = do
  let v = [A 1 True, B [2, 3], C]
  print (everywhere (mkT ((+ 1) :: Int -> Int)) v)
  print (everything (+) (mkQ 0 (id :: Int -> Int)) v)
  print (map toConstr v, map (constrIndex . toConstr) v)
  print (dataTypeOf (A 1 True), dataTypeName (dataTypeOf C))
  print (toConstr (3 :: Int), toConstr 'x', toConstr (Just ()), toConstr [()], toConstr (1.5 :: Double))
  print (fromConstr cC :: T, (fromConstrB (fromConstr (toConstr (7 :: Int))) aC :: T) `seq` ())
  print (gmapQ (const ()) (A 1 False), gmapQi 1 (mkQ False not) (A 1 False))
  print (readConstr tDT "B", maxConstrIndex tDT, isAlgType (dataTypeOf 'c'))
  print (tyconUQname "Data.Map.Map", tyconModule "Data.Map.Map")
  print (gmapM (\d -> Just d) (A 3 True))
