module App exposing (..)

import Html exposing (Html)
import Dom exposing (..)
import Mouse
import Task exposing (..)
import Model exposing (..)
import Types exposing (..)
import Views exposing (view)
import Random.Pcg exposing (initialSeed)


main : Program Int Model Msg
main =
    Html.programWithFlags
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


init : Int -> ( Model, Cmd Msg )
init flags =
    ( { seed = (initialSeed flags)
      , groups = []
      , focusedTaskUuid = Nothing
      , mouseCoords = Nothing
      }
    , loadModel ()
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Ignore result ->
            ( model, Cmd.none )

        MouseMove pos ->
            ( { model | mouseCoords = Just pos }, Cmd.none )

        GroupTitle group title ->
            let
                newModel =
                    updateGroup model { group | title = title }
            in
                ( newModel, saveModel newModel )

        TaskDescription group task desc ->
            let
                newModel =
                    updateTask model group { task | description = desc }
            in
                ( newModel, saveModel newModel )

        TaskIsDone group task ->
            let
                newModel =
                    updateTask model group { task | isDone = (not task.isDone) }
            in
                ( newModel, saveModel newModel )

        TaskRemove group task ->
            let
                newModel =
                    removeTask task group model
            in
                ( newModel, saveModel newModel )

        TaskNew group ->
            let
                ( newModel, newTask ) =
                    addNewTask model group
            in
                ( newModel, Cmd.batch [ (saveModel newModel), (Dom.focus (toString newTask.uuid) |> Task.attempt Ignore) ] )

        TaskDrag group task ->
            let
                newModel =
                    updateTask model group { task | isDragging = True }
            in
                ( newModel, Cmd.none )

        TaskDrop group ->
            let
                newModel =
                    case group of
                        Nothing ->
                            dropAllTasks model

                        Just group ->
                            dropDraggedTaskInto group model
            in
                ( newModel, Cmd.none )

        Import ->
            ( model, Cmd.none )

        GroupNew preceedingGroup ->
            let
                newModel =
                    addNewGroup model preceedingGroup
            in
                ( newModel, saveModel newModel )

        GroupRemove group ->
            let
                newModel =
                    removeGroup model group
            in
                ( newModel, saveModel newModel )

        OnLoad jsonStr ->
            let
                newModel =
                    deserialize jsonStr model
            in
                ( newModel, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ onModelLoaded OnLoad
        , Mouse.moves MouseMove
        ]
