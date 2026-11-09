; ============================================================================
; Music Downloader — Instalador Windows (Inno Setup 6)
; ----------------------------------------------------------------------------
; COMPILAÇÃO (na máquina Windows):
;   - GUI: abra este arquivo no Inno Setup 6 e pressione Compile, OU
;   - CLI: "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer.iss
;
; PRÉ-REQUISITO: pasta dist/ na raiz do repositório, contendo:
;   dist/
;   ├── downloader.exe (+ DLLs e assets do flutter build windows)
;   └── bin/
;       ├── yt-dlp.exe
;       ├── spotdl.exe
;       ├── ffmpeg.exe / ffprobe.exe
;       └── python/            (Python 3.12 embutido com spotdl + yt-dlp)
;
; Como obter dist/:
;   1) CI: GitHub Actions > "Build Windows Release" > artefato
;      music-downloader-windows.zip (ou release v*) — descompacte o
;      conteúdo para dist/ na raiz do repositório; OU
;   2) Local: flutter build windows --release e copie
;      build\windows\x64\runner\Release\* para dist\, além da pasta
;      bin\ (ferramentas) — mesma estrutura montada pelo CI.
;
; OPCIONAL (recomendado): coloque vc_redist.x64.exe ao lado deste script
; para o instalador garantir o runtime do Visual C++ em máquinas limpas.
; Download: https://aka.ms/vs/17/release/vc_redist.x64.exe
; (se ausente, o script compila normalmente — apenas sem esse passo)
; ============================================================================

#define MyAppName "Music Downloader"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Andre Camillo"
#define MyAppExeName "downloader.exe"
; AppId fixo e estável — NÃO alterar entre versões (preserva instalação anterior)
#define MyAppId "{{A7D4E91B-3F62-4C8E-9B15-6D2F8E0C4A31}"

[Setup]
AppId={#MyAppId}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
VersionInfoVersion={#MyAppVersion}.0
VersionInfoProductTextVersion={#MyAppVersion}
UninstallDisplayName={#MyAppName}
UninstallDisplayIcon={app}\{#MyAppExeName}

; Ícone do instalador — mesmo ícone do app
SetupIconFile=windows\runner\resources\app_icon.ico

; Instalação por usuário, sem admin — OBRIGATÓRIO: o app grava log.txt,
; downloads/ e temp_downloads/ ao lado do exe; Program Files quebraria
; para usuário comum (sem permissão de escrita).
PrivilegesRequired=lowest
DefaultDirName={localappdata}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes

ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
MinVersion=10.0

OutputDir=Output
OutputBaseFilename=MusicDownloader-Setup-{#MyAppVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
SetupLogging=yes

[Languages]
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "launchafter"; Description: "Executar {#MyAppName} ao finalizar a instalação"; Flags: checkedonce

[Files]
; App compilado + bin/ (yt-dlp, spotdl, ffmpeg, python embutido)
Source: "dist\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

; Runtime do Visual C++ — apenas se vc_redist.x64.exe existir ao lado do script
#ifexist "vc_redist.x64.exe"
Source: "vc_redist.x64.exe"; DestDir: "{tmp}"; Flags: ignoreversion
#endif

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
; VC++ Redistributable (silencioso) — só se não estiver instalado
#ifexist "vc_redist.x64.exe"
Filename: "{tmp}\vc_redist.x64.exe"; \
  Parameters: "/install /quiet /norestart"; \
  StatusMsg: "Instalando runtime do Visual C++..."; \
  Flags: runhidden waituntilterminated; \
  Check: NeedVCRedist
#endif

; Atalho pós-instalação
Filename: "{app}\{#MyAppExeName}"; \
  Description: "{cm:LaunchProgram,{#MyAppName}}"; \
  Flags: postinstall nowait skipifsilent; \
  Tasks: launchafter

[UninstallDelete]
; Arquivos gerados pelo app — NÃO mexer em downloads\ (dados do usuário)
Type: files; Name: "{app}\log.txt"
Type: filesandordirs; Name: "{app}\temp_downloads"

[Code]
{ Verifica se o runtime VC++ 14 (VS 2015-2022) x64 já está presente }
function NeedVCRedist: Boolean;
var
  Installed: Cardinal;
begin
  Result := not (
    RegQueryDWordValue(
      HKLM,
      'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64',
      'Installed',
      Installed
    ) and (Installed = 1)
  );
end;
