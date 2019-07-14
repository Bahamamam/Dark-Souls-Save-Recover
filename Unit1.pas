unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.Variants, System.Classes, Vcl.Graphics, SHFolder,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, ShellApi, Vcl.ExtCtrls, Vcl.Menus, mmsystem, SysUtils;

type
  TForm1 = class(TForm)
    TrayIcon1: TTrayIcon;
    PopupMenu1: TPopupMenu;
    Close1: TMenuItem;
    Timer1: TTimer;
    procedure Close1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
 protected
   procedure HotKey(var Msg: TMessage); message WM_HOTKEY;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  F5_ID, F9_ID: ATOM;

implementation

{$R RES.RES}
{$R *.dfm}


// ‘”Õ ÷»ﬂ  Œœ»–Œ¬¿Õ»ﬂ ƒ»–≈ “Œ–»» —Œ’–¿Õ≈Õ»…
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


// ‘”Õ ÷»ﬂ œŒ»— ¿ ÃŒ»’ ƒŒ ”Ã≈Õ“Œ¬
function GetMyDocsPath:string;
var
  Buf:array[0..255] of Char;
begin
  Result:='';
  if SHGetFolderPath(0, CSIDL_PERSONAL, 0, 0, Buf) = 0 then Result:=Buf;
end;


// œ–Œ÷≈ƒ”–¿ »—œŒÀ‹«Œ¬¿Õ»ﬂ ’Œ“ ≈≈¬
procedure TForm1.HotKey(var Msg: TMessage);
begin
  if Msg.LParamHi = VK_F9 then
  begin
   FullDirectoryCopy(GetMyDocsPath+'\NBGI\DSSR_D1R\', GetMyDocsPath+'\NBGI\DARK SOULS REMASTERED\', false, true);
   sndPlaySound('LOAD', SND_MEMORY or SND_RESOURCE or SND_ASYNC);
  end;

  if Msg.LParamHi = VK_F5 then
  begin
   FullDirectoryCopy(GetMyDocsPath+'\NBGI\DARK SOULS REMASTERED\', GetMyDocsPath+'\NBGI\DSSR_D1R\', false, true);
   sndPlaySound('SAVE', SND_MEMORY or SND_RESOURCE or SND_ASYNC);
  end;

end;

// «¿ –€“»≈ œ–Œ√–¿ÃÃ€
procedure TForm1.Close1Click(Sender: TObject);
begin
  Form1.Close;
  Form1.Destroy;
end;

// –≈√»—“–¿÷»ﬂ ’Œ“ ≈≈¬
procedure TForm1.FormCreate(Sender: TObject);
begin
 F9_ID := GlobalAddAtom('HotkeyF9');
 RegisterHotKey(Handle, 1, 0, VK_F9);
 F5_ID := GlobalAddAtom('HotkeyF5');
 RegisterHotKey(Handle, 1, 0, VK_F5);
 application.ShowMainForm:=false;
end;

// ƒ≈–≈√»—“–¿÷»ﬂ ’Œ“ ≈≈¬
procedure TForm1.FormDestroy(Sender: TObject);
begin
UnRegisterHotkey( Handle, 1 );
end;




end.
