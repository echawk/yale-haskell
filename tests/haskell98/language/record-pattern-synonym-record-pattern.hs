-- A record pattern synonym whose pattern is a record pattern: its
-- selectors, and a use by position (Agda's CheckResult).
{-# LANGUAGE PatternSynonyms #-}
module Main where

data ModuleInfo = ModuleInfo { miInterface :: String, miWarnings :: [String], miPrim :: Bool, miMode :: Int }
data CheckResult = CheckResult' { crModuleInfo :: ModuleInfo, crSource' :: FilePath }

pattern CheckResult :: String -> [String] -> Int -> FilePath -> CheckResult
pattern CheckResult { crInterface, crWarnings, crMode, crSource } <- CheckResult'
  { crModuleInfo = ModuleInfo crInterface crWarnings _ crMode
  , crSource' = crSource
  }

main :: IO ()
main = do
  let r = CheckResult' (ModuleInfo "iface" ["w1", "w2"] False 3) "A.agda"
  putStrLn (crInterface r)
  print (crWarnings r, crMode r, crSource r)
  case r of
    CheckResult i _ m s -> putStrLn (i ++ " " ++ show m ++ " " ++ s)
