unit unit_main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Spin, Buttons, PopupNotifier, MaskEdit, Menus, blcksock, LogINI, images_list,
  LazFileUtils, MouseAndKeyInput, LCLType, DefaultTranslator, lazutf8, FileUtil,
  strutils;

type

  { TThread_em_marine }

  // заданное нами имя потока.
  TThread_em_marine = class(TThread)
  private
    { Private declarations }
    procedure SendKey;
    procedure socket_em_marine;
  protected
    procedure Execute; override;
  end;


  { TForm_Options }

  TForm_Options = class(TForm)
    BitBtn_Save: TBitBtn;
    CheckBox_PressEnter: TCheckBox;
    Edit_IP: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    MenuItem_Info: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem_Exit: TMenuItem;
    MenuItem_Options: TMenuItem;
    Panel_Buttons: TPanel;
    PopupMenu_Tray: TPopupMenu;
    SpinEdit_Port: TSpinEdit;
    Timer_Update: TTimer;
    TrayIcon: TTrayIcon;
    procedure BitBtn_SaveClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure MenuItem_ExitClick(Sender: TObject);
    procedure MenuItem_InfoClick(Sender: TObject);
    procedure MenuItem_OptionsClick(Sender: TObject);
    procedure Timer_UpdateTimer(Sender: TObject);
  private

  public

  end;

 // общие процедуры
 procedure ReadINIOptions();

var
  Form_Options: TForm_Options;
  Thread_em_marine: TThread_em_marine;
  Socket: TTCPBlockSocket;
  buffer: String = '';
  FileINI, FileLog, PixmapsDirectory: String;
  IP, Port, PressEnter, DeviceStatus: String;
  CloseForm: Boolean;
  Code: String;

implementation

{$R *.lfm}

uses unit_info;

//===============================================
// Создать и запустить em_marine
procedure create_em_marine();
begin
   if IP <> '' then
   begin
      // создание и запуск потока em_marine
      Thread_em_marine:= TThread_em_marine.Create(False);
      Thread_em_marine.Priority:= tpNormal;
   end;
end;

//===============================================
// процедура отправки клавиш
procedure TThread_em_marine.SendKey;
begin
  // код, который будет выполняться в потоке
  if Thread_em_marine.Terminated then
     Exit;
  KeyInput.Press(Code);
  if PressEnter = 'Yes' then
     KeyInput.Press(VK_RETURN);
end;

//===============================================
procedure TThread_em_marine.socket_em_marine();
var
  ReadBuf: array of Byte;
  i, ReadCount: Integer;
  Str: String;
  const ValLuck: array[0..13] of Byte = (30,5,0,0,0,0,1,0,0,0,1,1,0,0);

begin
   Str:= ''; Code:= '';
   Socket := TTCPBlockSocket.Create;
   Socket.SetTimeout(200);
   Socket.Connect(IP, Port);
   // Was there an error?
   if Socket.LastError <> 0 then
   begin
      if DeviceStatus <> 'not_connect' then
         Log('Could not connect to server.', FileLog, 1, 0);
      DeviceStatus:= 'not_connect';
      Exit;
   end else
   if DeviceStatus <> 'connect' then
      DeviceStatus:= 'connect';
   while true do
   begin
      // поступила команда закрыть программу
      if CloseForm = True then
         begin
           Socket.CloseSocket;
           Log('Close socket.', FileLog, 0,0);
           Break;
         end;
      while Socket.CanRead(10) do
      begin
         // поступила команда закрыть программу
         if CloseForm = True then
            begin
              Log('Close socket.', FileLog, 0,0);
              Socket.CloseSocket;
              Exit;
            end;
         //кол-во данных, доступных для чтения
         ReadCount:= Socket.WaitingData;
         if ReadCount > 0 then
         begin
           SetLength(ReadBuf, ReadCount);
           for i:= Low(ReadBuf) to High(ReadBuf) do
           begin
              Str:= Str + IntToHex(Socket.RecvByte(250), 2);
           end;
           // удалим 1F и 4B
           Str := StringReplace(Str, '1F4B', '', [rfReplaceAll, rfIgnoreCase]);
           try
              Code := IntToStr(Hex2Dec('00B65492'));
           except
             on EConvertError do
               begin
                 Log('Error Hex2Dec', FileLog, 1,1);
                 Exit;
               end;
           end;
           Log('Data obtained from the reader "' + Code + '"' , FileLog, 0,0);
           // отправим значение
           Synchronize(@SendKey);
           // пошлем в устройство что карточка прочитана
           for i := 0 to Length(ValLuck) do
              Socket.SendByte(ValLuck[i]);
           Str := '';
           Code:= '';
           Break;
         end;
      end;
   end;
   Socket.CloseSocket;
end;

//===============================================
// остановим поток Thread_em_marine
procedure terminate_thread_em_marine();
begin
  // Советуем потоку завершиться
  Thread_em_marine.Terminate;
  // Если поток заморожен, то он будет таким до ресета
  // Поэтому разрешаем ему двигаться дальше.
  if Thread_em_marine.Suspended then
    Thread_em_marine.Resume;
  // Ждем окончания функции Execute.
  Thread_em_marine.WaitFor;
  // Убиваем объект потока.
  Thread_em_marine.Free;
end;

//===============================================
// процедура выполнения потока
procedure TThread_em_marine.Execute;
begin
  // код, который будет выполняться в потоке
  if Thread_em_marine.Terminated then
     Exit;

  // цикл получения данных для основной формы
  while not Terminated do
     begin
        if Thread_em_marine.Terminated then
           Break;
        // Получение данных
        socket_em_marine();
        Sleep(1000);
     end;
end;

{ TForm_Options }

//===============================================
procedure TForm_Options.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  CanClose := CloseForm;
  if CloseForm = True then
  begin
    // останавливаем таймер
    Timer_Update.Enabled:= False;
    terminate_thread_em_marine();
    // тут оcтанавливаем
    if Socket <> nil then
       Socket.Free;
  end
  else
     MenuItem_OptionsClick(Sender);
end;

//===============================================
procedure ReadINIOptions();
var LogDir, ApplNameExe, ExeName, FileName: String;
    HomeDir: String;
begin
  IP         := ReadINI('Options', 'IP',   '192.168.1.191',     FileINI);
  Port       := ReadINI('Options', 'Port', '9761', FileINI);
  PressEnter := ReadINI('Options', 'PressEnter', 'No', FileINI);

  ExeName         := ExtractFileExt(Application.ExeName);
  FileName        := ExtractFileName(Application.ExeName);
  {$IFDEF UNIX}
     ApplNameExe := FileName;
  {$ENDIF}
  {$IFDEF WINDOWS}
     ApplNameExe := Copy(FileName, 1, Pos(ExeName, FileName) - 1);
  {$ENDIF}
  PixmapsDirectory:= ReadINI('Options', 'PixmapsDirectory', '/usr/share/pixmaps/' + ApplNameExe, FileINI);
  {$IFDEF UNIX}
     HomeDir:= GetEnvironmentVariableUTF8('HOME');
     LogDir := HomeDir + '/.local/share/' + ApplNameExe + '/';
  {$ENDIF}
  {$IFDEF WINDOWS}
     LogDir  := ExtractFilePath(Application.ExeName) + 'Log/';
  {$ENDIF}
  if not DirectoryExists(LogDir) then
     CreateDir(LogDir);

  FileLog := LogDir + FileName + '-' + DateToStr(Date) + '.log';
end;

//===========================================
// запись параметров
procedure TForm_Options.BitBtn_SaveClick(Sender: TObject);
begin
  WriteINI('Options', 'IP',   Edit_IP.Text,       FileINI);
  WriteINI('Options', 'Port', SpinEdit_Port.Text, FileINI);
  if CheckBox_PressEnter.Checked then
     WriteINI('Options', 'PressEnter', 'Yes', FileINI)
  else
     WriteINI('Options', 'PressEnter', 'No', FileINI);

  ReadINIOptions();
  // свернем форму
  Close;
end;

//===========================================
// при создании формы
procedure TForm_Options.FormCreate(Sender: TObject);
var HomeDir: String;
begin

   // сворачиваем программу в трей
   Application.ShowMainForm := False;
   {$IFDEF UNIX}
      HomeDir:= GetEnvironmentVariableUTF8('HOME');
      if not DirectoryExistsUTF8(HomeDir + '/.config/em-marine/') then
         CreateDirUTF8(HomeDir + '/.config/em-marine/');
      FileINI := HomeDir + '/.config/em-marine/options.ini';
      if not FileExistsUTF8(FileINI) then
         CopyFile('/etc/em-marine/options.ini', FileINI);
   {$ENDIF}
   {$IFDEF WINDOWS}
      FileINI := ExtractFilePath(Application.ExeName) + 'options.ini';
   {$ENDIF}
   if not FileExists(FileINI) then
   begin
     Log('Not found file "' + FileINI + '"' , FileLog, 1, 1);
     Application.Free;
   end;
   ReadINIOptions();

   // добавим иконку программы
   if FileExistsUTF8(PixmapsDirectory + 'tray/em-marine.png') then
      Application.Icon.Assign(LoadBitmapFromFile(PixmapsDirectory + 'tray/em-marine.png'));
   { при использовании GetIcon есть утечка памяти
   // загрузим все иконки для Tray
   AddAllFileImageList(ImageList_Tray, ImageStrList_tray, PixmapsDirectory + 'tray', Width , Height);
   // выведем иконку в трей
   ImageList_Tray.GetIcon(ReturnIndexImageList(ImageStrList_tray, 'em-marine.png'), TrayIcon.Icon);
   }
   TrayIcon.Visible:= True;

   // загрузим все иконки для меню
   AddAllFileImageList(ImageList_menu, ImageStrList_menu, PixmapsDirectory + 'menu');

   // PopupMenu_Tray
   PopupMenu_Tray.Images:= ImageList_menu;
   MenuItem_Options.ImageIndex := ReturnIndexImageList(ImageStrList_menu, 'options.png');
   MenuItem_Exit.ImageIndex    := ReturnIndexImageList(ImageStrList_menu, 'exit.png');
   MenuItem_Info.ImageIndex    := ReturnIndexImageList(ImageStrList_menu, 'information.png');

   Edit_IP.Text      := IP;
   SpinEdit_Port.Text:= Port;
   if PressEnter = 'Yes' then
      CheckBox_PressEnter.Checked:= True
   else
      CheckBox_PressEnter.Checked:= False;
   BitBtn_Save.Images:= ImageList_menu;
   BitBtn_Save.ImageIndex := ReturnIndexImageList(ImageStrList_menu, 'save.png');
   BitBtn_Save.ImageWidth:= 16;

   if not DirectoryExistsUTF8(PixmapsDirectory) then
   begin
     Log('Not found path "' + PixmapsDirectory + '"' , FileLog, 1, 1);
     Application.Free;
   end;

   create_em_marine();
end;

//===============================================
// закрытие программы
procedure TForm_Options.MenuItem_ExitClick(Sender: TObject);
begin
  CloseForm:= True;
  Close;
end;

//===============================================
procedure TForm_Options.MenuItem_InfoClick(Sender: TObject);
begin
  Form_Info := TForm_info.Create(Application);
  Form_Info.Position := poDesktopCenter;
  Form_Info.BorderStyle := bsSingle;
  Form_Info.ShowModal;
  Form_Info.Free;
end;

//===============================================
// Options
procedure TForm_Options.MenuItem_OptionsClick(Sender: TObject);
begin
  // сворачиваем и разворачиваем программу в трей
  if Application.ShowMainForm then
     begin
       Application.ShowMainForm := False;
       Form_Options.Visible:= False;
     end
  else
     begin
       Application.ShowMainForm := True;
       Form_Options.Visible:= True;
     end;
end;

//===============================================
// выполнение таймера
procedure TForm_Options.Timer_UpdateTimer(Sender: TObject);
var file_connect, file_not_connect: String;
begin
  file_connect    := PixmapsDirectory + 'tray/connect.ico';
  file_not_connect:= PixmapsDirectory + 'tray/not_connect.ico';
  //TrayIcon.Icon.FreeImage;
  if DeviceStatus = 'connect' then
     if FileExistsUTF8(file_connect) = True then
        TrayIcon.Icon.LoadFromFile( file_connect)
     else
        begin
          Log('Not found file "' + file_connect + '"', FileLog, 1, 1);
          CloseForm:= True;
          Close;
        end;
  if DeviceStatus = 'not_connect' then
     if FileExistsUTF8(file_not_connect) = True then
        TrayIcon.Icon.LoadFromFile( file_not_connect)
     else
        begin
           Log('Not found file "' + file_not_connect+ '"', FileLog, 1, 1);
           CloseForm:= True;
           Close;
        end;

  { при использовании GetIcon есть утечка памяти
  if DeviceStatus = 'not_connect' then
     ImageList_Tray.GetIcon(ReturnIndexImageList(ImageStrList_tray, 'no.png'), TrayIcon.Icon);
  if DeviceStatus = 'connect' then
     ImageList_Tray.GetIcon(ReturnIndexImageList(ImageStrList_tray, 'em-marine.png'), Icon1);
  }
end;


end.

