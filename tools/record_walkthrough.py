"""Capture the emulator window while the automated happy path is executed."""

from __future__ import annotations

import ctypes
import threading
import time
from ctypes import wintypes
from pathlib import Path

import imageio.v2 as imageio
import numpy as np
from PIL import Image

from ui_walkthrough import ROOT, walk_happy_path


WINDOW_TITLE = "Emulator"
TARGET_FPS = 8
OUTPUT = ROOT / "docs" / "videos" / "MysteryGame-demo.mp4"


class BitmapInfoHeader(ctypes.Structure):
    _fields_ = [
        ("biSize", wintypes.DWORD),
        ("biWidth", wintypes.LONG),
        ("biHeight", wintypes.LONG),
        ("biPlanes", wintypes.WORD),
        ("biBitCount", wintypes.WORD),
        ("biCompression", wintypes.DWORD),
        ("biSizeImage", wintypes.DWORD),
        ("biXPelsPerMeter", wintypes.LONG),
        ("biYPelsPerMeter", wintypes.LONG),
        ("biClrUsed", wintypes.DWORD),
        ("biClrImportant", wintypes.DWORD),
    ]


def _find_emulator_window() -> int:
    user32 = ctypes.windll.user32
    candidates: list[tuple[int, str]] = []
    enum_proc = ctypes.WINFUNCTYPE(wintypes.BOOL, wintypes.HWND, wintypes.LPARAM)

    def collect(hwnd, _lparam):
        if not user32.IsWindowVisible(hwnd):
            return True
        title_length = user32.GetWindowTextLengthW(hwnd)
        title = ctypes.create_unicode_buffer(title_length + 1)
        user32.GetWindowTextW(hwnd, title, title_length + 1)
        class_name = ctypes.create_unicode_buffer(256)
        user32.GetClassNameW(hwnd, class_name, 256)
        if title.value == WINDOW_TITLE:
            candidates.append((hwnd, class_name.value))
        return True

    user32.EnumWindows(enum_proc(collect), 0)
    for hwnd, class_name in candidates:
        if "QWindowIcon" in class_name:
            return hwnd
    if candidates:
        return candidates[0][0]
    raise RuntimeError("The DevEco emulator window was not found")


def _force_foreground(hwnd: int) -> None:
    user32 = ctypes.windll.user32
    kernel32 = ctypes.windll.kernel32
    foreground = user32.GetForegroundWindow()
    current_thread = kernel32.GetCurrentThreadId()
    foreground_thread = user32.GetWindowThreadProcessId(foreground, None)
    target_thread = user32.GetWindowThreadProcessId(hwnd, None)
    user32.AttachThreadInput(current_thread, foreground_thread, True)
    user32.AttachThreadInput(current_thread, target_thread, True)
    user32.ShowWindow(hwnd, 9)
    user32.BringWindowToTop(hwnd)
    user32.SetForegroundWindow(hwnd)
    user32.SetFocus(hwnd)
    user32.AttachThreadInput(current_thread, target_thread, False)
    user32.AttachThreadInput(current_thread, foreground_thread, False)
    time.sleep(0.8)


def _capture_window(hwnd: int, width: int, height: int) -> Image.Image:
    user32 = ctypes.windll.user32
    gdi32 = ctypes.windll.gdi32
    window_dc = user32.GetWindowDC(hwnd)
    memory_dc = gdi32.CreateCompatibleDC(window_dc)
    bitmap = gdi32.CreateCompatibleBitmap(window_dc, width, height)
    old_bitmap = gdi32.SelectObject(memory_dc, bitmap)
    try:
        if not user32.PrintWindow(hwnd, memory_dc, 2):
            raise RuntimeError("PrintWindow failed for the emulator window")
        header = BitmapInfoHeader()
        header.biSize = ctypes.sizeof(BitmapInfoHeader)
        header.biWidth = width
        header.biHeight = -height
        header.biPlanes = 1
        header.biBitCount = 32
        header.biCompression = 0
        buffer = ctypes.create_string_buffer(width * height * 4)
        gdi32.GetDIBits(memory_dc, bitmap, 0, height, buffer, ctypes.byref(header), 0)
        return Image.frombuffer("RGBA", (width, height), buffer, "raw", "BGRA", 0, 1).convert("RGB")
    finally:
        gdi32.SelectObject(memory_dc, old_bitmap)
        gdi32.DeleteObject(bitmap)
        gdi32.DeleteDC(memory_dc)
        user32.ReleaseDC(hwnd, window_dc)


def record() -> None:
    ctypes.windll.shcore.SetProcessDpiAwareness(2)
    hwnd = _find_emulator_window()
    _force_foreground(hwnd)

    user32 = ctypes.windll.user32
    rect = wintypes.RECT()
    user32.GetWindowRect(hwnd, ctypes.byref(rect))
    screen_height = rect.bottom - rect.top
    screen_width = round(screen_height * 1320 / 2848) + 4
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    stop_event = threading.Event()
    errors: list[Exception] = []
    writer = imageio.get_writer(
        OUTPUT,
        fps=TARGET_FPS,
        codec="libx264",
        quality=7,
        pixelformat="yuv420p",
        macro_block_size=2,
        output_params=["-preset", "fast"],
        ffmpeg_log_level="error",
    )

    def capture_frames() -> None:
        interval = 1 / TARGET_FPS
        while not stop_event.is_set():
            started = time.monotonic()
            try:
                window_frame = _capture_window(hwnd, rect.right - rect.left, screen_height)
                frame = np.asarray(window_frame.crop((0, 0, screen_width, screen_height)))
                writer.append_data(frame)
            except Exception as error:  # pragma: no cover - environment dependent
                errors.append(error)
                stop_event.set()
                break
            elapsed = time.monotonic() - started
            time.sleep(max(0.01, interval - elapsed))

    capture_thread = threading.Thread(target=capture_frames, daemon=True)
    capture_thread.start()
    try:
        time.sleep(1.0)
        walk_happy_path()
        time.sleep(2.0)
    finally:
        stop_event.set()
        capture_thread.join(timeout=5)
        writer.close()

    if errors:
        raise errors[0]
    if not OUTPUT.exists() or OUTPUT.stat().st_size == 0:
        raise RuntimeError("Video output was not created")
    print(f"Recording saved to {OUTPUT} ({OUTPUT.stat().st_size} bytes)")


if __name__ == "__main__":
    record()
