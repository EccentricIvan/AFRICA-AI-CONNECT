import os
import unittest
from unittest.mock import Mock, patch

from api.index import ChatMessage, ChatRequest, chat, health


class VercelApiTest(unittest.TestCase):
    def test_health_lists_all_seven_languages(self):
        payload = health()
        self.assertEqual(payload["status"], "ok")
        self.assertEqual(payload["supported_languages"], [
            "en", "lg", "sw", "nyn", "nyo", "ach", "teo"
        ])

    @patch.dict(os.environ, {"GROQ_API_KEY": "test-key"})
    @patch("api.index.requests.post")
    def test_chat_forwards_selected_language_to_groq(self, post: Mock):
        response = Mock()
        response.raise_for_status.return_value = None
        response.json.return_value = {
            "choices": [{"message": {"content": "Agandi?"}}]
        }
        post.return_value = response

        payload = chat(ChatRequest(
            message="And next?",
            language="nyn",
            history=[ChatMessage(role="user", content="Hello")],
        ))

        self.assertEqual(payload["reply"], "Agandi?")
        request_payload = post.call_args.kwargs["json"]
        self.assertIn("Runyankore", request_payload["messages"][0]["content"])
        self.assertEqual(request_payload["messages"][1]["content"], "Hello")
        self.assertEqual(request_payload["messages"][2]["content"], "And next?")


if __name__ == "__main__":
    unittest.main()
