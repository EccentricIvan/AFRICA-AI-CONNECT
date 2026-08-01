import unittest
from unittest.mock import patch

from app.services.chat_service import ChatProviderError, ChatService
from app.services.sunbird_service import SunbirdError


class ChatTranslationPipelineTests(unittest.TestCase):
    def setUp(self):
        self.service = ChatService()

    def test_luganda_is_translated_reasoned_and_translated_back(self):
        context = [
            {"role": "user", "content": "Nina emitwalo kkumi."},
            {"role": "assistant", "content": "Oyagala kukola ki?"},
        ]
        with patch(
            "app.services.chat_service.sunbird_service.translate",
            side_effect=[
                "USER: I have UGX 100,000.\nASSISTANT: What do you want to do?\nLATEST USER: Give me practical business advice.",
                "Tandika okutunda ebibala mu kitundu kyo.",
            ],
        ) as translate, patch.object(
            self.service,
            "_groq",
            return_value="Start by selling fruit in your neighborhood.",
        ) as groq:
            result = self.service.chat("Mpa amagezi ga bizinensi ag'enjawulo.", "lug", context)

        self.assertEqual(result.provider, "sunbird+groq+sunbird")
        self.assertEqual(result.response, "Tandika okutunda ebibala mu kitundu kyo.")
        self.assertEqual(translate.call_count, 2)
        inbound = translate.call_args_list[0]
        self.assertEqual(inbound.kwargs["source_language"], "lug")
        self.assertEqual(inbound.kwargs["target_language"], "eng")
        self.assertIn("ASSISTANT: Oyagala kukola ki?", inbound.args[0])
        outbound = translate.call_args_list[1]
        self.assertEqual(outbound.kwargs["source_language"], "eng")
        self.assertEqual(outbound.kwargs["target_language"], "lug")
        reasoning_prompt = groq.call_args.args[0][1]["content"]
        self.assertIn("translated conversation", reasoning_prompt.lower())
        self.assertIn("UGX", reasoning_prompt)
        self.assertIn("401(k)", reasoning_prompt)
        self.assertIn("Do not name a specific bank", reasoning_prompt)
        self.assertIn("do not invent one", reasoning_prompt)

    def test_swahili_uses_the_same_pipeline(self):
        with patch(
            "app.services.chat_service.sunbird_service.translate",
            side_effect=["LATEST USER: How can I save money?", "Weka akiba kidogo kila siku."],
        ), patch.object(self.service, "_groq", return_value="Save a small amount every day."):
            result = self.service.chat("Ninawezaje kuweka akiba?", "swa")
        self.assertEqual(result.response, "Weka akiba kidogo kila siku.")
        self.assertEqual(result.provider, "sunbird+groq+sunbird")

    def test_english_still_goes_directly_to_groq(self):
        with patch.object(self.service, "_groq", return_value="A relevant English answer."), patch(
            "app.services.chat_service.sunbird_service.translate"
        ) as translate:
            result = self.service.chat("Give me practical advice.", "eng")
        self.assertEqual(result.provider, "groq")
        self.assertEqual(result.response, "A relevant English answer.")
        translate.assert_not_called()

    def test_translation_failure_is_safe_and_retryable(self):
        with patch(
            "app.services.chat_service.sunbird_service.translate",
            side_effect=SunbirdError("technical provider detail"),
        ):
            with self.assertRaises(ChatProviderError) as raised:
                self.service.chat("Oli otya?", "lug")
        self.assertEqual(raised.exception.code, "CHAT_PROVIDER_UNAVAILABLE")
        self.assertTrue(raised.exception.retryable)
        self.assertNotIn("technical", str(raised.exception))


if __name__ == "__main__":
    unittest.main()
