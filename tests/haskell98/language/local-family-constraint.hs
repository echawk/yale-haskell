{-# LANGUAGE GADTs, TypeFamilies, OverloadedStrings #-}
module Main (main) where
import qualified Data.Map as Map
import qualified GHC.Exts as E

data Info = Info { a :: Map.Map Int [Int], b :: Map.Map Char [Char] }

class Render t where
  render :: t -> [String]

instance Render Info where
 render i = [prRen "a" (a i), prRen "b" (b i)]
   where
    prRen s r = unwords (s : map pr xs)
      where
        xs = [ (k, v) | (k, vs) <- Map.toList r, v <- E.toList vs ]
    pr (x, y) = show x ++ "->" ++ show y

main :: IO ()
main = mapM_ putStrLn (render (Info (Map.fromList [(1, [2])]) (Map.fromList [('c', "d")])))
