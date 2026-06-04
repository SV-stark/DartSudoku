[Setup]
AppName=DartSudoku
AppVersion=1.0.0
DefaultDirName={autopf}\DartSudoku
DefaultGroupName=DartSudoku
UninstallDisplayIcon={app}\dart_sudoku.exe
Compression=lzma2
SolidCompression=yes
OutputDir=build\windows\installer
OutputBaseFilename=DartSudokuSetup

[Files]
Source: "build\windows\x64\runner\Release\dart_sudoku.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\flutter_windows.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\DartSudoku"; Filename: "{app}\dart_sudoku.exe"
Name: "{commondesktop}\DartSudoku"; Filename: "{app}\dart_sudoku.exe"
