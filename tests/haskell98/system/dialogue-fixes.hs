-- Runtime fixes seen through the Prelude's Dialogue functions (these
-- are the Haskell 1.2 requests; update this test when the Prelude
-- drops them):
--   * writeFile truncates an existing, longer file;
--   * getEnv of an unset variable calls the failure continuation.
module Main where

file :: String
file = "/tmp/yale-haskell-dialogue-fixes.txt"

main =
  writeFile file "a long first line\n" exit
  (writeFile file "short\n" exit
  (readFile file exit (\s ->
   appendChan stdout ("contents: " ++ s) exit
  (deleteFile file exit
  (getEnv "YALE_HASKELL_SURELY_UNSET_VARIABLE"
     (\e -> appendChan stdout "unset: failure continuation\n" exit done)
     (\v -> appendChan stdout ("unset: got " ++ v ++ "\n") exit done))))))
