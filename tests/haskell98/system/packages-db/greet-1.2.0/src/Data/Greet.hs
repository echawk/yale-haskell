module Data.Greet (greet, greetVersion) where
#include "greet.h"
greet :: String -> String
greet n = GREETING ++ ", " ++ n ++ bang
  where bang = (\case { _ -> "!" }) ()
greetVersion :: String
#if MIN_VERSION_greet(1,1,0)
greetVersion = "new " ++ PKGTAG
#else
greetVersion = "old"
#endif
