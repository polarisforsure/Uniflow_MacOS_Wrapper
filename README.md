# 🚀 UniFLOW MacOS Wrapper Script

**Author:** POLARISFORSURE  
**Version:** 1.0 – August 2025  

---

## 📌 Overview
The **UniFLOW MacOS Wrapper Script** repackages the official Canon SmartClient installer (`.pkg`) from a supplied UniFLOW `.ISO` file **together** with the `.tenantcfg.plist` configuration file into a **single unified .pkg installer**.  

The resulting package:
- Automatically deploys `.tenantcfg.plist` to  
  `/Library/Preferences/NT-ware/uniFLOW/.tenantcfg.plist`
- Installs the official Canon SmartClient for macOS in one seamless step.

---

## ✨ Features
- Extracts and combines the official Canon `.pkg` and `.tenantcfg.plist`
- Auto-detects Canon SmartClient version for the output filename
- Outputs a clean, ready-to-install `.pkg`
- Preserves the vendor installer’s signature
- Removes the need for manual configuration file deployment

---

## 🛠 Prerequisites
- A Mac running **macOS** with Terminal access
- Official **UniFLOW SmartClient MacOS `.ISO`** file downloaded from Canon
- Administrator privileges
- Basic familiarity with Terminal commands

---

## 📂 Script Setup

1. Save the script to your **Desktop** as:
make_uniflow_wrapper.sh


2. Make it executable:
```bash
chmod +x ~/Desktop/make_uniflow_wrapper.sh
```
3. Open the script in a text editor and update the ISO_PATH:

ISO_PATH="/Users/CHANGEME/Downloads/MacOS_UniflowSMRTclient_macos_2025.2.0.1.iso" # ====== Add your path (HERE) ======

## 🔍 How to Find Your ISO Path

1. Download the .ISO from Canon.

2. Locate it in Finder (usually in ~/Downloads).

3. Right-click → Get Info.

4. Copy the Where path.

5. Append the file name to the path. Example:
/Users/johndoe/Downloads/MacOS_UniflowSMRTclient_macos_2025.2.0.1.iso

6. Paste it into ISO_PATH in the script.

## ▶ Running the Script

From Terminal:
```bash
cd ~/Desktop
```
```bash
./make_uniflow_wrapper.sh
```

## What happens:

1. Mounts the ISO

2. Copies .tenantcfg.plist and SmartClientForMac.pkg

3. Detects the Canon version

4. Creates UniFLOW_MacOS_<version>.pkg on your Desktop

5. Unmounts the ISO

## 💻 Installing the Output Package

Option 1 – Double-click

Simply double-click the .pkg on your Desktop and follow the installer prompts.

Option 2 – Terminal install with logs
```bash
sudo /usr/sbin/installer -pkg ~/Desktop/UniFLOW_MacOS_<version>.pkg -target / -dumplog -verboseR
```
## 🔄 Maintenance & Updates

When Canon releases a new version:

1. Download the new .ISO

2. Update ISO_PATH in the script

3. Run the script again

4. Deploy the new .pkg

## 🐛 Troubleshooting

❌ ERROR: Not found: /Volumes/SmartClientMac/.tenantcfg.plist
→ ISO did not mount, or EXPECTED_VOLNAME in the script is wrong. Update it to match your ISO’s mounted name.

❌ Copied file is empty
→ ISO might be corrupted. Re-download from Canon.

⚠ Installer says unsigned package
→ Expected for the configuration component. The Canon installer itself remains signed.

## Need detailed debugging?
Run:
```bash
bash -x ./make_uniflow_wrapper.sh
```
## 📄 Technical Documentation

For a detailed step-by-step guide, refer to the included PDF.
