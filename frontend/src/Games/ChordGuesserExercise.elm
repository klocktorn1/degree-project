module Games.ChordGuesserExercise exposing (..)

import Games.TheoryApi as TheoryApi
import Html exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Http
import List.Extra as ListExtra
import Random
import String


type alias Model =
    { maybeChords : Maybe (List TheoryApi.Chord2)
    , maybeChosenChord : Maybe TheoryApi.Chord2
    , randomizedChord : Maybe TheoryApi.Chord2
    , lastRandomIndex : Maybe Int
    , score : Int
    , mistakes : Int
    , gameOver : Bool
    }


type Msg
    = GotChordData (Result Http.Error (List TheoryApi.Chord2))
    | RandomChordPicked Int
    | ChordChosen TheoryApi.Chord2
    | ResetChordGuesser
    | GoBack


type alias Flags =
    String


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { maybeChords = Nothing
      , maybeChosenChord = Nothing
      , randomizedChord = Nothing
      , lastRandomIndex = Nothing
      , score = 0
      , mistakes = 0
      , gameOver = False
      }
    , Cmd.none
    )



-- initial fetch used by Main when entering chord exercise


initialFetch : Cmd Msg
initialFetch =
    -- adjust root and types as desired; Main should call this when route is chord-exercise
    TheoryApi.fetchChords2 "C" [ "major", "minor", "dom7", "sus4" ] GotChordData


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotChordData (Ok chords) ->
            let
                chordCount =
                    List.length chords
            in
            -- store chords and immediately request a random index if there are any chords
            if chordCount > 0 then
                ( { model | maybeChords = Just chords }, randomizeChord chordCount )

            else
                ( { model | maybeChords = Just [] }, Cmd.none )

        GotChordData (Err _) ->
            -- keep things simple: don't change state on error (or log if you want)
            ( model, Cmd.none )

        RandomChordPicked randomIndex ->
            let
                chordCount =
                    List.length (Maybe.withDefault [] model.maybeChords)

                -- helper to pick the chord at index or default
                newRandomChord =
                    pickRandomChord model.maybeChords randomIndex
            in
            case model.lastRandomIndex of
                Just lastIndex ->
                    if lastIndex == randomIndex && chordCount > 1 then
                        -- avoid same index: try again
                        ( model, randomizeChord chordCount )

                    else
                        ( { model | randomizedChord = Just newRandomChord, lastRandomIndex = Just randomIndex }, Cmd.none )

                Nothing ->
                    ( { model | randomizedChord = Just newRandomChord, lastRandomIndex = Just randomIndex }, Cmd.none )

        ChordChosen chord ->
            let
                modelWithChordChosen =
                    { model | maybeChosenChord = Just chord }

                ( updatedModel, cmd ) =
                    checkIfChordIsCorrect modelWithChordChosen
            in
            ( updatedModel, cmd )

        ResetChordGuesser ->
            ( { model
                | maybeChosenChord = Nothing
                , gameOver = False
                , mistakes = 0
                , score = 0
              }
            , Cmd.none
            )

        GoBack ->
            ( model, Cmd.none )


view : Model -> Html Msg
view model =
    Html.div []
        [ Html.text "Chord guesser"
        , viewRandomizedChord model
        , viewChords model
        , Html.p [] [ Html.text <| "Score:  " ++ String.fromInt model.score ]
        , Html.p [] [ Html.text <| "Mistakes:  " ++ String.fromInt model.mistakes ]
        , Html.button [ HA.class "custom-button", HE.onClick ResetChordGuesser ] [ Html.text "Reset" ]
        , Html.button [ HA.class "custom-button", HE.onClick GoBack ] [ Html.text " <-- Go Back" ]
        ]


viewChords : Model -> Html Msg
viewChords model =
    case model.maybeChords of
        Just chords ->
            Html.div [ HA.class "chords-container" ]
                (List.map viewChord chords)

        Nothing ->
            Html.div [] [ Html.text "No chords found" ]


viewChord : TheoryApi.Chord2 -> Html Msg
viewChord chord =
    Html.div [ HA.class "custom-button", HE.onClick (ChordChosen chord) ]
        [ Html.text chord.chord ]


viewRandomizedChord : Model -> Html Msg
viewRandomizedChord model =
    case model.randomizedChord of
        Just randomizedChord ->
            Html.p [] [ Html.text ("Which chord is this? " ++ viewRandomizedChordNotes randomizedChord.notes) ]

        Nothing ->
            Html.p [] [ Html.text "No chord found" ]



viewRandomizedChordNotes : List String -> String
viewRandomizedChordNotes notes =
    String.join ", " notes

defaultChord : TheoryApi.Chord2
defaultChord =
    { chord = "No chord found"
    , root = ""
    , formula = []
    , degrees = []
    , notes = []
    }


pickRandomChord : Maybe (List TheoryApi.Chord2) -> Int -> TheoryApi.Chord2
pickRandomChord maybeChords randomIndex =
    case maybeChords of
        Just chords ->
            case ListExtra.getAt randomIndex chords of
                Just randomChordObject ->
                    randomChordObject

                Nothing ->
                    defaultChord

        Nothing ->
            defaultChord


randomizeChord : Int -> Cmd Msg
randomizeChord maxIndex =
    if maxIndex <= 0 then
        Cmd.none

    else
        Random.generate RandomChordPicked (Random.int 0 (maxIndex - 1))


checkIfChordIsCorrect : Model -> ( Model, Cmd Msg )
checkIfChordIsCorrect model =
    case ( model.maybeChosenChord, model.randomizedChord ) of
        ( Just chosenChord, Just randomizedChord ) ->
            if chosenChord == randomizedChord then
                let
                    newScore =
                        model.score + 1

                    chordCount =
                        List.length (Maybe.withDefault [] model.maybeChords)
                in
                ( { model | score = newScore }, randomizeChord chordCount )

            else
                let
                    newMistakes =
                        model.mistakes + 1

                    setGameOver =
                        if newMistakes >= 3 then
                            True

                        else
                            False
                in
                ( { model | mistakes = newMistakes, gameOver = setGameOver }, Cmd.none )

        _ ->
            ( model, Cmd.none )
