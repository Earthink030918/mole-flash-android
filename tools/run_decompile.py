# -*- coding: utf-8 -*-
"""Decompile base(4) APK components: AndroidManifest.xml + classes.dex -> Java sources."""
import os
import sys

BASE = r"C:\Users\Huawei\Downloads\base(4)"
OUT = r"C:\Users\Huawei\WorkBuddy\2026-10-17-00-34-31\decompile\out"
os.makedirs(OUT, exist_ok=True)

# ---------- 1. AndroidManifest.xml (AXML -> XML) ----------
from androguard.core.axml import AXMLPrinter

with open(os.path.join(BASE, "AndroidManifest.xml"), "rb") as f:
    axml = AXMLPrinter(f.read())
xml_str = axml.get_xml().decode("utf-8", errors="replace") if isinstance(axml.get_xml(), bytes) else axml.get_xml()
with open(os.path.join(OUT, "AndroidManifest.decoded.xml"), "w", encoding="utf-8") as f:
    f.write(xml_str)
print("[ok] AndroidManifest.decoded.xml")

# ---------- 2. classes.dex -> Java ----------
from loguru import logger as _lg
_lg.remove()  # 关掉 DEBUG 刷屏

from androguard.misc import AnalyzeDex
from androguard.decompiler.decompiler import DecompilerDAD

DEX_PATH = os.path.join(BASE, "classes.dex")
_sha, d, dx = AnalyzeDex(DEX_PATH)
dec = DecompilerDAD(d, dx)

java_dir = os.path.join(OUT, "java")
count = 0
for cls in d.get_classes():
    name = cls.get_name()  # e.g. Lcom/taomee/mole/MainActivity;
    path = name[1:-1]  # strip L and ;
    # skip libraries, keep app package + a summary for the rest
    if not (path.startswith("com/taomee/") or path.count("/") <= 1):
        continue
    try:
        src = dec.get_source_class(cls)
    except Exception as e:
        src = "/* DECOMPILE ERROR: %s */\n" % e
    out_path = os.path.join(java_dir, path + ".java")
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(src)
    count += 1
    print("[java]", path)

print("[done] %d classes written to %s" % (count, java_dir))

# ---------- 3. summary: strings / urls / permissions ----------
urls = set()
for s in d.get_strings():
    if "http" in s or ".com" in s or ".cn" in s:
        urls.add(s)
with open(os.path.join(OUT, "strings_urls.txt"), "w", encoding="utf-8") as f:
    for u in sorted(urls):
        f.write(u + "\n")
print("[ok] strings_urls.txt (%d entries)" % len(urls))

# class inventory
with open(os.path.join(OUT, "classes_inventory.txt"), "w", encoding="utf-8") as f:
    for cls in d.get_classes():
        f.write(cls.get_name() + "\n")
print("[ok] classes_inventory.txt")
