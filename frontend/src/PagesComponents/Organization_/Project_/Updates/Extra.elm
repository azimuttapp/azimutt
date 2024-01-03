module PagesComponents.Organization_.Project_.Updates.Extra exposing (Extra, addCmd, addCmdT, addHistoryT, apply, cmd, cmdL, cmdM, cmdML, cmdT, combine, concat, defaultT, dropHistory, history, historyL, historyM, msg, msgM, msgR, new, newCL, newHL, newLL, none, setHistory, unpackT, unpackTM)

import Task


type alias Extra msg =
    { cmd : Cmd msg
    , history : List ( msg, msg )
    }


none : Extra msg
none =
    { cmd = Cmd.none, history = [] }


new : Cmd msg -> ( msg, msg ) -> Extra msg
new c h =
    { cmd = c, history = [ h ] }


newCL : List (Cmd msg) -> ( msg, msg ) -> Extra msg
newCL c h =
    { cmd = Cmd.batch c, history = [ h ] }


newHL : Cmd msg -> List ( msg, msg ) -> Extra msg
newHL c h =
    { cmd = c, history = h }


newLL : List (Cmd msg) -> List ( msg, msg ) -> Extra msg
newLL c h =
    { cmd = Cmd.batch c, history = h }


cmd : Cmd msg -> Extra msg
cmd c =
    { cmd = c, history = [] }


cmdM : Maybe (Cmd msg) -> Extra msg
cmdM c =
    c |> Maybe.map cmd |> Maybe.withDefault none


cmdL : List (Cmd msg) -> Extra msg
cmdL c =
    { cmd = Cmd.batch c, history = [] }


cmdT : ( a, Cmd msg ) -> ( a, Extra msg )
cmdT ( a, c ) =
    ( a, cmd c )


cmdML : Maybe (List (Cmd msg)) -> Extra msg
cmdML c =
    c |> Maybe.map cmdL |> Maybe.withDefault none


msg : msg -> Extra msg
msg m =
    { cmd = m |> Task.succeed |> Task.perform identity, history = [] }


msgM : Maybe msg -> Extra msg
msgM m =
    m |> Maybe.map msg |> Maybe.withDefault none


msgR : Result e msg -> Extra msg
msgR m =
    m |> Result.map msg |> Result.withDefault none


history : ( msg, msg ) -> Extra msg
history h =
    { cmd = Cmd.none, history = [ h ] }


historyM : Maybe ( msg, msg ) -> Extra msg
historyM h =
    h |> Maybe.map history |> Maybe.withDefault none


historyL : List ( msg, msg ) -> Extra msg
historyL h =
    { cmd = Cmd.none, history = h }


addCmd : Cmd msg -> Extra msg -> Extra msg
addCmd c e =
    { e | cmd = Cmd.batch [ e.cmd, c ] }


addCmdT : Cmd msg -> ( a, Extra msg ) -> ( a, Extra msg )
addCmdT c ( a, e ) =
    ( a, e |> addCmd c )


addHistoryT : ( msg, msg ) -> ( a, Extra msg ) -> ( a, Extra msg )
addHistoryT h ( a, e ) =
    ( a, { e | history = e.history ++ [ h ] } )


setHistory : ( msg, msg ) -> Extra msg -> Extra msg
setHistory h e =
    { e | history = [ h ] }


dropHistory : Extra msg -> Extra msg
dropHistory e =
    { e | history = [] }


defaultT : ( a, Maybe (Extra msg) ) -> ( a, Extra msg )
defaultT ( a, e ) =
    ( a, e |> Maybe.withDefault none )


combine : Extra msg -> Extra msg -> Extra msg
combine a b =
    { cmd = Cmd.batch [ a.cmd, b.cmd ], history = a.history ++ b.history }


concat : List (Extra msg) -> Extra msg
concat extras =
    { cmd = extras |> List.map .cmd |> Cmd.batch, history = extras |> List.map .history |> List.concat }


unpackT : ( a, Extra msg ) -> ( a, Cmd msg )
unpackT ( a, e ) =
    ( a, e.cmd )


unpackTM : ( a, Maybe (Extra msg) ) -> ( a, Cmd msg )
unpackTM ( a, eM ) =
    eM |> Maybe.map (\e -> ( a, e.cmd )) |> Maybe.withDefault ( a, Cmd.none )


apply : (List msg -> msg) -> ( { m | history : List ( msg, msg ), future : List ( msg, msg ) }, Extra msg ) -> ( { m | history : List ( msg, msg ), future : List ( msg, msg ) }, Cmd msg )
apply batch ( model, e ) =
    case e.history of
        [] ->
            ( model, e.cmd )

        one :: [] ->
            ( { model | history = one :: model.history |> List.take 100, future = [] }, e.cmd )

        many ->
            ( { model | history = (many |> tupleList |> Tuple.mapBoth batch batch) :: model.history |> List.take 100, future = [] }, e.cmd )


tupleList : List ( a, b ) -> ( List a, List b )
tupleList list =
    -- from List.tupleSeq but avoid dependency on List module
    List.foldr (\( a, b ) ( aList, bList ) -> ( a :: aList, b :: bList )) ( [], [] ) list
