import lzma
import pathlib
import shutil
import sys

source = pathlib.Path(sys.argv[1])
target = pathlib.Path(sys.argv[2])
with lzma.open(source, "rb") as compressed, target.open("wb") as output:
    shutil.copyfileobj(compressed, output)
print(f"DECOMPRESSED {target} {target.stat().st_size} bytes")
