{-# LANGUAGE PatternSynonyms #-}
module RecordSynonymA where
data PData = PData Int [Int] deriving Show
data Defn = PrimitiveDefn PData | Other deriving Show
pattern Primitive
  :: Int
  -> [Int]
  -> Defn
pattern Primitive
  { primName
  , primClauses
  } = PrimitiveDefn (PData
    primName
    primClauses
  )
