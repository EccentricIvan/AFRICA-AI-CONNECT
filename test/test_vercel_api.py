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

    @patch.dict(os.environ, {
        "GROQ_API_KEY": "test-key",
        "SUNBIRD_API_TOKEN": "sunbird-key",
    })
    @patch("api.index.requests.post")
    def test_local_chat_uses_sunbird_groq_sunbird_pipeline(self, post: Mock):
        to_english = Mock()
        to_english.raise_for_status.return_value = None
        to_english.json.return_value = {
            "output": {"translated_text": "USER: Hello\nUSER: And next?"}
        }
        groq = Mock()
        groq.raise_for_status.return_value = None
        groq.json.return_value = {
            "choices": [{"message": {"content": "Here is the next step."}}]
        }
        to_runyankore = Mock()
        to_runyankore.raise_for_status.return_value = None
        to_runyankore.json.return_value = {
            "output": {"translated_text": "Eki nikyo ekirikukurataho."}
        }
        post.side_effect = [to_english, groq, to_runyankore]

        payload = chat(ChatRequest(
            message="And next?",
            language="nyn",
            history=[ChatMessage(role="user", content="Hello")],
        ))

        self.assertEqual(payload["reply"], "Eki nikyo ekirikukurataho.")
        self.assertEqual(payload["provider"], "sunbird+groq+sunbird")
        self.assertEqual(post.call_count, 3)
        first_translation = post.call_args_list[0].kwargs["json"]
        self.assertEqual(first_translation["source_language"], "nyn")
        self.assertEqual(first_translation["target_language"], "eng")
        groq_payload = post.call_args_list[1].kwargs["json"]
        self.assertIn("English translation", groq_payload["messages"][-1]["content"])
        last_translation = post.call_args_list[2].kwargs["json"]
        self.assertEqual(last_translation["source_language"], "eng")
        self.assertEqual(last_translation["target_language"], "nyn")

    @patch.dict(os.environ, {"GROQ_API_KEY": "test-key"})
    @patch("api.index.requests.post")
    def test_english_chat_keeps_conversation_history(self, post: Mock):
        response = Mock()
        response.raise_for_status.return_value = None
        response.json.return_value = {
            "choices": [{"message": {"content": "Agandi?"}}]
        }
        post.return_value = response

        payload = chat(ChatRequest(
            message="And next?",
            language="en",
            history=[ChatMessage(role="user", content="Hello")],
        ))

        self.assertEqual(payload["reply"], "Agandi?")
        request_payload = post.call_args.kwargs["json"]
        self.assertEqual(request_payload["messages"][1]["content"], "Hello")
        self.assertEqual(request_payload["messages"][2]["content"], "And next?")


if __name__ == "__main__":
    unittest.main()
