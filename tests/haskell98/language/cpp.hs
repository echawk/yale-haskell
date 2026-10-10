{-# LANGUAGE CPP #-}
-- The C preprocessor: #include, object- and function-like macros, #if
-- expressions with defined() and unknown names, #ifdef, literals left alone.
module Main where

#include "cpp-include.h"

#define TWICE(x) ((x) + (x))
#define NAME "macro-name"
#define FEATURE 3

#if defined(FEATURE) && FEATURE >= 2
feature :: String
feature = "feature on"
#elif FEATURE == 1
feature = "feature one"
#else
feature = "feature off"
#endif

#ifdef __GLASGOW_HASKELL__
compiler = "ghc"
#else
compiler = "not ghc"
#endif

#if MIN_VERSION_base(4,8,0)
base = "new base"
#else
base = "old base"
#endif

main :: IO ()
main = do
  putStrLn greeting
  print (TWICE(21) :: Int)
  putStrLn NAME
  putStrLn "NAME stays in strings, and TWICE(1) too"
  putStrLn feature
  putStrLn compiler
  putStrLn base
  print (length [x' | x' <- "it's"])
