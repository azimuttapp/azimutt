module PagesComponents.Organization_.Project_.Models.ErdCustomType exposing (ErdCustomType, create, get, merge, unpack)

import Dict exposing (Dict)
import Libs.Maybe as Maybe
import Models.Project.ColumnType exposing (ColumnType)
import Models.Project.CustomType exposing (CustomType)
import Models.Project.CustomTypeId exposing (CustomTypeId)
import Models.Project.CustomTypeName exposing (CustomTypeName)
import Models.Project.CustomTypeValue as CustomTypeValue exposing (CustomTypeValue)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source exposing (Source)
import PagesComponents.Organization_.Project_.Models.ErdOrigin as ErdOrigin exposing (ErdOrigin)


type alias ErdCustomType =
    { id : CustomTypeId
    , name : CustomTypeName
    , value : CustomTypeValue
    , origins : List ErdOrigin
    }


create : Source -> CustomType -> ErdCustomType
create source t =
    { id = t.id
    , name = t.name
    , value = t.value
    , origins = [ ErdOrigin.create source ]
    }


unpack : ErdCustomType -> CustomType
unpack t =
    { id = t.id
    , name = t.name
    , value = t.value
    }


merge : ErdCustomType -> ErdCustomType -> ErdCustomType
merge t1 t2 =
    { id = t1.id
    , name = t1.name
    , value = CustomTypeValue.merge t1.value t2.value
    , origins = t1.origins ++ t2.origins
    }


get : SchemaName -> ColumnType -> Dict CustomTypeId ErdCustomType -> Maybe ErdCustomType
get defaultSchema kind dict =
    case kind |> String.split "." of
        "" :: name :: [] ->
            dict |> Dict.get ( defaultSchema, name ) |> Maybe.orElse (dict |> Dict.get ( "", name ))

        schema :: name :: [] ->
            dict |> Dict.get ( schema, name )

        _ ->
            dict |> Dict.get ( defaultSchema, kind ) |> Maybe.orElse (dict |> Dict.get ( "", kind ))
