"""Websockify Basic Auth plugin backed by a salted hash file."""
import base64
import hashlib
import hmac
import json

from websockify.auth_plugins import AuthenticationError


class HashedBasicAuth:
    def __init__(self, src=None):
        if not src:
            raise ValueError("Credential file is required")
        with open(src, encoding="utf-8") as handle:
            config = json.load(handle)
        self.username = config["username"]
        self.salt = bytes.fromhex(config["salt"])
        self.expected = bytes.fromhex(config["digest"])

    def authenticate(self, headers, target_host, target_port):
        header = headers.get("Authorization", "")
        if not header.startswith("Basic "):
            self._demand_auth()
        try:
            decoded = base64.b64decode(header[6:], validate=True).decode("ISO-8859-1")
            username, password = decoded.split(":", 1)
        except (ValueError, UnicodeDecodeError):
            self._demand_auth()
            return

        actual = hashlib.scrypt(
            password.encode("utf-8"), salt=self.salt, n=2**14, r=8, p=1, dklen=32
        )
        if not (hmac.compare_digest(username, self.username) and hmac.compare_digest(actual, self.expected)):
            self._demand_auth()

    @staticmethod
    def _demand_auth():
        raise AuthenticationError(
            response_code=401,
            response_headers={"WWW-Authenticate": 'Basic realm="SAP Override"'},
            response_msg="Authentication required",
        )
