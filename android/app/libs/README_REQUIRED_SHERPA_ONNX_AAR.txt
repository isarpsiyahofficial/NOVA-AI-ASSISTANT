Nova API-first final patch keeps local ears and local speaker identity.

Required external file that is not bundled here because it was not present in the uploaded ZIP:
- android/app/libs/sherpa-onnx.aar

Keep this AAR from your local asset/native package. Without it, embedded Sherpa ASR and
nemo_en_titanet_small speaker verification Kotlin imports cannot compile.

The large ASR / TitaNet ONNX model files remain in your assets side:
- sherpa_asr/config.json
- sherpa_asr/tokens.txt
- sherpa_asr/encoder.onnx / decoder.onnx / joiner.onnx or model.onnx variant
- speaker_id/nemo_en_titanet_small.onnx or speaker_id/nemo_titanet_small/nemo_en_titanet_small.onnx
