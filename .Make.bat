@echo off
set REGION=2
set OUTPUT=SCD.iso
set ASM68K=_Bin\asm68k.exe /p /o ae- /o l. /e REGION=%REGION%

if not exist _Built mkdir _Built
if not exist _Built\Files mkdir _Built\Files
if not exist _Built\System mkdir _Built\System
if %REGION%==0 (copy _Original\Japan\*.* _Built\Files > nul)
if %REGION%==1 (copy _Original\USA\*.* _Built\Files > nul)
if %REGION%==2 (copy _Original\Europe\*.* _Built\Files > nul)
if %REGION%==0 (copy BADAPPLE60.BIN _Built\Files\BADAPPL.BIN > nul)
if %REGION%==1 (copy BADAPPLE60.BIN _Built\Files\BADAPPL.BIN > nul)
if %REGION%==2 (copy BADAPPLE50.BIN _Built\Files\BADAPPL.BIN > nul)
del _Built\Files\.gitkeep > nul

%ASM68K% "CD Initial Program\IP.asm", "_Built\System\IP.BIN", , "CD Initial Program\IP.lst"
%ASM68K% "CD Initial Program\IPX.asm", "_Built\Files\IPX___.BIN", , "CD Initial Program\IPX.lst"
%ASM68K% "CD System Program\SP.asm", "_Built\System\SP.BIN", , "CD System Program\SP.lst"
%ASM68K% "CD System Program\SPX.asm", "_Built\Files\SPX___.BIN", , "CD System Program\SPX.lst"
%ASM68K% /e DEMO=0 "Level\Palmtree Panic\Act 1 Present.asm", "_Built\Files\R11A__.MMD", , "Level\Palmtree Panic\Act 1 Present.lst"

echo.
echo Compiling filesystem...
_Bin\mkisofs.exe -quiet -abstract ABS.TXT -biblio BIB.TXT -copyright CPY.TXT -A "SEGA ENTERPRISES" -V "SONIC_CD___" -publisher "SEGA ENTERPRISES" -p "SEGA ENTERPRISES" -sysid "MEGA_CD" -iso-level 1 -o _Built\System\Files.BIN _Built\Files

%ASM68K% main.asm, _Built\%OUTPUT%
del _Built\System\Files.BIN > nul

pause