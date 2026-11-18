from __future__ import annotations

import asyncio
from dataclasses import dataclass, field
from pathlib import Path

IGNORED = {".git", "node_modules", "__pycache__"}


@dataclass(slots=True)
class FileIndex:
    root: Path
    files: dict[str, int] = field(default_factory=dict)

    def add(self, path: Path) -> None:
        self.files[str(path.relative_to(self.root))] = path.stat().st_size

    @property
    def total_bytes(self) -> int:
        return sum(self.files.values())


async def build_index(root: Path, *, limit: int = 10_000) -> FileIndex:
    """Walk a workspace and record file sizes, skipping ignored folders."""
    index = FileIndex(root)
    for path in root.rglob("*"):
        if IGNORED.intersection(path.parts) or not path.is_file():
            continue
        index.add(path)
        if len(index.files) >= limit:
            break
        await asyncio.sleep(0)
    return index


if __name__ == "__main__":
    result = asyncio.run(build_index(Path.cwd()))
    print(f"{len(result.files)} files, {result.total_bytes / 1e6:.1f} MB")
