module PagesComponents.Organization_.Project_.Updates.Extra exposing (Extra, addCmd, addCmdT, batch, cmd, cmdM, cmdT, combine, concat, defaultT, dropHistory, history, historyL, historyM, msg, msgM, msgR, new, newL, newM, none)

import Task


type alias Extra msg =
    ( Cmd msg, List ( msg, msg ) )


new : Cmd msg -> ( msg, msg ) -> Extra msg
new c h =
    ( c, [ h ] )


newM : Cmd msg -> Maybe ( msg, msg ) -> Extra msg
newM c hM =
    ( c, hM |> Maybe.map (\h -> [ h ]) |> Maybe.withDefault [] )


newL : Cmd msg -> List ( msg, msg ) -> Extra msg
newL c h =
    ( c, h )


none : Extra msg
none =
    ( Cmd.none, [] )


cmd : Cmd msg -> Extra msg
cmd c =
    ( c, [] )


cmdM : Maybe (Cmd msg) -> Extra msg
cmdM cM =
    cM |> Maybe.map (\c -> ( c, [] )) |> Maybe.withDefault none


cmdT : ( a, Cmd msg ) -> ( a, Extra msg )
cmdT ( a, c ) =
    ( a, ( c, [] ) )


batch : List (Cmd msg) -> Extra msg
batch cs =
    ( Cmd.batch cs, [] )


msg : msg -> Extra msg
msg m =
    ( m |> Task.succeed |> Task.perform identity, [] )


msgM : Maybe msg -> Extra msg
msgM mM =
    mM |> Maybe.map msg |> Maybe.withDefault none


msgR : Result e msg -> Extra msg
msgR mM =
    mM |> Result.map msg |> Result.withDefault none


history : ( msg, msg ) -> Extra msg
history h =
    ( Cmd.none, [ h ] )


historyM : Maybe ( msg, msg ) -> Extra msg
historyM hM =
    ( Cmd.none, hM |> Maybe.map (\h -> [ h ]) |> Maybe.withDefault [] )


historyL : List ( msg, msg ) -> Extra msg
historyL hL =
    ( Cmd.none, hL )


addCmd : Cmd msg -> Extra msg -> Extra msg
addCmd c2 ( c, h ) =
    ( Cmd.batch [ c, c2 ], h )


addCmdT : Cmd msg -> ( a, Extra msg ) -> ( a, Extra msg )
addCmdT c2 ( a, ( c, h ) ) =
    ( a, ( Cmd.batch [ c, c2 ], h ) )


dropHistory : Extra msg -> Extra msg
dropHistory ( c, _ ) =
    ( c, [] )


defaultT : ( a, Maybe (Extra msg) ) -> ( a, Extra msg )
defaultT ( a, extraM ) =
    ( a, extraM |> Maybe.withDefault none )


combine : Extra msg -> Extra msg -> Extra msg
combine ( aCmd, aH ) ( bCmd, bH ) =
    ( Cmd.batch [ aCmd, bCmd ], aH ++ bH )


concat : List (Extra msg) -> Extra msg
concat extras =
    extras |> List.unzip |> Tuple.mapBoth Cmd.batch List.concat
