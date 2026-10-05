module	PreludeText (
	reads, shows, show, read, lex,
	showChar, showString, readParen, showParen,
	readLitChar, showLitChar, lexLitChar ) where

{-#Prelude#-}  -- Indicates definitions of compiler prelude symbols

-- lex, lexLitChar and readLitChar follow the Haskell 98 Report
-- (report/PreludeText.hs and libraries/code/Char.hs; see the notice in
-- PreludeChar.hs).

import PreludeChar(isSpace, isAlpha, isDigit, isAlphaNum, isUpper,
		   isOctDigit, isHexDigit, ord, chr)
import PreludeNumeric(lexDigits, readDec, readOct, readHex)
import PreludeArray(listArray, (!), assocs)

reads 	        :: (Text a) => ReadS a
reads		=  readsPrec 0

shows 	    	:: (Text a) => a -> ShowS
shows		=  showsPrec 0

read 	    	:: (Text a) => String -> a
read s 	    	=  case [x | (x,t) <- reads s, ("","") <- lex t] of
			[x] -> x
			[]  -> error "read{PreludeText}: no parse"
			_   -> error "read{PreludeText}: ambiguous parse"

show 	    	:: (Text a) => a -> String
show x 	    	=  shows x ""

showChar    	:: Char -> ShowS
showChar    	=  (:)

showString  	:: String -> ShowS
showString  	=  (++)

showParen   	:: Bool -> ShowS -> ShowS
showParen b p 	=  if b then showChar '(' . p . showChar ')' else p

readParen   	:: Bool -> ReadS a -> ReadS a
readParen b g	=  if b then mandatory else optional
		   where optional r  = g r ++ mandatory r
			 mandatory r = [(x,u) | ("(",s) <- lex r,
						(x,t)   <- optional s,
						(")",u) <- lex t    ]

lex		 :: ReadS String
lex ""		 =  [("","")]
lex (c:s)
   | isSpace c	 =  lex (dropWhile isSpace s)
lex ('\'':s)	 =  [('\'':ch++"'", t) | (ch,'\'':t)  <- lexLitChar s,
					 ch /= "'" ]
lex ('"':s)	 =  [('"':str, t)      | (str,t) <- lexString s]
		    where
		    lexString ('"':s) = [("\"",s)]
		    lexString s = [(ch++str, u)
					 | (ch,t)  <- lexStrItem s,
					   (str,u) <- lexString t  ]

		    lexStrItem ('\\':'&':s) =  [("\\&",s)]
		    lexStrItem ('\\':c:s) | isSpace c
					   =  [("\\&",t) |
					       '\\':t <-
						   [dropWhile isSpace s]]
		    lexStrItem s	   =  lexLitChar s

lex (c:s) | isSingle c = [([c],s)]
	  | isSym c    = [(c:sym,t)	  | (sym,t) <- [span isSym s]]
	  | isAlpha c  = [(c:nam,t)	  | (nam,t) <- [span isIdChar s]]
	  | isDigit c  = [(c:ds++fe,t)	  | (ds,s)  <- [span isDigit s],
					    (fe,t)  <- lexFracExp s	]
	  | otherwise  = []    -- bad character
	     where
	      isSingle c =  c `elem` ",;()[]{}_`"
	      isSym c	 =  c `elem` "!@#$%&*+./<=>?\\^|:-~"
	      isIdChar c =  isAlphaNum c || c `elem` "_'"

	      lexFracExp ('.':c:cs) | isDigit c
			    = [('.':ds++e,u) | (ds,t) <- lexDigits (c:cs),
					       (e,u)  <- lexExp t]
	      lexFracExp s  = lexExp s

	      lexExp (e:s) | e `elem` "eE"
		       = [(e:c:ds,u) | (c:t)  <- [s], c `elem` "+-",
						 (ds,u) <- lexDigits t] ++
			 [(e:ds,t)   | (ds,t) <- lexDigits s]
	      lexExp s = [("",s)]

lexLitChar	    :: ReadS String
lexLitChar ('\\':s) =  map (prefix '\\') (lexEsc s)
	where
	  lexEsc (c:s)	   | c `elem` "abfnrtv\\\"'" = [([c],s)]
	  lexEsc ('^':c:s) | c >= '@' && c <= '_'    = [(['^',c],s)]

	  -- Numeric escapes
	  lexEsc ('o':s)	       = [prefix 'o' (span isOctDigit s)]
	  lexEsc ('x':s)	       = [prefix 'x' (span isHexDigit s)]
	  lexEsc s@(d:_)   | isDigit d = [span isDigit s]

	  -- Very crude approximation to \XYZ.
	  lexEsc s@(c:_)   | isUpper c = [span isCharName s]
	  lexEsc _		       = []

	  isCharName c	 = isUpper c || isDigit c
	  prefix c (t,s) = (c:t, s)

lexLitChar (c:s)    =  [([c],s)]
lexLitChar ""	    =  []

match			:: (Eq a) => [a] -> [a] -> ([a],[a])
match (x:xs) (y:ys) | x == y  =  match xs ys
match xs     ys		      =  (xs,ys)

asciiTab = listArray ('\NUL', ' ')
	   ["NUL", "SOH", "STX", "ETX", "EOT", "ENQ", "ACK", "BEL",
	    "BS",  "HT",  "LF",  "VT",  "FF",  "CR",  "SO",  "SI", 
	    "DLE", "DC1", "DC2", "DC3", "DC4", "NAK", "SYN", "ETB",
	    "CAN", "EM",  "SUB", "ESC", "FS",  "GS",  "RS",  "US", 
	    "SP"] 



readLitChar 		:: ReadS Char
readLitChar ('\\':s)	=  readEsc s
	where
	readEsc ('a':s)	 = [('\a',s)]
	readEsc ('b':s)	 = [('\b',s)]
	readEsc ('f':s)	 = [('\f',s)]
	readEsc ('n':s)	 = [('\n',s)]
	readEsc ('r':s)	 = [('\r',s)]
	readEsc ('t':s)	 = [('\t',s)]
	readEsc ('v':s)	 = [('\v',s)]
	readEsc ('\\':s) = [('\\',s)]
	readEsc ('"':s)	 = [('"',s)]
	readEsc ('\'':s) = [('\'',s)]
	readEsc ('^':c:s) | c >= '@' && c <= '_'
			 = [(chr (ord c - ord '@'), s)]
	readEsc s@(d:_) | isDigit d
			 = [(chr n, t) | (n,t) <- readDec s]
	readEsc ('o':s)  = [(chr n, t) | (n,t) <- readOct s]
	readEsc ('x':s)	 = [(chr n, t) | (n,t) <- readHex s]
	readEsc s@(c:_) | isUpper c
			 = let table = ('\DEL', "DEL") : assocs asciiTab
			   in case [(c,s') | (c, mne) <- table,
					     ([],s') <- [match mne s]]
			      of (pr:_) -> [pr]
				 []	-> []
	readEsc _	 = []
readLitChar (c:s)	=  [(c,s)]
readLitChar []		=  []

showLitChar 		   :: Char -> ShowS
showLitChar c | c > '\DEL' =  showChar '\\' . protectEsc isDigit (shows (ord c))
showLitChar '\DEL'	   =  showString "\\DEL"
showLitChar '\\'	   =  showString "\\\\"
showLitChar c | c >= ' '   =  showChar c
showLitChar '\a'	   =  showString "\\a"
showLitChar '\b'	   =  showString "\\b"
showLitChar '\f'	   =  showString "\\f"
showLitChar '\n'	   =  showString "\\n"
showLitChar '\r'	   =  showString "\\r"
showLitChar '\t'	   =  showString "\\t"
showLitChar '\v'	   =  showString "\\v"
showLitChar '\SO'	   =  protectEsc (== 'H') (showString "\\SO")
showLitChar c		   =  showString ('\\' : asciiTab!c)

protectEsc p f		   = f . cont
			     where cont s@(c:_) | p c = "\\&" ++ s
				   cont s	      = s

