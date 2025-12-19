module Pages.Exercises exposing (Model, Msg, init, subscriptions, update, view)

import Exercises.ChordGuesserExercise as ChordGuesserExercise
import Html exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Platform.Cmd exposing (Cmd)
import Platform.Sub exposing (Sub)


type alias Model =
    { chordGuesserModel : ChordGuesserExercise.Model
    , currentGame : Maybe Game
    }


type Game
    = ChordGuesser


type Msg
    = ChordGuesserMsg ChordGuesserExercise.Msg
    | SelectGame Game
    | BackToList




init : () -> ( Model, Cmd Msg )
init _ =
    let
        _ =
            Debug.log "ChordGuesserExercise init called"

        ( chordModel, chordCmd ) =
            ChordGuesserExercise.init ()
    in
    ( { chordGuesserModel = chordModel, currentGame = Nothing }
    , Cmd.batch [ Cmd.map ChordGuesserMsg chordCmd ]
    )



-- expose an initialFetch to be used by top-level Main when entering /exercises


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChordGuesserMsg subMsg ->
            let
                ( updated, cmd ) =
                    ChordGuesserExercise.update subMsg model.chordGuesserModel
            in
            ( { model | chordGuesserModel = updated }, Cmd.map ChordGuesserMsg cmd )

        SelectGame ChordGuesser ->
            let
                fetchCmd =
                    ChordGuesserExercise.fetchSubExercisesCmd
            in
            ( { model | currentGame = Just ChordGuesser }
            , Cmd.map ChordGuesserMsg fetchCmd
            )

        BackToList ->
            ( { model | currentGame = Nothing }, Cmd.none )


view : Model -> Html Msg
view model =
    case model.currentGame of
        Just ChordGuesser ->
            if model.chordGuesserModel.isGameStarted then
                Html.div []
                    [ Html.map ChordGuesserMsg (ChordGuesserExercise.view model.chordGuesserModel)
                    ]

            else
                Html.div []
                    [ Html.map ChordGuesserMsg (ChordGuesserExercise.view model.chordGuesserModel)
                    , Html.button [ HA.class "custom-button", HE.onClick BackToList ] [ Html.text "< Back to exercises" ]
                    ]

        Nothing ->
            Html.div []
                [ Html.h2 [] [ Html.text "Exercises" ]
                , Html.ul []
                    [ Html.li []
                        [ Html.button
                            [ HE.onClick (SelectGame ChordGuesser), HA.class "custom-button" ]
                            [ Html.text "Chord Guesser" ]
                        ]
                    ]
                ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map ChordGuesserMsg (ChordGuesserExercise.subscriptions model.chordGuesserModel)
