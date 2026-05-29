Place the real Sherpa ASR assets here for native-first loading.
Supported starter names:
- model.onnx
- model.int8.onnx
- encoder.onnx
- decoder.onnx
- joiner.onnx
- tokens.txt
- config.json

NovaAsrModelLocator now checks this native directory first,
then nova_asr/, models/asr/, and finally flutter_assets/assets/models/asr/.
