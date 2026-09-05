# Bundled third-party: Piper TTS

This folder vendors the [Piper](https://github.com/rhasspy/piper) text-to-speech
engine and one voice model so Text Speaker sounds good on a fresh clone with no
manual setup.

## Why an archived release

Piper's original repository (`rhasspy/piper`) was archived in October 2025;
development continued at `OHF-Voice/piper1-gpl` under the GPL-3.0 license as a
Python `pip` package. That fits neither this repo's "clone and run, no Python
required" goal nor its licensing preferences, so this bundles the last release
of the original MIT-licensed, standalone-binary project instead:
**`2023.11.14-2`**. It won't receive further upstream fixes; that's an
accepted trade-off for portability and license simplicity.

## What's here

- `Engine/` - the official `piper_windows_amd64.zip` release (MIT). Unmodified,
  except `espeak-ng-data`'s ~100 non-English dictionary files were removed
  (only `en_dict` is needed here) to cut this folder from ~18MB to ~1MB;
  synthesis was re-verified afterward.
  - `Engine/LICENSE-piper.txt` - Piper's MIT license.
  - `Engine/LICENSE-espeak-ng.txt` - Piper bundles `espeak-ng.dll` for
    phonemization, which is GPL-3.0. It's redistributed here verbatim,
    unmodified, exactly as shipped in Piper's own official release. Source:
    https://github.com/espeak-ng/espeak-ng
- `Voices/en_US-lessac-medium/` - a medium-quality English voice model (MIT),
  from https://huggingface.co/rhasspy/piper-voices. See `MODEL_CARD.md` for
  the underlying training dataset and its own license terms.

## Usage

`Piper Synthesizer.ahk` wraps `Engine/piper.exe`: give it text, get back a
path to a synthesized WAV file. See that file for details.
