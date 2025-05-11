import gleam/option.{type Option}
import rsvp

pub type Model {
  Model(
    loading: Bool,
    txt: String,
    data: Option(Word),
    is_playing: Bool,
    error_text: Option(ErrorResponse),
  )
}

pub type Word {
  Word(
    word: String,
    phonetic: Option(String),
    meanings: List(Meaning),
    phonetics: List(Phonetic),
  )
}

pub type Phonetic {
  Phonetic(text: Option(String), audio: String)
}

pub type Meaning {
  Meaning(
    part_of_speech: String,
    synonyms: List(String),
    definitions: List(Definition),
  )
}

pub type Definition {
  Definition(def: String)
}

pub type ErrorResponse {
  ErrorResponse(title: String, message: String, resolution: String)
}

pub type Msg {
  UserSetText(String)
  UserSearch
  UserPressedEnter(String)
  ApiReturnedWord(Result(List(Word), rsvp.Error))
  UserPausedAudio(String)
  UserPlayedAudio(String)
  UserClickedOnSynonym(String)
  AudioEnded
}
