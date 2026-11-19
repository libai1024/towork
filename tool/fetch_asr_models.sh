#!/usr/bin/env bash
# Downloads the bundled offline speech models (git-ignored *.onnx) and
# verifies their SHA-256. Run once after cloning, before `flutter build`.
#
#   tool/fetch_asr_models.sh
set -euo pipefail
cd "$(dirname "$0")/.."

SV=csukuangfj/sherpa-onnx-sense-voice-zh-en-ja-ko-yue-2024-07-17
# target | sha256 | candidate URLs (tried in order)
MODELS=(
  "assets/asr/sense-voice-int8/model.int8.onnx|c71f0ce00bec95b07744e116345e33d8cbbe08cef896382cf907bf4b51a2cd51|https://hf-mirror.com/$SV/resolve/main/model.int8.onnx https://huggingface.co/$SV/resolve/main/model.int8.onnx"
  "assets/asr/silero-vad/silero_vad.onnx|9e2449e1087496d8d4caba907f23e0bd3f78d91fa552479bb9c23ac09cbb1fd6|https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/silero_vad.onnx"
)

sha() { shasum -a 256 "$1" | cut -d' ' -f1; }

for entry in "${MODELS[@]}"; do
  IFS='|' read -r target want urls <<<"$entry"
  if [[ -f "$target" && "$(sha "$target")" == "$want" ]]; then
    echo "ok      $target"
    continue
  fi
  mkdir -p "$(dirname "$target")"
  done_one=false
  for url in $urls; do
    echo "fetch   $target <- $url"
    if curl -fL --retry 3 -C - -o "$target.part" "$url" &&
      [[ "$(sha "$target.part")" == "$want" ]]; then
      mv "$target.part" "$target"
      done_one=true
      break
    fi
    echo "failed  $url" >&2
    rm -f "$target.part"
  done
  $done_one || { echo "could not fetch $target" >&2; exit 1; }
  echo "ok      $target"
done
