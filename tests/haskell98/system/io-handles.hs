-- IO: file handles, reading and writing, seeking, buffering, handle
-- state, and stdin (from io-handles.stdin).
module Main where

import Prelude hiding (stdin, stdout, stderr)
import IO
import Directory

file :: String
file = "/tmp/yale-haskell-io-handles-test.txt"

say :: String -> IO ()
say s = hPutStrLn stdout s

failing :: String -> IO a -> IO ()
failing what m =
  catch (m `thenIO_` say (what ++ ": no error"))
        (\e -> say (what ++ ": " ++ kind e))

kind :: IOError -> String
kind e | isEOFError e          = "eof"
       | isDoesNotExistError e = "doesNotExist"
       | isIllegalOperation e  = "illegalOperation"
       | isPermissionError e   = "permission"
       | otherwise             = "other error"

showBuffering :: BufferMode -> String
showBuffering NoBuffering        = "NoBuffering"
showBuffering LineBuffering      = "LineBuffering"
showBuffering (BlockBuffering n) = "BlockBuffering " ++ maybe "default" show n

-- (Shows a list of strings without depending on the Prelude's showList.)
showAll :: [String] -> String
showAll xs = concat (map (\x -> show x ++ ";") xs)

flags :: Handle -> IO String
flags h = hIsOpen h `thenIO` \o ->
          hIsClosed h `thenIO` \c ->
          returnIO ("open " ++ show o ++ ", closed " ++ show c)

main :: IO ()
main =
  -- writing truncates; appending adds
  openFile file WriteMode `thenIO` \h ->
  hPutStr h "first line\nsecond" `thenIO_`
  hPutChar h '!' `thenIO_`
  hPutStrLn h "" `thenIO_`
  hPrint h (42 :: Int) `thenIO_`
  hIsWritable h `thenIO` \w ->
  hIsReadable h `thenIO` \r ->
  say ("write handle: writable " ++ show w ++ ", readable " ++ show r) `thenIO_`
  hClose h `thenIO_`
  openFile file AppendMode `thenIO` \h2 ->
  hPutStr h2 "last, no newline" `thenIO_`
  hClose h2 `thenIO_`
  -- reading line by line
  openFile file ReadMode `thenIO` \h3 ->
  hFileSize h3 `thenIO` \size ->
  say ("size: " ++ show size) `thenIO_`
  hGetLine h3 `thenIO` \l1 ->
  hLookAhead h3 `thenIO` \c ->
  hGetChar h3 `thenIO` \c' ->
  hGetLine h3 `thenIO` \l2 ->
  hGetLine h3 `thenIO` \l3 ->
  hIsEOF h3 `thenIO` \eof1 ->
  hGetLine h3 `thenIO` \l4 ->
  hIsEOF h3 `thenIO` \eof2 ->
  say (showAll [l1, [c, c'], l2, l3, l4]) `thenIO_`
  say ("eof before/after last line: " ++ show (eof1, eof2)) `thenIO_`
  failing "hGetLine at end" (hGetLine h3) `thenIO_`
  failing "hGetChar at end" (hGetChar h3) `thenIO_`
  -- seeking
  hSeek h3 AbsoluteSeek 6 `thenIO_`
  hGetLine h3 `thenIO` \s1 ->
  hGetPosn h3 `thenIO` \p ->
  hSeek h3 RelativeSeek 3 `thenIO_`
  hGetLine h3 `thenIO` \s2 ->
  hSeek h3 SeekFromEnd (-4) `thenIO_`
  hGetLine h3 `thenIO` \s3 ->
  hSetPosn p `thenIO_`
  hGetLine h3 `thenIO` \s4 ->
  hIsSeekable h3 `thenIO` \sk ->
  say (showAll [s1, s2, s3, s4] ++ " seekable " ++ show sk) `thenIO_`
  failing "write to a read handle" (hPutStr h3 "x") `thenIO_`
  hClose h3 `thenIO_`
  flags h3 `thenIO` \fl ->
  say ("after hClose: " ++ fl) `thenIO_`
  hClose h3 `thenIO_`
  failing "read a closed handle" (hGetLine h3) `thenIO_`
  -- hGetContents is lazy and semi-closes the handle
  openFile file ReadMode `thenIO` \h4 ->
  hGetContents h4 `thenIO` \s ->
  flags h4 `thenIO` \fl1 ->
  say ("after hGetContents: " ++ fl1) `thenIO_`
  failing "hGetLine on a semi-closed handle" (hGetLine h4) `thenIO_`
  say ("lines: " ++ show (length (lines s)) ++ ", chars: " ++ show (length s)) `thenIO_`
  flags h4 `thenIO` \fl2 ->
  say ("after reading it all: " ++ fl2) `thenIO_`
  -- read/write mode keeps the contents
  openFile file ReadWriteMode `thenIO` \h5 ->
  hPutStr h5 "FIRST" `thenIO_`
  hSeek h5 AbsoluteSeek 0 `thenIO_`
  hGetLine h5 `thenIO` \rw ->
  say ("read/write: " ++ rw) `thenIO_`
  hClose h5 `thenIO_`
  -- buffering modes are remembered
  openFile file AppendMode `thenIO` \h6 ->
  hGetBuffering h6 `thenIO` \b0 ->
  hSetBuffering h6 NoBuffering `thenIO_`
  hGetBuffering h6 `thenIO` \b1 ->
  hSetBuffering h6 (BlockBuffering (Just 512)) `thenIO_`
  hGetBuffering h6 `thenIO` \b2 ->
  hFlush h6 `thenIO_`
  hClose h6 `thenIO_`
  say ("buffering: " ++ unwords (map showBuffering [b0, b1, b2])) `thenIO_`
  failing "open a directory" (openFile "/tmp" ReadMode) `thenIO_`
  -- handles compare and show
  say (show (stdin == stdin, stdin == stdout, h4 == h4)) `thenIO_`
  say (show stdout ++ " " ++ show stderr) `thenIO_`
  removeFile file `thenIO_`
  -- stdin
  isEOF `thenIO` \e ->
  say ("isEOF: " ++ show e) `thenIO_`
  hGetLine stdin `thenIO` \in1 ->
  hGetChar stdin `thenIO` \in2 ->
  hGetContents stdin `thenIO` \rest ->
  say ("stdin: " ++ show (in1, in2, rest)) `thenIO_`
  failing "isEOF after hGetContents stdin" isEOF `thenIO_`
  hPutStr stderr "to stderr\n" `thenIO_`
  hFlush stdout
