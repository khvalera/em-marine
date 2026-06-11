unit single_instance;

{$mode objfpc}{$H+}

interface

function AcquireSingleInstanceLock: Boolean; overload;
function AcquireSingleInstanceLock(const AAppName: String): Boolean; overload;
procedure ReleaseSingleInstanceLock; overload;
procedure ReleaseSingleInstanceLock(const AAppName: String); overload;

{ Compatibility names used by em_marine.lpr }
function AppInstanceAcquireLock: Boolean; overload;
function AppInstanceAcquireLock(const AAppName: String): Boolean; overload;
procedure AppInstanceReleaseLock; overload;
procedure AppInstanceReleaseLock(const AAppName: String); overload;

implementation

uses
  SysUtils
  {$IFDEF WINDOWS}
  , Windows
  {$ENDIF}
  {$IFDEF UNIX}
  , BaseUnix
  {$ENDIF}
  ;

const
  DefaultAppLockName = 'em-marine-single-instance';

var
  LockAcquired: Boolean = False;
  CurrentAppLockName: String = DefaultAppLockName;

{$IFDEF WINDOWS}
var
  MutexHandle: THandle = 0;
{$ENDIF}

{$IFDEF UNIX}
var
  LockDirName: String = '';

function NormalizeLockName(const AAppName: String): String;
var
  S: String;
  I: Integer;
begin
  S := Trim(AAppName);

  if S = '' then
    S := DefaultAppLockName;

  for I := 1 to Length(S) do
  begin
    if not (S[I] in ['A'..'Z', 'a'..'z', '0'..'9', '-', '_', '.']) then
      S[I] := '-';
  end;

  Result := S;
end;

function GetLockBaseDir: String;
var
  HomeDir: String;
begin
  Result := GetEnvironmentVariable('XDG_RUNTIME_DIR');

  if Result = '' then
  begin
    HomeDir := GetEnvironmentVariable('HOME');
    if HomeDir <> '' then
      Result := IncludeTrailingPathDelimiter(HomeDir) + '.config'
    else
      Result := GetTempDir(False);
  end;

  if Result = '' then
    Result := '/tmp';
end;

function GetPidFileName: String;
begin
  Result := IncludeTrailingPathDelimiter(LockDirName) + 'pid';
end;

function WritePidFile: Boolean;
var
  F: TextFile;
begin
  Result := False;

  try
    AssignFile(F, GetPidFileName);
    Rewrite(F);
    WriteLn(F, fpGetPid);
    CloseFile(F);
    Result := True;
  except
    Result := False;
  end;
end;

function ReadPidFile(out Pid: Integer): Boolean;
var
  F: TextFile;
  S: String;
begin
  Result := False;
  Pid := 0;

  if not FileExists(GetPidFileName) then
    Exit;

  try
    AssignFile(F, GetPidFileName);
    Reset(F);
    ReadLn(F, S);
    CloseFile(F);

    Result := TryStrToInt(Trim(S), Pid);
  except
    Result := False;
  end;
end;

function ProcessExists(Pid: Integer): Boolean;
begin
  if Pid <= 0 then
    Exit(False);

  Result := fpKill(Pid, 0) = 0;
end;

function RemoveStaleLockIfNeeded: Boolean;
var
  Pid: Integer;
begin
  Result := False;

  if not DirectoryExists(LockDirName) then
    Exit;

  { If there is no PID file, do not remove the lock immediately.
    Another instance may have created the directory and may still be writing PID. }
  if not ReadPidFile(Pid) then
    Exit;

  if ProcessExists(Pid) then
    Exit;

  DeleteFile(GetPidFileName);
  Result := RemoveDir(LockDirName);
end;
{$ENDIF}

function AcquireSingleInstanceLock: Boolean;
begin
  Result := AcquireSingleInstanceLock(DefaultAppLockName);
end;

function AcquireSingleInstanceLock(const AAppName: String): Boolean;
{$IFDEF UNIX}
var
  BaseDir: String;
{$ENDIF}
begin
  if LockAcquired then
    Exit(True);

  CurrentAppLockName := NormalizeLockName(AAppName);

  {$IFDEF WINDOWS}
  MutexHandle := CreateMutex(nil, True, PChar('Global\' + CurrentAppLockName));

  if MutexHandle = 0 then
  begin
    MutexHandle := CreateMutex(nil, True, PChar(CurrentAppLockName));
    if MutexHandle = 0 then
      Exit(False);
  end;

  if GetLastError = ERROR_ALREADY_EXISTS then
  begin
    CloseHandle(MutexHandle);
    MutexHandle := 0;
    Exit(False);
  end;

  LockAcquired := True;
  Exit(True);
  {$ENDIF}

  {$IFDEF UNIX}
  BaseDir := GetLockBaseDir;

  if not DirectoryExists(BaseDir) then
    ForceDirectories(BaseDir);

  LockDirName := IncludeTrailingPathDelimiter(BaseDir) + CurrentAppLockName + '.lock';

  if CreateDir(LockDirName) then
  begin
    LockAcquired := WritePidFile;
    if not LockAcquired then
      RemoveDir(LockDirName);
    Exit(LockAcquired);
  end;

  if RemoveStaleLockIfNeeded then
  begin
    if CreateDir(LockDirName) then
    begin
      LockAcquired := WritePidFile;
      if not LockAcquired then
        RemoveDir(LockDirName);
      Exit(LockAcquired);
    end;
  end;

  Exit(False);
  {$ENDIF}

  {$IFNDEF WINDOWS}
  {$IFNDEF UNIX}
  LockAcquired := True;
  Result := True;
  {$ENDIF}
  {$ENDIF}
end;

procedure ReleaseSingleInstanceLock;
begin
  ReleaseSingleInstanceLock(CurrentAppLockName);
end;

procedure ReleaseSingleInstanceLock(const AAppName: String);
begin
  if not LockAcquired then
    Exit;

  {$IFDEF WINDOWS}
  if MutexHandle <> 0 then
  begin
    ReleaseMutex(MutexHandle);
    CloseHandle(MutexHandle);
    MutexHandle := 0;
  end;
  {$ENDIF}

  {$IFDEF UNIX}
  if LockDirName <> '' then
  begin
    DeleteFile(GetPidFileName);
    RemoveDir(LockDirName);
    LockDirName := '';
  end;
  {$ENDIF}

  LockAcquired := False;
end;

function AppInstanceAcquireLock: Boolean;
begin
  Result := AcquireSingleInstanceLock(DefaultAppLockName);
end;

function AppInstanceAcquireLock(const AAppName: String): Boolean;
begin
  Result := AcquireSingleInstanceLock(AAppName);
end;

procedure AppInstanceReleaseLock;
begin
  ReleaseSingleInstanceLock;
end;

procedure AppInstanceReleaseLock(const AAppName: String);
begin
  ReleaseSingleInstanceLock(AAppName);
end;

end.
