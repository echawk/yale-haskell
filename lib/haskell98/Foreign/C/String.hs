-- Foreign.C.String: the Haskell 2010 library module (Report 2010, chapter
-- 29), for Yale Haskell's Haskell 98 dialect.  Strings are encoded as
-- UTF-8 (the "locale" encoding of the Report is taken to be UTF-8), so
-- the CAString functions, which use one byte per Char, differ only for
-- characters above '\255'.
module Foreign.C.String (
    CString, CStringLen,
    peekCString, peekCStringLen, newCString, newCStringLen,
    withCString, withCStringLen,
    castCharToCChar, castCCharToChar,
    peekCAString, peekCAStringLen, newCAString, newCAStringLen,
    withCAString, withCAStringLen,
    CWString, CWStringLen, peekCWString, peekCWStringLen, newCWString,
    newCWStringLen, withCWString, withCWStringLen,
    charIsRepresentable
  ) where

import Data.Int
import Data.Char (ord, chr)
import ForeignPrims
import PreludeIO (catch)
import Foreign.Ptr
import Foreign.Storable
import Foreign.C.Types
import Foreign.Marshal.Alloc
import Foreign.Marshal.Array

type CString    = Ptr CChar
type CStringLen = (Ptr CChar, Int)

peekCString :: CString -> IO String
peekCString = primPeekCString

peekCStringLen :: CStringLen -> IO String
peekCStringLen (p, n) = primPeekCStringLen p n

newCString :: String -> IO CString
newCString = primNewCString

newCStringLen :: String -> IO CStringLen
newCStringLen s = primNewCString s >>= \p -> return (p, primCStringLength s)

withCString :: String -> (CString -> IO a) -> IO a
withCString s f = do
  p <- primNewCString s
  r <- f p `catch` (\e -> primFree p >> ioError e)
  primFree p
  return r

withCStringLen :: String -> (CStringLen -> IO a) -> IO a
withCStringLen s f = withCString s (\p -> f (p, primCStringLength s))

castCharToCChar :: Char -> CChar
castCharToCChar c = fromIntegral (ord c)

castCCharToChar :: CChar -> Char
castCCharToChar c = chr (fromIntegral c `mod` 256)

-- One byte per character.
peekCAString :: CString -> IO String
peekCAString p = lengthArray0 0 p >>= \n -> peekCAStringLen (p, n)

peekCAStringLen :: CStringLen -> IO String
peekCAStringLen (p, n) = peekArray n p >>= return . map castCCharToChar

newCAString :: String -> IO CString
newCAString s = newArray0 0 (map castCharToCChar s)

newCAStringLen :: String -> IO CStringLen
newCAStringLen s = newArray (map castCharToCChar s) >>= \p -> return (p, length s)

withCAString :: String -> (CString -> IO a) -> IO a
withCAString s = withArray0 0 (map castCharToCChar s)

withCAStringLen :: String -> (CStringLen -> IO a) -> IO a
withCAStringLen s f = withArrayLen (map castCharToCChar s) (\n p -> f (p, n))

-- wchar_t is 32 bits (UTF-32) on the platforms SBCL runs on.
type CWString    = Ptr CWchar
type CWStringLen = (Ptr CWchar, Int)

peekCWString :: CWString -> IO String
peekCWString p = lengthArray0 0 p >>= \n -> peekCWStringLen (p, n)

peekCWStringLen :: CWStringLen -> IO String
peekCWStringLen (p, n) = peekArray n p >>= return . map (chr . fromIntegral)

newCWString :: String -> IO CWString
newCWString s = newArray0 0 (map (fromIntegral . ord) s)

newCWStringLen :: String -> IO CWStringLen
newCWStringLen s = newArray (map (fromIntegral . ord) s) >>= \p -> return (p, length s)

withCWString :: String -> (CWString -> IO a) -> IO a
withCWString s = withArray0 0 (map (fromIntegral . ord) s)

withCWStringLen :: String -> (CWStringLen -> IO a) -> IO a
withCWStringLen s f = withArrayLen (map (fromIntegral . ord) s) (\n p -> f (p, n))

charIsRepresentable :: Char -> IO Bool
charIsRepresentable _ = return True
