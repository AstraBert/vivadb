import httpx
import platform
import os

from pathlib import Path

__version__ = "0.1.0-beta"
_download_path = Path(__file__).resolve().parents[0]

async def _download_binary() -> None:
    op_sys = "linux"
    if platform.system().lower() == "windows":
        raise ValueError("It is not possible, for now, to use vivadb on Windows. We hope to release a version with support for it soon!")
    elif platform.system().lower() == "darwin":
        op_sys = "macos"
    download_path = f"https://github.com/AstraBert/vivadb/releases/download/{__version__}/vivadb-{op_sys}"
    async with httpx.AsyncClient() as client:
        response = await client.get(download_path, follow_redirects=True)
        content = response.content
        if len(content) > 0:
            with open(os.path.join(_download_path, "vivadb"), "wb") as f:
                f.write(content)
            return None
        else:
            raise ValueError("Unable to download vivadb at this time, please retry later")
