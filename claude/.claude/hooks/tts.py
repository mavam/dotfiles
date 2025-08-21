#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.8"
# dependencies = [
#     "elevenlabs",
#     "python-dotenv",
# ]
# ///

import os
import sys
import json
import argparse
from dotenv import load_dotenv
from elevenlabs import ElevenLabs, play


class TTSClient:
    """Text-to-speech client wrapper for ElevenLabs."""

    def __init__(self, api_key: str):
        """Initialize the TTS client with an API key."""
        self.client = ElevenLabs(api_key=api_key)
        self.voice = "dCnu06FiOZma2KVNUoPZ"
        self.voice_id = self._resolve_voice(self.voice)

    def set_voice(self, voice: str):
        """Set a new voice and resolve its ID."""
        self.voice = voice
        self.voice_id = self._resolve_voice(voice)

    def _resolve_voice(self, voice_input: str) -> str:
        """Resolve voice name to ID if needed."""
        if voice_input[0] in "_0123456789" or len(voice_input) >= 20:
            return voice_input
        try:
            return next((v.voice_id for v in self.client.voices.get_all().voices
                        if v.name.lower() == voice_input.lower()), voice_input)
        except:
            return voice_input

    def generate_speech(self, text: str, voice_id: str = None):
        """Generate and play speech."""
        if voice_id is None:
            voice_id = self.voice_id
        play(self.client.text_to_speech.convert(
            text=text,
            voice_id=voice_id,
            model_id="eleven_turbo_v2_5",
            output_format="mp3_44100_128",
        ))


def get_text_from_hook_input(hook_data):
    """Extract text based on hook event type."""
    event = hook_data.get("hook_event_name", "")

    event_map = {
        "SessionStart": "New session",
        "SessionEnd": "Session ended",
        "SubagentStart": lambda: f"Starting {hook_data.get('subagent_type', 'agent')}",
        "SubagentStop": lambda: f"{hook_data.get('subagent_type', 'Agent')} complete",
        "PreToolUse": lambda: f"Using {hook_data.get('tool_name', 'tool')}",
        "PostToolUse": lambda: f"{hook_data.get('tool_name', 'Tool')} complete",
    }

    if event == "Notification":
        notif_type = hook_data.get("notification_type", "")
        return {"error": "Error", "warning": "Warning"}.get(notif_type, "Notification")

    result = event_map.get(event, f"Event: {event}")
    return result() if callable(result) else result


def main():
    load_dotenv()

    api_key = os.getenv('ELEVENLABS_API_KEY')
    if not api_key:
        print("❌ ELEVENLABS_API_KEY not found in environment", file=sys.stderr)
        sys.exit(1)

    parser = argparse.ArgumentParser(description="Text-to-speech using ElevenLabs")
    parser.add_argument("text", nargs="*", help="Text to convert to speech")
    parser.add_argument("-v", "--voice", help="Voice name or ID")
    args = parser.parse_args()

    if args.text:
        text = " ".join(args.text)
    elif not sys.stdin.isatty():
        try:
            input_data = sys.stdin.read().strip()
            text = get_text_from_hook_input(json.loads(input_data)) if input_data else ""
            if not text:
                sys.exit(1)
        except Exception as e:
            print(f"⚠️ Failed to parse input: {e}", file=sys.stderr)
            sys.exit(1)
    else:
        sys.exit(1)

    tts_client = TTSClient(api_key=api_key)
    if args.voice:
        tts_client.set_voice(args.voice)

    print(f"💬 {text}", file=sys.stderr)
    print(f"🎙️ Voice: {tts_client.voice}{' → ' + tts_client.voice_id if tts_client.voice != tts_client.voice_id else ''}", file=sys.stderr)

    try:
        tts_client.generate_speech(text)
    except Exception as e:
        print(f"❌ Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
