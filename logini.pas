unit LogINI;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IniFiles,
  //для ShowMessage:
  Dialogs;

procedure Log(Text: String; FileName: String; Error: Byte = 0; ShowMess: Byte = 0);
procedure WriteINI(SectionName: string; ValueName: string; Value: string; FileINI: string);
function ReadINI(SectionName: string; ValueName: string; ValueDefault: string; FileINI: string): string;

var INI: TIniFile;

implementation

//=================================================
procedure WriteINI(SectionName: string; ValueName: string; Value: string; FileINI: string);
begin
  if FileINI = Null then
     Exit;
  INI := TIniFile.Create(FileINI);
  try
    INI.WriteString(SectionName, ValueName, Value);
  finally
    INI.Free;
  end;
end;

//=================================================
function ReadINI(SectionName: string; ValueName: string; ValueDefault: string; FileINI: string): string;
var Value: String;
begin
  if FileINI = Null then
     Exit;
  INI := TIniFile.Create(FileINI);
  try
    Value := INI.ReadString(SectionName, ValueName, '');
    if Value = '' then
       begin
         INI.WriteString(SectionName, ValueName, ValueDefault);
         Result:= ValueDefault;
       end;
  finally
    INI.Free;
    Result := Value;
  end;
end;

//=================================================
procedure Log(Text: String; FileName: String; Error: Byte = 0; ShowMess: Byte = 0);
var
  F : TextFile;
  dt: string;
begin
  AssignFile(F, FileName);
  if FileExists(FileName) then
     Append(F)
  else
     Rewrite(F);
  ShortDateFormat := 'yyyy-mm-dd';
  dt:= DateToStr(Date);
  dt:= dt + ' ' + TimeToStr(Time);
  WriteLn(F, dt + ': ' + Text);
  CloseFile(F);
  if ShowMess <> 0 then
     if Error = 1 then
        MessageDlg(Text, mtError, [mbOK], 0)
     else
        MessageDlg(Text, mtInformation, [mbOK], 0);
end;

end.

