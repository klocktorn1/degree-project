module Exercises.ChordGuesserExercise exposing (..)

import Api.TheoryApi as TheoryApi
import Html exposing (Html, s)
import Html.Attributes as HA
import Html.Events as HE
import Http
import List.Extra as ListExtra
import Random
import Random.List as RandomList
import String


type alias Model =
    { maybeChords : Maybe (List TheoryApi.Chord)
    , isGameStarted : Bool
    , chosenDifficulty : Difficulty
    , pendingFetches : Int
    , rootNotes : List String
    , maybeChosenChord : Maybe TheoryApi.Chord
    , randomizedChord : Maybe TheoryApi.Chord
    , randomizedChordNotes : Maybe (List String)
    , lastRandomIndex : Maybe Int
    , areNotesShuffled : Bool
    , score : Int
    , mistakes : Int
    , gameOver : Bool
    }


type Msg
    = GotChordData (Result Http.Error (List TheoryApi.Chord))
    | RandomChordPicked Int
    | DifficultyChosen Difficulty
    | ChordChosen TheoryApi.Chord
    | ChordGroupChosen (List String)
    | Shuffled (List String)
    | ToggleNotesShuffle
    | GoBack


type Difficulty
    = Easy
    | Medium
    | Hard
    | Advanced
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
      , randomizedChordNotes = Nothing
      , lastRandomIndex = Nothing
      , areNotesShuffled = False
      , score = 0
      , mistakes = 0
      , gameOver = False
      }
    , Cmd.none
    )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


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

                areNotesShuffled =
                    case newDifficulty of
                        Easy ->
                            False

                        Medium ->
                            False

                        Hard ->
                            True

                        Advanced ->
                            True

                        Extreme ->
                            True
            in
            ( { model | chosenDifficulty = newDifficulty, rootNotes = setRootNotes newDifficulty, areNotesShuffled = areNotesShuffled }, Cmd.none )

        ChordGroupChosen chordTypes ->
            let
                fetchCount =
                    List.length model.rootNotes
            in
            ( { model | isGameStarted = True, maybeChords = Just [], pendingFetches = fetchCount }
            , TheoryApi.fetchChords model.rootNotes chordTypes GotChordData
            )

        Shuffled chordNotes ->
            -- Don't mutate the canonical `randomizedChord` used for equality checks.
            -- Store the shuffled/ display-only notes in `randomizedChordNotes`.
            ( { model | randomizedChordNotes = Just chordNotes }, Cmd.none )

        RandomChordPicked randomIndex ->
            let
                chordCount =
                    List.length (Maybe.withDefault [] model.maybeChords)

                -- helper to pick the chord at index or default
                newRandomChord =
                    pickRandomChord model.maybeChords randomIndex

                notes =
                    newRandomChord.notes
            in
            case model.lastRandomIndex of
                Just lastIndex ->
                    if lastIndex == randomIndex && chordCount > 1 then
                        -- avoid same index: try again
                        ( model, randomizeChord chordCount )

                    else
                        ( { model
                            | randomizedChord = Just newRandomChord
                            , lastRandomIndex = Just randomIndex
                            , randomizedChordNotes = Just notes
                          }
                        , shuffleNotesInChord model notes
                        )

                Nothing ->
                    ( { model
                        | randomizedChord = Just newRandomChord
                        , lastRandomIndex = Just randomIndex
                        , randomizedChordNotes = Just notes
                      }
                    , shuffleNotesInChord model notes
                    )

        ToggleNotesShuffle ->
            ( { model | areNotesShuffled = not model.areNotesShuffled }, Cmd.none )

        ChordChosen chord ->
            let
                modelWithChordChosen =
                    { model | maybeChosenChord = Just chord }

                ( updatedModel, cmd ) =
                    checkIfChordIsCorrect modelWithChordChosen
            in
            ( updatedModel, cmd )

        GoBack ->
            let
                updatedModel =
                    { model
                        | isGameStarted = False
                        , maybeChosenChord = Nothing
                        , gameOver = False
                        , mistakes = 0
                        , score = 0
                    }

                _ =
                    Debug.log "hello" updatedModel
            in
            ( updatedModel, Cmd.none )


listOfDifficulities : List Difficulty
listOfDifficulities =
    [ Easy, Medium, Hard, Advanced, Extreme ]


isToggleShuffleDisabled : Difficulty -> Bool
isToggleShuffleDisabled difficulty =
    case difficulty of
        Easy ->
            False

        Medium ->
            False

        Hard ->
            True

        Advanced ->
            True

        Extreme ->
            False


view : Model -> Html Msg
view model =
    if model.isGameStarted then
        Html.div []
            [ Html.text "Chord guesser"
            , viewRandomizedChordNotes model
            , viewChords model
            , Html.p [] [ Html.text <| "Score:  " ++ String.fromInt model.score ]
            , Html.p [] [ Html.text <| "Mistakes:  " ++ String.fromInt model.mistakes ]
            , Html.button [ HA.class "custom-button", HE.onClick GoBack ] [ Html.text "< Back" ]
            ]

    else
        Html.section []
            [ Html.h2 [] [ Html.text "Chord Guesser Exercise" ]
            , viewDifficultyButtons listOfDifficulities
            , Html.div []
                [ Html.text ("Chosen difficulty: " ++ stringFromDifficulty model.chosenDifficulty)
                ]
            , Html.label [ HA.for "shuffle-notes-checkbox" ] [ Html.text "Shuffle Notes" ]
            , Html.input
                [ HA.type_ "checkbox"
                , HA.checked model.areNotesShuffled
                , HA.id "shuffle-notes-checkbox"
                , HE.onClick ToggleNotesShuffle
                , HA.disabled (isToggleShuffleDisabled model.chosenDifficulty)
                ]
                [ Html.text "Toggle Shuffle Notes" ]
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
            ]


viewDifficultyButtons : List Difficulty -> Html Msg
viewDifficultyButtons difficulties =
    Html.div []
        (List.map
            (\difficulty ->
                Html.button
                    [ HA.class "custom-button"
                    , HE.onClick (DifficultyChosen difficulty)
                    ]
                    [ Html.text (stringFromDifficulty difficulty) ]
            )
            difficulties
        )


setRootNotes : Difficulty -> List String
setRootNotes difficulty =
    case difficulty of
        Easy ->
            [ "C", "G", "F" ]

        -- Only C, G, F, notes are not shuffled, user can choose to shuffle notes maybe?
        Medium ->
            [ "C", "G", "F", "D", "A" ]

        Hard ->
            [ "C", "G", "F", "D", "A", "Bb", "Eb" ]

        -- Notes are always shuffled
        Advanced ->
            [ "C", "G", "F", "D", "A", "Bb", "Eb", "E", "B", "Ab", "Db" ]

        Extreme ->
            [ "C", "G", "F", "D", "A", "Bb", "Eb", "E", "B", "Ab", "Db", "Fsharp", "Csharp", "Gsharp", "Dsharp", "Asharp" ]


stringFromDifficulty : Difficulty -> String
stringFromDifficulty difficulty =
    case difficulty of
        Easy ->
            "Easy"

        Medium ->
            "Medium"

        Hard ->
            "Hard"

        Advanced ->
            "Advanced"

        Extreme ->
            "Extreme"



-- rotateLeft : List a -> List a
-- rotateLeft list =
--     case list of
--         x :: xs ->
--             xs ++ [ x ]
--         [] ->
--             []


viewChords : Model -> Html Msg
viewChords model =
    case model.maybeChords of
        Just chords ->
            Html.div [ HA.class "chords-container" ]
                (List.map viewChord chords)

        Nothing ->
            Html.div [] [ Html.text "No chords found" ]


viewChord : TheoryApi.Chord -> Html Msg
viewChord chord =
    Html.div [ HA.class "custom-button", HE.onClick (ChordChosen chord) ]
        [ Html.text chord.chord ]


viewRandomizedChordNotes : Model -> Html Msg
viewRandomizedChordNotes model =
    case model.randomizedChordNotes of
        Just randomizedChordNotes ->
            Html.p [] [ Html.text ("Which chord is this? " ++ String.join ", " randomizedChordNotes) ]

        Nothing ->
            Html.p [] [ Html.text "No chord found" ]



-- Random.generate Shuffled (RandomList.shuffle notes)


shuffleNotesInChord : Model -> List String -> Cmd Msg
shuffleNotesInChord model notes =
    if model.areNotesShuffled then
        Random.generate Shuffled (RandomList.shuffle notes)

    else
        Cmd.none


defaultChord : TheoryApi.Chord
defaultChord =
    { chord = "No chord found"
    , root = ""
    , formula = []
    , degrees = []
    , notes = []
    }


pickRandomChord : Maybe (List TheoryApi.Chord) -> Int -> TheoryApi.Chord
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
            -- Compare by the chord identifier (the `chord` string) so presentation-only
            -- reordering of `notes` doesn't affect correctness.
            if chosenChord.chord == randomizedChord.chord then
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
