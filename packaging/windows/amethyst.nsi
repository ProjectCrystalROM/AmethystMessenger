Unicode true
RequestExecutionLevel user
SetCompressor /SOLID lzma
Name "Amethyst Messenger 2.11.0"
OutFile "${OUTPUT}"
InstallDir "$LOCALAPPDATA\Programs\Amethyst Messenger"
InstallDirRegKey HKCU "Software\Amethyst Messenger" "InstallDir"

VIProductVersion "2.11.0.0"
VIAddVersionKey /LANG=1033 "ProductName" "Amethyst Messenger"
VIAddVersionKey /LANG=1033 "CompanyName" "Project Crystal"
VIAddVersionKey /LANG=1033 "FileDescription" "Amethyst Messenger Setup"
VIAddVersionKey /LANG=1033 "FileVersion" "2.11.0"
VIAddVersionKey /LANG=1033 "ProductVersion" "2.11.0"
VIAddVersionKey /LANG=1033 "LegalCopyright" "Derived from Pidgin 2.11.0"

!include "MUI2.nsh"
!define MUI_ICON "${ICON}"
!define MUI_UNICON "${ICON}"
!define MUI_FINISHPAGE_RUN "$INSTDIR\amethyst.exe"
!define MUI_FINISHPAGE_RUN_TEXT "Launch Amethyst Messenger"
!define MUI_FINISHPAGE_RUN_NOTCHECKED
!insertmacro MUI_PAGE_LICENSE "${PAYLOAD}/COPYING"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"

Section "Amethyst Messenger" MainSection
    SectionIn RO
    IfFileExists "$INSTDIR\.amethyst-messenger" update
    IfFileExists "$INSTDIR\*.*" 0 install
    MessageBox MB_OK|MB_ICONSTOP "Choose an empty folder, or select the existing Amethyst Messenger folder to update." /SD IDOK
    Abort
update:
    IfFileExists "$INSTDIR\amethyst.exe" 0 install
    IfFileExists "$INSTDIR\plugins\libmsn.dll" 0 install
    IfFileExists "$INSTDIR\pidgin.exe" 0 install
    MessageBox MB_OK|MB_ICONSTOP "This folder contains a different application. Choose an Amethyst Messenger folder." /SD IDOK
    Abort
install:
    SetOutPath "$INSTDIR"
    File /r "${PAYLOAD}/*"
    WriteUninstaller "$INSTDIR\Uninstall.exe"

    CreateDirectory "$SMPROGRAMS\Amethyst Messenger"
    CreateShortCut "$SMPROGRAMS\Amethyst Messenger\Amethyst Messenger.lnk" "$INSTDIR\amethyst.exe"
    CreateShortCut "$SMPROGRAMS\Amethyst Messenger\Uninstall.lnk" "$INSTDIR\Uninstall.exe"
    WriteRegStr HKCU "Software\Amethyst Messenger" "InstallDir" "$INSTDIR"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Amethyst Messenger" "DisplayName" "Amethyst Messenger 2.11.0"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Amethyst Messenger" "DisplayVersion" "2.11.0"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Amethyst Messenger" "Publisher" "Project Crystal"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Amethyst Messenger" "InstallLocation" "$INSTDIR"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Amethyst Messenger" "DisplayIcon" "$INSTDIR\amethyst.exe"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Amethyst Messenger" "UninstallString" '"$INSTDIR\Uninstall.exe"'
    WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Amethyst Messenger" "NoModify" 1
    WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Amethyst Messenger" "NoRepair" 1
SectionEnd

Section "Desktop shortcut" DesktopSection
    CreateShortCut "$DESKTOP\Amethyst Messenger.lnk" "$INSTDIR\amethyst.exe"
SectionEnd

Section "Uninstall"
    !include "${REMOVAL}"
    Delete "$INSTDIR\Uninstall.exe"
    RMDir "$INSTDIR"
    Delete "$DESKTOP\Amethyst Messenger.lnk"
    Delete "$SMPROGRAMS\Amethyst Messenger\Amethyst Messenger.lnk"
    Delete "$SMPROGRAMS\Amethyst Messenger\Uninstall.lnk"
    RMDir "$SMPROGRAMS\Amethyst Messenger"
    DeleteRegKey HKCU "Software\Amethyst Messenger"
    DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Amethyst Messenger"
SectionEnd
