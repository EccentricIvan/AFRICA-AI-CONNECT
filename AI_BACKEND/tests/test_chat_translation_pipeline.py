import unittest
from unittest.mock import patch

from app.services.chat_service import (
    ChatProviderError,
    ChatService,
    english_grounding_issues,
)
from app.services.sunbird_service import SunbirdError


class ChatTranslationPipelineTests(unittest.TestCase):
    def test_additional_ugandan_languages_use_translation_pipeline(self):
        for language in ("nyn", "teo", "nyo", "ach"):
            service = ChatService()
            with self.subTest(language=language), patch.object(
                service, "_translate", side_effect=["English request", "Local answer"]
            ) as translate, patch.object(
                service, "_reason_from_transcript", return_value="English answer"
            ):
                result = service.chat("Local request", language)
                self.assertEqual(result.response, "Local answer")
                self.assertEqual(result.provider, "sunbird+groq+sunbird")
                self.assertEqual(translate.call_args_list[0].args[2], language)
                self.assertEqual(translate.call_args_list[1].args[1], language)

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

    def test_unrequested_brands_and_amounts_trigger_rewrite(self):
        issues = english_grounding_issues(
            "Nnyinza ntya okutereka ensimbi?",
            "LATEST USER: How can I save money?",
            "Save UGX 50,000 using MTN Mobile Money or Airtel Money.",
        )
        self.assertEqual(len(issues), 2)
        self.assertIn("mtn", issues[0])
        self.assertIn("invented currency", issues[1])


if __name__ == "__main__":
    unittest.main()
