module PagesComponents.Organization_.Project_.Updates.Memo exposing (Model, handleMemo)

import Models.ErdProps exposing (ErdProps)
import PagesComponents.Organization_.Project_.Models exposing (MemoMsg(..), Msg)
import PagesComponents.Organization_.Project_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Organization_.Project_.Models.ErdLayout as ErdLayout
import PagesComponents.Organization_.Project_.Updates.Utils exposing (setDirty)
import Services.Lenses exposing (mapErdM, mapMemos)
import Time


type alias Model x =
    { x
        | conf : ErdConf
        , erdElem : ErdProps
        , dirty : Bool
        , erd : Maybe Erd
    }


handleMemo : Time.Posix -> MemoMsg -> Model x -> ( Model x, Cmd Msg )
handleMemo now msg model =
    case msg of
        MCreate e ->
            model |> mapErdM (Erd.mapCurrentLayoutWithTime now (\l -> l |> mapMemos (List.append [ e |> ErdLayout.createMemo model.erdElem l ]))) |> setDirty
