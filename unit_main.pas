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
  LastDeviceStatus: String = '';

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
// Создать файл настроек по умолчанию
procedure CreateDefaultINIOptions();
begin
   WriteINI('Options', 'IP', '192.168.1.191', FileINI);
   WriteINI('Options', 'Port', '9761', FileINI);
   WriteINI('Options', 'PressEnter', 'No', FileINI);
end;

//===============================================
// Український інтерфейс
procedure ApplyUkrainianInterface();
begin
   Form_Options.Caption := 'Налаштування';
   Form_Options.Label1.Caption := 'IP-адреса:';
   Form_Options.Label2.Caption := 'Порт:';
   Form_Options.CheckBox_PressEnter.Caption := 'Натискати Enter';
   Form_Options.BitBtn_Save.Caption := 'Зберегти';
   Form_Options.MenuItem_Info.Caption := 'Про програму';
   Form_Options.MenuItem_Options.Caption := 'Налаштування';
   Form_Options.MenuItem_Exit.Caption := 'Вихід';
   Form_Options.TrayIcon.Hint := 'Зчитувач EM-Marine';
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
  i, ReadCount: Integer;
  Str: String;
  const ValLuck: array[0..13] of Byte = (30,5,0,0,0,0,1,0,0,0,1,1,0,0);

begin
   Str:= ''; Code:= '';
   Socket := TTCPBlockSocket.Create;
   try
      Socket.SetTimeout(200);
      Socket.Connect(IP, Port);
      // Was there an error?
      if Socket.LastError <> 0 then
      begin
         if DeviceStatus <> 'not_connect' then
            Log('Не вдалося підключитися до зчитувача.', FileLog, 1, 0);
         DeviceStatus:= 'not_connect';
         Exit;
      end else
      if DeviceStatus <> 'connect' then
         DeviceStatus:= 'connect';

      while not Terminated do
      begin
         // поступила команда закрыть программу
         if CloseForm = True then
         begin
           Log('Сокет закрито.', FileLog, 0,0);
           Break;
         end;

         if Socket.CanRead(500) then
         begin
            // поступила команда закрыть программу
            if CloseForm = True then
            begin
              Log('Сокет закрито.', FileLog, 0,0);
              Break;
            end;

            //кол-во данных, доступных для чтения
            ReadCount:= Socket.WaitingData;
            if ReadCount > 0 then
            begin
              Str := '';
              for i:= 1 to ReadCount do
              begin
                 Str:= Str + IntToHex(Socket.RecvByte(250), 2);
              end;
              // удалим 1F и 4B
              Str := StringReplace(Str, '1F4B', '', [rfReplaceAll, rfIgnoreCase]);
              try
                //Code := IntToStr(Hex2Dec('00B65492'));
                Code := IntToStr(Hex2Dec(Str));
              except
                on EConvertError do
                  begin
                    Log('Помилка перетворення HEX-коду картки.', FileLog, 1,1);
                    Exit;
                  end;
              end;
              Log('Отримано код зі зчитувача: "' + Code + '"' , FileLog, 0,0);
              // отправим значение
              Synchronize(@SendKey);
              // пошлем в устройство что карточка прочитана
              for i := Low(ValLuck) to High(ValLuck) do
                  Socket.SendByte(ValLuck[i]);
              Str := '';
              Code:= '';
            end;
         end;
      end;
   finally
      Socket.CloseSocket;
      Socket.Free;
      Socket := nil;
   end;
end;

//===============================================
// остановим поток Thread_em_marine
procedure terminate_thread_em_marine();
begin
  if Thread_em_marine = nil then
     Exit;
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
  Thread_em_marine := nil;
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
    begin
       Socket.Free;
       Socket := nil;
    end;
  end
  else
     MenuItem_OptionsClick(Sender);
end;

//===============================================
procedure ReadINIOptions();
var LogDir, ApplNameExe, ExeName, FileName, DefaultPixmapsDirectory, LocalPixmapsDirectory: String;
    HomeDir: String;
begin
  ExeName         := ExtractFileExt(Application.ExeName);
  FileName        := ExtractFileName(Application.ExeName);
  {$IFDEF UNIX}
     ApplNameExe := FileName;
     HomeDir:= GetEnvironmentVariableUTF8('HOME');
     LogDir := HomeDir + '/.local/share/' + ApplNameExe + '/';
  {$ENDIF}
  {$IFDEF WINDOWS}
     ApplNameExe := Copy(FileName, 1, Pos(ExeName, FileName) - 1);
     LogDir  := ExtractFilePath(Application.ExeName) + 'Log/';
  {$ENDIF}
  if not DirectoryExistsUTF8(LogDir) then
     CreateDirUTF8(LogDir);

  FileLog := LogDir + FileName + '-' + DateToStr(Date) + '.log';

  IP         := ReadINI('Options', 'IP',   '192.168.1.191',     FileINI);
  Port       := ReadINI('Options', 'Port', '9761', FileINI);
  PressEnter := ReadINI('Options', 'PressEnter', 'No', FileINI);
  if IP = '' then
     IP := '192.168.1.191';
  if Port = '' then
     Port := '9761';
  if PressEnter = '' then
     PressEnter := 'No';

  DefaultPixmapsDirectory := IncludeTrailingPathDelimiter('/usr/share/pixmaps/' + ApplNameExe);
  LocalPixmapsDirectory   := IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName) + 'images');
  PixmapsDirectory        := ReadINI('Options', 'PixmapsDirectory', DefaultPixmapsDirectory, FileINI);
  if PixmapsDirectory = '' then
     PixmapsDirectory := DefaultPixmapsDirectory;
  PixmapsDirectory        := IncludeTrailingPathDelimiter(PixmapsDirectory);

  // Якщо стандартного каталогу з іконками немає, беремо images біля програми.
  if not DirectoryExistsUTF8(PixmapsDirectory) then
  begin
    if DirectoryExistsUTF8(LocalPixmapsDirectory) then
       PixmapsDirectory := LocalPixmapsDirectory
    else
    begin
      Log('Каталог із зображеннями не знайдено: ' + PixmapsDirectory + ' або ' + LocalPixmapsDirectory, FileLog, 1, 1);
      Halt;
    end;
  end;
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
   Timer_Update.Interval := 500;
   {$IFDEF UNIX}
      Edit_IP.Height:= 28;
      SpinEdit_Port.Height:= 31;
      HomeDir:= GetEnvironmentVariableUTF8('HOME');
      if not DirectoryExistsUTF8(HomeDir + '/.config/em-marine/') then
         CreateDirUTF8(HomeDir + '/.config/em-marine/');
      FileINI := HomeDir + '/.config/em-marine/options.ini';
      if not FileExistsUTF8(FileINI) then
      begin
         if FileExistsUTF8('/etc/em-marine/options.ini') then
            CopyFile('/etc/em-marine/options.ini', FileINI)
         else
            CreateDefaultINIOptions();
      end;
   {$ENDIF}
   {$IFDEF WINDOWS}
      Edit_IP.Height:= 22;
      SpinEdit_Port.Height:= 22;
      FileINI := ExtractFilePath(Application.ExeName) + 'options.ini';
      if not FileExistsUTF8(FileINI) then
         CreateDefaultINIOptions();
   {$ENDIF}
   if not FileExistsUTF8(FileINI) then
   begin
     MessageDlg('Файл налаштувань не знайдено: "' + FileINI + '"' , mtError, [mbOK], 0);
     Halt;
   end;
   ReadINIOptions();
   // добавим иконку программы
   if FileExistsUTF8(PixmapsDirectory + 'tray/connect.ico') then
      Application.Icon.Assign(LoadBitmapFromFile(PixmapsDirectory + 'tray/connect.ico'));
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

   ApplyUkrainianInterface();
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
  if DeviceStatus = '' then
     Exit;

  // Не перечитываем иконку 100 раз в секунду. Меняем ее только при смене статуса.
  if DeviceStatus = LastDeviceStatus then
     Exit;
  LastDeviceStatus := DeviceStatus;

  file_connect    := PixmapsDirectory + 'tray/connect.ico';
  file_not_connect:= PixmapsDirectory + 'tray/not_connect.ico';
  //TrayIcon.Icon.FreeImage;
  if DeviceStatus = 'connect' then
     if FileExistsUTF8(file_connect) = True then
        TrayIcon.Icon.LoadFromFile( file_connect)
     else
        begin
          Log('Файл іконки не знайдено: "' + file_connect + '"', FileLog, 1, 1);
          CloseForm:= True;
          Close;
        end;
  if DeviceStatus = 'not_connect' then
     if FileExistsUTF8(file_not_connect) = True then
        TrayIcon.Icon.LoadFromFile( file_not_connect)
     else
        begin
           Log('Файл іконки не знайдено: "' + file_not_connect+ '"', FileLog, 1, 1);
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
