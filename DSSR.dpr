program DSSR;

uses
  Vcl.Forms,
  Unit1 in 'Unit1.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Dark Souls Saver Recover 1.0';
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
