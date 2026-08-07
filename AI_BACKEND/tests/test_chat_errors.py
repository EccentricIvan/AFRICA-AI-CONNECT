import os
import unittest
from unittest.mock import Mock, patch

from fastapi.testclient import TestClient

from app.config import get_groq_api_key, validate_provider_configuration
from app.main import app
from app.services.chat_service import ChatProviderError, ChatService


class ChatProviderConfigurationTests(unittest.TestCase):
    def test_key_is_trimmed_and_valid_english_request_calls_provider(self):
        response = Mock(status_code=200)
        response.raise_for_status.return_value = None
        response.json.return_value = {
            "choices": [{"message": {"content": "Hello! How can I help?"}}]
        }
        with patch.dict(os.environ, {"GROQ_API_KEY": "  valid-test-key  "}), patch(
            "app.services.chat_service.GROQ_SESSION.post", return_value=response
        ) as post:
            result = ChatService().chat("Hi there.", "eng")
        self.assertEqual(result.response, "Hello! How can I help?")
        self.assertEqual(post.call_args.kwargs["headers"]["Authorization"], "Bearer valid-test-key")

    def test_missing_key_validation_logs_status_not_secret(self):
        with patch.dict(os.environ, {}, clear=True), self.assertLogs(
            "app.config", level="INFO"
        ) as logs:
            self.assertFalse(validate_provider_configuration())
            self.assertIsNone(get_groq_api_key())
        output = " ".join(logs.output)
        self.assertIn("missing", output)
        self.assertNotIn("GROQ_API_KEY", output)

    def test_401_becomes_safe_structured_error(self):
        response = Mock(status_code=401)
        with patch.dict(os.environ, {"GROQ_API_KEY": "invalid-test-key"}), patch(
            "app.services.chat_service.GROQ_SESSION.post", return_value=response
        ):
            with self.assertRaises(ChatProviderError) as raised:
                ChatService().chat("Hi there.", "eng")
        self.assertEqual(raised.exception.code, "CHAT_PROVIDER_AUTH_FAILED")
        self.assertFalse(raised.exception.retryable)

        with patch("app.routes.chat.chat_service.chat", side_effect=raised.exception):
            api_response = TestClient(app).post(
                "/chat", json={"message": "Hi there.", "language": "eng"}
            )
        self.assertEqual(api_response.status_code, 502)
        self.assertEqual(
            api_response.json(),
            {"error": {"code": "CHAT_PROVIDER_AUTH_FAILED", "retryable": False}},
        )
        serialized = api_response.text.lower()
        for forbidden in ("unauthorized", "api.groq.com", "groq_api_key", "invalid-test-key"):
            self.assertNotIn(forbidden, serialized)


if __name__ == "__main__":
    unittest.main()
