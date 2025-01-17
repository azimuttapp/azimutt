module Components.Atoms.Icons exposing (color, column, columns, comment, fromText, notes, sources, table, tags, warning)

import Components.Atoms.Icon as Icon exposing (Icon)


table : Icon
table =
    Icon.Table


column : Icon
column =
    Icon.Tag


comment : Icon
comment =
    Icon.Chat


notes : Icon
notes =
    Icon.DocumentText


tags : Icon
tags =
    Icon.Hashtag


color : Icon
color =
    Icon.ColorSwatch


warning : Icon
warning =
    Icon.Exclamation


columns : { primaryKey : Icon, foreignKey : Icon, unique : Icon, index : Icon, check : Icon, nested : Icon, nestedOpen : Icon }
columns =
    { primaryKey = Icon.Key
    , foreignKey = Icon.ExternalLink
    , unique = Icon.FingerPrint
    , index = Icon.SortDescending
    , check = Icon.Check
    , nested = Icon.ChevronRight
    , nestedOpen = Icon.ChevronDown
    }


sources : { database : Icon, sql : Icon, prisma : Icon, json : Icon, aml : Icon, empty : Icon, project : Icon, sample : Icon, remote : Icon, missing : Icon }
sources =
    { database = Icon.Database
    , sql = Icon.DocumentText
    , prisma = Icon.DocumentText
    , json = Icon.Code
    , aml = Icon.User
    , empty = Icon.Document
    , project = Icon.FolderDownload
    , sample = Icon.Gift
    , remote = Icon.CloudDownload
    , missing = Icon.XCircle
    }


fromText : String -> Icon
fromText text =
    case text of
        "archive" ->
            Icon.Archive

        "at" ->
            Icon.AtSymbol

        "bar-chart" ->
            Icon.ChartBar

        "bell" ->
            Icon.Bell

        "chat" ->
            Icon.Chat

        "check" ->
            Icon.BadgeCheck

        "clock" ->
            Icon.Clock

        "cloud" ->
            Icon.Cloud

        "code" ->
            Icon.Code

        "euro" ->
            Icon.CurrencyEuro

        "experiment" ->
            Icon.Beaker

        "database" ->
            Icon.Database

        "desktop" ->
            Icon.DesktopComputer

        "document" ->
            Icon.Document

        "dollar" ->
            Icon.CurrencyDollar

        "exclamation" ->
            Icon.ExclamationCircle

        "eye" ->
            Icon.Eye

        "flag" ->
            Icon.Flag

        "folder" ->
            Icon.Folder

        "forbid" ->
            Icon.Ban

        "grid" ->
            Icon.ViewGrid

        "hand" ->
            Icon.Hand

        "hashtag" ->
            Icon.Hashtag

        "heart" ->
            Icon.Heart

        "home" ->
            Icon.Home

        "image" ->
            Icon.Photograph

        "info" ->
            Icon.InformationCircle

        "list" ->
            Icon.ViewList

        "lock" ->
            Icon.LockClosed

        "lock-open" ->
            Icon.LockOpen

        "mail" ->
            Icon.Mail

        "phone" ->
            Icon.Phone

        "paperclip" ->
            Icon.PaperClip

        "pen" ->
            Icon.Pencil

        "pie-chart" ->
            Icon.ChartPie

        "refresh" ->
            Icon.Refresh

        "search" ->
            Icon.Search

        "settings" ->
            Icon.Adjustments

        "share" ->
            Icon.Share

        "sparkles" ->
            Icon.Sparkles

        "star" ->
            Icon.Star

        "tag" ->
            Icon.Tag

        "terminal" ->
            Icon.Terminal

        "thumb-down" ->
            Icon.ThumbDown

        "thumb-up" ->
            Icon.ThumbUp

        "trash" ->
            Icon.Trash

        "user" ->
            Icon.User

        _ ->
            Icon.Empty
