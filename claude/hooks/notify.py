#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "elevenlabs",
#     "python-dotenv",
#     "pync",
# ]
# ///
"""
Multi-modal notification system for Claude Code hooks.

Supports additive notification modes:
- Speech providers: ElevenLabs, macOS say
- Badge notifications: macOS native via pync

Usage:
    notify.py --badge                          # Badge only
    notify.py --speech elevenlabs              # Speech only
    notify.py --speech say --badge             # Both modes
    notify.py --speech elevenlabs --voice Anna # Custom voice
"""

import os
import sys
import json
import argparse
import subprocess
from abc import ABC, abstractmethod
from dotenv import load_dotenv
from elevenlabs import ElevenLabs, play
import pync


class SpeechProvider(ABC):
    """Abstract base class for speech providers."""

    @abstractmethod
    def generate_speech(self, text: str, voice: str = None):
        """Generate and play speech."""
        pass

    @abstractmethod
    def set_voice(self, voice: str):
        """Set the voice for this provider."""
        pass


class ElevenLabsProvider(SpeechProvider):
    """ElevenLabs text-to-speech provider."""

    def __init__(self, api_key: str):
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
        except Exception:
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


class MacOSSayProvider(SpeechProvider):
    """macOS built-in say command provider."""

    def __init__(self):
        self.voice = "Albert"  # Default macOS voice

    def set_voice(self, voice: str):
        """Set the voice for the say command."""
        self.voice = voice

    def generate_speech(self, text: str, voice: str = None):
        """Generate speech using macOS say command."""
        voice_to_use = voice or self.voice
        try:
            subprocess.run(["say", "-v", voice_to_use, text], check=True)
        except subprocess.CalledProcessError as e:
            print(f"❌ Say command failed: {e}", file=sys.stderr)
        except FileNotFoundError:
            print("❌ Say command not found (not on macOS?)", file=sys.stderr)


class BadgeNotifier:
    """Badge notification provider using pync (pure Python)."""

    def __init__(self, title: str = "🤖 Claude Code"):
        self.title = title
        # Try to use Terminal or Developer icon as a default
        self.icon_path = "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/DeveloperFolderIcon.icns"
        # Use a more interesting sound
        self.sound = "Ping"  # Options: Basso, Blow, Bottle, Frog, Funk, Glass, Hero, Morse, Ping, Pop, Purr, Sosumi, Submarine, Tink

    def send_notification(self, text: str, subtitle: str = None):
        """Send a badge notification using pync."""
        try:
            pync.notify(
                message=text,
                title=self.title,
                subtitle=subtitle or "",
                sound=self.sound,  # Use Ping sound (or any from the list above)
                appIcon=self.icon_path if os.path.exists(self.icon_path) else None
            )
        except Exception as e:
            print(f"❌ pync notification failed: {e}", file=sys.stderr)


def get_text_from_hook_input(hook_data):
    """Extract text based on hook event type."""
    event = hook_data.get("hook_event_name", "")

    match event:
        case "SessionStart":
            match hook_data.get("source", ""):
                case "startup":
                    return "Starting Claude"
                case "resume":
                    return "Resuming session"
                case "clear":
                    return "Session cleared"
                case _:
                    return "New session"
        case "SessionEnd":
            return "Session ended"
        case "SubagentStart":
            return f"Starting {hook_data.get('subagent_type', 'agent')}"
        case "SubagentStop":
            return f"{hook_data.get('subagent_type', 'Agent')} complete"
        case "PreToolUse":
            return f"Using {hook_data.get('tool_name', 'tool')}"
        case "PostToolUse":
            return f"{hook_data.get('tool_name', 'Tool')} complete"
        case "Stop":
            return "Agent complete"
        case "UserPromptSubmit":
            return "Processing prompt"
        case "PreCompact":
            return "Compacting context"
        case "Notification":
            notif_type = hook_data.get("notification_type", "")
            message = hook_data.get("message", "")

            # Extract meaningful part of the message
            if message:
                # For permission requests, extract what's being requested
                if "permission" in message.lower():
                    if "Would you like me to" in message:
                        action = message.split("Would you like me to")[1].split("?")[0].strip()
                        return f"Permission: {action[:50]}"
                    else:
                        return "Permission required"
                # Return first line or first 50 chars of message
                first_line = message.split('\n')[0][:80]
                return first_line if first_line else "Notification"

            # Fall back to type-based messages
            match notif_type:
                case "error":
                    return "Error occurred"
                case "warning":
                    return "Warning"
                case _:
                    return "Notification"
        case _:
            return f"Event: {event}"


def main():
    load_dotenv()

    parser = argparse.ArgumentParser(description="Multi-modal notification system")
    parser.add_argument("text", nargs="*", help="Text to send notifications for")
    parser.add_argument("--speech", action="append", choices=["elevenlabs", "say"],
                        help="Add speech provider(s) - can be used multiple times")
    parser.add_argument("--badge", action="store_true", help="Add badge notification")
    parser.add_argument("-v", "--voice", help="Voice name or ID (for speech providers)")
    parser.add_argument("--sound", default="Ping", 
                        choices=["Basso", "Blow", "Bottle", "Frog", "Funk", "Glass", "Hero", 
                                "Morse", "Ping", "Pop", "Purr", "Sosumi", "Submarine", "Tink", "None"],
                        help="Notification sound (default: Ping, use 'None' for silent)")

    args = parser.parse_args()

    # Default to elevenlabs speech if no modes specified
    if not args.speech and not args.badge:
        args.speech = ["elevenlabs"]

    # Get text from arguments or stdin
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

    print(f"💬 {text}", file=sys.stderr)

    # Process speech providers
    if args.speech:
        for provider_name in args.speech:
            if provider_name == "elevenlabs":
                api_key = os.getenv('ELEVENLABS_API_KEY')
                if not api_key:
                    print("❌ ELEVENLABS_API_KEY not found in environment", file=sys.stderr)
                    continue

                provider = ElevenLabsProvider(api_key)
                if args.voice:
                    provider.set_voice(args.voice)

                print(f"🎙️ ElevenLabs Voice: {provider.voice}{' → ' + provider.voice_id if provider.voice != provider.voice_id else ''}", file=sys.stderr)

                try:
                    provider.generate_speech(text)
                except Exception as e:
                    print(f"❌ ElevenLabs error: {e}", file=sys.stderr)

            elif provider_name == "say":
                provider = MacOSSayProvider()
                if args.voice:
                    provider.set_voice(args.voice)

                print(f"🎙️ macOS Say Voice: {provider.voice}", file=sys.stderr)
                provider.generate_speech(text)

    # Process badge notification
    if args.badge:
        notifier = BadgeNotifier()
        # Override sound if specified
        if args.sound and args.sound != "None":
            notifier.sound = args.sound
        elif args.sound == "None":
            notifier.sound = False
        print(f"🔔 Sending badge notification{' with ' + args.sound + ' sound' if args.sound != 'None' else ' (silent)'}", file=sys.stderr)
        notifier.send_notification(text)


if __name__ == "__main__":
    main()
