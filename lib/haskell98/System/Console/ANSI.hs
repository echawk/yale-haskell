-- System.Console.ANSI (ansi-terminal), a subset: Select Graphic Rendition
-- (colours, intensity, italics, underlining) and the common cursor and
-- screen sequences, as ECMA-48 escape codes.  Written for Yale Haskell
-- after ansi-terminal 1.0's API.
module System.Console.ANSI (
    Color(..), ColorIntensity(..), ConsoleLayer(..), ConsoleIntensity(..),
    Underlining(..), BlinkSpeed(..), SGR(..),
    setSGRCode, setSGR, hSetSGR, hSupportsANSI, hSupportsANSIColor,
    clearScreen, clearLine, hClearScreen, hClearLine,
    clearScreenCode, clearLineCode, setCursorPosition, hSetCursorPosition,
    setCursorPositionCode, cursorUp, cursorDown, cursorForward, cursorBackward,
    hideCursor, showCursor, hHideCursor, hShowCursor,
    getTerminalSize, hGetTerminalSize,
    hCursorUp, hCursorDown, hCursorForward, hCursorBackward,
    cursorUpCode, cursorDownCode, cursorForwardCode, cursorBackwardCode,
    cursorUpLine, cursorDownLine, hCursorUpLine, hCursorDownLine,
    cursorUpLineCode, cursorDownLineCode,
    setCursorColumn, hSetCursorColumn, setCursorColumnCode,
    clearFromCursorToScreenEnd, clearFromCursorToScreenBeginning,
    clearFromCursorToLineEnd, clearFromCursorToLineBeginning,
    hClearFromCursorToScreenEnd, hClearFromCursorToScreenBeginning,
    hClearFromCursorToLineEnd, hClearFromCursorToLineBeginning,
    clearFromCursorToScreenEndCode, clearFromCursorToScreenBeginningCode,
    clearFromCursorToLineEndCode, clearFromCursorToLineBeginningCode,
    saveCursor, restoreCursor, hSaveCursor, hRestoreCursor,
    scrollPageUp, scrollPageDown
  ) where

import System.IO (Handle, hPutStr, stdout, hIsTerminalDevice)
import Data.List (intercalate)

data Color = Black | Red | Green | Yellow | Blue | Magenta | Cyan | White
  deriving (Eq, Ord, Bounded, Enum, Show, Read)
data ColorIntensity = Dull | Vivid deriving (Eq, Ord, Bounded, Enum, Show, Read)
data ConsoleLayer = Foreground | Background deriving (Eq, Ord, Bounded, Enum, Show, Read)
data ConsoleIntensity = BoldIntensity | FaintIntensity | NormalIntensity
  deriving (Eq, Ord, Bounded, Enum, Show, Read)
data Underlining = SingleUnderline | DoubleUnderline | NoUnderline
  deriving (Eq, Ord, Bounded, Enum, Show, Read)
data BlinkSpeed = SlowBlink | RapidBlink | NoBlink deriving (Eq, Ord, Bounded, Enum, Show, Read)

data SGR = Reset
         | SetConsoleIntensity ConsoleIntensity
         | SetItalicized Bool
         | SetUnderlining Underlining
         | SetBlinkSpeed BlinkSpeed
         | SetVisible Bool
         | SetSwapForegroundBackground Bool
         | SetColor ConsoleLayer ColorIntensity Color
         | SetDefaultColor ConsoleLayer
  deriving (Eq, Show)

sgrCode :: SGR -> Int
sgrCode s = case s of
  Reset -> 0
  SetConsoleIntensity BoldIntensity -> 1
  SetConsoleIntensity FaintIntensity -> 2
  SetConsoleIntensity NormalIntensity -> 22
  SetItalicized b -> if b then 3 else 23
  SetUnderlining SingleUnderline -> 4
  SetUnderlining DoubleUnderline -> 21
  SetUnderlining NoUnderline -> 24
  SetBlinkSpeed SlowBlink -> 5
  SetBlinkSpeed RapidBlink -> 6
  SetBlinkSpeed NoBlink -> 25
  SetVisible b -> if b then 28 else 8
  SetSwapForegroundBackground b -> if b then 7 else 27
  SetColor layer intensity c ->
    fromEnum c + (case (layer, intensity) of
                    (Foreground, Dull) -> 30
                    (Background, Dull) -> 40
                    (Foreground, Vivid) -> 90
                    (Background, Vivid) -> 100)
  SetDefaultColor Foreground -> 39
  SetDefaultColor Background -> 49

csi :: [Int] -> String -> String
csi args code = "\ESC[" ++ intercalate ";" (map show args) ++ code

setSGRCode :: [SGR] -> String
setSGRCode sgrs = csi (map sgrCode sgrs) "m"

hSetSGR :: Handle -> [SGR] -> IO ()
hSetSGR h sgrs = hPutStr h (setSGRCode sgrs)

setSGR :: [SGR] -> IO ()
setSGR = hSetSGR stdout

hSupportsANSI, hSupportsANSIColor :: Handle -> IO Bool
hSupportsANSI = hIsTerminalDevice
hSupportsANSIColor = hIsTerminalDevice

clearScreenCode, clearLineCode :: String
clearScreenCode = csi [2] "J"
clearLineCode = csi [2] "K"

hClearScreen, hClearLine :: Handle -> IO ()
hClearScreen h = hPutStr h clearScreenCode
hClearLine h = hPutStr h clearLineCode

clearScreen, clearLine :: IO ()
clearScreen = hClearScreen stdout
clearLine = hClearLine stdout

setCursorPositionCode :: Int -> Int -> String
setCursorPositionCode row col = csi [row + 1, col + 1] "H"

hSetCursorPosition :: Handle -> Int -> Int -> IO ()
hSetCursorPosition h row col = hPutStr h (setCursorPositionCode row col)

setCursorPosition :: Int -> Int -> IO ()
setCursorPosition = hSetCursorPosition stdout

cursorUpCode, cursorDownCode, cursorForwardCode, cursorBackwardCode,
  cursorUpLineCode, cursorDownLineCode, setCursorColumnCode :: Int -> String
cursorUpCode n = csi [n] "A"
cursorDownCode n = csi [n] "B"
cursorForwardCode n = csi [n] "C"
cursorBackwardCode n = csi [n] "D"
cursorUpLineCode n = csi [n] "F"
cursorDownLineCode n = csi [n] "E"
setCursorColumnCode col = csi [col + 1] "G"

hCursorUp, hCursorDown, hCursorForward, hCursorBackward, hCursorUpLine,
  hCursorDownLine, hSetCursorColumn :: Handle -> Int -> IO ()
hCursorUp h = hPutStr h . cursorUpCode
hCursorDown h = hPutStr h . cursorDownCode
hCursorForward h = hPutStr h . cursorForwardCode
hCursorBackward h = hPutStr h . cursorBackwardCode
hCursorUpLine h = hPutStr h . cursorUpLineCode
hCursorDownLine h = hPutStr h . cursorDownLineCode
hSetCursorColumn h = hPutStr h . setCursorColumnCode

cursorUp, cursorDown, cursorForward, cursorBackward, cursorUpLine,
  cursorDownLine, setCursorColumn :: Int -> IO ()
cursorUp = hCursorUp stdout
cursorDown = hCursorDown stdout
cursorForward = hCursorForward stdout
cursorBackward = hCursorBackward stdout
cursorUpLine = hCursorUpLine stdout
cursorDownLine = hCursorDownLine stdout
setCursorColumn = hSetCursorColumn stdout

clearFromCursorToScreenEndCode, clearFromCursorToScreenBeginningCode,
  clearFromCursorToLineEndCode, clearFromCursorToLineBeginningCode :: String
clearFromCursorToScreenEndCode = csi [0] "J"
clearFromCursorToScreenBeginningCode = csi [1] "J"
clearFromCursorToLineEndCode = csi [0] "K"
clearFromCursorToLineBeginningCode = csi [1] "K"

hClearFromCursorToScreenEnd, hClearFromCursorToScreenBeginning,
  hClearFromCursorToLineEnd, hClearFromCursorToLineBeginning,
  hSaveCursor, hRestoreCursor :: Handle -> IO ()
hClearFromCursorToScreenEnd h = hPutStr h clearFromCursorToScreenEndCode
hClearFromCursorToScreenBeginning h = hPutStr h clearFromCursorToScreenBeginningCode
hClearFromCursorToLineEnd h = hPutStr h clearFromCursorToLineEndCode
hClearFromCursorToLineBeginning h = hPutStr h clearFromCursorToLineBeginningCode
hSaveCursor h = hPutStr h "\ESC7"
hRestoreCursor h = hPutStr h "\ESC8"

clearFromCursorToScreenEnd, clearFromCursorToScreenBeginning,
  clearFromCursorToLineEnd, clearFromCursorToLineBeginning,
  saveCursor, restoreCursor :: IO ()
clearFromCursorToScreenEnd = hClearFromCursorToScreenEnd stdout
clearFromCursorToScreenBeginning = hClearFromCursorToScreenBeginning stdout
clearFromCursorToLineEnd = hClearFromCursorToLineEnd stdout
clearFromCursorToLineBeginning = hClearFromCursorToLineBeginning stdout
saveCursor = hSaveCursor stdout
restoreCursor = hRestoreCursor stdout

scrollPageUp, scrollPageDown :: Int -> IO ()
scrollPageUp n = hPutStr stdout (csi [n] "S")
scrollPageDown n = hPutStr stdout (csi [n] "T")

hHideCursor, hShowCursor :: Handle -> IO ()
hHideCursor h = hPutStr h "\ESC[?25l"
hShowCursor h = hPutStr h "\ESC[?25h"

hideCursor, showCursor :: IO ()
hideCursor = hHideCursor stdout
showCursor = hShowCursor stdout

-- The terminal's (rows, columns), which this library does not ask the
-- terminal for: Nothing, as ansi-terminal answers when it cannot tell
-- (tasty's console reporter then uses its defaults)
getTerminalSize :: IO (Maybe (Int, Int))
getTerminalSize = return Nothing

hGetTerminalSize :: Handle -> IO (Maybe (Int, Int))
hGetTerminalSize _ = return Nothing
