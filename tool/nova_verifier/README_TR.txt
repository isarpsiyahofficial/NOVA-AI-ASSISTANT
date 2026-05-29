
NOVA CMD VERIFIER

AmaÃ§:
- Manuel "denedim olmadÄ±" dÃ¶ngÃ¼sÃ¼nÃ¼ azaltmak.
- CMD Ã¼zerinden Nova'i aÃ§Ä±p gerÃ§ek model-brain zincirini otomatik doÄŸrulamak.
- PASS/FAIL Ã¼retmek.

Ã‡alÄ±ÅŸtÄ±rma:
1) Bu klasÃ¶rÃ¼ C:\Projects\nova\tool\nova_verifier gibi bir yere Ã§Ä±kar.
2) Telefon baÄŸlÄ± ve adb aÃ§Ä±k olsun.
3) CMD:
   cd /d C:\Projects\nova\tool\nova_verifier
   nova_verify.cmd

VarsayÄ±lan:
- Paket: com.example.nova
- Activity: com.example.nova/.MainActivity
- SÃ¼re: 180 saniye
- Build/Flutter yoktur.
- UygulamayÄ± aÃ§Ä±kÃ§a MainActivity ile baÅŸlatÄ±r.

Manuel aÃ§mak istersen:
   nova_verify.cmd -NoLaunch

Daha uzun izlemek istersen:
   nova_verify.cmd -DurationSec 300

Bugreport da eklensin:
   nova_verify.cmd -Bugreport

PASS ÅŸartlarÄ±:
- Native generate Ã§aÄŸrÄ±sÄ± gÃ¶rÃ¼lmeli.
- Raw model output gÃ¶rÃ¼lmeli.
- BrainDecision / SingleBrain modelUsed=true olmalÄ±.
- local_model_failed_strict / AI_REQUIRED_BLOCK olmamalÄ±.
- SINGLE_BRAIN_FAST_DECISION, CoreProfileHash, Runtime KatmanÄ± gibi internal format dÄ±ÅŸ cevaba sÄ±zmamalÄ±.
- Timeout, native crash, OOM/LMKD kill olmamalÄ±.

Ã‡Ä±ktÄ±lar:
- nova_verify_out\run_YYYYMMDD_HHMMSS\NOVA_VERIFY_RESULT.txt
- nova_verify_out\run_YYYYMMDD_HHMMSS\11_model_filtered.txt
- nova_verify_out\run_YYYYMMDD_HHMMSS\12_error_filtered.txt
- nova_verify_out\nova_verify_latest.zip

Not:
Bu script "uygulama %100 Ã§alÄ±ÅŸÄ±r" garantisi vermez; cihazdaki gerÃ§ek Ã§alÄ±ÅŸmayÄ± sert kriterlerle otomatik doÄŸrular.
PASS Ã§Ä±kmazsa hangi ÅŸartÄ±n kÄ±rÄ±ldÄ±ÄŸÄ±nÄ± aÃ§Ä±k yazar.
