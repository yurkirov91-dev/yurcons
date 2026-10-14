#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
python3 - <<'PY'
from pathlib import Path
import hashlib
import importlib
import shutil
import urllib.request

for module in ['pypdf', 'docx', 'openpyxl', 'yaml', 'fitz']:
    importlib.import_module(module)
for tool in ['pdftotext', 'pdftoppm', 'tesseract']:
    if not shutil.which(tool):
        raise RuntimeError('Base environment missing tool: ' + tool)
folder = Path('.local/tessdata')
folder.mkdir(parents=True, exist_ok=True)
target = folder / 'rus.traineddata'
expected = 'e16e5e036cce1d9ec2b00063cf8b54472625b9e14d893a169e2b0dedeb4df225'
if not target.exists() or hashlib.sha256(target.read_bytes()).hexdigest() != expected:
    url = 'https://raw.githubusercontent.com/tesseract-ocr/tessdata_fast/87416418657359cb625c412a48b6e1d6d41c29bd/rus.traineddata'
    with urllib.request.urlopen(url, timeout=60) as response:
        data = response.read()
    if hashlib.sha256(data).hexdigest() != expected:
        raise RuntimeError('Russian OCR checksum mismatch')
    temporary = folder / 'rus.traineddata.download'
    temporary.write_bytes(data)
    temporary.replace(target)
for language in ['eng', 'osd']:
    destination = folder / (language + '.traineddata')
    if not destination.exists():
        source = Path('/usr/share/tesseract-ocr/5/tessdata') / destination.name
        if not source.exists():
            raise RuntimeError('Missing base OCR data: ' + str(source))
        destination.symlink_to(source)
print('Document modules, tools and Russian OCR verified')
PY
TESSDATA_PREFIX="$PWD/.local/tessdata" tesseract --list-langs
