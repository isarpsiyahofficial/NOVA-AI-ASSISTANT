# NOVA Real Bidirectional Carrier Call Bridge

This stack solves the carrier-media problem outside Android's public SIM-call audio boundary.
It does not pretend that speakerphone and microphone mute are a call media transport.

## Real media path

```text
Mobile number / carrier call forwarding / SIP DID
        ↓
SIP or PSTN trunk
        ↓
Asterisk PJSIP
        ↓ signed-linear PCM in both directions
Asterisk AudioSocket
        ↓
NOVA media gateway
        ├─ Whisper STT
        ├─ Gemini / OpenAI / Qwen / generic NOVA brain
        └─ Turkish Piper TTS
        ↓ 20 ms PCM frames
Asterisk AudioSocket
        ↓
Original caller hears NOVA in the same phone call
```

The Android application still owns local Telecom controls, contacts, permissions, owner voice
verification and user-facing state. Carrier downlink/uplink media is handled by this stack.

## Components

- `asterisk/`: inbound and outbound SIP/PSTN routes, AudioSocket and call recordings.
- `media_gateway/`: actual PCM endpointing, Whisper STT, AI decision and Piper TTS injection.
- `control_gateway/`: authenticated health, policy synchronization and owner-approved outbound call control through private Asterisk AMI.
- `run_e2e.sh`: originates a real Asterisk call and verifies both audio directions.

## GitHub test

The workflow `.github/workflows/nova-call-bridge-e2e.yml` performs all of these operations:

1. Downloads checksum-verified Whisper and Turkish Piper models.
2. Builds Asterisk, media gateway and control gateway containers.
3. Generates a real Turkish caller fixture with Piper.
4. Originates an Asterisk Local call.
5. Routes caller PCM into AudioSocket.
6. Transcribes it with Whisper.
7. Produces an AI reply.
8. Synthesizes and writes the reply back to the caller leg.
9. Records the caller channel.
10. Fails unless transcript tokens, input/output byte counts, RMS thresholds and returned caller audio all pass.

Run locally:

```bash
cp infra/call-bridge/.env.example infra/call-bridge/.env
chmod +x infra/call-bridge/run_e2e.sh
infra/call-bridge/run_e2e.sh
```

Evidence is written under `infra/call-bridge/runtime/`.

## Production deployment

1. Obtain a SIP trunk or DID from a provider that permits the intended call-assistant use case.
2. Route the user's mobile number to that DID with carrier call forwarding, or make the SIP DID the NOVA-assisted number.
3. Copy `.env.example` to a protected `.env` outside version control.
4. Set all `NOVA_SIP_TRUNK_*`, `NOVA_CALL_CONTROL_TOKEN` and `NOVA_ASTERISK_AMI_SECRET` values.
5. Select `gemini`, `openai`, `qwen` or `generic` as `NOVA_CALL_AI_PROVIDER`.
6. Place the public SIP/RTP side behind the deployment firewall rules required by the trunk provider.
7. Publish only the HTTPS control endpoint through a reverse proxy. Never expose AMI port 5038 publicly.
8. Run:

```bash
cd infra/call-bridge
docker compose up -d --build
curl -fsS http://127.0.0.1:18090/health
```

## Inbound calls

The trunk sends calls to context `from-nova-carrier`. Asterisk answers, creates a UUID,
records the channel and attaches it to the media gateway with AudioSocket.

## Owner-approved outbound calls

The HTTPS control endpoint receives:

```http
POST /calls/outbound
Authorization: Bearer <NOVA_CALL_CONTROL_TOKEN>
Content-Type: application/json

{
  "to": "+905551112233",
  "owner_approved": true,
  "contact_name": "Anne",
  "greeting": "Merhaba, ben NOVA.",
  "allowed_topics": ["Aile", "Günlük plan"],
  "forbidden_topics": ["Finans", "Kimlik bilgileri"]
}
```

The control service validates the number and owner approval, stores the call policy and uses
private AMI to bridge the real outbound PSTN leg to the AudioSocket AI leg.

## Policy API

```http
POST /policies
Authorization: Bearer <token>

{
  "phone_number": "+905551112233",
  "contact_name": "Anne",
  "greeting": "Merhaba, ben NOVA.",
  "allowed_topics": ["Aile"],
  "forbidden_topics": ["Finans"],
  "owner_approved": true
}
```

Other endpoints:

- `GET /health`
- `GET /sessions/latest`
- `GET /sessions/context/<uuid>`
- `GET /policies/<phone-number>`

Write endpoints require the bearer token.

## Security boundaries

- Production trunk, AI and control secrets are environment values only.
- AMI is available only on the private Docker network.
- The control API requires a long bearer token and should be exposed only through HTTPS.
- Outbound calling requires explicit owner approval.
- Phone numbers are normalized and rejected outside 7–15 digits.
- Call evidence and recordings are deployment data; retention and consent policies must be configured before production use.

## Real-device gate

`.github/workflows/nova-tecno-real-device-lab.yml` is intentionally self-hosted. It requires a
USB-connected physical TECNO device and a real call-trigger provider. It tests actual SIM ringing,
answer/mute/speaker/hangup, SIP media, screen-lock survival, thirty-minute background operation,
memory, CPU and battery evidence. Emulators cannot satisfy that gate.
