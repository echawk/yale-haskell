-- The Haskell 98 Prelude exports only Haskell 98 names: Haskell 1.2's
-- Dialogue I/O (appendChan, stdin, done, exit, ...) is in the Dialogue
-- library, the character functions in Char.  So a program may define
-- those names, and IO's stdout/stderr are Handles.
import IO (hPutStrLn, stdout)

appendChan :: Int
appendChan = 1
stdin, exit, done, abort :: Int
stdin = 2
exit = 3
done = 4
abort = 5
isSpace :: Char -> Bool
isSpace c = c == '_'

main :: IO ()
main = do
  print (appendChan + stdin + exit + done + abort)
  print (filter isSpace "a_b c")
  hPutStrLn stdout "IO's stdout is a Handle"
