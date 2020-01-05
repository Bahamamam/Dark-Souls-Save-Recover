unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.Variants, System.Classes, Vcl.Graphics, SHFolder,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, ShellApi, Vcl.ExtCtrls, Vcl.Menus, mmsystem, SysUtils,
  Registry, ShlObj, Vcl.StdCtrls, TlHelp32;

type
  TForm1 = class(TForm)
    TrayIcon1: TTrayIcon;
    PopupMenu1: TPopupMenu;
    Close1: TMenuItem;
    Game: TMenuItem;
    DS1: TMenuItem;
    DS1R: TMenuItem;
    DS2: TMenuItem;
    DS3: TMenuItem;
    Sound: TMenuItem;
    AudioOn: TMenuItem;
    AudioOff: TMenuItem;
    procedure Close1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure DS1Click(Sender: TObject);
    procedure DS1RClick(Sender: TObject);
    procedure DS2Click(Sender: TObject);
    procedure DS3Click(Sender: TObject);
    function  ReturnGame:string;
    function  InitializateHotkeys:string;
    procedure AudioOnClick(Sender: TObject);
    procedure AudioOffClick(Sender: TObject);
    function  ReturnSound:string;
 protected
    procedure SaveLoad(var Msg: TMessage); message WM_HOTKEY;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1          : TForm1;
  F5_ID, F9_ID,
  Enter          : ATOM;
  GameID,
  Audio          : string;
  Reg            : TRegistry;
  SavePath,
  LoadPath       : string;
  GetHandle      : integer;

implementation

// Connected save&load sounds
{$R RES.RES}
{$R *.dfm}


// Function for copy save file
function FullDirectoryCopy(SourceDir, TargetDir: string; StopIfNotAllCopied,
  OverWriteFiles: Boolean): Boolean;
var
  SR: TSearchRec;
  I: Integer;
begin
  Result := False;
  SourceDir := IncludeTrailingBackslash(SourceDir);
  TargetDir := IncludeTrailingBackslash(TargetDir);
  if not DirectoryExists(SourceDir) then
    Exit;
  if not ForceDirectories(TargetDir) then
    Exit;

  I := FindFirst(SourceDir + '*', faAnyFile, SR);
  try
    while I = 0 do
    begin
      if (SR.Name <> '') and (SR.Name <> '.') and (SR.Name <> '..') then
      begin
        if SR.Attr = faDirectory then
          Result := FullDirectoryCopy(SourceDir + SR.Name, TargetDir + SR.NAME,
            StopIfNotAllCopied, OverWriteFiles)
        else if not (not OverWriteFiles and FileExists(TargetDir + SR.Name))
          then
          Result := CopyFile(Pchar(SourceDir + SR.Name), Pchar(TargetDir +
            SR.Name), False)
        else
          Result := True;
        if not Result and StopIfNotAllCopied then
          exit;
      end;
      I := FindNext(SR);
    end;
  finally
    SysUtils.FindClose(SR);
  end;
end;

// Function to check runned darksoulsIII.exe
function GetExeNameByProcID(ProcID: DWord): string;
var
ContinueLoop: BOOL;
FSnapshotHandle: THandle;
FProcessEntry32: TProcessEntry32;
begin
FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
FProcessEntry32.dwSize := Sizeof(FProcessEntry32);
ContinueLoop := Process32First(FSnapshotHandle, FProcessEntry32);
Result := '';
while (Integer(ContinueLoop) <> 0) and (Result = '') do
begin
if FProcessEntry32.th32ProcessID = ProcID then
Result:= FProcessEntry32.szExeFile;
ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
end;
end;

// Main function to find %AppData% (default dir for DS2 and DS3 files)
function GetSpecialFolderPath(CSIDL : Integer) : String;
var
  Path : PChar;
begin
  Result := '';
  GetMem(Path,MAX_PATH);
  Try
    If Not SHGetSpecialFolderPath(0,Path,CSIDL,False) Then
      Raise 
      Exception.Create('Error');
      Result := Trim(StrPas(Path));
  Finally
    FreeMem(Path,MAX_PATH);
  End;
end;

// Function to find MyDocuments folder (default dir for DS1 and DSR files))
function GetMyDocsPath:string;
var
  Buf:array[0..255] of Char;
begin
  Result:='';
  if SHGetFolderPath(0, CSIDL_PERSONAL, 0, 0, Buf) = 0 then Result:=Buf;
end;

// Second function to find %AppData%
function GetUserAppDataFolderPath : String;
begin
  Result := GetSpecialFolderPath(CSIDL_APPDATA);
end;

// Function to make full path to save any DS games
function PathFind:string;
begin
  if GameID = '0' then
   begin
    SavePath := GetUserAppDataFolderPath+'\DSSR\DSSR_DS1\';
    LoadPath := GetMyDocsPath+'\NBGI\DarkSouls\';
   end;
  if GameID = '1' then
   begin
    SavePath := GetUserAppDataFolderPath+'\DSSR\DSSR_DS1R\';
    LoadPath := GetMyDocsPath+'\NBGI\DARK SOULS REMASTERED\';
   end;
  if GameID = '2' then
   begin
    SavePath := GetUserAppDataFolderPath+'\DSSR\DSSR_DS2\';
    LoadPath := GetUserAppDataFolderPath+'\DarkSoulsII\';
   end;
  if GameID = '3' then
   begin
    SavePath := GetUserAppDataFolderPath+'\DSSR\DSSR_DS3\';
    LoadPath := GetUserAppDataFolderPath+'\DarkSoulsIII\';
   end;
end;

// Save settings choised game to registry
function SaveChoise:string;
begin
Reg         := TRegistry.Create;
Reg.RootKey := HKEY_CURRENT_USER;
If Reg.OpenKey('\SoftWare\Dark Souls Save Recover\', True) Then
 begin
  Reg.WriteString('GameID',GameID);
  Reg.CloseKey;
 end;
Reg.Free;
PathFind;
end;

// Read last used DS game from saved settings
function ReadGame:string;
begin
Result:='';
Reg         := TRegistry.Create;
Reg.RootKey := HKEY_CURRENT_USER;
If Reg.OpenKey('\SoftWare\Dark Souls Save Recover\', True) Then
 begin
  Result := Reg.ReadString('GameID');
 end;
Reg.Free;
end;

// Save sound settings to registry
function SoundChoise:string;
begin
Reg         := TRegistry.Create;
Reg.RootKey := HKEY_CURRENT_USER;
If Reg.OpenKey('\SoftWare\Dark Souls Save Recover\', True) Then
 begin
  Reg.WriteString('Sound',Audio);
  Reg.CloseKey;
 end;
Reg.Free;
end;

// Reas last used sound settings
function ReadSound:string;
begin
Result:='';
Reg         := TRegistry.Create;
Reg.RootKey := HKEY_CURRENT_USER;
If Reg.OpenKey('\SoftWare\Dark Souls Save Recover\', True) Then
 begin
  Result := Reg.ReadString('Sound');
 end;
Reg.Free;
end;

// Hotkey Function
procedure TForm1.SaveLoad(var Msg: TMessage);
var ngame,
    process_name  : string;
    ds_handle     : HWND;
    id            : ^dword;

begin
  // Save game if pressed F5
  if Msg.LParamHi = VK_F5 then
  begin
   FullDirectoryCopy(LoadPath, SavePath, false, true);
   if Audio = '1' then sndPlaySound('SAVE', SND_MEMORY or SND_RESOURCE or SND_ASYNC);
   case StrToInt(GameID) of
    0 : ngame := 'DS1';
    1 : ngame := 'DSR';
    2 : ngame := 'DS2';
    3 : ngame := 'DS3';
   end;
  end;

  // Load game if pressed F9
  if Msg.LParamHi = VK_F8 then
  begin
   FullDirectoryCopy(SavePath, LoadPath, false, true);
   if Audio = '1' then sndPlaySound('LOAD', SND_MEMORY or SND_RESOURCE or SND_ASYNC);

   case StrToInt(GameID) of
    0 : ngame := 'DS1';
    1 : ngame := 'DSR';
    2 : ngame := 'DS2';
    3 : ngame := 'DS3';
   end;
  end;

  // Make fullscreen game if pressed Alt+Enter
  if Msg.LParamHi = &VK_Return then
  begin
    ds_handle := FindWindow(nil,'DARK SOULS III');
    GetMem(id, SizeOf(DWORD));
    GetWindowThreadProcessId(ds_handle, id);
    process_name:=GetExeNameByProcID(id^);
    if (ds_handle <> 0) and (process_name = 'DarkSoulsIII.exe') then
    SetWindowLong(ds_handle, GWL_STYLE, GetWindowLong(ds_handle, GWL_STYLE) and not(WS_CAPTION or WS_THICKFRAME));
  end;
end;

// Function Sounds off
procedure TForm1.AudioOffClick(Sender: TObject);
begin
  Audio            := '0';
  AudioOn.Checked  := false;
  AudioOff.Checked := true;
  SoundChoise;
end;

// Function Sounds on
procedure TForm1.AudioOnClick(Sender: TObject);
begin
  Audio            := '1';
  AudioOn.Checked  := true;
  AudioOff.Checked := false;
  SoundChoise;
end;

// Function main form programm destroy
procedure TForm1.Close1Click(Sender: TObject);
begin
  Form1.Close;
  Form1.Destroy;
end;


// Function choise game (DS1)
procedure TForm1.DS1Click(Sender: TObject);
begin
  GameID       := '0';
  DS1.Checked  := true;
  DS1R.Checked := false;
  DS2.Checked  := false;
  DS3.Checked  := false;
  SaveChoise;
end;

// Function choise game (DSR)
procedure TForm1.DS1RClick(Sender: TObject);
begin
  GameID       := '1';
  DS1.Checked  := false;
  DS1R.Checked := true;
  DS2.Checked  := false;
  DS3.Checked  := false;
  SaveChoise;
end;

// Function choise game (DS2)
procedure TForm1.DS2Click(Sender: TObject);
begin
  GameID       := '2';
  DS1.Checked  := false;
  DS1R.Checked := false;
  DS2.Checked  := true;
  DS3.Checked  := false;
  SaveChoise;
end;

// Function choise game (DS3)
procedure TForm1.DS3Click(Sender: TObject);
begin
  GameID       := '3';
  DS1.Checked  := false;
  DS1R.Checked := false;
  DS2.Checked  := false;
  DS3.Checked  := true;
  SaveChoise;
end;

// Function check choised game in running programm
function TForm1.ReturnGame:string;
begin
  if ReadGame <> '' then
  case StrToInt(ReadGame) of
  0 : begin
     DS1.Checked := true;  DS1R.Checked := false;
     DS2.Checked := false; DS3.Checked  := false;
     end;
  1 : begin
     DS1.Checked := false; DS1R.Checked := true;
     DS2.Checked := false; DS3.Checked  := false;
     end;
  2 : begin
     DS1.Checked := false; DS1R.Checked := false;
     DS2.Checked := true; DS3.Checked  := false;
     end;
  3 : begin
     DS1.Checked := false; DS1R.Checked := false;
     DS2.Checked := false; DS3.Checked  := true;
     end;
  end;
  PathFind;
end;

// Function check choised sound settings in running programm
function TForm1.ReturnSound:string;
begin
  if ReadSound <> '' then
  case StrToInt(ReadSound) of
  0 : begin
      AudioOn.Checked  := false;
      AudioOff.Checked := true;
      Audio := '0';
      end;
  1 : begin
      AudioOn.Checked  := true;
      AudioOff.Checked := false;
      Audio := '1';
      end;
  end
  else
    begin
      Audio            := '1';
      AudioOn.Checked  := true;
    end;
end;

// Function create hotkey hook
function TForm1.InitializateHotkeys:string;
begin
  F9_ID := GlobalAddAtom('HotkeyF8');
  RegisterHotKey(Handle, 1, 0, VK_F8);
  F5_ID := GlobalAddAtom('HotkeyF5');
  RegisterHotKey(Handle, 1, 0, VK_F5);
  Enter := GlobalAddAtom('HotkeyEnter');
  RegisterHotKey(Handle, 1, MOD_ALT, VK_Return);
  application.ShowMainForm:=false;
end;

// Function initialization programm
procedure TForm1.FormCreate(Sender: TObject);
begin
  if ReadGame <> '' then GameID := ReadGame;
  InitializateHotkeys;
  ReturnGame;
  ReturnSound;
end;

// Function disable hotkeyhooks
procedure TForm1.FormDestroy(Sender: TObject);
begin
  UnRegisterHotkey( Handle, 1 );
end;





end.
