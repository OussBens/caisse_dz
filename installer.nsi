Name "CaisseDZ"
OutFile "CaisseDZInstaller.exe"
InstallDir "$PROGRAMFILES\CaisseDZ"

RequestExecutionLevel admin

Page directory
Page instfiles

Section "Install"

  SetOutPath "$INSTDIR"

  File /r "build\windows\x64\runner\Release\*"

  CreateShortcut "$DESKTOP\CaisseDZ.lnk" "$INSTDIR\caisse_dz.exe"

  WriteUninstaller "$INSTDIR\Uninstall.exe"

SectionEnd

Section "Uninstall"

  Delete "$DESKTOP\CaisseDZ.lnk"
  RMDir /r "$INSTDIR"

SectionEnd