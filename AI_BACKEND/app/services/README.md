# OTIC Local Language Translator MVP

## Overview

This is the first working backend prototype for an OTIC-owned local language translation system.

The goal is to build an independent translation service without depending on the Sunbird API. This first version runs locally and exposes a FastAPI endpoint for translation requests.

## Current Version

Version: 0.1.0 - Demo Translation API

## Current Features

- FastAPI backend
- `/translate/` API endpoint
- Swagger API documentation at `/docs`
- Demo English ↔ Luganda translation responses
- Service-based structure ready for AI model integration

## Current Limitation

This version does not yet use the real NLLB AI model. It currently uses a small demo dictionary to prove that the backend and API flow work.

The real AI model will be connected after PyTorch and model dependencies are fully installed.

## Project Structure

```text
Backend/
  app/
    main.py
    routes/
      translate.py
    services/
      translator_service.py
    models/
      translation_schema.py
  requirements.txt
  venv/