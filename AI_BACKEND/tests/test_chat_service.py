import unittest
from unittest.mock import patch

from app.services.chat_service import (
    ChatService,
    build_system_prompt,
    normalise_context,
    plain_text,
    quality_issues,
)


class ChatServiceTests(unittest.TestCase):
    def setUp(self):
        self.service = ChatService()

    def reply(self, message, answer, context=None):
        with patch.object(self.service, "_generate", return_value=answer) as generate:
            result = self.service.chat(message, "lug", context or [])
        return result.response, generate

    def test_culturally_appropriate_luganda_greeting(self):
        response, generate = self.reply(
            "Mukama yebazibwe",
            "Amiina! Mukama yebazibwe nnyo. Oli otya leero?",
        )
        self.assertIn("Amiina", response)
        self.assertNotIn("support", response.lower())
        self.assertEqual(generate.call_count, 1)

    def test_short_natural_oli_otya_reply(self):
        response, _ = self.reply(
            "Oli otya?", "Ndi bulungi, weebale kubuuza. Ggwe oli otya?"
        )
        self.assertLess(len(response), 100)
        self.assertIn("weebale", response)

    def test_small_business_answer_keeps_amount_and_luganda(self):
        response, _ = self.reply(
            "Nnyinza ntya okutandika obusuubuzi obutono nga nina emitwalo kkumi zokka?",
            "Emitwalo kkumi osobola okugitandikisa obusuubuzi obutono. Tandika n'ekintu kye weetegereza, ogule bya mutwalo musanvu, okuume ebisigadde ku ntambula n'ensimbi ez'amangu.",
        )
        self.assertIn("emitwalo kkumi", response.lower())
        self.assertIn("obusuubuzi", response.lower())

    def test_budget_three_kampala_options_and_no_markdown(self):
        answer = """**Emitwalo kkumi gigabanye bw'oti:**
1. Emitwalo musanvu ku by'okutunda.
2. Emitwalo ebiri ku ntambula n'ebikozesebwa.
3. Omutwalo gumu ogukuume.

Bizinensi ssatu mu Kampala:
1. Ebibala ebyasaliddwa.
2. Amagi amafumbe.
3. Sabbuuni ow'amazzi mu bucupa."""
        response, _ = self.reply(
            "Nsalirewo emitwalo kkumi ezo mu bitundu, era ompe bizinensi ssatu ze nnyinza okutandikawo mu Kampala.",
            answer,
        )
        self.assertIn("emitwalo kkumi", response.lower())
        self.assertIn("ssatu", response.lower())
        self.assertIn("Kampala", response)
        self.assertNotIn("**", response)
        self.assertEqual(sum(line.startswith(("1.", "2.", "3.")) for line in response.splitlines()), 6)

    def test_language_lock_is_present_after_long_history(self):
        context = [
            {"role": "user", "content": "Oli otya?"},
            {"role": "assistant", "content": "Ndi bulungi."},
            {"role": "user", "content": "Njagala bizinensi."},
            {"role": "assistant", "content": "Olina ensimbi mmeka?"},
            {"role": "user", "content": "Emitwalo kkumi."},
            {"role": "assistant", "content": "Kale."},
        ]
        response, generate = self.reply("Mpaayo endala ssatu.", "Ebirala ssatu bye bino: ebibala, amagi, ne sabbuuni.", context)
        sent_context = generate.call_args.args[3]
        self.assertEqual([turn["role"] for turn in sent_context], ["user", "assistant"] * 3)
        self.assertIn("ssatu", response)
        self.assertIn("Reply entirely in Luganda", build_system_prompt("lug"))

    def test_multi_instruction_failure_triggers_one_retry(self):
        incomplete = "Osobola okutunda ebibala mu Kampala."
        complete = "Emitwalo kkumi gigabanye mu bitundu. Bizinensi ssatu mu Kampala ze bino: ebibala, amagi, ne sabbuuni."
        with patch.object(self.service, "_generate", side_effect=[incomplete, complete]) as generate:
            result = self.service.chat(
                "Nsalirewo emitwalo kkumi ezo mu bitundu, era ompe bizinensi ssatu ze nnyinza okutandikawo mu Kampala.",
                "lug",
            )
        self.assertEqual(generate.call_count, 2)
        self.assertIn("ssatu", result.response)
        self.assertIn("emitwalo kkumi", result.response.lower())

    def test_wrong_language_and_markdown_are_detected(self):
        issues = quality_issues(
            "Mpaayo bizinensi ssatu.",
            "**The business options are good and you can start this today.**",
            "lug",
        )
        self.assertGreaterEqual(len(issues), 2)
        self.assertEqual(plain_text("**Ebibala**"), "Ebibala")

    def test_legacy_history_roles_are_recovered(self):
        turns = normalise_context(["user: Oli otya?", "assistant: Ndi bulungi."])
        self.assertEqual(turns[1]["role"], "assistant")


if __name__ == "__main__":
    unittest.main()
