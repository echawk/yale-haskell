-- System.Console.Haskeline.Completion (haskeline): the completion types
-- and functions, which System.Console.Haskeline defines here.
module System.Console.Haskeline.Completion (
    CompletionFunc, Completion(Completion, replacement, display, isFinished),
    completeWord, completeWord', completeWordWithPrev, completeQuotedWord,
    completeFilename, listFiles, noCompletion, simpleCompletion,
    fallbackCompletion, filenameWordBreakChars
  ) where

import System.Console.Haskeline
