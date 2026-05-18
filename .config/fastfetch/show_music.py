#!/usr/bin/env python3
import asyncio
import base64
import io
import sys

from PIL import Image, ImageDraw
from winsdk.windows.media.control import (
    GlobalSystemMediaTransportControlsSessionManager as MediaManager,
)
from winsdk.windows.storage.streams import Buffer, DataReader, InputStreamOptions

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")

IMG_WIDTH_CELLS = 6
IMG_HEIGHT_CELLS = 3
ICON_PX = 240

STATUS_MAP = {0: "Closed", 1: "Opened", 2: "Changing", 3: "Stopped", 4: "Playing", 5: "Paused"}
STATUS_ICON = {"Playing": "▶", "Paused": "⏸", "Stopped": "■"}

MAUVE = "\x1b[38;2;203;166;247m"
PINK = "\x1b[38;2;245;194;231m"
LAVENDER = "\x1b[38;2;180;190;254m"
SUBTLE = "\x1b[38;2;127;132;156m"
RESET = "\x1b[0m"
BOLD = "\x1b[1m"


async def fetch_media():
    sessions = await MediaManager.request_async()
    session = sessions.get_current_session()
    if not session:
        return None
    info = await session.try_get_media_properties_async()
    playback = session.get_playback_info()
    status = STATUS_MAP.get(playback.playback_status, "Unknown")
    thumb_bytes = None
    if info.thumbnail:
        stream = await info.thumbnail.open_read_async()
        buf = Buffer(stream.size)
        await stream.read_async(buf, stream.size, InputStreamOptions.NONE)
        reader = DataReader.from_buffer(buf)
        arr = bytearray(buf.length)
        reader.read_bytes(arr)
        thumb_bytes = bytes(arr)
    return {
        "title": (info.title or "").strip(),
        "artist": (info.artist or "").strip(),
        "album": (info.album_title or "").strip(),
        "status": status,
        "source": session.source_app_user_model_id or "",
        "thumb": thumb_bytes,
    }


def pretty_source(source: str) -> str:
    s = source.lower()
    if "spotify" in s:
        return "Spotify"
    if "msedge" in s or "microsoft.edge" in s:
        return "Edge"
    if "apple" in s:
        return "Apple Music"
    if "groove" in s or "zunemusic" in s:
        return "Groove"
    if "chrome" in s:
        return "Chrome"
    if "firefox" in s:
        return "Firefox"
    return source.split(".")[-1] if source else "Player"


def make_circle_png(raw_bytes: bytes, size: int = ICON_PX) -> bytes:
    img = Image.open(io.BytesIO(raw_bytes)).convert("RGBA")
    side = min(img.size)
    left = (img.size[0] - side) // 2
    top = (img.size[1] - side) // 2
    img = img.crop((left, top, left + side, top + side)).resize((size, size), Image.LANCZOS)
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, size, size), fill=255)
    img.putalpha(mask)
    out = io.BytesIO()
    img.save(out, format="PNG")
    return out.getvalue()


def iterm2_image(png: bytes, width_cells: int, height_cells: int) -> str:
    b64 = base64.b64encode(png).decode("ascii")
    name = base64.b64encode(b"music.png").decode("ascii")
    return (
        f"\x1b]1337;File=name={name};size={len(png)};"
        f"width={width_cells};height={height_cells};"
        f"preserveAspectRatio=1;inline=1:{b64}\x07"
    )


def truncate(text: str, max_chars: int) -> str:
    if len(text) <= max_chars:
        return text
    return text[: max_chars - 1] + "…"


def render(info: dict) -> None:
    png = make_circle_png(info["thumb"])
    img_seq = iterm2_image(png, IMG_WIDTH_CELLS, IMG_HEIGHT_CELLS)

    src = pretty_source(info["source"])
    status_icon = STATUS_ICON.get(info["status"], "")
    title = truncate(info["title"] or "(no title)", 48)
    artist = truncate(info["artist"] or "(unknown)", 48)
    album = truncate(info["album"] or "", 48)

    # 右側に出すテキスト 3 行 (画像 3 セル高に合わせる)
    lines = [
        f"{PINK}{BOLD} Music{RESET}  {MAUVE}{title}{RESET}",
        f"{LAVENDER}by{RESET} {artist}" + (f"  {SUBTLE}/ {album}{RESET}" if album else ""),
        f"{SUBTLE}{src} {status_icon} {info['status']}{RESET}",
    ]

    sys.stdout.write("\n")
    sys.stdout.write("\x1b[s")          # save cursor
    sys.stdout.write(img_seq)            # render image (cursor moves to row+H)
    sys.stdout.write("\x1b[u")          # restore cursor to row where image started
    indent = IMG_WIDTH_CELLS + 2
    for i, line in enumerate(lines):
        sys.stdout.write(f"\x1b[{indent}C{line}")
        if i < len(lines) - 1:
            sys.stdout.write("\n")
    # 画像の最終行 (cursor は最後のテキスト行) より下にカーソルを動かす
    remaining = IMG_HEIGHT_CELLS - len(lines)
    for _ in range(max(remaining, 0) + 1):
        sys.stdout.write("\n")
    sys.stdout.flush()


def main() -> None:
    try:
        info = asyncio.run(fetch_media())
    except Exception:
        return
    if not info or not info.get("thumb"):
        return
    if info["status"] not in ("Playing", "Paused"):
        return
    render(info)


if __name__ == "__main__":
    main()
