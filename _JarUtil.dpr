program _JarUtil;

uses
  Forms,
  SysUtils,
  UnitMain in 'UnitMain.pas' {frmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  if ParamCount >= 1 then
  begin
    if LowerCase(ParamStr(1)) = 'silent' then
    begin
      frmMain.MakeJarSilent;
    end;
  end else
    Application.Run;
end.
