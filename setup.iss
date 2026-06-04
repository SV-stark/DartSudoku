[Setup]
AppName=Sudoku Nexus
AppVersion=1.0.0
DefaultDirName={autopf}\SudokuNexus
DefaultGroupName=Sudoku Nexus
UninstallDisplayIcon={app}\dart_sudoku.exe
Compression=lzma2
SolidCompression=yes
OutputDir=build\windows\installer
OutputBaseFilename=SudokuNexusSetup

[Files]
Source: "build\windows\x64\runner\Release\dart_sudoku.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\flutter_windows.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Sudoku Nexus"; Filename: "{app}\dart_sudoku.exe"
Name: "{commondesktop}\Sudoku Nexus"; Filename: "{app}\dart_sudoku.exe"
