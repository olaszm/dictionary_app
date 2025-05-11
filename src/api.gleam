import gleam/dynamic/decode
import gleam/json
import gleam/option.{None, Some}
import lustre/effect.{type Effect}
import rsvp
import types.{
  type Msg, ApiReturnedWord, Definition, ErrorResponse, Meaning, Phonetic, Word,
}

pub fn get_word_data(word: String) -> Effect(Msg) {
  let def_decoder = {
    use d <- decode.field("definition", decode.string)
    decode.success(Definition(def: d))
  }

  let meaning_decoder = {
    use synonyms <- decode.field("synonyms", decode.list(decode.string))
    use p <- decode.field("partOfSpeech", decode.string)
    use def <- decode.field("definitions", decode.list(def_decoder))

    decode.success(Meaning(synonyms:, part_of_speech: p, definitions: def))
  }

  let phonetics_decoder = {
    use text <- decode.optional_field("text", "", decode.string)
    use audio <- decode.field("audio", decode.string)

    let p_text = case text {
      "" -> None
      _ -> Some(text)
    }

    decode.success(Phonetic(text: p_text, audio:))
  }

  let decoder = {
    use word <- decode.field("word", decode.string)
    use phonetic <- decode.optional_field("phonetic", "", decode.string)
    use meanings <- decode.field("meanings", decode.list(meaning_decoder))
    use phonetics <- decode.field("phonetics", decode.list(phonetics_decoder))

    let p = case phonetic {
      "" -> None
      _ -> Some(phonetic)
    }

    decode.success(Word(word:, phonetic: p, meanings:, phonetics:))
  }

  let url = "https://api.dictionaryapi.dev/api/v2/entries/en/" <> word
  let handler = rsvp.expect_json(decode.list(decoder), ApiReturnedWord)

  rsvp.get(url, handler)
}

pub fn decode_error(
  err: String,
) -> Result(types.ErrorResponse, json.DecodeError) {
  let err_decoder = {
    use title <- decode.field("title", decode.string)
    use message <- decode.field("message", decode.string)
    use resolution <- decode.field("resolution", decode.string)

    decode.success(ErrorResponse(title:, message:, resolution:))
  }

  json.parse(err, err_decoder)
}
