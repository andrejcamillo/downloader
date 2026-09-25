@echo off
echo === INSTALADOR DO PYTHON EMBUTIDO ===
cd /d "%~dp0python_embed"

set "EMBED_PY=%cd%"

echo.
echo [1/3] Baixando get-pip.py...
if not exist get-pip.py (
  curl -O https://bootstrap.pypa.io/get-pip.py
)

echo.
echo [2/3] Instalando pip...
python.exe get-pip.py

:: Verifica se pip foi instalado corretamente
echo.
echo [Verificando se o pip foi instalado corretamente...]
python.exe -m pip --version || (
  echo.
  echo [⚠️] Pip ainda não está funcionando. Forçando instalação com ensurepip...
  python.exe -m ensurepip --upgrade
  python.exe -m pip install --upgrade pip
)

echo.
echo [3/3] Instalando yt-dlp e spotdl...
python.exe -m pip install yt-dlp spotdl

echo.
echo === Concluído! Pressione qualquer tecla para sair. ===
pause >nul
