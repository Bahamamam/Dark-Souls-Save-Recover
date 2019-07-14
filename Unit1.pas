unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.Variants, System.Classes, Vcl.Graphics, SHFolder,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, ShellApi, Vcl.ExtCtrls, Vcl.Menus, mmsystem, SysUtils,
  Registry, ShlObj;

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
   procedure HotKey(var Msg: TMessage); message WM_HOTKEY;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1        : TForm1;
  F5_ID, F9_ID : ATOM;
  GameID,
  Audio        : string;
  Reg          : TRegistry;
  SavePath,
  LoadPath     : string;

implementation

{$R RES.RES}
{$R *.dfm}

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

function GetMyDocsPath:string;
var
  Buf:array[0..255] of Char;
begin
  Result:='';
  if SHGetFolderPath(0, CSIDL_PERSONAL, 0, 0, Buf) = 0 then Result:=Buf;
end;

function GetUserAppDataFolderPath : String;
begin
  Result := GetSpecialFolderPath(CSIDL_APPDATA);
end;

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

procedure TForm1.HotKey(var Msg: TMessage);
begin
  if Msg.LParamHi = VK_F5 then
  begin
   FullDirectoryCopy(LoadPath, SavePath, false, true);
   if Audio = '1' then sndPlaySound('SAVE', SND_MEMORY or SND_RESOURCE or SND_ASYNC);
  end;
  if Msg.LParamHi = VK_F9 then
  begin
   FullDirectoryCopy(SavePath, LoadPath, false, true);
   if Audio = '1' then sndPlaySound('LOAD', SND_MEMORY or SND_RESOURCE or SND_ASYNC);
  end;
end;

procedure TForm1.AudioOffClick(Sender: TObject);
begin
  Audio            := '0';
  AudioOn.Checked  := false;
  AudioOff.Checked := true;
  SoundChoise;
end;

procedure TForm1.AudioOnClick(Sender: TObject);
begin
  Audio            := '1';
  AudioOn.Checked  := true;
  AudioOff.Checked := false;
  SoundChoise;   
end;

procedure TForm1.Close1Click(Sender: TObject);
begin
  Form1.Close;
  Form1.Destroy;
end;

procedure TForm1.DS1Click(Sender: TObject);
begin
  GameID       := '0';
  DS1.Checked  := true;
  DS1R.Checked := false;
  DS2.Checked  := false;
  DS3.Checked  := false;
  SaveChoise;
end;

procedure TForm1.DS1RClick(Sender: TObject);
begin
  GameID       := '1';
  DS1.Checked  := false;
  DS1R.Checked := true;
  DS2.Checked  := false;
  DS3.Checked  := false;
  SaveChoise;
end;

procedure TForm1.DS2Click(Sender: TObject);
begin
  GameID       := '2';
  DS1.Checked  := false;
  DS1R.Checked := false;
  DS2.Checked  := true;
  DS3.Checked  := false;
  SaveChoise;
end;

procedure TForm1.DS3Click(Sender: TObject);
begin
  GameID       := '3';
  DS1.Checked  := false;
  DS1R.Checked := false;
  DS2.Checked  := false;
  DS3.Checked  := true;
  SaveChoise;
end;

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

function TForm1.InitializateHotkeys:string;
begin
  F9_ID := GlobalAddAtom('HotkeyF9');
  RegisterHotKey(Handle, 1, 0, VK_F9);
  F5_ID := GlobalAddAtom('HotkeyF5');
  RegisterHotKey(Handle, 1, 0, VK_F5);
  application.ShowMainForm:=false;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  if ReadGame <> '' then GameID := ReadGame;
  InitializateHotkeys;
  ReturnGame;
  ReturnSound;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  UnRegisterHotkey( Handle, 1 );
end;

end.
