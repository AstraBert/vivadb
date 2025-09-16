import pytest
import platform

from src.vivadb_py.main import _download_binary, _exists_and_is_executable

windows_skip = not (platform.system().lower() == "darwin" or platform.system().lower() == "linux")

@pytest.mark.skipif(
    condition=windows_skip,
    reason="Your operating system is not supported by vivadb"
)
@pytest.mark.asyncio
async def test_helper_functions() -> None:
    await _download_binary()
    assert _exists_and_is_executable()
