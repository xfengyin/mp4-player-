#!/usr/bin/env bash
set -euo pipefail
FW="$1"       # firmware/original_firmware.bin
BIN="$2"      # build/mp4-player
OUTDIR="$3"   # build/output
mkdir -p "$OUTDIR"
workdir=$(mktemp -d)
echo "workdir=$workdir"

# 1) extract with binwalk
echo "Extracting firmware..."
binwalk -e "$FW" -C "$workdir/extracted" || true

# Heuristics: locate extracted squashfs
sq=$(find "$workdir/extracted" -type f -iname "*.sqfs" -o -iname "*.squashfs" | head -n1 || true)
if [ -z "$sq" ]; then
  # try common extracted folders
  sq=$(find "$workdir/extracted" -type f -name "squashfs-root" -print -quit || true)
fi

if [ -n "$sq" ]; then
  echo "Found squashfs: $sq"
  # if it's a squashfs file, unsquash it
  ssdir="$workdir/rootfs"
  mkdir -p "$ssdir"
  if file "$sq" | grep -qi squashfs; then
    echo "Unsquashing..."
    unsquashfs -f -d "$ssdir" "$sq"
  else
    # if unpacked dir already present
    if [ -d "$sq" ]; then
      cp -a "$sq/." "$ssdir/"
    fi
  fi

  # 2) inject our binary (adjust target path as needed)
  echo "Injecting binary..."
  mkdir -p "$ssdir/usr/bin"
  cp "$BIN" "$ssdir/usr/bin/mp4-player"
  chmod +x "$ssdir/usr/bin/mp4-player"

  # 3) rebuild squashfs (options may vary)
  new_sq="$OUTDIR/newroot.squashfs"
  mksquashfs "$ssdir" "$new_sq" -noappend -comp xz

  # 4) Repack firmware - vendor specific. Here we just place new squashfs into OUTDIR and
  #    leave vendor-specific headering/packing as manual step.
  echo "Repacked squashfs created: $new_sq"
  echo "NOTE: Final firmware packaging (combining kernel/headers and new squashfs) is vendor-specific."
  echo "You may need to re-run mkimage or a vendor tool to produce final 'update.bin'."
  ls -l "$OUTDIR"
else
  echo "No squashfs found. Manual intervention required. Check $workdir/extracted for available files."
  ls -R "$workdir/extracted" | sed -n '1,200p'
fi

echo "Done. Output in $OUTDIR"
