module Games.ChordGuesserExercise exposing (..)

import Games.TheoryApi as TheoryApi
import Html exposing (Html, s)
import Html.Attributes as HA
import Html.Events as HE
import Http
import List.Extra as ListExtra
import Random
import Random.List as RandomList
import String


type alias Model =
    { maybeChords : Maybe (List TheoryApi.Chord2)
    , isGameStarted : Bool
    , chosenDifficulty : Difficulty
    , pendingFetches : Int
    , rootNotes : List String
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
    | DifficultyChosen Difficulty
    | ChordChosen TheoryApi.Chord2
    | ChordGroupChosen (List String)

    | ResetChordGuesser
    | GoBack


type Difficulty
    = Easy
    | Medium
    | Hard
    | Extreme


type alias Flags =
    String


init : Flags -> ( Model, Cmd Msg )
init _ =
    ( { maybeChords = Nothing
      , maybeChosenChord = Nothing
      , isGameStarted = False
      , chosenDifficulty = Easy
      , pendingFetches = 0
      , rootNotes = [ "C", "G", "F" ]
      , randomizedChord = Nothing
      , lastRandomIndex = Nothing
      , score = 0
      , mistakes = 0
      , gameOver = False
      }
    , Cmd.none
    )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


initialFetch : List String -> List String -> Cmd Msg
initialFetch rootNotes chordTypes =
    -- adjust root and types as desired; Main should call this when route is chord-exercise
    TheoryApi.fetchChords2 rootNotes chordTypes GotChordData


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotChordData (Ok chords) ->
            let
                existingChords =
                    Maybe.withDefault [] model.maybeChords

                combined =
                    existingChords ++ chords

                remaining =
                    model.pendingFetches - 1

                chordCount =
                    List.length combined

                cmd =
                    if remaining <= 0 && chordCount > 0 then
                        randomizeChord chordCount

                    else
                        Cmd.none
            in
            ( { model | maybeChords = Just combined, pendingFetches = remaining }, cmd )

        GotChordData (Err _) ->
            let
                remaining =
                    model.pendingFetches - 1

                chordCount =
                    List.length (Maybe.withDefault [] model.maybeChords)

                cmd =
                    if remaining <= 0 && chordCount > 0 then
                        randomizeChord chordCount

                    else
                        Cmd.none
            in
            ( { model | pendingFetches = remaining }, cmd )

        DifficultyChosen difficulty ->
            let
                newDifficulty =
                    difficulty
            in
            ( { model | chosenDifficulty = newDifficulty, rootNotes = setRootNotes newDifficulty }, Cmd.none )

        ChordGroupChosen chordTypes ->
            let
                fetchCount =
                    List.length model.rootNotes
            in
            ( { model | isGameStarted = True, maybeChords = Just [], pendingFetches = fetchCount }
            , TheoryApi.fetchChords2 model.rootNotes chordTypes GotChordData
            )

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
    if model.isGameStarted then
        Html.div []
            [ Html.text "Chord guesser"
            , viewRandomizedChord model
            , viewChords model
            , Html.p [] [ Html.text <| "Score:  " ++ String.fromInt model.score ]
            , Html.p [] [ Html.text <| "Mistakes:  " ++ String.fromInt model.mistakes ]
            , Html.button [ HA.class "custom-button", HE.onClick ResetChordGuesser ] [ Html.text "Reset" ]
            ]

    else
        Html.section []
            [ Html.h2 [] [ Html.text "Chord Guesser Exercise" ]
            , Html.button [ HA.class "custom-button", HE.onClick (DifficultyChosen Easy) ] [ Html.text "Easy" ]
            , Html.button [ HA.class "custom-button", HE.onClick (DifficultyChosen Medium) ] [ Html.text "Medium" ]
            , Html.button [ HA.class "custom-button", HE.onClick (DifficultyChosen Hard) ] [ Html.text "Hard" ]
            , Html.button [ HA.class "custom-button", HE.onClick (DifficultyChosen Extreme) ] [ Html.text "Extreme" ]
            , Html.div []
                [ Html.text ("Chosen difficulty: " ++ stringFromDifficulty model.chosenDifficulty)
                ]
            , Html.div []
                [ Html.ul []
                    [ Html.li [ HE.onClick (ChordGroupChosen [ "major", "minor" ]) ] [ Html.text "Major and minor" ]
                    , Html.li [ HE.onClick (ChordGroupChosen [ "dom7", "maj7", "minor7" ]) ] [ Html.text "Dom7, Maj7 and Minor7" ]
                    , Html.li [ HE.onClick (ChordGroupChosen [ "diminished", "dim7", "minor7flat5" ]) ] [ Html.text "Dim, dim7 and m7b5" ]
                    , Html.li [ HE.onClick (ChordGroupChosen [ "augmented", "aug7", "maj7sharp5" ]) ] [ Html.text "Aug, aug7 and maj7#5" ]
                    , Html.li [ HE.onClick (ChordGroupChosen [ "sus2", "sus4" ]) ] [ Html.text "Sus2 and sus4" ]
                    , Html.li [ HE.onClick (ChordGroupChosen [ "major6", "minor6" ]) ] [ Html.text "6 and m6" ]
                    , Html.li [ HE.onClick (ChordGroupChosen [ "dom9", "maj9", "minor9" ]) ] [ Html.text "Dom9, maj9 and minor9" ]
                    , Html.li [ HE.onClick (ChordGroupChosen [ "dom11", "maj11", "minor11" ]) ] [ Html.text "Dom11, maj11 and minor11" ]
                    , Html.li [ HE.onClick (ChordGroupChosen [ "dom13", "maj13", "minor13" ]) ] [ Html.text "Dom13, maj13 and minor13" ]
                    , Html.li [ HE.onClick (ChordGroupChosen [ "dom7flat9", "dom7sharp9", "dom7sharp11" ]) ] [ Html.text "7b9, 7#9 and 7#11" ]
                    , Html.li [ HE.onClick (ChordGroupChosen [ "dom7flat13", "dom7sharp5", "dom7flat5" ]) ] [ Html.text "7b13, 7#5 and 7b5" ]
                    , Html.li [ HE.onClick (ChordGroupChosen [ "sus13", "minorMaj7", "dim9" ]) ] [ Html.text "sus13, mMaj7 and dim9" ]
                    ]
                ]
            , Html.button [ HA.class "custom-button", HE.onClick GoBack ] [ Html.text "< Back" ]
            ]


setRootNotes : Difficulty -> List String
setRootNotes difficulty =
    case difficulty of
        Easy ->
            [ "C", "G", "F" ]

        Medium ->
            [ "C", "G", "F", "D", "A", "B♭", "E♭" ]

        Hard ->
            [ "C", "G", "F", "D", "A", "B♭", "E♭", "E", "B", "A♭", "D♭" ]

        Extreme ->
            [ "C", "G", "F", "D", "A", "B♭", "E♭", "E", "B", "A♭", "D♭", "F#", "C#", "G#", "D#", "A#" ]


stringFromDifficulty : Difficulty -> String
stringFromDifficulty difficulty =
    case difficulty of
        Easy ->
            "Easy"

        Medium ->
            "Medium"

        Hard ->
            "Hard"

        Extreme ->
            "Extreme"


rotateLeft : List a -> List a
rotateLeft list =
    case list of
        x :: xs ->
            xs ++ [ x ]

        [] ->
            []

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
            Html.p [] [ Html.text ("Which chord is this? " ++ viewRandomizedChordNotes (rotateLeft randomizedChord.notes)) ]

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
