
## [CHECKPOINT] 2026-09-17 15:01:21 WIB - Rename Folder Project
- **Perubahan**: Rename direktori fisik dari `/data/Projects/SAP-Modul-Project-with-Agentic-AI` ke `/data/Projects/Project-SAP`.
- **Kompatibilitas**:
  - Symlink baru dibuat: `/home/abap/Projects/Project-SAP` -> `/data/Projects/Project-SAP`.
  - Symlink backward-compatibility: `/home/abap/Projects/SAP-Modul-Project-with-Agentic-AI` -> `/data/Projects/Project-SAP`.
- **Git Config**: Tetap mengarah ke `https://github.com/bud1purwanto/SAP-Modul-Project-with-Agentic-AI.git` (tidak ada dampak negatif ke push/pull).
- **Hermes Skill**: Path pada skill `sap-gui-virtual-session` diperbarui ke direktori baru.
- **Status**: Sukses dan terverifikasi.
