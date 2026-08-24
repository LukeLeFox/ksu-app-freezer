from __future__ import annotations

from hashlib import sha256
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo


ROOT = Path(__file__).resolve().parents[1]
MODULE_DIR = ROOT / "module"
ARCHIVE_PREFIX = "KSU-App-Freezer"
EXECUTABLE_NAMES = {"action.sh", "customize.sh", "manage.sh", "uninstall.sh"}


def read_properties(path: Path) -> dict[str, str]:
    result: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if "=" in line and not line.lstrip().startswith("#"):
            key, value = line.split("=", 1)
            result[key.strip()] = value.strip()
    return result


def add_file(archive: ZipFile, source: Path, relative: Path) -> None:
    mode = 0o755 if source.name in EXECUTABLE_NAMES else 0o644
    info = ZipInfo(relative.as_posix(), date_time=(2026, 1, 1, 0, 0, 0))
    info.create_system = 3
    info.external_attr = (0o100000 | mode) << 16
    info.compress_type = ZIP_DEFLATED
    archive.writestr(info, source.read_bytes())


def main() -> None:
    version = read_properties(MODULE_DIR / "module.prop")["version"]
    release_dir = ROOT / "release"
    release_dir.mkdir(parents=True, exist_ok=True)
    output = release_dir / f"{ARCHIVE_PREFIX}-v{version}.zip"

    for stale in release_dir.glob(f"{ARCHIVE_PREFIX}-v*.zip"):
        if stale != output:
            stale.unlink()

    with ZipFile(output, "w") as archive:
        for source in sorted(path for path in MODULE_DIR.rglob("*") if path.is_file()):
            if source.name == "README.md":
                continue
            add_file(archive, source, source.relative_to(MODULE_DIR))

    checksum_file = release_dir / "SHA256SUMS.txt"
    checksum_file.write_text(
        f"{sha256(output.read_bytes()).hexdigest()}  {output.name}\n",
        encoding="ascii",
        newline="\n",
    )
    print(output.relative_to(ROOT))
    print(checksum_file.relative_to(ROOT))


if __name__ == "__main__":
    main()
