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
import argparse
from dotenv import load_dotenv
from elevenlabs import ElevenLabs, play


def resolve_voice(client, voice_input):
    """Resolve voice name to ID if needed."""
    if voice_input.startswith(("_", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9")) or len(voice_input) >= 20:
        return voice_input
    
    try:
        voices = client.voices.get_all()
        for voice in voices.voices:
            if voice.name.lower() == voice_input.lower():
                return voice.voice_id
    except:
        pass
    
    return voice_input


def generate_speech(client, text, voice_id):
    """Generate and play speech."""
    audio = client.text_to_speech.convert(
        text=text,
        voice_id=voice_id,
        model_id="eleven_turbo_v2_5",
        output_format="mp3_44100_128",
    )
    play(audio)


def main():
    load_dotenv()
    
    api_key = os.getenv('ELEVENLABS_API_KEY')
    if not api_key:
        print("❌ ELEVENLABS_API_KEY not found in environment", file=sys.stderr)
        sys.exit(1)
    
    parser = argparse.ArgumentParser(description="Text-to-speech using ElevenLabs")
    parser.add_argument("text", nargs="*", help="Text to convert to speech")
    parser.add_argument("-v", "--voice", default="dCnu06FiOZma2KVNUoPZ", help="Voice name or ID")
    args = parser.parse_args()
    
    if args.text:
        text = " ".join(args.text)
    else:
        text = "The first move is what sets everything in motion."
    
    client = ElevenLabs(api_key=api_key)
    voice_id = resolve_voice(client, args.voice)
    
    print(f"💬 {text}", file=sys.stderr)
    if args.voice != voice_id:
        print(f"🎙️ Voice: {args.voice} → {voice_id}", file=sys.stderr)
    else:
        print(f"🎙️ Voice: {args.voice}", file=sys.stderr)
    print("🔊 Generating...", file=sys.stderr)
    
    try:
        generate_speech(client, text, voice_id)
        print("✅ Done!", file=sys.stderr)
    except Exception as e:
        print(f"❌ Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
