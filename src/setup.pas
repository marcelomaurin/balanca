unit Setup;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  setmain;

type

  { TfrmSetup }

  TfrmSetup = class(TForm)
    Button1: TButton;
    btCancelar: TButton;
    cbBaudrate: TComboBox;
    cbDatabits: TRadioGroup;
    edSerialPort: TEdit;
    Label12: TLabel;
    Label13: TLabel;
    rgFlowControl: TRadioGroup;
    rgParity: TRadioGroup;
    rgStopbit: TRadioGroup;
    procedure btCancelarClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
         procedure Salvar();
  public

  end;

var
  frmSetup: TfrmSetup;

implementation

{$R *.lfm}

{ TfrmSetup }

procedure TfrmSetup.btCancelarClick(Sender: TObject);
begin
  close;
end;

procedure TfrmSetup.Button1Click(Sender: TObject);
begin
  Salvar();
  close;
end;

procedure TfrmSetup.Salvar();
begin
  FSETMAIN.COMPORT :=frmSetup.edSerialPort.text;
  FSETMAIN.BAUDRATE := frmSetup.cbBaudrate.ItemIndex;
  FSETMAIN.DATABIT := frmSetup.cbDatabits.ItemIndex;
  FSETMAIN.PARIDADE := frmSetup.rgParity.ItemIndex;
  //frmSetup.rgFlowControl.ItemIndex:=FSETMAIN.;
  FSETMAIN.STOPBIT := frmSetup.rgStopbit.ItemIndex;
end;

end.

