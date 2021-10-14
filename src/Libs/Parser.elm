module Libs.Parser exposing (getWhile, identifier, isSpace, notSpace, quotedParser, quotedParserKeep, symbolInsensitive)

import Parser exposing ((|.), (|=), Parser, chompIf, chompWhile, getChompedString, oneOf, succeed, symbol)



-- generic parsers, could be extracted as a lib


identifier : Parser String
identifier =
    getWhile Char.isAlphaNum (\c -> notSpace c && c /= '.' && c /= ',' && c /= '(' && c /= ')')


quotedParser : Char -> Char -> Parser String
quotedParser first last =
    succeed identity
        |. chompIf (\c -> c == first)
        |= (getChompedString <|
                succeed ()
                    |. chompWhile (\c -> c /= last)
           )
        |. chompIf (\c -> c == last)


quotedParserKeep : Char -> Char -> Parser String
quotedParserKeep first last =
    succeed (\string -> String.fromChar first ++ string ++ String.fromChar last)
        |. chompIf (\c -> c == first)
        |= (getChompedString <|
                succeed ()
                    |. chompWhile (\c -> c /= last)
           )
        |. chompIf (\c -> c == last)


symbolInsensitive : String -> Parser ()
symbolInsensitive name =
    oneOf [ symbol (name |> String.toUpper), symbol (name |> String.toLower) ]


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
