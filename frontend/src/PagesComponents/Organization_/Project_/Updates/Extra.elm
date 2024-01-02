module PagesComponents.Organization_.Project_.Updates.Extra exposing (Extra, addCmdT, addHistoryT, cmd, cmdL, cmdM, cmdT, combine, concat, defaultT, dropHistory, history, historyL, historyM, msg, msgM, msgR, new, newL, newM, none)

import Task


type alias Extra msg =
    ( Cmd msg, List ( msg, msg ) )


none : Extra msg
none =
    ( Cmd.none, [] )


new : Cmd msg -> ( msg, msg ) -> Extra msg
new c h =
    ( c, [ h ] )


newM : Cmd msg -> Maybe ( msg, msg ) -> Extra msg
newM c h =
    h |> Maybe.map (new c) |> Maybe.withDefault none


newL : Cmd msg -> List ( msg, msg ) -> Extra msg
newL c h =
    ( c, h )


cmd : Cmd msg -> Extra msg
cmd c =
    ( c, [] )


cmdM : Maybe (Cmd msg) -> Extra msg
cmdM c =
    c |> Maybe.map cmd |> Maybe.withDefault none


cmdL : List (Cmd msg) -> Extra msg
cmdL c =
    ( Cmd.batch c, [] )


cmdT : ( a, Cmd msg ) -> ( a, Extra msg )
cmdT ( a, c ) =
    ( a, cmd c )


msg : msg -> Extra msg
msg m =
    ( m |> Task.succeed |> Task.perform identity, [] )


msgM : Maybe msg -> Extra msg
msgM m =
    m |> Maybe.map msg |> Maybe.withDefault none


msgR : Result e msg -> Extra msg
msgR m =
    m |> Result.map msg |> Result.withDefault none


history : ( msg, msg ) -> Extra msg
history h =
    ( Cmd.none, [ h ] )


historyM : Maybe ( msg, msg ) -> Extra msg
historyM h =
    h |> Maybe.map history |> Maybe.withDefault none


historyL : List ( msg, msg ) -> Extra msg
historyL h =
    ( Cmd.none, h )


addCmdT : Cmd msg -> ( a, Extra msg ) -> ( a, Extra msg )
addCmdT c2 ( a, ( c, h ) ) =
    ( a, ( Cmd.batch [ c, c2 ], h ) )


addHistoryT : ( msg, msg ) -> ( a, Extra msg ) -> ( a, Extra msg )
addHistoryT h2 ( a, ( c, h ) ) =
    ( a, ( c, h ++ [ h2 ] ) )


dropHistory : Extra msg -> Extra msg
dropHistory ( c, _ ) =
    ( c, [] )


defaultT : ( a, Maybe (Extra msg) ) -> ( a, Extra msg )
defaultT ( a, e ) =
    ( a, e |> Maybe.withDefault none )


combine : Extra msg -> Extra msg -> Extra msg
combine ( cmdA, hA ) ( cmdB, hB ) =
    ( Cmd.batch [ cmdA, cmdB ], hA ++ hB )


concat : List (Extra msg) -> Extra msg
concat extras =
    extras |> List.unzip |> Tuple.mapBoth Cmd.batch List.concat
