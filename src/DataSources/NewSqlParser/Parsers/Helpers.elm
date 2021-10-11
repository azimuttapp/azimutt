module DataSources.NewSqlParser.Parsers.Helpers exposing (getWhile, isSpace, notSpace, quotedParser)

import Parser exposing ((|.), (|=), Parser, chompIf, chompWhile, getChompedString, succeed)



-- generic parsers, could be extracted as a lib


quotedParser : Char -> Char -> Parser String
quotedParser first last =
    succeed identity
        |. chompIf (\c -> c == first)
        |= getWhile (\c -> c /= last) (\c -> c /= last)
        |. chompIf (\c -> c == last)


getWhile : (Char -> Bool) -> (Char -> Bool) -> Parser String
getWhile start end =
    getChompedString <|
        succeed ()
            |. chompIf start
            |. chompWhile end


isSpace : Char -> Bool
isSpace c =
    c == ' ' || c == '\n' || c == '\u{000D}'


notSpace : Char -> Bool
notSpace c =
    not (isSpace c)
