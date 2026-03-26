#!/usr/bin/env python3
"""Convert supported binary files to Markdown using markitdown, with optional Mistral OCR fallback."""

import base64
import hashlib
import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Optional

SUPPORTED_EXTENSIONS = {
    ".pdf",
    ".docx",
    ".xlsx",
    ".xls",
    ".pptx",
    ".ppt",
    ".epub",
    ".ipynb",
}

CACHE_DIR = Path.home() / ".cache" / "ai-hooks" / "binary-to-markdown"
MISTRAL_OCR_URL = "https://api.mistral.ai/v1/ocr"
MISTRAL_MODEL = "mistral-ocr-latest"


def eprint(message: str) -> None:
    print(message, file=sys.stderr)


def is_poor_extraction(text: str) -> bool:
    stripped = text.strip()
    if len(stripped) < 100:
        return True

    total_chars = len(text)
    if total_chars == 0:
        return True

    noisy_chars = 0
    for char in text:
        if ord(char) > 127 or char in "\x00\x01\x02":
            noisy_chars += 1

    ratio = float(noisy_chars) / float(total_chars)
    return ratio > 0.05


def cache_key_for_file(file_path: Path) -> str:
    stat_info = file_path.stat()
    key_input = "{0}-{1}".format(stat_info.st_mtime, stat_info.st_size)
    return hashlib.md5(key_input.encode("utf-8")).hexdigest()


def read_cache(cache_file: Path) -> Optional[str]:
    if not cache_file.exists():
        return None
    try:
        return cache_file.read_text(encoding="utf-8")
    except OSError as exc:
        eprint("[binary-to-markdown] Cache read failed: {0}".format(exc))
        return None


def write_cache(cache_file: Path, markdown: str) -> None:
    try:
        CACHE_DIR.mkdir(parents=True, exist_ok=True)
        cache_file.write_text(markdown, encoding="utf-8")
    except OSError as exc:
        eprint("[binary-to-markdown] Cache write failed: {0}".format(exc))


def run_markitdown(file_path: Path) -> str:
    try:
        result = subprocess.run(
            ["markitdown", str(file_path)],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=False,
        )
    except FileNotFoundError:
        raise RuntimeError(
            "markitdown CLI not found on PATH. Install with: pip install markitdown"
        )

    if result.returncode != 0:
        stderr_text = result.stderr.strip()
        if stderr_text:
            raise RuntimeError("markitdown failed: {0}".format(stderr_text))
        raise RuntimeError("markitdown failed with exit code {0}".format(result.returncode))

    return result.stdout


def run_mistral_ocr_if_applicable(file_path: Path, markitdown_output: str) -> str:
    if not is_poor_extraction(markitdown_output):
        return markitdown_output

    if file_path.suffix.lower() != ".pdf":
        return markitdown_output

    api_key = os.environ.get("MISTRAL_API_KEY", "").strip()
    if not api_key:
        return markitdown_output

    try:
        import httpx
    except ImportError:
        eprint("[binary-to-markdown] httpx not installed. Skipping Mistral OCR fallback.")
        return markitdown_output

    try:
        file_bytes = file_path.read_bytes()
    except OSError as exc:
        eprint("[binary-to-markdown] Failed to read PDF for OCR fallback: {0}".format(exc))
        return markitdown_output

    b64_data = base64.b64encode(file_bytes).decode("ascii")
    payload = {
        "model": MISTRAL_MODEL,
        "document": {
            "type": "document_url",
            "document_url": "data:application/pdf;base64,{0}".format(b64_data),
        },
    }
    headers = {
        "Authorization": "Bearer {0}".format(api_key),
        "Content-Type": "application/json",
    }

    try:
        response = httpx.post(
            MISTRAL_OCR_URL,
            headers=headers,
            json=payload,
            timeout=120.0,
        )
    except Exception as exc:  # pragma: no cover - network/runtime dependent
        eprint("[binary-to-markdown] Mistral OCR request failed: {0}".format(exc))
        return markitdown_output

    if response.status_code < 200 or response.status_code >= 300:
        body = response.text.strip()
        if body:
            eprint(
                "[binary-to-markdown] Mistral OCR returned {0}: {1}".format(
                    response.status_code, body
                )
            )
        else:
            eprint("[binary-to-markdown] Mistral OCR returned status {0}.".format(response.status_code))
        return markitdown_output

    try:
        data = response.json()
    except json.JSONDecodeError:
        eprint("[binary-to-markdown] Mistral OCR response was not valid JSON.")
        return markitdown_output

    pages = data.get("pages", [])
    markdown_pages = []
    for page in pages:
        markdown = page.get("markdown")
        if isinstance(markdown, str) and markdown.strip():
            markdown_pages.append(markdown)

    if not markdown_pages:
        eprint("[binary-to-markdown] Mistral OCR response contained no markdown pages.")
        return markitdown_output

    return "\n\n".join(markdown_pages)


def main() -> int:
    if len(sys.argv) != 2:
        eprint("Usage: convert.py <file_path>")
        return 1

    input_path = Path(sys.argv[1]).expanduser()
    if not input_path.exists() or not input_path.is_file():
        eprint("[binary-to-markdown] File not found: {0}".format(input_path))
        return 1

    if input_path.suffix.lower() not in SUPPORTED_EXTENSIONS:
        eprint("[binary-to-markdown] Unsupported file extension: {0}".format(input_path.suffix))
        return 1

    try:
        cache_key = cache_key_for_file(input_path)
    except OSError as exc:
        eprint("[binary-to-markdown] Failed to stat file: {0}".format(exc))
        return 1

    cache_file = CACHE_DIR / (cache_key + ".md")
    cached_markdown = read_cache(cache_file)
    if cached_markdown is not None:
        print(cached_markdown, end="")
        return 0

    try:
        markdown = run_markitdown(input_path)
    except RuntimeError as exc:
        eprint("[binary-to-markdown] {0}".format(exc))
        return 1

    markdown = run_mistral_ocr_if_applicable(input_path, markdown)
    write_cache(cache_file, markdown)
    print(markdown, end="")
    return 0


if __name__ == "__main__":
    sys.exit(main())