unit peso;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, LedNumber;

type

  { TfrmPeso }

  TfrmPeso = class(TForm)
    Label2: TLabel;
    Label3: TLabel;
    lbPeso: TLEDNumber;
  private

  public
    procedure Peso(info: string);

  end;

var
  frmPeso: TfrmPeso;

implementation

{$R *.lfm}

{ TfrmPeso }

procedure TfrmPeso.Peso(info: string);
begin
  lbPeso.Caption:= info;
  Application.ProcessMessages;
end;

end.

