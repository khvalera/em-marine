program em_marine;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, Dialogs, lazmouseandkeyinput, unit_main, unit_info, single_instance
  { you can add units after this };

{$R *.res}

var
  SingleInstanceError: string;

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;

  if not AppInstanceAcquireLock(SingleInstanceError) then
  begin
    MessageDlg('Програма em-marine вже запущена.', mtInformation, [mbOK], 0);
    Halt(0);
  end;

  try
    Application.CreateForm(TForm_Options, Form_Options);
    Application.Run;
  finally
    AppInstanceReleaseLock;
  end;
end.
