#!/bin/bash

cat <<'POLARIS_ASCII'
 _______  _______  _        _______  _______ _________ _______ 
(  ____ )(  ___  )( \      (  ___  )(  ____ )\__   __/(  ____ \
| (    )|| (   ) || (      | (   ) || (    )|   ) (   | (    \/
| (____)|| |   | || |      | (___) || (____)|   | |   | (_____ 
|  _____)| |   | || |      |  ___  ||     __)   | |   (_____  )
| (      | |   | || |      | (   ) || (\ (      | |         ) |
| )      | (___) || (____/\| )   ( || ) \ \_____) (___/\____) |
|/       (_______)(_______/|/     \||/   \__/\_______/\_______)
                                                               
POLARIS_ASCII
# ====== This script is dedicated to my fantastic co-worker Faviol Sinanaj ======
# ====== If you need more useful scripts - Check out my Github @polarisforsure ======
# ====== I made this while on the toilet, imagine what I could do if they compensated me better ======
set -euo pipefail

# ====== CONFIG (adjust ISO_PATH only if your path changes) ======
ISO_PATH="/Users/CHANGEME/Downloads/MacOS_UniflowSMRTclient_macos_2025.2.0.1.iso" # ====== Add your path (HERE) ======
EXPECTED_VOLNAME="SmartClientMac"   # ISO mounts as /Volumes/SmartClientMac
TARGET_PLIST_PATH="/Library/Preferences/NT-ware/uniFLOW/.tenantcfg.plist"
WRK="${HOME}/uniflow-wrap"
# ===============================================================

log(){ echo ">> $*"; }

# Derive version (prefer vendor pkg; fallback to version in ISO name)
derive_version() {
  local vendor_pkg="$1"
  local iso_path="$2"
  local expand_dir
  expand_dir="$(dirname "$vendor_pkg")/_expand"
  rm -rf "$expand_dir"; mkdir -p "$expand_dir"
  pkgutil --expand-full "$vendor_pkg" "$expand_dir" >/dev/null 2>&1 || true
  local ver=""
  if [[ -f "$expand_dir/Distribution" ]]; then
    ver="$(awk 'match($0,/version="[^"]+"/){v=substr($0,RSTART+9,RLENGTH-10); print v; exit}' "$expand_dir/Distribution")"
  fi
  if [[ -z "$ver" ]]; then
    ver="$(grep -ho 'version="[^"]*"' "$expand_dir"/**/PackageInfo 2>/dev/null \
          | sed -E 's/.*version="([^"]*)".*/\1/' | sort -V | tail -1 || true)"
  fi
  if [[ -z "$ver" ]]; then
    ver="$(echo "$iso_path" | grep -Eo '[0-9]+(\.[0-9]+){1,3}' | tail -1 || true)"
  fi
  [[ -n "$ver" ]] || ver="unknown"
  echo "$ver"
}

# Clean working dir
log "Reset working dir..."
rm -rf "$WRK"; mkdir -p "$WRK"; cd "$WRK"

# Mount ISO and auto-detach on exit
MNT_POINT="/Volumes/${EXPECTED_VOLNAME}"
mounted_before=false
trap 'if mount | grep -q "$MNT_POINT"; then hdiutil detach "$MNT_POINT" >/dev/null || true; fi' EXIT

if ! mount | grep -q "/Volumes/${EXPECTED_VOLNAME} "; then
  log "Mounting ISO..."
  hdiutil attach -nobrowse -readonly "$ISO_PATH" >/dev/null
else
  mounted_before=true
fi
[[ -d "$MNT_POINT" ]] || { echo "ERROR: Expected mount at $MNT_POINT not found."; exit 1; }
log "Mounted at: $MNT_POINT"

# Required files on ISO
PLIST_ON_ISO="${MNT_POINT}/.tenantcfg.plist"
VENDOR_PKG_ON_ISO="${MNT_POINT}/SmartClientForMac.pkg"
[[ -f "$PLIST_ON_ISO" ]] || { echo "ERROR: Not found: $PLIST_ON_ISO"; ls -la "$MNT_POINT" || true; exit 1; }
[[ -f "$VENDOR_PKG_ON_ISO" ]] || { echo "ERROR: Not found: $VENDOR_PKG_ON_ISO"; ls -la "$MNT_POINT" || true; exit 1; }

# Copy required files into working dir
log "Copy cfg and vendor pkg from ISO..."
cp "$PLIST_ON_ISO" "$WRK/.tenantcfg.plist"
cp "$VENDOR_PKG_ON_ISO" "$WRK/SmartClientForMac.pkg"
[[ -s "$WRK/.tenantcfg.plist" ]] || { echo "ERROR: Copied .tenantcfg.plist is empty."; exit 1; }
[[ -s "$WRK/SmartClientForMac.pkg" ]] || { echo "ERROR: Copied SmartClientForMac.pkg is empty."; exit 1; }

# Determine version and output name
VERSION="$(derive_version "$WRK/SmartClientForMac.pkg" "$ISO_PATH")"
OUTPUT_NAME="UniFLOW_MacOS_${VERSION}.pkg"
log "Detected version: ${VERSION}"
log "Output will be named: ${OUTPUT_NAME}"

# Detach ISO unless it was already mounted before the script
if ! $mounted_before; then
  if mount | grep -q "$MNT_POINT"; then
    log "Detaching ISO..."
    hdiutil detach "$MNT_POINT" >/dev/null || true
  fi
fi

# Build a single wrapper component pkg with a postinstall that:
#  1) installs .tenantcfg.plist
#  2) runs Canon's SmartClientForMac.pkg
log "Building wrapper pkg with postinstall..."
mkdir -p "$WRK/scripts"
cat > "$WRK/scripts/postinstall" <<'PIEOF'
#!/bin/bash
set -euo pipefail
TARGET_PLIST_PATH="__TARGET_PLIST_PATH__"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Placing cfg to: $TARGET_PLIST_PATH"
install -d -m 755 "$(dirname "$TARGET_PLIST_PATH")"
install -m 644 "$SCRIPT_DIR/.tenantcfg.plist" "$TARGET_PLIST_PATH"
chown root:wheel "$TARGET_PLIST_PATH"

echo "Invoking Canon installer..."
/usr/sbin/installer -pkg "$SCRIPT_DIR/SmartClientForMac.pkg" -target / -dumplog -verboseR

echo "Wrapper postinstall complete."
exit 0
PIEOF
chmod +x "$WRK/scripts/postinstall"

# Put resources in Scripts dir so they are embedded in the pkg
cp "$WRK/.tenantcfg.plist" "$WRK/scripts/.tenantcfg.plist"
cp "$WRK/SmartClientForMac.pkg" "$WRK/scripts/SmartClientForMac.pkg"

# Create the wrapper pkg (payload-free)
pkgbuild \
  --identifier "com.universum.uniflow.wrapper" \
  --version "$VERSION" \
  --scripts "$WRK/scripts" \
  --nopayload \
  "$HOME/Desktop/$OUTPUT_NAME"

# Verify output
if [[ -s "$HOME/Desktop/$OUTPUT_NAME" ]]; then
  log "Build complete."
  echo
  echo "== Verify output =="
  ls -lh "$HOME/Desktop/$OUTPUT_NAME" || true
  echo
  echo "== Signature check =="
  pkgutil --check-signature "$HOME/Desktop/$OUTPUT_NAME" || true
  echo
  echo "Done: $HOME/Desktop/$OUTPUT_NAME"
  echo
  echo "Tip: Install via CLI for full logs:"
  echo "  sudo /usr/sbin/installer -pkg \"$HOME/Desktop/$OUTPUT_NAME\" -target / -dumplog -verboseR"
else
  echo "ERROR: Final pkg not created."
  exit 1
fi
