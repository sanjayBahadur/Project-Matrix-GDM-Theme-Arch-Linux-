# 🟩 Project Matrix GDM Theme (Arch Linux)

A fully automated, plug-and-play Matrix-themed GDM and Plymouth installer for Arch Linux running GNOME + Wayland.

## 🔧 Features
- Green code rain GDM background (generated on-the-fly)
- Plymouth boot splash with Matrix animation
- Fully automated installer with `--install`, `--revert`, and `--uninstall`
- Self-contained. No preloaded images. Internet access only used for dependency installation.

## 🛠 Requirements
- Arch Linux
- GNOME Display Manager (GDM)
- Wayland session

## 🚀 Installation
```bash
git clone https://github.com/yourname/project_matrix.git
cd project_matrix
sudo ./install.sh --install
```

## 🧹 Revert or Uninstall
```bash
sudo ./install.sh --revert    # Restore original GDM + Plymouth
sudo ./install.sh --uninstall # Completely remove and clean up
```

## 📁 Files
- `install.sh`: Main installer script
- `gdm/`: GDM theme generation assets (auto-generated)
- `plymouth/`: Plymouth animation frames (auto-generated)

## 🔐 Safe and Clean
- Backs up your original GDM theme
- Detects issues and fails gracefully
- Does not require any preloaded image assets

## 👨‍💻 License
MIT
