-- Character and string escapes (Haskell 98 section 2.6): named
-- escapes, decimal codes, control characters, \& and string gaps,
-- checked by comparing characters so the output stays printable.
module Main where

out :: String
out = unlines [ show ('\65' == 'A', "\66\67" == "BC", '\'' == '\39', '"' == '\34')
              , show ('\n' == '\10', '\t' == '\9', '\\' == '\92')
              , show ('\NUL' == '\0', '\SOH' == '\1', '\DEL' == '\127', '\ESC' == '\27')
              , show ('\^A' == '\SOH', '\^Z' == '\26', '\^@' == '\NUL')
              , show (length "\SO\&H", length "a\&b", "\12\&3" == ['\12', '3'])
              , "string \
                \gap" ]

main = appendChan stdout out abort done
