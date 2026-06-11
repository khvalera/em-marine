unit unit_info;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  ExtCtrls, fileinfo,
  {$IFDEF WINDOWS}
  winpeimagereader,
  {$ENDIF}
  {$IFDEF UNIX}
    {$IFDEF DARWIN}
    machoreader,
    {$ELSE}
    elfreader,
    {$ENDIF}
  {$ENDIF}
  LCLIntf, DefaultTranslator;

type

  { TForm_info }

  TForm_info = class(TForm)
    BitBtn_Seve: TBitBtn;
    Image1: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label_Site_Device: TLabel;
    Label_Github: TLabel;
    Label_Version: TLabel;
    Label_Developer: TLabel;
    Label_Email: TLabel;
    Panel_Buttons: TPanel;
    procedure FormCreate(Sender: TObject);
    procedure Label2Click(Sender: TObject);
    procedure Label_GithubClick(Sender: TObject);
    procedure Label_EmailClick(Sender: TObject);
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
   Caption := 'Про програму';
   Label_Version.Caption:= 'Версія: ' + ReadVersion();

   // Переклад видимих написів без зміни логіки форми.
   BitBtn_Seve.Caption := 'Закрити';
   Label_Site_Device.Caption := StringReplace(Label_Site_Device.Caption, 'Site with device:', 'Сайт пристрою:', [rfIgnoreCase]);
   Label_Site_Device.Caption := StringReplace(Label_Site_Device.Caption, 'site with device:', 'Сайт пристрою:', [rfIgnoreCase]);
   Label_Developer.Caption := StringReplace(Label_Developer.Caption, 'Developer:', 'Розробник:', [rfIgnoreCase]);
   Label_Email.Caption := StringReplace(Label_Email.Caption, 'Email:', 'Ел. пошта:', [rfIgnoreCase]);

   // У деяких версіях форми цей напис розбитий на два Label у .lfm.
   // Тому встановлюємо український текст примусово, незалежно від старого Caption.
   Label1.Caption := 'Програма для зчитувача EM-Marine з Ethernet';
   Label3.Caption := 'інтерфейсом (TCP/IP).';
end;

//===========================================
procedure TForm_info.Label2Click(Sender: TObject);
begin
  OpenURL('http://vkmodule.com.ua/Ethernet/Ethernet5.html');
end;

//===========================================
procedure TForm_info.Label_GithubClick(Sender: TObject);
begin
   OpenURL('https://github.com/khvalera/em-marine');
end;

//===========================================
procedure TForm_info.Label_EmailClick(Sender: TObject);
begin
  OpenURL('mailto:khvalera@ukr.net?subject=em_marine&body=Hello!');
end;

end.
