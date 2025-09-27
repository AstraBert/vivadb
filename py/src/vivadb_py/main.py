import httpx
import asyncio
import platform
import os
import sys
import subprocess as sp
import stat

from pathlib import Path

__version__ = "v0.1.1-alpha"
_download_path = Path(__file__).resolve().parents[0]

async def _download_binary() -> None:
    op_sys = "linux"
    if platform.system().lower() == "windows":
        raise ValueError("It is not possible, for now, to use vivadb on Windows. We hope to release a version with support for it soon!")
    elif platform.system().lower() == "darwin":
        op_sys = "macos"
    download_url = f"https://github.com/AstraBert/vivadb/releases/download/{__version__}/vivadb-{op_sys}"
    async with httpx.AsyncClient() as client:
        response = await client.get(download_url, follow_redirects=True)
        content = response.content
        if len(content) > 0:
            with open(os.path.join(_download_path, "vivadb"), "wb") as f:
                f.write(content)
            current_mode = os.stat(os.path.join(_download_path, "vivadb")).st_mode
            os.chmod(os.path.join(_download_path, "vivadb"), current_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)
            return None
        else:
            raise ValueError("Unable to download vivadb at this time, please retry later")

def _exists_and_is_executable() -> bool:
    return os.path.exists(os.path.join(_download_path, "vivadb")) and os.access(os.path.join(_download_path, "vivadb"), os.X_OK)

async def async_main(args: list[str]) -> None:
    if not _exists_and_is_executable():
        await _download_binary()
    exec_path = os.path.join(_download_path, "vivadb")
    try:
        result = sp.run(
            [exec_path, *args],
            stdin=sys.stdin,
            stdout=sys.stdout,
            stderr=sys.stderr,
            timeout=10,
            text=True
        )
    except sp.CalledProcessError as e:
        print(f"Process failed with return code: {e.returncode}")
        print(e.stderr)
    except FileNotFoundError:
        print("File not found or not executable")
    except Exception as e:
        print(f"An error occurred: {e}")

def main():
    args = sys.argv[1:]
    asyncio.run(async_main(args))
