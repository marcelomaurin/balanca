unit protocolfactory;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, scaleprotocol;

type
  TScaleProtocolClass = class of TScaleProtocol;

  { TScaleProtocolFactory }
  TScaleProtocolFactory = class
  private
    class var FRegistry: TStringList;
    class procedure EnsureRegistry; static;
  public
    class procedure RegisterProtocol(const AId: string;
      AProtocolClass: TScaleProtocolClass); static;
    class function CreateProtocol(const AId: string): TScaleProtocol; static;
    class function IsRegistered(const AId: string): Boolean; static;
    class function RegisteredProtocols: string; static;
  end;

implementation

class procedure TScaleProtocolFactory.EnsureRegistry;
begin
  if not Assigned(FRegistry) then
  begin
    FRegistry := TStringList.Create;
    FRegistry.CaseSensitive := False;
    FRegistry.Sorted := True;
    FRegistry.Duplicates := dupIgnore;
  end;
end;

class procedure TScaleProtocolFactory.RegisterProtocol(const AId: string;
  AProtocolClass: TScaleProtocolClass);
var
  Id: string;
  Index: Integer;
begin
  EnsureRegistry;
  Id := LowerCase(Trim(AId));

  if Id = '' then
    raise Exception.Create('Identificador de protocolo vazio');

  Index := FRegistry.IndexOf(Id);
  if Index >= 0 then
    FRegistry.Objects[Index] := TObject(AProtocolClass)
  else
    FRegistry.AddObject(Id, TObject(AProtocolClass));
end;

class function TScaleProtocolFactory.CreateProtocol(
  const AId: string): TScaleProtocol;
var
  Id: string;
  Index: Integer;
  ProtocolClass: TScaleProtocolClass;
begin
  EnsureRegistry;
  Id := LowerCase(Trim(AId));

  Index := FRegistry.IndexOf(Id);
  if Index < 0 then
    raise Exception.CreateFmt('Protocolo não registrado: %s', [AId]);

  ProtocolClass := TScaleProtocolClass(FRegistry.Objects[Index]);
  Result := ProtocolClass.Create;
end;

class function TScaleProtocolFactory.IsRegistered(const AId: string): Boolean;
begin
  EnsureRegistry;
  Result := FRegistry.IndexOf(LowerCase(Trim(AId))) >= 0;
end;

class function TScaleProtocolFactory.RegisteredProtocols: string;
begin
  EnsureRegistry;
  Result := StringReplace(Trim(FRegistry.Text), LineEnding, ',', [rfReplaceAll]);
  while (Length(Result) > 0) and (Result[Length(Result)] = ',') do
    Delete(Result, Length(Result), 1);
end;

finalization
  FreeAndNil(TScaleProtocolFactory.FRegistry);

end.
