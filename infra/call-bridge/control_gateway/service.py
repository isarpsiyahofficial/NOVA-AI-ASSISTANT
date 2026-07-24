#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import re
import socket
import time
import urllib.error
import urllib.request
from dataclasses import dataclass, asdict
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any
from urllib.parse import parse_qs, urlparse

HOST = os.getenv("NOVA_CALL_CONTROL_HOST", "0.0.0.0")
PORT = int(os.getenv("NOVA_CALL_CONTROL_PORT", "8090"))
TOKEN = os.getenv("NOVA_CALL_CONTROL_TOKEN", "nova-ci-control-token-not-for-production")
AMI_HOST = os.getenv("NOVA_ASTERISK_AMI_HOST", "asterisk")
AMI_PORT = int(os.getenv("NOVA_ASTERISK_AMI_PORT", "5038"))
AMI_USER = os.getenv("NOVA_ASTERISK_AMI_USER", "nova-control")
AMI_SECRET = os.getenv("NOVA_ASTERISK_AMI_SECRET", "nova-ci-ami-secret-not-for-production")
MEDIA_BASE = os.getenv("NOVA_MEDIA_GATEWAY_BASE_URL", "http://media-gateway:8080")
DATA_DIR = Path(os.getenv("NOVA_CALL_CONTROL_DATA_DIR", "/shared/control"))
DATA_DIR.mkdir(parents=True, exist_ok=True)


def normalize_number(raw: str) -> str:
    value = raw.strip()
    has_plus = value.startswith("+")
    digits = re.sub(r"[^0-9]", "", value)
    if len(digits) < 7 or len(digits) > 15:
        return ""
    return f"+{digits}" if has_plus else digits


def safe_session_id(raw: str) -> str:
    value = raw.strip().lower()
    return value if re.fullmatch(r"[0-9a-f-]{16,64}", value) else ""


def json_request(url: str, timeout: float = 5.0) -> tuple[int, dict[str, Any]]:
    try:
        with urllib.request.urlopen(url, timeout=timeout) as response:
            payload = response.read().decode("utf-8")
            data = json.loads(payload)
            return response.status, data if isinstance(data, dict) else {"data": data}
    except urllib.error.HTTPError as error:
        payload = error.read().decode("utf-8", errors="replace")
        try:
            data = json.loads(payload)
        except Exception:
            data = {"error": payload[:500]}
        return error.code, data
    except Exception as error:
        return 503, {"error": f"{type(error).__name__}: {error}"}


@dataclass
class SessionContext:
    session_id: str
    direction: str
    caller: str = ""
    called: str = ""
    contact_name: str = ""
    greeting: str = ""
    allowed_topics: list[str] | None = None
    forbidden_topics: list[str] | None = None
    owner_approved: bool = False
    created_at: float = 0.0

    def to_dict(self) -> dict[str, Any]:
        result = asdict(self)
        result["allowed_topics"] = self.allowed_topics or []
        result["forbidden_topics"] = self.forbidden_topics or []
        return result


def session_path(session_id: str) -> Path:
    return DATA_DIR / "sessions" / f"{session_id}.json"


def policy_path(number: str) -> Path:
    safe = number.replace("+", "plus-")
    return DATA_DIR / "policies" / f"{safe}.json"


def save_json(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_suffix(path.suffix + ".tmp")
    temp.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    temp.replace(path)


def load_json(path: Path) -> dict[str, Any]:
    if not path.is_file():
        return {}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
        return data if isinstance(data, dict) else {}
    except Exception:
        return {}


def ami_action(fields: dict[str, str]) -> dict[str, str]:
    with socket.create_connection((AMI_HOST, AMI_PORT), timeout=8) as sock:
        stream = sock.makefile("rwb", buffering=0)
        banner = stream.readline().decode("utf-8", errors="replace").strip()
        login = {
            "Action": "Login",
            "Username": AMI_USER,
            "Secret": AMI_SECRET,
            "Events": "off",
        }
        _ami_write(stream, login)
        login_response = _ami_read(stream)
        if login_response.get("Response") != "Success":
            raise RuntimeError(f"AMI login failed: {login_response}")
        _ami_write(stream, fields)
        response = _ami_read(stream)
        _ami_write(stream, {"Action": "Logoff"})
        return {"banner": banner, **response}


def _ami_write(stream: Any, fields: dict[str, str]) -> None:
    payload = "".join(f"{key}: {value}\r\n" for key, value in fields.items()) + "\r\n"
    stream.write(payload.encode("utf-8"))


def _ami_read(stream: Any) -> dict[str, str]:
    result: dict[str, str] = {}
    while True:
        line = stream.readline()
        if not line:
            break
        text = line.decode("utf-8", errors="replace").rstrip("\r\n")
        if not text:
            if result:
                break
            continue
        if ":" in text:
            key, value = text.split(":", 1)
            result[key.strip()] = value.strip()
    return result


class Handler(BaseHTTPRequestHandler):
    server_version = "NOVA-Call-Control/1.0"

    def log_message(self, fmt: str, *args: Any) -> None:
        print(f"{self.client_address[0]} {fmt % args}", flush=True)

    def do_GET(self) -> None:  # noqa: N802
        parsed = urlparse(self.path)
        if parsed.path == "/health":
            media_status, media = json_request(f"{MEDIA_BASE}/health")
            self.respond(
                200 if media_status == 200 and media.get("ready") is True else 503,
                {
                    "ready": media_status == 200 and media.get("ready") is True,
                    "media_gateway": media,
                    "ami_host": AMI_HOST,
                    "control_token_configured": len(TOKEN) >= 24,
                },
            )
            return
        if parsed.path == "/sessions/latest":
            status, body = json_request(f"{MEDIA_BASE}/sessions/latest")
            self.respond(status, body)
            return
        if parsed.path.startswith("/sessions/context/"):
            session_id = safe_session_id(parsed.path.rsplit("/", 1)[-1])
            if not session_id:
                self.respond(400, {"error": "invalid session_id"})
                return
            context = load_json(session_path(session_id))
            self.respond(200 if context else 404, context or {"error": "session context not found"})
            return
        if parsed.path.startswith("/policies/"):
            number = normalize_number(parsed.path.rsplit("/", 1)[-1])
            if not number:
                self.respond(400, {"error": "invalid phone number"})
                return
            policy = load_json(policy_path(number))
            self.respond(200 if policy else 404, policy or {"error": "policy not found"})
            return
        self.respond(404, {"error": "not found"})

    def do_POST(self) -> None:  # noqa: N802
        if not self.authorized():
            self.respond(401, {"error": "unauthorized"})
            return
        parsed = urlparse(self.path)
        body = self.read_json()
        if body is None:
            return
        if parsed.path == "/calls/outbound":
            self.outbound(body)
            return
        if parsed.path == "/sessions/register":
            self.register_session(body)
            return
        if parsed.path == "/policies":
            self.save_policy(body)
            return
        self.respond(404, {"error": "not found"})

    def authorized(self) -> bool:
        if len(TOKEN) < 24:
            return False
        header = self.headers.get("Authorization", "")
        return header == f"Bearer {TOKEN}"

    def read_json(self) -> dict[str, Any] | None:
        try:
            length = int(self.headers.get("Content-Length", "0"))
            if length <= 0 or length > 262_144:
                raise ValueError("invalid content length")
            data = json.loads(self.rfile.read(length).decode("utf-8"))
            if not isinstance(data, dict):
                raise ValueError("body must be an object")
            return data
        except Exception as error:
            self.respond(400, {"error": f"invalid JSON: {error}"})
            return None

    def outbound(self, body: dict[str, Any]) -> None:
        number = normalize_number(str(body.get("to") or ""))
        if not number:
            self.respond(400, {"error": "invalid destination"})
            return
        if body.get("owner_approved") is not True:
            self.respond(403, {"error": "owner_approved=true is required"})
            return
        policy = self.policy_from_body(body, number)
        save_json(policy_path(number), policy)
        action_id = f"nova-outbound-{int(time.time() * 1000)}"
        try:
            response = ami_action(
                {
                    "Action": "Originate",
                    "ActionID": action_id,
                    "Channel": f"Local/{number}@nova-outbound/n",
                    "Context": "nova-call-test",
                    "Exten": "7000",
                    "Priority": "1",
                    "Async": "true",
                    "CallerID": str(body.get("caller_id") or "NOVA"),
                    "Variable": "NOVA_OWNER_APPROVED=1",
                }
            )
        except Exception as error:
            self.respond(502, {"error": f"AMI originate failed: {type(error).__name__}: {error}"})
            return
        accepted = response.get("Response") == "Success"
        self.respond(
            202 if accepted else 502,
            {
                "accepted": accepted,
                "action_id": action_id,
                "destination": number,
                "ami": response,
            },
        )

    def register_session(self, body: dict[str, Any]) -> None:
        session_id = safe_session_id(str(body.get("session_id") or ""))
        if not session_id:
            self.respond(400, {"error": "invalid session_id"})
            return
        caller = normalize_number(str(body.get("caller") or ""))
        called = normalize_number(str(body.get("called") or ""))
        direction = str(body.get("direction") or "unknown").strip().lower()
        lookup = caller if direction == "inbound" else called
        policy = load_json(policy_path(lookup)) if lookup else {}
        context = SessionContext(
            session_id=session_id,
            direction=direction,
            caller=caller,
            called=called,
            contact_name=str(policy.get("contact_name") or ""),
            greeting=str(policy.get("greeting") or ""),
            allowed_topics=list(policy.get("allowed_topics") or []),
            forbidden_topics=list(policy.get("forbidden_topics") or []),
            owner_approved=bool(body.get("owner_approved") or policy.get("owner_approved")),
            created_at=time.time(),
        )
        save_json(session_path(session_id), context.to_dict())
        self.respond(201, context.to_dict())

    def save_policy(self, body: dict[str, Any]) -> None:
        number = normalize_number(str(body.get("phone_number") or ""))
        if not number:
            self.respond(400, {"error": "invalid phone_number"})
            return
        policy = self.policy_from_body(body, number)
        save_json(policy_path(number), policy)
        self.respond(200, policy)

    @staticmethod
    def policy_from_body(body: dict[str, Any], number: str) -> dict[str, Any]:
        allowed = [str(item).strip() for item in list(body.get("allowed_topics") or []) if str(item).strip()]
        forbidden = [str(item).strip() for item in list(body.get("forbidden_topics") or []) if str(item).strip()]
        return {
            "phone_number": number,
            "contact_name": str(body.get("contact_name") or "").strip()[:120],
            "greeting": str(body.get("greeting") or "").strip()[:500],
            "allowed_topics": allowed[:50],
            "forbidden_topics": forbidden[:50],
            "owner_approved": body.get("owner_approved") is True,
            "updated_at": time.time(),
        }

    def respond(self, status: int, body: dict[str, Any]) -> None:
        payload = json.dumps(body, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)


if __name__ == "__main__":
    print(f"NOVA call control listening on {HOST}:{PORT}", flush=True)
    ThreadingHTTPServer((HOST, PORT), Handler).serve_forever()
