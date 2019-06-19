unit unit_info;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  ExtCtrls, fileinfo, winpeimagereader, elfreader, machoreader ;

type

  { TForm_info }

  TForm_info = class(TForm)
    BitBtn_Seve: TBitBtn;
    Image1: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Label_Version: TLabel;
    Label_Developer: TLabel;
    Label_Email: TLabel;
    Panel_Buttons: TPanel;
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

var
  Form_info: TForm_info;
  FileVerInfo: TFileVersionInfo;

implementation

{$R *.lfm}

{ TForm_info }

//===========================================
function ReadVersion(): string;
var
  MajorNum: string;
  MinorNum: string;
  RevisionNum: string;
  BuildNum: string;
  Info: TVersionInfo;
begin

  Info := TVersionInfo.Create;
  Info.Load(HINSTANCE);
  MajorNum := IntToStr(Info.FixedInfo.FileVersion[0]);
  MinorNum := IntToStr(Info.FixedInfo.FileVersion[1]);
  RevisionNum := IntToStr(Info.FixedInfo.FileVersion[2]);
  BuildNum := IntToStr(Info.FixedInfo.FileVersion[3]);
  Info.Free;

  Result := MajorNum + '.' + MinorNum + '.' + RevisionNum + '.' + BuildNum;
end;

//===========================================
procedure TForm_info.FormCreate(Sender: TObject);
begin
   Label_Version.Caption:= ReadVersion();
end;

end.

