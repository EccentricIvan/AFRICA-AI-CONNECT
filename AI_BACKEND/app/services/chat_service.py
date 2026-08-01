"""Context-aware, language-locked chat orchestration."""
from __future__ import annotations

import os
import re
from dataclasses import dataclass
from typing import Any

import requests

from app.config import get_groq_api_key
from app.services.sunbird_service import SunbirdError, sunbird_service

GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions"
LANGUAGE_ALIASES = {
    "en": "eng", "eng": "eng", "english": "eng",
    "lg": "lug", "lug": "lug", "luganda": "lug",
    "sw": "swa", "swa": "swa", "swh": "swa", "swahili": "swa", "kiswahili": "swa",
}
LANGUAGE_NAMES = {"eng": "English", "lug": "Luganda", "swa": "Swahili"}

SYSTEM_PROMPT_TEMPLATE = """You are OTIC CONNECT, a practical assistant for African youth.

LANGUAGE LOCK: Reply entirely in {language_name}. This instruction applies to every turn. Do not switch to or translate the final answer into another language. Keep names, numbers, currencies, and place names accurate. Avoid mixing English unless a term is commonly used locally or has no clear equivalent.

Before answering, silently identify every instruction in the user's complete request. Answer every part directly. Never replace a specific instruction with general advice. Preserve the requested location, amount, number of examples, constraints, and format. Use relevant conversation history to resolve follow-ups such as “that money”, “three more”, or “which of these”. Silently check the finished answer against the request; do not reveal this review or private reasoning.

Be concise, concrete, and useful. For money or business questions, use the exact amount, give a practical budget where requested, suggest options that genuinely fit the budget and location, and include concrete next steps. Do not invent certainty.

For Luganda, write like a fluent Ugandan Luganda speaker: use natural conversational wording, short clear sentences, culturally appropriate greeting replies, and correct common spellings such as “weebale”. Avoid word-for-word English constructions and repeated generic support paragraphs. Ask a follow-up question only when it helps.

Return plain text only. Do not use Markdown markers such as **, __, #, or backticks. Numbered lists and ordinary line breaks are allowed."""

COMMON_ENGLISH = {"the", "and", "you", "your", "is", "are", "to", "of", "for", "with", "can", "this", "that", "business", "money", "start", "please", "would", "should", "have"}
LANGUAGE_MARKERS = {
    "lug": {"nga", "era", "nnyo", "weebale", "oli", "ndi", "osobola", "okutandika", "ensimbi", "obusuubuzi", "omutwalo", "emitwalo", "bizinensi", "ku", "mu", "ne", "ggwe"},
    "swa": {"na", "kwa", "ya", "ni", "unaweza", "asante", "habari", "biashara", "fedha", "katika"},
}
QUANTITY_WORDS = {
    "lug": {"emu", "bbiri", "ssatu", "nnya", "ttaano", "mukaaga", "musanvu", "munaana", "mwenda", "kkumi"},
    "swa": {"moja", "mbili", "tatu", "nne", "tano", "sita", "saba", "nane", "tisa", "kumi"},
    "eng": {"one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"},
}


@dataclass(frozen=True)
class ChatResult:
    response: str
    provider: str


class ChatProviderError(RuntimeError):
    def __init__(self, code: str, retryable: bool) -> None:
        super().__init__(code)
        self.code = code
        self.retryable = retryable


def build_system_prompt(language_code: str) -> str:
    return SYSTEM_PROMPT_TEMPLATE.format(language_name=LANGUAGE_NAMES[language_code])


def normalise_context(context: list[Any] | None) -> list[dict[str, str]]:
    """Keep real user/assistant roles while accepting legacy flattened strings."""
    turns: list[dict[str, str]] = []
    for item in (context or [])[-20:]:
        if isinstance(item, str):
            match = re.match(r"^(user|assistant)\s*:\s*(.+)$", item.strip(), re.I | re.S)
            role, content = (match.group(1).lower(), match.group(2)) if match else ("user", item)
        else:
            data = item.model_dump() if hasattr(item, "model_dump") else item
            role, content = data.get("role"), data.get("content", "")
        if role in {"user", "assistant"} and isinstance(content, str) and content.strip():
            turns.append({"role": role, "content": content.strip()})
    return turns


def plain_text(text: str) -> str:
    text = re.sub(r"```(?:\w+)?\s*|```", "", text)
    text = re.sub(r"\*\*(.*?)\*\*|__(.*?)__", lambda m: m.group(1) or m.group(2), text)
    text = re.sub(r"(?m)^\s{0,3}#{1,6}\s*", "", text).replace("`", "")
    return re.sub(r"[ \t]+\n", "\n", text).strip()


def mostly_wrong_language(text: str, language_code: str) -> bool:
    if language_code == "eng":
        return False
    words = re.findall(r"[A-Za-zÀ-ž’']+", text.lower())
    if len(words) < 4:
        return False
    english = sum(word in COMMON_ENGLISH for word in words)
    local = sum(word in LANGUAGE_MARKERS[language_code] for word in words)
    return english >= 3 and english > local * 2


def quality_issues(message: str, answer: str, language_code: str) -> list[str]:
    issues: list[str] = []
    if mostly_wrong_language(answer, language_code):
        issues.append(f"The draft is not consistently in {LANGUAGE_NAMES[language_code]}.")
    missing: list[str] = []
    for detail in re.findall(r"\b\d[\d,.]*\b", message):
        if detail not in answer:
            missing.append(detail)
    lower_message, lower_answer = message.lower(), answer.lower()
    for word in QUANTITY_WORDS[language_code]:
        if re.search(rf"\b{word}\b", lower_message) and not re.search(rf"\b{word}\b", lower_answer):
            missing.append(word)
    for match in re.finditer(r"\b[A-Z][a-z]{2,}\b", message):
        place = match.group(0)
        if match.start() > 0 and place.lower() not in lower_answer:
            missing.append(place)
    if missing:
        issues.append("The draft omitted requested details: " + ", ".join(dict.fromkeys(missing)) + ".")
    if re.search(r"\*\*|__|```|^\s*#", answer, flags=re.MULTILINE):
        issues.append("The draft contains Markdown symbols.")
    return issues


def english_grounding_issues(
    original_message: str, translated_transcript: str, english_answer: str
) -> list[str]:
    """Reject financial specifics that were not supplied by the user."""
    issues: list[str] = []
    source = f"{original_message}\n{translated_transcript}".lower()
    answer = english_answer.lower()
    named_products = ("401(k)", "mtn", "airtel", "stanbic", "dfcu", "pride sacco", "post office")
    introduced = [name for name in named_products if name in answer and name not in source]
    if introduced:
        issues.append("Remove unrequested named institutions or products: " + ", ".join(introduced) + ".")
    source_has_amount = bool(re.search(r"(?:UGX|USD|\$|\b\d[\d,]{2,})", source, re.I))
    answer_has_amount = bool(re.search(r"(?:UGX|USD|\$|\b\d[\d,]{2,})", english_answer, re.I))
    if answer_has_amount and not source_has_amount:
        issues.append("Remove invented currency amounts; ask the user for their income or budget.")
    return issues


class ChatService:
    def _groq(self, messages: list[dict[str, str]]) -> str:
        api_key = get_groq_api_key()
        if not api_key:
            raise ChatProviderError("CHAT_PROVIDER_AUTH_FAILED", retryable=False)
        try:
            response = requests.post(
                GROQ_API_URL,
                headers={"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"},
                json={"model": os.getenv("GROQ_MODEL", "llama-3.1-8b-instant"), "messages": messages, "temperature": 0.5, "max_tokens": 650},
                timeout=45,
            )
            if response.status_code in {401, 403}:
                raise ChatProviderError("CHAT_PROVIDER_AUTH_FAILED", retryable=False)
            response.raise_for_status()
            answer = response.json()["choices"][0]["message"]["content"]
        except ChatProviderError:
            raise
        except (requests.Timeout, requests.ConnectionError) as exc:
            raise ChatProviderError("CHAT_PROVIDER_UNAVAILABLE", retryable=True) from exc
        except (requests.RequestException, KeyError, IndexError, TypeError, ValueError) as exc:
            raise ChatProviderError("CHAT_PROVIDER_UNAVAILABLE", retryable=True) from exc
        if not isinstance(answer, str) or not answer.strip():
            raise ChatProviderError("CHAT_PROVIDER_UNAVAILABLE", retryable=True)
        return answer.strip()

    def _generate_english(
        self,
        message: str,
        context: list[dict[str, str]],
        correction: str | None = None,
    ) -> str:
        messages = [
            {"role": "system", "content": build_system_prompt("eng")},
            *context,
            {"role": "user", "content": message},
        ]
        if correction:
            messages.append({"role": "system", "content": correction})
        return self._groq(messages)

    @staticmethod
    def _local_transcript(message: str, context: list[dict[str, str]]) -> str:
        """Build one translation request while retaining recent speaker turns."""
        lines = [
            f"{turn['role'].upper()}: {turn['content'][:1200]}"
            for turn in context[-8:]
        ]
        lines.append(f"LATEST USER: {message}")
        return "\n".join(lines)

    def _reason_from_transcript(
        self,
        translated_transcript: str,
        language_code: str,
        correction: str | None = None,
    ) -> str:
        regional_context = (
            "The user is a Luganda speaker in Uganda unless they explicitly name another "
            "location. Use UGX and realistic Ugandan options such as mobile money, SACCOs, "
            "local banks, and locally available businesses. Never introduce US-specific "
            "products such as 401(k) plans or dollar amounts. Do not name a specific bank, "
            "SACCO, company, or government program unless the user named it first. If the "
            "user did not provide income or an amount, do not invent one; give a percentage "
            "or method and ask for the amount needed to make a precise plan."
            if language_code == "lug"
            else "The user is a Swahili speaker in East Africa. Follow any location they "
            "provide; otherwise give regionally practical advice without inventing a country, "
            "currency, or foreign financial product."
        )
        instruction = (
            "The text below is an English translation of a conversation. "
            "Answer the LATEST USER request in English. Use earlier turns to resolve "
            "references and follow-ups. Preserve every amount, place, requested quantity, "
            "constraint, and task. Give a complete, concrete answer of at most 160 words. "
            f"{regional_context}\n\n"
            f"TRANSLATED CONVERSATION:\n{translated_transcript}"
        )
        return self._generate_english(instruction, [], correction)

    @staticmethod
    def _translate(text: str, target: str, source: str) -> str:
        try:
            return sunbird_service.translate(
                text, target_language=target, source_language=source
            )
        except (SunbirdError, ValueError) as exc:
            raise ChatProviderError("CHAT_PROVIDER_UNAVAILABLE", retryable=True) from exc

    def chat(self, message: str, language: str, context: list[Any] | None = None) -> ChatResult:
        language_code = LANGUAGE_ALIASES.get(language.strip().lower())
        if language_code is None:
            raise ValueError("language must be English, Luganda, or Swahili")
        clean_message, turns = message.strip(), normalise_context(context)

        if language_code == "eng":
            answer = self._generate_english(clean_message, turns)
            provider = "groq"
        else:
            transcript = self._local_transcript(clean_message, turns)
            translated_transcript = self._translate(transcript, "eng", language_code)
            english_answer = self._reason_from_transcript(
                translated_transcript, language_code
            )
            grounding = english_grounding_issues(
                clean_message, translated_transcript, english_answer
            )
            if grounding:
                correction = (
                    "Rewrite the draft and fix every grounding problem: "
                    + " ".join(grounding)
                    + " Keep the useful advice generic and locally appropriate.\n\n"
                    "Draft to rewrite:\n"
                    + english_answer
                )
                english_answer = self._reason_from_transcript(
                    translated_transcript, language_code, correction
                )
            answer = self._translate(english_answer, language_code, "eng")
            provider = "sunbird+groq+sunbird"

        issues = quality_issues(clean_message, answer, language_code)
        if issues:
            correction = (
                "Rewrite the English answer once. " + " ".join(issues) + " "
                "Answer every part of the latest request, preserve all constraints, and "
                "output plain text only.\n\nEnglish draft to rewrite:\n"
                + (english_answer if language_code != "eng" else answer)
            )
            if language_code == "eng":
                answer = self._generate_english(clean_message, turns, correction)
            else:
                english_answer = self._reason_from_transcript(
                    translated_transcript, language_code, correction
                )
                answer = self._translate(english_answer, language_code, "eng")
        return ChatResult(plain_text(answer), provider)


chat_service = ChatService()
