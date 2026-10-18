{-# LANGUAGE DeriveDataTypeable, DeriveLift #-}
-- (Global names keep the module that defines them in Yale Haskell:
-- PreludeCore.Just where GHC has GHC.Internal.Maybe.Just.)
-- Template Haskell's library without splices: building syntax with the
-- Lib functions, printing it (pprint, show), Lift and liftData, names.
import Language.Haskell.TH
import Language.Haskell.TH.Syntax
import Data.Data (Data)

data Color = Red | Rgb Int Int Int deriving (Show, Data, Lift)
data P = P { px :: Int, py :: Maybe String } deriving (Show, Data, Lift)

main :: IO ()
main = do
  -- declarations
  ds <- runQ (sequence
    [ dataD (cxt []) (mkName "T") [PlainTV (mkName "a") BndrReq] Nothing
        [normalC (mkName "A") [bangType (bang noSourceUnpackedness noSourceStrictness) (varT (mkName "a"))],
         recC (mkName "B") [varBangType (mkName "unB") (bangType (bang noSourceUnpackedness sourceStrict) (conT (mkName "Int")))]]
        [derivClause Nothing [conT (mkName "Show")]]
    , sigD (mkName "swap") (forallT [PlainTV (mkName "a") SpecifiedSpec, PlainTV (mkName "b") SpecifiedSpec] (cxt [])
        (appT (appT arrowT (appT (appT (tupleT 2) (varT (mkName "a"))) (varT (mkName "b"))))
              (appT (appT (tupleT 2) (varT (mkName "b"))) (varT (mkName "a")))))
    , funD (mkName "swap") [clause [tupP [varP (mkName "x"), varP (mkName "y")]]
                               (normalB (tupE [varE (mkName "y"), varE (mkName "x")])) []]
    , valD (varP (mkName "n")) (guardedB [normalGE (conE (mkName "True")) (infixE (Just (litE (integerL 1))) (varE (mkName "+")) (Just (litE (integerL 2))))]) []
    ])
  mapM_ (putStrLn . pprint) ds
  -- expressions
  e <- runQ (lamE [varP (mkName "xs")]
              (caseE (varE (mkName "xs"))
                 [match (conP (mkName "[]") []) (normalB (conE (mkName "Nothing"))) [],
                  match (infixP (varP (mkName "y")) (mkName ":") wildP)
                        (normalB (appE (conE (mkName "Just"))
                                       (infixE (Just (varE (mkName "y"))) (varE (mkName "*")) (Just (litE (integerL 2)))))) []]))
  putStrLn (pprint e)
  le <- runQ (letE [valD (varP (mkName "z")) (normalB (litE (integerL 5))) []]
                   (condE (infixE (Just (varE (mkName "z"))) (varE (mkName ">")) (Just (litE (integerL 3)))) (litE (stringL "big")) (litE (charL 's'))))
  putStrLn (pprint le)
  -- Lift: derived and base instances
  mapM_ (\x -> runQ x >>= putStrLn . pprint)
    [ lift (Rgb 1 2 3), lift [Red], lift (P 3 (Just "q")), lift ('c', 2.5 :: Double, ())
    , lift (Left 3 :: Either Int Bool), liftString "hi" ]
  -- liftData, through Data
  ld <- runQ (liftData (P 1 Nothing))
  putStrLn (pprint ld)
  -- names
  n1 <- runQ (newName "v")
  n2 <- runQ (newName "v")
  print (n1 == n2, nameBase n1, mkName "Data.Map.insert", nameModule (mkName "Data.Map.insert"))
  print (tupleDataName 3, tupleTypeName 2, showName' Applied (mkName "+"))
