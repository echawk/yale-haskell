-- Data.Typeable (base): run-time type representations.  Every type
-- constructor is Typeable without an instance, as in GHC: the type
-- checker makes the dictionary for T t1 .. tn from T's name and the ti's
-- dictionaries (util/instance-manager.mumble's get-typeable-instance;
-- the representation is built by prim.typeable-dict in base-runtime.lisp).
-- deriving Typeable is accepted and does nothing; instances cannot be
-- written.  Type constructors are represented by their unqualified
-- names, so two types of one name from different modules are equal here.
module Data.Typeable (
    Typeable(primTypeRepOf), TypeRep, TyCon, Proxy(Proxy),
    typeOf, typeRep, cast, gcast, gcast1, gcast2, eqTypeRep,
    typeRepTyCon, typeRepArgs, splitTyConApp, funResultTy, tyConName,
    showsTypeRep, rnfTypeRep, primTypeableDict
  ) where

import Data.Proxy (Proxy(Proxy))
import Unsafe.Coerce (unsafeCoerce)
import BasePrims (TypeRepObj, primTypeRepName, primTypeRepArity, primTypeRepArg,
                  primTypeableDict)

class Typeable a where
  primTypeRepOf :: Proxy a -> TypeRepObj

data TypeRep = TypeRep TyCon [TypeRep] deriving (Eq, Ord)

newtype TyCon = TyCon String deriving (Eq, Ord)

instance Show TyCon where
  showsPrec _ (TyCon n) = showString n

tyConName :: TyCon -> String
tyConName (TyCon n) = n

fromObj :: TypeRepObj -> TypeRep
fromObj o = TypeRep (TyCon (primTypeRepName o))
                    [fromObj (primTypeRepArg o i) | i <- [0 .. primTypeRepArity o - 1]]

typeRep :: Typeable a => proxy a -> TypeRep
typeRep p = fromObj (primTypeRepOf (reproxy p))
  where reproxy :: proxy a -> Proxy a
        reproxy _ = Proxy

typeOf :: Typeable a => a -> TypeRep
typeOf x = fromObj (primTypeRepOf (proxyOf x))
  where proxyOf :: a -> Proxy a
        proxyOf _ = Proxy

eqTypeRep :: TypeRep -> TypeRep -> Bool
eqTypeRep = (==)

cast :: (Typeable a, Typeable b) => a -> Maybe b
cast x = r
  where r = if typeOf x == typeOf (unJust r) then Just (unsafeCoerce x) else Nothing
        unJust :: Maybe b -> b
        unJust _ = undefined

gcast :: (Typeable a, Typeable b) => c a -> Maybe (c b)
gcast x = r
  where r = if typeRep (arg x) == typeRep (arg (unJust r))
              then Just (unsafeCoerce x) else Nothing
        arg :: c x -> Proxy x
        arg _ = Proxy
        unJust :: Maybe y -> y
        unJust _ = undefined

-- a cast of a type constructor's application: t to t' under c
gcast1 :: (Typeable t, Typeable t') => c (t a) -> Maybe (c (t' a))
gcast1 x = r
  where r = if typeRep (arg x) == typeRep (arg (unJust r))
              then Just (unsafeCoerce x) else Nothing
        arg :: c (t a) -> Proxy t
        arg _ = Proxy
        unJust :: Maybe y -> y
        unJust _ = undefined

gcast2 :: (Typeable t, Typeable t') => c (t a b) -> Maybe (c (t' a b))
gcast2 x = r
  where r = if typeRep (arg x) == typeRep (arg (unJust r))
              then Just (unsafeCoerce x) else Nothing
        arg :: c (t a b) -> Proxy t
        arg _ = Proxy
        unJust :: Maybe y -> y
        unJust _ = undefined

typeRepTyCon :: TypeRep -> TyCon
typeRepTyCon (TypeRep c _) = c

typeRepArgs :: TypeRep -> [TypeRep]
typeRepArgs (TypeRep _ as) = as

splitTyConApp :: TypeRep -> (TyCon, [TypeRep])
splitTyConApp (TypeRep c as) = (c, as)

funResultTy :: TypeRep -> TypeRep -> Maybe TypeRep
funResultTy (TypeRep (TyCon "->") [a, r]) b | a == b = Just r
funResultTy _ _ = Nothing

rnfTypeRep :: TypeRep -> ()
rnfTypeRep (TypeRep (TyCon n) as) = length n `seq` foldr seq () (map rnfTypeRep as)

-- GHC's format: Maybe [Char], Int -> Int, (Int,Bool), Either Int (Maybe Int)
instance Show TypeRep where
  showsPrec = showsTypeRepPrec

showsTypeRep :: TypeRep -> ShowS
showsTypeRep = shows

showsTypeRepPrec :: Int -> TypeRep -> ShowS
showsTypeRepPrec d (TypeRep (TyCon n) as) = case (n, as) of
  ("[]", [a]) -> showChar '[' . showsTypeRepPrec 0 a . showChar ']'
  ("->", [a, r]) -> showParen (d > 8) (showsTypeRepPrec 9 a . showString " -> "
                                       . showsTypeRepPrec 8 r)
  ('(' : ',' : _, _) | length as == length n - 1 ->
      showChar '(' . commas (map (showsTypeRepPrec 0) as) . showChar ')'
  (_, []) -> showString n
  _ -> showParen (d > 9) (showString n . foldr (\a s -> showChar ' ' . showsTypeRepPrec 10 a . s) id as)
  where commas [] = id
        commas [s] = s
        commas (s : ss) = s . showChar ',' . commas ss
