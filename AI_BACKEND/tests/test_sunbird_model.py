import os
import unittest
from unittest.mock import patch

from app.services.sunbird_service import SunbirdService


class SunbirdModelSelectionTests(unittest.TestCase):
    def test_sunflower_9b_is_the_default(self):
        with patch.dict(os.environ, {}, clear=True):
            self.assertEqual(SunbirdService().chat_model, "sunflower-9b")

    def test_chat_sends_selected_model(self):
        service = SunbirdService()
        provider_response = {
            "choices": [{"message": {"content": "Ndi bulungi."}}]
        }
        with patch.dict(os.environ, {"SUNBIRD_CHAT_MODEL": " sunflower-9b "}), patch.object(
            service, "_post", return_value=provider_response
        ) as post:
            response = service.chat("Oli otya?", "lug")

        self.assertEqual(response, "Ndi bulungi.")
        self.assertEqual(post.call_args.args[1]["model"], "sunflower-9b")

    def test_invalid_model_is_rejected(self):
        with patch.dict(os.environ, {"SUNBIRD_CHAT_MODEL": "sunflower-99b"}):
            with self.assertRaisesRegex(ValueError, "sunflower-9b"):
                _ = SunbirdService().chat_model


if __name__ == "__main__":
    unittest.main()
