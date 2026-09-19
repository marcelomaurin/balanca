unit scaleprotocol;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, scalecommands;

type
  TWeightEvent = procedure(Sender: TObject; const AWeight: string) of object;

  { TScaleProtocol }
  TScaleProtocol = class abstract
  private
    FOnWeight: TWeightEvent;
  protected
    procedure EmitWeight(const AWeight: string);
  public
    procedure Reset; virtual; abstract;
    procedure Feed(const AData: string); virtual; abstract;
    function SupportsCommand(ACommand: TScaleCommand): Boolean; virtual; abstract;
    function TryEncodeCommand(ACommand: TScaleCommand;
      out AData: string): Boolean; virtual; abstract;

    function ProtocolId: string; virtual; abstract;
    function DisplayName: string; virtual; abstract;
    function LastFrame: string; virtual; abstract;
    function LastPayload: string; virtual; abstract;
    function DiscardedFrames: QWord; virtual; abstract;
    function IgnoredBytes: QWord; virtual; abstract;

    property OnWeight: TWeightEvent read FOnWeight write FOnWeight;
  end;

implementation

procedure TScaleProtocol.EmitWeight(const AWeight: string);
begin
  if Assigned(FOnWeight) then
    FOnWeight(Self, AWeight);
end;

end.
