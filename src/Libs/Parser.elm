module Libs.Parser exposing (exists, getWhile, identifier, identifierOrQuoted, isSpace, maybe, notSpace, quotedParser, symbolInsensitive)

import Parser exposing ((|.), (|=), Parser, chompIf, chompWhile, getChompedString, oneOf, succeed, symbol)



-- generic parsers, could be extracted as a lib


identifierOrQuoted : Parser String
identifierOrQuoted =
    oneOf
        [ quotedParser '`' '`'
        , quotedParser '\'' '\''
        , quotedParser '"' '"'
        , quotedParser '[' ']'
        , identifier
        ]


identifier : Parser String
identifier =
    getWhile Char.isAlphaNum (\c -> notSpace c && c /= '.' && c /= ',' && c /= '(' && c /= ')')


quotedParser : Char -> Char -> Parser String
quotedParser first last =
    succeed identity
        |. chompIf (\c -> c == first)
        |= (succeed ()
                |. chompWhile (\c -> c /= last)
                |> getChompedString
           )
        |. chompIf (\c -> c == last)


getWhile : (Char -> Bool) -> (Char -> Bool) -> Parser String
getWhile start end =
    succeed ()
        |. chompIf start
        |. chompWhile end
        |> getChompedString


symbolInsensitive : String -> Parser String
symbolInsensitive name =
    oneOf [ symbol (name |> String.toUpper), symbol (name |> String.toLower) ] |> getChompedString


maybe : Parser a -> Parser (Maybe a)
maybe p =
    oneOf
        [ succeed Just |= p
        , succeed Nothing
        ]


exists : Parser a -> Parser Bool
exists p =
    oneOf
        [ succeed True |. p
        , succeed False
        ]


isSpace : Char -> Bool
isSpace c =
    c == ' ' || c == '\n' || c == '\u{000D}'


notSpace : Char -> Bool
notSpace c =
    not (isSpace c)
