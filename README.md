# dotfiles-windows

Windows-side settings. WSL dotfiles live in `ultrinn/dotfiles` (yadm) and Claude Code settings in
`gerrtrav/claude-config`.

| Path | What | Restored to |
|---|---|---|
| `git/.gitconfig` | Git identity, SSMS diff/merge tool | `%USERPROFILE%\.gitconfig` |
| `windows-terminal/settings.json` | Windows Terminal profiles, theme, keybindings | `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json` |

Not in this repo:
- **VS Code**: use its built-in Settings Sync (Accounts menu > Backup and Sync Settings), which also restores extensions.
- **SSH keys** (`%USERPROFILE%\.ssh`), `.aws`, `.azure`, `.config\mcp-mssql`: restore from the password manager.

## Restore on a new machine

1. Turn on Developer Mode (Settings > System > For developers) so the script can create links.
2. Clone and run:

```powershell
git clone git@github.com:ultrinn/dotfiles-windows.git $env:USERPROFILE\source\repos\dotfiles-windows
powershell -ExecutionPolicy Bypass -File $env:USERPROFILE\source\repos\dotfiles-windows\install.ps1
```

## Day to day

If the install made links, changes (including ones made in the Windows Terminal settings UI) show up in
`git status` here; commit and push them.

If it made copies (no Developer Mode or admin rights, as on managed PCs), pull your changes back first:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Pull
```
