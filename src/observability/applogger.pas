unit applogger;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SyncObjs;

type
  TLogLevel = (llDebug, llInfo, llWarn, llError);
  TLogEvent = procedure(Sender: TObject; ALevel: TLogLevel;
    const ACategory, AMessage: string) of object;

  { TAppLogger }
  TAppLogger = class
  private
    FLock: TCriticalSection;
    FMinLevel: TLogLevel;
    FFileName: string;
    FConsoleEnabled: Boolean;
    FOnLog: TLogEvent;
    function LevelName(ALevel: TLogLevel): string;
    procedure AppendFile(const ALine: string);
  public
    constructor Create;
    destructor Destroy; override;

    procedure Log(ALevel: TLogLevel; const ACategory, AMessage: string);
    procedure Debug(const ACategory, AMessage: string);
    procedure Info(const ACategory, AMessage: string);
    procedure Warn(const ACategory, AMessage: string);
    procedure Error(const ACategory, AMessage: string);

    property MinLevel: TLogLevel read FMinLevel write FMinLevel;
    property FileName: string read FFileName write FFileName;
    property ConsoleEnabled: Boolean read FConsoleEnabled write FConsoleEnabled;
    property OnLog: TLogEvent read FOnLog write FOnLog;
  end;

function ParseLogLevel(const AValue: string): TLogLevel;
function LogLevelName(ALevel: TLogLevel): string;

implementation

function LogLevelName(ALevel: TLogLevel): string;
begin
  case ALevel of
    llDebug: Result := 'DEBUG';
    llInfo: Result := 'INFO';
    llWarn: Result := 'WARN';
    llError: Result := 'ERROR';
  else
    Result := 'INFO';
  end;
end;

function ParseLogLevel(const AValue: string): TLogLevel;
var
  V: string;
begin
  V := LowerCase(Trim(AValue));
  if V = 'debug' then Exit(llDebug);
  if V = 'warn' then Exit(llWarn);
  if V = 'warning' then Exit(llWarn);
  if V = 'error' then Exit(llError);
  Result := llInfo;
end;

constructor TAppLogger.Create;
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FMinLevel := llInfo;
  FFileName := '';
  FConsoleEnabled := False;
end;

destructor TAppLogger.Destroy;
begin
  FLock.Free;
  inherited Destroy;
end;

function TAppLogger.LevelName(ALevel: TLogLevel): string;
begin
  Result := LogLevelName(ALevel);
end;

procedure TAppLogger.AppendFile(const ALine: string);
var
  F: TextFile;
  Dir: string;
begin
  if Trim(FFileName) = '' then
    Exit;

  Dir := ExtractFileDir(FFileName);
  if (Dir <> '') and (not DirectoryExists(Dir)) then
    ForceDirectories(Dir);

  AssignFile(F, FFileName);
  try
    if FileExists(FFileName) then
      Append(F)
    else
      Rewrite(F);
    WriteLn(F, ALine);
  finally
    CloseFile(F);
  end;
end;

procedure TAppLogger.Log(ALevel: TLogLevel; const ACategory, AMessage: string);
var
  Line: string;
begin
  if Ord(ALevel) < Ord(FMinLevel) then
    Exit;

  Line := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz', Now) +
    ' [' + LevelName(ALevel) + '] [' + ACategory + '] ' + AMessage;

  FLock.Acquire;
  try
    if FConsoleEnabled then
    begin
      if ALevel >= llWarn then
        WriteLn(StdErr, Line)
      else
        WriteLn(Line);
    end;

    AppendFile(Line);
  finally
    FLock.Release;
  end;

  if Assigned(FOnLog) then
    FOnLog(Self, ALevel, ACategory, AMessage);
end;

procedure TAppLogger.Debug(const ACategory, AMessage: string);
begin
  Log(llDebug, ACategory, AMessage);
end;

procedure TAppLogger.Info(const ACategory, AMessage: string);
begin
  Log(llInfo, ACategory, AMessage);
end;

procedure TAppLogger.Warn(const ACategory, AMessage: string);
begin
  Log(llWarn, ACategory, AMessage);
end;

procedure TAppLogger.Error(const ACategory, AMessage: string);
begin
  Log(llError, ACategory, AMessage);
end;

end.
