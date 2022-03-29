unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  ExtCtrls, LazSerial, FileUtil, LazFileUtils, LazSynaSer, SdpoSerial, synaser,
  LedNumber;

type

  { TForm1 }

  TForm1 = class(TForm)
    btDesconectar1: TButton;
    Button1: TButton;
    btConectar: TButton;
    btTesta: TButton;
    cbserial: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    lbstatus: TLabel;
    LazSerial1: TLazSerial;
    lbPeso: TLEDNumber;
    Timer1: TTimer;
    procedure btConectarClick(Sender: TObject);
    procedure btDesconectar1Click(Sender: TObject);
    procedure btTestaClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure LazSerial1BlockSerialStatus(Sender: TObject;
      Reason: THookSerialReason; const Value: string);
    procedure LazSerial1RxData(Sender: TObject);
    procedure SdpoSerial1BlockSerialStatus(Sender: TObject;
      Reason: THookSerialReason; const Value: string);
    procedure SdpoSerial1RxData(Sender: TObject);
    procedure Timer1StartTimer(Sender: TObject);
    procedure Timer1StopTimer(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    Lbuffer: String;
    procedure ListDev();
    function PegaSerial() : String;
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  Lbuffer:= '';;
  ListDev();
end;

procedure TForm1.LazSerial1BlockSerialStatus(Sender: TObject;
  Reason: THookSerialReason; const Value: string);
begin
  if(LazSerial1.Active) then
  begin
    //Shape1.Color:= clRed;
    lbstatus.Caption:= 'Open';
  end
  else
  begin
    //Shape1.Color:= clwhite;
    lbstatus.Caption:= 'close';
  end;
  Application.ProcessMessages();
end;

procedure TForm1.LazSerial1RxData(Sender: TObject);
var
  info : string;
begin

  if( LazSerial1.DataAvailable) then
  begin
    info := LazSerial1.ReadData();
  end;

  if (#3 <> info)  then
  begin
     Lbuffer:=Lbuffer + info;
  end
  else
  begin
     if (#2 = info)  then
     begin
         //Nao faz nada
     end
     else
     begin
       //Memo1.Lines.Add(Lbuffer);
        lbPeso.Caption:=Lbuffer;
       Application.ProcessMessages;
       LBuffer := '';
     end;
  end;
end;

procedure TForm1.SdpoSerial1BlockSerialStatus(Sender: TObject;
  Reason: THookSerialReason; const Value: string);
begin

end;

procedure TForm1.SdpoSerial1RxData(Sender: TObject);
begin
end;

procedure TForm1.Timer1StartTimer(Sender: TObject);
begin
  lbstatus.Caption:= 'Lendo...';
end;

procedure TForm1.Timer1StopTimer(Sender: TObject);
begin
 lbstatus.Caption:= 'Não Lendo';
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  LazSerial1.WriteData(#05);
  Application.ProcessMessages();
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
   //PegaSerial();
end;

procedure TForm1.btConectarClick(Sender: TObject);
begin

  LazSerial1.close;
  LazSerial1.Device := cbserial.Text;
  LazSerial1.Open;
  Application.ProcessMessages();
end;

procedure TForm1.btDesconectar1Click(Sender: TObject);
begin
  //SdpoSerial1.close;
  LazSerial1.close;
  Application.ProcessMessages();
end;

procedure TForm1.btTestaClick(Sender: TObject);
begin
 Timer1.Enabled:= not Timer1.Enabled;
end;

procedure TForm1.ListDev();
begin
  //cbserial.Text :=  PegaSerial();
end;

function TForm1.PegaSerial(): String;
var
  ListOfFiles: TStringList;
  Directory : string;
  posicao : integer;
begin


  ListOfFiles := TStringList.create();
  {$IFDEF LINUX}
  Directory := '/dev';
  FindAllFiles ( ListOfFiles , Directory ,  '*' ,  false ) ;
  posicao := 0;
  //ListOfFiles.Find('ttyS',posicao);
  //ListOfFiles.Sorted := true;
  cbserial.items.Clear;
  cbserial.Items.text:= ListOfFiles.Text;
  {$ENDIF}
end;

end.

