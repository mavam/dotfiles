#!/usr/bin/env -S uv run
# /// script
# dependencies = ["rapidhash"]
# ///
"""
graft: Optimize a new git worktree by copying cached state from the primary worktree.

Usage as worktrunk post-create hook:
  [post-create]
  graft = "~/.config/worktrunk/scripts/graft.py {{ worktree_path }}"

What it does:
  - Copies file timestamps (preserves build cache validity)
  - Copies submodules with their .git directories (avoids network fetches)
  - Copies CMake build directory and fixes embedded paths
  - Fixes ninja build files (.ninja_log hashes, .ninja_deps paths)
  - Trusts Claude Code in the new worktree
"""

from __future__ import annotations

import argparse
import contextlib
import fcntl
import json
import os
import pty
import re
import select
import shutil
import struct
import subprocess
import sys
import termios
import threading
import time
from abc import ABC, abstractmethod
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass, field
from pathlib import Path
from typing import TYPE_CHECKING

import rapidhash

if TYPE_CHECKING:
    pass

# =============================================================================
# Configuration
# =============================================================================

VERBOSE = False

# Build directory patterns to detect (relative to worktree root)
BUILD_DIR_PATTERNS = [
    "build/*",  # CMake presets: build/release, build/debug, build/RelWithDebInfo
    "build",  # Single build directory
    ".build",  # Alternative convention
    "_build",  # Another alternative
]


# =============================================================================
# UI Module: ANSI codes, logging, spinner
# =============================================================================

ANSI_ESCAPE = re.compile(
    r"\x1b\[[0-9;]*[a-zA-Z]|\x1b\][^\x07]*\x07|\x1b[<>=?]?[0-9;]*[a-zA-Z]"
)

# ANSI codes
DIM = "\033[2m"
RESET = "\033[0m"
BLUE = "\033[34m"
GREEN = "\033[32m"
RED = "\033[31m"
MOVE_UP = "\033[A"
CLEAR_LINE = "\033[2K"
HIDE_CURSOR = "\033[?25l"
SHOW_CURSOR = "\033[?25h"

# Symbols
CHECK = "\u2714"
CROSS = "\u2718"


def strip_ansi(text: str) -> str:
    """Remove ANSI escape sequences from text."""
    return ANSI_ESCAPE.sub("", text)


_active_spinner: Spinner | None = None


def log(msg: str) -> None:
    """Log a message (only in verbose mode)."""
    if VERBOSE:
        # Clear spinner lines before logging, spinner will redraw
        if _active_spinner:
            _active_spinner._clear_for_log()
        print(f"{DIM}[*] {msg}{RESET}", flush=True)


class Spinner:
    """A spinner that can track multiple concurrent tasks."""

    frames = "\u280b\u2819\u2839\u2838\u283c\u2834\u2826\u2827\u2807\u280f"

    def __init__(self) -> None:
        self._frame = 0
        self._stop = threading.Event()
        self._thread: threading.Thread | None = None
        self._lock = threading.Lock()
        # Tasks: {name: {"status": "pending"|"active"|"done", "msg": str}}
        self._tasks: dict[str, dict[str, str]] = {}
        self._task_order: list[str] = []
        self._num_lines = 0

    def _render(self) -> list[str]:
        """Render all task lines."""
        lines = []
        for name in self._task_order:
            task = self._tasks.get(name)
            if not task:
                continue
            status = task["status"]
            msg = task["msg"]
            if status == "done":
                lines.append(f"{GREEN}{CHECK}{RESET} {DIM}{msg}{RESET}")
            elif status == "active":
                spinner_char = self.frames[self._frame % len(self.frames)]
                lines.append(f"{BLUE}{spinner_char}{RESET} {msg}")
            else:  # pending
                lines.append(f"  {DIM}{msg}{RESET}")
        return lines

    def _clear_for_log(self) -> None:
        """Clear all lines for logging output."""
        if self._num_lines > 0:
            # Move up and clear each line
            for _ in range(self._num_lines):
                print(f"{MOVE_UP}{CLEAR_LINE}", end="")
            print("\r", end="", flush=True)

    def _spin(self) -> None:
        while not self._stop.wait(0.12):
            if VERBOSE:
                # In verbose mode, don't animate - just wait
                continue

            with self._lock:
                lines = self._render()

            # Move cursor up to overwrite previous output
            if self._num_lines > 0:
                print(f"\033[{self._num_lines}A", end="")

            # Print each line, clearing to end
            for line in lines:
                print(f"{CLEAR_LINE}{line}", flush=True)

            # Clear any extra lines from previous render
            for _ in range(self._num_lines - len(lines)):
                print(CLEAR_LINE, flush=True)

            # Move cursor back up to end of current content
            extra_lines = self._num_lines - len(lines)
            if extra_lines > 0:
                print(f"\033[{extra_lines}A", end="", flush=True)

            self._num_lines = len(lines)
            self._frame += 1

    def start(self, msg: str = "") -> None:
        """Start the spinner with an optional initial single task."""
        global _active_spinner
        if not VERBOSE:
            print(HIDE_CURSOR, end="", flush=True)
        if msg:
            self._tasks["main"] = {"status": "active", "msg": msg}
            self._task_order = ["main"]
        self._stop.clear()
        self._thread = threading.Thread(target=self._spin, daemon=True)
        self._thread.start()
        _active_spinner = self

    def update(self, msg: str) -> None:
        """Update the main task message (single-task mode)."""
        with self._lock:
            if "main" in self._tasks:
                self._tasks["main"]["msg"] = msg

    def add_task(self, name: str, msg: str, status: str = "active") -> None:
        """Add a new task to track."""
        with self._lock:
            self._tasks[name] = {"status": status, "msg": msg}
            if name not in self._task_order:
                self._task_order.append(name)

    def update_task(
        self, name: str, msg: str | None = None, status: str | None = None
    ) -> None:
        """Update a specific task's message or status."""
        with self._lock:
            if name in self._tasks:
                if msg is not None:
                    self._tasks[name]["msg"] = msg
                if status is not None:
                    self._tasks[name]["status"] = status

    def complete_task(self, name: str, msg: str | None = None) -> None:
        """Mark a task as completed."""
        self.update_task(name, msg=msg, status="done")

    def set_tasks(
        self, tasks: list[tuple[str, str]], active: list[str] | None = None
    ) -> None:
        """Set multiple tasks at once. tasks is a list of (name, msg) tuples.
        active is an optional list of task names to mark as initially active."""
        active = active or []
        with self._lock:
            self._tasks = {
                name: {"status": "active" if name in active else "pending", "msg": msg}
                for name, msg in tasks
            }
            self._task_order = [name for name, _ in tasks]

    def start_task(self, name: str) -> None:
        """Mark a task as active/running."""
        self.update_task(name, status="active")

    def stop(self) -> None:
        """Stop the spinner and clear output (unless verbose mode)."""
        global _active_spinner
        if self._stop.is_set():
            return  # Already stopped
        self._stop.set()
        if self._thread:
            self._thread.join()
        _active_spinner = None
        # Clear all lines (skip if verbose to preserve log output)
        if self._num_lines > 0 and not VERBOSE:
            print(f"\033[{self._num_lines}A", end="")
            for _ in range(self._num_lines):
                print(f"{CLEAR_LINE}")
            print(f"\033[{self._num_lines}A", end="")
            self._num_lines = 0
        print(SHOW_CURSOR, end="", flush=True)


@contextlib.contextmanager
def spinner(msg: str):
    """Show a spinner while a block executes, then clear the line."""
    s = Spinner()
    s.start(msg)
    try:
        yield s
    finally:
        s.stop()


# =============================================================================
# Git Utilities
# =============================================================================


def find_primary_worktree(worktree_path: Path) -> Path | None:
    """Find the primary worktree (source) for a given worktree."""
    # Get the git common dir - this points to the shared .git directory
    result = subprocess.run(
        ["git", "rev-parse", "--git-common-dir"],
        cwd=worktree_path,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return None

    # List all worktrees to find the primary one
    result = subprocess.run(
        ["git", "worktree", "list", "--porcelain"],
        cwd=worktree_path,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return None

    # Parse worktree list - first entry is typically the primary
    # Format: worktree /path/to/worktree\nHEAD ...\nbranch ...\n\n
    current_worktree = None
    for line in result.stdout.split("\n"):
        if line.startswith("worktree "):
            path = Path(line[9:])
            if current_worktree is None:
                # First worktree is the primary (main worktree)
                if path.resolve() != worktree_path.resolve():
                    return path
                # If the first worktree IS our target, keep looking
            current_worktree = path
        elif line == "":
            current_worktree = None

    # If we only found one worktree (ours), there's no source to copy from
    return None


def validate_worktrees(source: Path, target: Path) -> str | None:
    """Validate that source and target are valid worktrees of the same repo.

    Returns an error message if validation fails, None if valid.
    """
    # Check both paths exist
    if not source.exists():
        return f"Source path does not exist: {source}"
    if not target.exists():
        return f"Target path does not exist: {target}"

    # Check they're not the same path
    if source.resolve() == target.resolve():
        return "Source and target are the same path"

    # Check both are git worktrees
    for path, name in [(source, "Source"), (target, "Target")]:
        result = subprocess.run(
            ["git", "rev-parse", "--git-dir"],
            cwd=path,
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            return f"{name} is not a git repository: {path}"

    # Check they share the same git common dir (same repo)
    def get_common_dir(path: Path) -> Path | None:
        result = subprocess.run(
            ["git", "rev-parse", "--git-common-dir"],
            cwd=path,
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            return None
        return (path / result.stdout.strip()).resolve()

    source_common = get_common_dir(source)
    target_common = get_common_dir(target)

    if source_common is None:
        return f"Cannot determine git common dir for source: {source}"
    if target_common is None:
        return f"Cannot determine git common dir for target: {target}"
    if source_common != target_common:
        return "Source and target are not worktrees of the same repository"

    return None


@dataclass
class SubmoduleInfo:
    """Information about a submodule."""

    name: str
    path: str
    url: str | None = None


def get_submodule_info(worktree_path: Path) -> list[SubmoduleInfo]:
    """Parse .gitmodules and return submodule information."""
    result = subprocess.run(
        [
            "git",
            "config",
            "--file",
            ".gitmodules",
            "--get-regexp",
            r"^submodule\..*\.path$",
        ],
        cwd=worktree_path,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0 or not result.stdout.strip():
        return []

    # Build map of submodule name -> path
    submodule_paths: dict[str, str] = {}
    for line in result.stdout.strip().split("\n"):
        # Format: submodule.<name>.path <path>
        key, path = line.split(maxsplit=1)
        # Strip "submodule." prefix and ".path" suffix to handle names with dots
        name = key[len("submodule.") : -len(".path")]
        submodule_paths[name] = path

    # Get submodule URLs
    url_result = subprocess.run(
        [
            "git",
            "config",
            "--file",
            ".gitmodules",
            "--get-regexp",
            r"^submodule\..*\.url$",
        ],
        cwd=worktree_path,
        capture_output=True,
        text=True,
    )
    submodule_urls: dict[str, str] = {}
    if url_result.returncode == 0:
        for line in url_result.stdout.strip().split("\n"):
            if not line.strip():
                continue
            key, url = line.split(maxsplit=1)
            # Strip "submodule." prefix and ".url" suffix
            name = key[len("submodule.") : -len(".url")]
            submodule_urls[name] = url

    return [
        SubmoduleInfo(name=name, path=path, url=submodule_urls.get(name))
        for name, path in submodule_paths.items()
    ]


def get_git_modules_dir(worktree_path: Path) -> Path | None:
    """Get the shared .git/modules directory for a worktree."""
    result = subprocess.run(
        ["git", "rev-parse", "--git-common-dir"],
        cwd=worktree_path,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return None
    return (worktree_path / result.stdout.strip() / "modules").resolve()


# =============================================================================
# Ninja Utilities
# =============================================================================


def get_ninja_commands(build_dir: Path) -> dict[str, str]:
    """Get expanded commands from ninja using 'ninja -t compdb'."""
    result = subprocess.run(
        ["ninja", "-t", "compdb"],
        cwd=build_dir,
        capture_output=True,
        text=True,
    )

    if result.returncode != 0:
        return {}

    output_to_command: dict[str, str] = {}
    try:
        entries = json.loads(result.stdout)
        for entry in entries:
            output = entry.get("output", "")
            command = entry.get("command", "")
            if output and command:
                # compdb gives relative paths, convert to match .ninja_log format
                if not output.startswith("/"):
                    output = str(build_dir / output)
                output_to_command[output] = command
                # Also store relative path version
                rel_output = str(Path(output).relative_to(build_dir))
                output_to_command[rel_output] = command
    except json.JSONDecodeError:
        pass

    return output_to_command


def fix_ninja_log(
    ninja_log_path: Path, build_dir: Path, output_to_command: dict[str, str]
) -> None:
    """Recompute command hashes and mtimes in .ninja_log based on actual files."""
    if not ninja_log_path.exists():
        return

    build_dir_str = str(build_dir) + "/"
    lines = ninja_log_path.read_text().split("\n")
    new_lines = []

    for line in lines:
        if line.startswith("#") or not line.strip():
            new_lines.append(line)
            continue

        parts = line.split("\t")
        if len(parts) != 5:
            new_lines.append(line)
            continue

        start, end, old_mtime, output, old_hash = parts

        # Get the actual file mtime
        if output.startswith("/"):
            output_path = Path(output)
            lookup_key = output
        else:
            output_path = build_dir / output
            # Try both relative and absolute paths for command lookup
            lookup_key = build_dir_str + output

        if output_path.exists():
            new_mtime = output_path.stat().st_mtime_ns
        else:
            new_mtime = old_mtime

        # Look up command for this output and recompute hash
        # Try the original output path first, then the converted absolute path
        command = output_to_command.get(output) or output_to_command.get(lookup_key)
        if command:
            new_hash = rapidhash.rapidhash(command.encode())
            new_lines.append(f"{start}\t{end}\t{new_mtime}\t{output}\t{new_hash:x}")
        else:
            new_lines.append(f"{start}\t{end}\t{new_mtime}\t{output}\t{old_hash}")

    ninja_log_path.write_text("\n".join(new_lines))


def fix_ninja_deps(ninja_deps_path: Path, src_str: str, dst_str: str) -> None:
    """Fix paths in .ninja_deps binary file.

    Format: header line + 4-byte version + records
    Each record: 4-byte length + [string + null + padding + 4-byte ID]
    """
    if not ninja_deps_path.exists():
        return

    content = ninja_deps_path.read_bytes()
    src_bytes = src_str.encode()
    if src_bytes not in content:
        return

    dst_bytes = dst_str.encode()
    result = bytearray()

    # Copy header (first line + version)
    header_end = content.index(b"\n") + 1 + 4
    result.extend(content[:header_end])
    i = header_end

    while i + 4 <= len(content):
        # Read record length (includes string + null + padding + 4-byte ID)
        rec_len = int.from_bytes(content[i : i + 4], "little")
        if rec_len < 4 or i + 4 + rec_len > len(content):
            result.extend(content[i:])
            break

        # Record data is rec_len bytes: string + null + padding + 4-byte ID
        rec_data = content[i + 4 : i + 4 + rec_len]
        str_part = rec_data[:-4]  # Everything except the 4-byte ID
        rec_id = rec_data[-4:]  # Last 4 bytes are the ID

        # Find null terminator in string part
        null_pos = str_part.find(b"\x00")
        if null_pos == -1:
            result.extend(content[i : i + 4 + rec_len])
            i += 4 + rec_len
            continue
        old_str = str_part[:null_pos]

        # Replace path if needed
        if src_bytes in old_str:
            new_str = old_str.replace(src_bytes, dst_bytes)
            new_str_padded_len = (
                (len(new_str) + 1) + 3
            ) & ~3  # +1 for null, align to 4
            new_rec_len = new_str_padded_len + 4  # +4 for ID
            result.extend(new_rec_len.to_bytes(4, "little"))
            result.extend(new_str)
            result.append(0)
            result.extend(b"\x00" * (new_str_padded_len - len(new_str) - 1))
            result.extend(rec_id)
        else:
            result.extend(content[i : i + 4 + rec_len])
        i += 4 + rec_len

    ninja_deps_path.write_bytes(bytes(result))


# =============================================================================
# PTY Utilities (for Claude trust)
# =============================================================================


def set_terminal_size(fd: int, rows: int = 24, cols: int = 80) -> None:
    """Set the terminal size for a PTY."""
    winsize = struct.pack("HHHH", rows, cols, 0, 0)
    fcntl.ioctl(fd, termios.TIOCSWINSZ, winsize)


# =============================================================================
# Task System
# =============================================================================


class Task(ABC):
    """Base class for graft tasks."""

    name: str
    description: str

    @abstractmethod
    def should_run(self, source: Path, target: Path) -> bool:
        """Check if this task should run for the given worktrees."""
        ...

    @abstractmethod
    def run(self, source: Path, target: Path, spinner: Spinner) -> None:
        """Execute the task."""
        ...

    def get_subtasks(self) -> list[tuple[str, str]]:
        """Return list of (name, description) tuples for subtasks.

        Override this if the task has subtasks that should be shown in the spinner.
        """
        return [(self.name, self.description)]


class TimestampTask(Task):
    """Copy file timestamps from source to target worktree."""

    name = "timestamps"
    description = "Copying file timestamps"

    def should_run(self, source: Path, target: Path) -> bool:
        # Always run if source exists
        return source.exists()

    def run(self, source: Path, target: Path, spinner: Spinner) -> None:
        def copy_timestamp(src_file: Path) -> None:
            rel_path = src_file.relative_to(source)
            dst_file = target / rel_path
            if dst_file.exists():
                try:
                    src_stat = src_file.stat()
                    os.utime(dst_file, (src_stat.st_atime, src_stat.st_mtime))
                except OSError:
                    pass  # Skip files that can't be stat'd or utime'd

        files = [f for f in source.rglob("*") if f.is_file() and not f.is_symlink()]
        with ThreadPoolExecutor(max_workers=8) as executor:
            list(executor.map(copy_timestamp, files))

        spinner.complete_task(self.name)


class SubmoduleTask(Task):
    """Copy submodules from source to target worktree."""

    name = "submodules"
    description = "Copying submodules"

    def __init__(self) -> None:
        self._submodules_to_copy: list[tuple[str, Path, Path]] = []
        self._submodules_to_init: list[tuple[str, str]] = []
        self._git_modules_dir: Path | None = None

    def should_run(self, source: Path, target: Path) -> bool:
        # Check if target has .gitmodules
        gitmodules = target / ".gitmodules"
        return gitmodules.exists()

    def get_subtasks(self) -> list[tuple[str, str]]:
        return [
            (self.name, self.description),
            ("submodules_update", "Updating submodules"),
        ]

    def _prepare(self, source: Path, target: Path) -> None:
        """Prepare submodule lists for copying."""
        self._submodules_to_copy = []
        self._submodules_to_init = []
        self._git_modules_dir = get_git_modules_dir(source)

        for info in get_submodule_info(target):
            src = source / info.path
            dst = target / info.path
            src_populated = src.exists() and any(src.iterdir())
            dst_empty = not dst.exists() or not any(dst.iterdir())

            if src_populated and dst_empty:
                self._submodules_to_copy.append((info.path, src, dst))
            elif not src_populated and info.url:
                # Submodule not initialized in source - will need to clone
                log(f"Will clone {info.path} (name={info.name}) from {info.url}")
                self._submodules_to_init.append((info.path, info.url))

    def run(self, source: Path, target: Path, spinner: Spinner) -> None:
        self._prepare(source, target)
        self._copy_submodules(source)
        spinner.complete_task(self.name)

        spinner.start_task("submodules_update")
        self._update_submodule_commits(target)
        self._clone_missing_submodules(target)
        spinner.complete_task("submodules_update")

    def _copy_submodules(self, source: Path) -> None:
        """Copy submodule working trees and .git directories."""
        if not self._submodules_to_copy:
            return

        def ignore_git(directory: str, files: list[str]) -> list[str]:
            return [".git"] if ".git" in files else []

        def copy_submodule(args: tuple[str, Path, Path]) -> None:
            submodule_path, src, dst = args
            # Safety check: never modify source directory
            assert not dst.is_relative_to(source), (
                f"dst {dst} is under source_root {source}"
            )
            if dst.exists():
                shutil.rmtree(dst)
            log(f"Copying submodule {submodule_path}")

            # Copy working tree files (exclude .git) with retry
            for attempt in range(3):
                try:
                    shutil.copytree(src, dst, symlinks=True, ignore=ignore_git)
                    break
                except shutil.Error as e:
                    if attempt == 2:
                        raise
                    log(f"Retrying copy of {submodule_path}: {e}")
                    if dst.exists():
                        shutil.rmtree(dst)
                    time.sleep(0.1)

            # Copy git data from shared modules to create standalone .git/ directory
            if self._git_modules_dir:
                src_git_dir = self._git_modules_dir / submodule_path
                dst_git_dir = dst / ".git"
                if src_git_dir.exists():
                    for attempt in range(3):
                        try:
                            shutil.copytree(src_git_dir, dst_git_dir, symlinks=True)
                            break
                        except shutil.Error as e:
                            if attempt == 2:
                                raise
                            log(f"Retrying .git copy for {submodule_path}: {e}")
                            if dst_git_dir.exists():
                                shutil.rmtree(dst_git_dir)
                            time.sleep(0.1)

                    # Make all files writable (git pack files are read-only)
                    for f in dst_git_dir.rglob("*"):
                        if f.is_file():
                            f.chmod(f.stat().st_mode | 0o200)

                    # Remove core.worktree - not needed when .git is inside working tree
                    config_file = dst_git_dir / "config"
                    subprocess.run(
                        [
                            "git",
                            "config",
                            "-f",
                            str(config_file),
                            "--unset",
                            "core.worktree",
                        ],
                        capture_output=True,
                    )

        with ThreadPoolExecutor(max_workers=4) as executor:
            list(executor.map(copy_submodule, self._submodules_to_copy))

    def _update_submodule_commits(self, target: Path) -> None:
        """Checkout the correct commit for each submodule.

        Uses ls-tree to get the commit the branch expects, not current state.
        Does not use `git submodule update` which modifies shared .git/modules config.
        """
        result = subprocess.run(
            ["git", "ls-tree", "-r", "HEAD"],
            cwd=target,
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            return

        for line in result.stdout.strip().split("\n"):
            if not line:
                continue
            # Format: <mode> <type> <commit>\t<path>
            parts = line.split()
            if len(parts) >= 4 and parts[1] == "commit":
                commit = parts[2]
                path = parts[3]
                submodule_dir = target / path
                if submodule_dir.exists():
                    subprocess.run(
                        ["git", "checkout", commit],
                        cwd=submodule_dir,
                        capture_output=True,
                    )

    def _clone_missing_submodules(self, target: Path) -> None:
        """Clone submodules that weren't initialized in source."""
        for submodule_path, url in self._submodules_to_init:
            log(f"Cloning submodule {submodule_path} from {url}")
            submodule_dir = target / submodule_path

            # Get expected commit for this submodule
            commit_result = subprocess.run(
                ["git", "ls-tree", "HEAD", submodule_path],
                cwd=target,
                capture_output=True,
                text=True,
            )
            if commit_result.returncode != 0:
                log(f"  ls-tree failed for {submodule_path}")
                continue
            parts = commit_result.stdout.split()
            if len(parts) < 3 or parts[1] != "commit":
                log(f"  not a commit entry: {commit_result.stdout}")
                continue
            commit = parts[2]
            log(f"  target commit: {commit}")

            # Clone and checkout
            if submodule_dir.exists():
                shutil.rmtree(submodule_dir)
            clone_result = subprocess.run(
                ["git", "clone", url, str(submodule_dir)],
                capture_output=True,
                text=True,
            )
            if clone_result.returncode != 0:
                log(f"  clone failed: {clone_result.stderr}")
                continue

            # Fetch the specific commit if not on default branch
            subprocess.run(
                ["git", "fetch", "origin", commit],
                cwd=submodule_dir,
                capture_output=True,
            )
            subprocess.run(
                ["git", "checkout", commit],
                cwd=submodule_dir,
                capture_output=True,
            )

            # Make all .git files writable (git pack files are read-only)
            git_dir = submodule_dir / ".git"
            if git_dir.is_dir():
                for f in git_dir.rglob("*"):
                    if f.is_file():
                        f.chmod(f.stat().st_mode | 0o200)


class BuildTask(Task):
    """Copy build directories from source to target and fix paths."""

    name = "build"
    description = "Processing build directory"

    def __init__(self) -> None:
        self._build_dirs_to_copy: list[tuple[Path, Path]] = []
        self._build_dirs_to_fix: list[Path] = []

    def should_run(self, source: Path, target: Path) -> bool:
        self._detect_build_dirs(source, target)
        return len(self._build_dirs_to_copy) > 0 or len(self._build_dirs_to_fix) > 0

    def get_subtasks(self) -> list[tuple[str, str]]:
        return [
            (self.name, self.description),
            ("cmake_paths", "Fixing CMake paths"),
            ("ninja_files", "Fixing ninja files"),
        ]

    def _detect_build_dirs(self, source: Path, target: Path) -> None:
        """Detect build directories to copy and existing directories to fix."""
        self._build_dirs_to_copy = []
        self._build_dirs_to_fix = []

        for pattern in BUILD_DIR_PATTERNS:
            if "*" in pattern:
                # Check source dirs to copy
                for src_dir in source.glob(pattern):
                    if src_dir.is_dir():
                        rel_path = src_dir.relative_to(source)
                        dst_dir = target / rel_path
                        if not dst_dir.exists():
                            self._build_dirs_to_copy.append((src_dir, dst_dir))
                # Check target dirs to fix (including target-only dirs)
                for dst_dir in target.glob(pattern):
                    if dst_dir.is_dir() and dst_dir not in self._build_dirs_to_fix:
                        self._build_dirs_to_fix.append(dst_dir)
            else:
                src_dir = source / pattern
                dst_dir = target / pattern
                if src_dir.is_dir() and not dst_dir.exists():
                    self._build_dirs_to_copy.append((src_dir, dst_dir))
                if dst_dir.is_dir() and dst_dir not in self._build_dirs_to_fix:
                    self._build_dirs_to_fix.append(dst_dir)

        # Remove parent directories if children are already in the lists
        # (e.g., don't copy/fix "build" if "build/release" is already listed)
        dst_paths = {dst for _, dst in self._build_dirs_to_copy}
        self._build_dirs_to_copy = [
            (src, dst)
            for src, dst in self._build_dirs_to_copy
            if not any(
                other != dst and other.is_relative_to(dst) for other in dst_paths
            )
        ]

        fix_paths = set(self._build_dirs_to_fix)
        self._build_dirs_to_fix = [
            dst
            for dst in self._build_dirs_to_fix
            if not any(
                other != dst and other.is_relative_to(dst) for other in fix_paths
            )
        ]

    def run(self, source: Path, target: Path, spinner: Spinner) -> None:
        src_str = str(source)
        dst_str = str(target)

        # Symlink CMakeUserPresets.json if it exists
        self._symlink_cmake_presets(source, target)

        # Copy all detected build directories
        copied_dirs = self._copy_build_dirs()
        spinner.complete_task(self.name)

        # Fix paths in both copied and existing directories
        all_dirs_to_fix = copied_dirs + self._build_dirs_to_fix

        if not all_dirs_to_fix:
            spinner.complete_task("cmake_paths")
            spinner.complete_task("ninja_files")
            return

        spinner.start_task("cmake_paths")
        self._fix_cmake_paths(all_dirs_to_fix, src_str, dst_str)
        spinner.complete_task("cmake_paths")

        spinner.start_task("ninja_files")
        self._fix_ninja_files(all_dirs_to_fix, src_str, dst_str)
        spinner.complete_task("ninja_files")

    def _symlink_cmake_presets(self, source: Path, target: Path) -> None:
        """Symlink CMakeUserPresets.json if it exists in source parent."""
        user_presets_src = source.parent / "CMakeUserPresets.json"
        user_presets_dst = target / "CMakeUserPresets.json"
        if user_presets_src.exists() and not user_presets_dst.exists():
            user_presets_dst.symlink_to(user_presets_src)

    def _copy_build_dirs(self) -> list[Path]:
        """Copy all detected build directories. Returns list of copied destination dirs."""
        copied = []
        for src_build, dst_build in self._build_dirs_to_copy:
            log(f"Copying {src_build.name}")
            for attempt in range(3):
                try:
                    shutil.copytree(src_build, dst_build, symlinks=True)
                    copied.append(dst_build)
                    break
                except shutil.Error as e:
                    if attempt == 2:
                        raise
                    log(f"Retrying build copy: {e}")
                    if dst_build.exists():
                        shutil.rmtree(dst_build)
                    time.sleep(0.1)
        return copied

    def _fix_cmake_paths(
        self, build_dirs: list[Path], src_str: str, dst_str: str
    ) -> None:
        """Fix paths in all CMake-generated files."""

        def fix_file(path: Path) -> None:
            try:
                content = path.read_text()
                if src_str in content:
                    stat = path.stat()
                    path.write_text(content.replace(src_str, dst_str))
                    os.utime(path, (stat.st_atime, stat.st_mtime))
            except (UnicodeDecodeError, PermissionError):
                pass  # Skip binary files

        for build_dir in build_dirs:
            files = [
                p for p in build_dir.rglob("*") if p.is_file() and not p.is_symlink()
            ]
            with ThreadPoolExecutor(max_workers=8) as executor:
                list(executor.map(fix_file, files))

    def _fix_ninja_files(
        self, build_dirs: list[Path], src_str: str, dst_str: str
    ) -> None:
        """Fix ninja log hashes and deps paths in all build directories."""
        for build_dir in build_dirs:
            # Run ninja_deps fixing and get_ninja_commands in parallel
            with ThreadPoolExecutor(max_workers=2) as executor:
                deps_future = executor.submit(
                    fix_ninja_deps, build_dir / ".ninja_deps", src_str, dst_str
                )
                commands_future = executor.submit(get_ninja_commands, build_dir)
                deps_future.result()
                output_to_command = commands_future.result()

            # Recompute command hashes in .ninja_log
            ninja_log = build_dir / ".ninja_log"
            if ninja_log.exists():
                fix_ninja_log(ninja_log, build_dir, output_to_command)


class ClaudeTrustTask(Task):
    """Trust Claude Code in the new worktree."""

    name = "trust"
    description = "Trusting Claude"

    def should_run(self, source: Path, target: Path) -> bool:
        # Only run if claude command exists
        return shutil.which("claude") is not None

    def run(self, source: Path, target: Path, spinner: Spinner) -> None:
        self._trust_claude(target)
        spinner.complete_task(self.name)

    def _trust_claude(self, cwd: Path) -> bool:
        """Launch Claude CLI and automatically confirm the trust dialog."""
        log("Starting Claude CLI...")

        master_fd, slave_fd = pty.openpty()
        set_terminal_size(slave_fd, 24, 120)

        # Use subprocess instead of fork to avoid issues with threading
        proc = subprocess.Popen(
            ["claude"],
            stdin=slave_fd,
            stdout=slave_fd,
            stderr=slave_fd,
            start_new_session=True,
            cwd=cwd,
        )
        os.close(slave_fd)
        log(f"Claude started (pid: {proc.pid})")

        buffer = b""
        trust_confirmed = False

        try:
            while True:
                ready, _, _ = select.select([master_fd], [], [], 5)

                if not ready:
                    log("Waiting for Claude output...")
                    continue

                try:
                    data = os.read(master_fd, 4096)
                except OSError as e:
                    log(f"Read error: {e}")
                    break

                if not data:
                    log("No more data from Claude")
                    break

                buffer += data
                raw_text = buffer.decode("utf-8", errors="ignore")
                text = strip_ansi(raw_text)

                snippet = strip_ansi(data.decode("utf-8", errors="ignore")).strip()
                if snippet:
                    if len(snippet) > 100:
                        snippet = snippet[:100] + "..."
                    log(f"Received: {repr(snippet)}")

                if not trust_confirmed and "trust this folder" in text.lower():
                    log("Trust dialog detected! Sending Enter to confirm...")
                    time.sleep(0.1)
                    os.write(master_fd, b"\r")
                    trust_confirmed = True
                    log("Trust confirmed. Waiting for Claude to initialize...")
                    set_terminal_size(master_fd, 24, 120)
                    continue

                if "Claude Code v" in text:
                    if trust_confirmed:
                        log("Claude initialized. Killing process...")
                    else:
                        log("Already trusted. Killing process...")
                    os.close(master_fd)
                    proc.kill()
                    proc.wait()
                    log("Done!")
                    return True

        except KeyboardInterrupt:
            log("Interrupted by user")
        finally:
            try:
                os.close(master_fd)
            except OSError:
                pass
            proc.kill()
            proc.wait()

        log("Could not detect Claude ready state.")
        return False


# =============================================================================
# Task Runner
# =============================================================================


@dataclass
class TaskRunner:
    """Orchestrates parallel execution of graft tasks."""

    source: Path
    target: Path
    tasks: list[Task] = field(default_factory=list)

    def __post_init__(self) -> None:
        # Register all task types
        self.tasks = [
            TimestampTask(),
            SubmoduleTask(),
            BuildTask(),
            ClaudeTrustTask(),
        ]

    def get_applicable_tasks(self) -> list[Task]:
        """Return list of tasks that should run for this worktree pair."""
        return [t for t in self.tasks if t.should_run(self.source, self.target)]

    def run(self) -> None:
        """Run all applicable tasks in parallel."""
        applicable = self.get_applicable_tasks()
        if not applicable:
            log("No tasks to run")
            return

        # Collect all subtasks for spinner display
        all_subtasks: list[tuple[str, str]] = []
        initial_active: list[str] = []
        for task in applicable:
            subtasks = task.get_subtasks()
            all_subtasks.extend(subtasks)
            # Mark first subtask of each task as initially active
            if subtasks:
                initial_active.append(subtasks[0][0])

        s = Spinner()
        s.set_tasks(all_subtasks, active=initial_active)
        s.start()

        try:
            # Run all tasks in parallel
            # Tasks operate on disjoint paths:
            # - TimestampTask: existing tracked files only
            # - SubmoduleTask: <submodule>/ directories
            # - BuildTask: build/*/ directories
            # - ClaudeTrustTask: external process, no file writes
            with ThreadPoolExecutor(max_workers=len(applicable)) as executor:
                futures = {
                    executor.submit(task.run, self.source, self.target, s): task
                    for task in applicable
                }
                error = None
                for future in futures:
                    try:
                        future.result()
                    except Exception as e:
                        if error is None:
                            error = (futures[future], e)
                if error:
                    s.stop()
                    task, exc = error
                    print(f"{RED}{CROSS}{RESET} {task.description}")
                    print(f"  {exc}")
                    sys.exit(1)
        finally:
            s.stop()

        # Print summary to stderr (stdout may be captured by hook runner)
        task_names = [t.name for t in applicable]
        print(
            f"{GREEN}{CHECK}{RESET} Grafted: {', '.join(task_names)}",
            file=sys.stderr,
            flush=True,
        )


# =============================================================================
# CLI
# =============================================================================


def main() -> None:
    global VERBOSE

    parser = argparse.ArgumentParser(
        description="Optimize a new git worktree by grafting cached state from the primary worktree"
    )
    parser.add_argument(
        "worktree_path",
        help="Path to the new worktree (use {{ worktree_path }} in hooks)",
    )
    parser.add_argument(
        "-s",
        "--source",
        help="Source worktree path (default: auto-detect primary worktree)",
    )
    parser.add_argument(
        "-v", "--verbose", action="store_true", help="Enable verbose output"
    )
    args = parser.parse_args()

    VERBOSE = args.verbose

    target = Path(args.worktree_path).resolve()
    if not target.exists():
        print(f"{RED}{CROSS}{RESET} Worktree path does not exist: {target}")
        sys.exit(1)

    # Find source worktree
    if args.source:
        source = Path(args.source).resolve()
    else:
        source = find_primary_worktree(target)

    if source is None:
        log("No source worktree found, nothing to graft")
        sys.exit(0)

    # Validate worktrees
    validation_error = validate_worktrees(source, target)
    if validation_error:
        print(f"{RED}{CROSS}{RESET} {validation_error}")
        sys.exit(1)

    log(f"Source: {source}")
    log(f"Target: {target}")

    # Run all applicable tasks
    runner = TaskRunner(source=source, target=target)
    runner.run()


if __name__ == "__main__":
    main()
