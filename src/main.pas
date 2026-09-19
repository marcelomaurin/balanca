unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  ExtCtrls, Menus, PopupNotifier, LazSerial, FileUtil, LazFileUtils, LazSynaSer,
  synaser, IdHTTPServer, lNetComponents, LedNumber, setmain, registro, peso,
  setup, lNet, log, IdCustomHTTPServer, IdCompressionIntercept,
  IdSSLOpenSSL, IdSchedulerOfThreadDefault, IdContext, scaledevice, scaleapi;

Const
    Version : string =  '0.04';
    PortBalanca = 8097;
    ServerName :string = 'localhost';


type

  { Tfrmmain }


  Tfrmmain = class(TForm)
    btDesconectar1: TButton;
    Button1: TButton;
    btConectar: TButton;
    btSetup: TButton;
    IdHTTPServer1: TIdHTTPServer;
    IdSchedulerOfThreadDefault1: TIdSchedulerOfThreadDefault;
    IdServerCompressionIntercept1: TIdServerCompressionIntercept;
    IdServerIOHandlerSSLOpenSSL1: TIdServerIOHandlerSSLOpenSSL;
    lbVersao: TLabel;
    lbstatus: TLabel;
    LazSerial1: TLazSerial;
    LTCPComponent1: TLTCPComponent;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    btlog: TMenuItem;
    popTray: TPopupMenu;
    PopupNotifier1: TPopupNotifier;
    Timer1: TTimer;
    btsair: TToggleBox;
    TrayIcon1: TTrayIcon;
    procedure btConectarClick(Sender: TObject);
    procedure btDesconectar1Click(Sender: TObject);
    procedure btlogClick(Sender: TObject);
    procedure btsairChange(Sender: TObject);
    procedure btSetupClick(Sender: TObject);
    procedure btTestaClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure IdHTTPServer1CommandGet(AContext: TIdContext;
      ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
    procedure LazSerial1BlockSerialStatus(Sender: TObject;
      Reason: THookSerialReason; const Value: string);
    procedure LazSerial1RxData(Sender: TObject);
    procedure LazSerial1Status(Sender: TObject; Reason: THookSerialReason;
      const Value: string);
    procedure LTCPComponent1Connect(aSocket: TLSocket);
    procedure LTCPComponent1Receive(aSocket: TLSocket);
    procedure MenuItem1Click(Sender: TObject);
    procedure MenuItem2Click(Sender: TObject);
    procedure MenuItem3Click(Sender: TObject);
    procedure SdpoSerial1BlockSerialStatus(Sender: TObject;
      Reason: THookSerialReason; const Value: string);
    procedure SdpoSerial1RxData(Sender: TObject);
    procedure Timer1StartTimer(Sender: TObject);
    procedure Timer1StopTimer(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    FScaleDevice: TScaleDevice;
    FScaleApi: TScaleApi;
    procedure ScaleWeight(Sender: TObject; const AWeight: string);
    procedure ListDev();
    function PegaSerial() : String;
    procedure SalvarContexto();
    procedure Setup();
    procedure getPage(aSocket : TLSocket; PeerAddress : string; mensagem: string);
    procedure RespostaHTMLCabecalho(aSocket: TLSocket);
  public

  end;

var
  frmmain: Tfrmmain;

implementation

{$R *.lfm}

{ Tfrmmain }

procedure Tfrmmain.ScaleWeight(Sender: TObject; const AWeight: string);
begin
  frmPeso.Peso(AWeight);
  Application.ProcessMessages;
end;

procedure Tfrmmain.FormCreate(Sender: TObject);
begin
  frmlog := TfrmLog.create(self);
  frmsetup := Tfrmsetup.create(self);
  Fsetmain := TSetmain.create();
  FScaleDevice := TScaleDevice.Create(LazSerial1);
  FScaleDevice.OnWeight := @ScaleWeight;
  FScaleApi := TScaleApi.Create(FScaleDevice, Fsetmain);
  self.left := Fsetmain.posx;
  self.top := fsetmain.posy;
  frmSetup.edSerialPort.text := FSETMAIN.COMPORT;
  frmRegistrar := TfrmRegistrar.Create(self);
  frmRegistrar.Identifica();
  frmpeso := TFrmpeso.create(self);
  frmpeso.show();
  ListDev();
  lbVersao.Caption:= Version;
end;

procedure Tfrmmain.FormDestroy(Sender: TObject);
begin
  SalvarContexto();
  FScaleApi.Free;
  FScaleDevice.Free;
  Fsetmain.free();
  frmlog.free;
  frmRegistrar.free;
  frmSetup.free;
end;

procedure Tfrmmain.IdHTTPServer1CommandGet(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
var
  Path: string;
  LegacyHtml: string;
begin
  Path := ARequestInfo.Document;

  if SameText(Path, '/api/v1/weight') then
  begin
    AResponseInfo.ResponseNo := 200;
    AResponseInfo.ContentType := 'application/json; charset=utf-8';
    AResponseInfo.ContentText := FScaleApi.WeightJson;
  end
  else if SameText(Path, '/api/v1/status') then
  begin
    AResponseInfo.ResponseNo := 200;
    AResponseInfo.ContentType := 'application/json; charset=utf-8';
    AResponseInfo.ContentText := FScaleApi.StatusJson;
  end
  else if SameText(Path, '/api/v1/config') then
  begin
    AResponseInfo.ResponseNo := 200;
    AResponseInfo.ContentType := 'application/json; charset=utf-8';
    AResponseInfo.ContentText := FScaleApi.ConfigJson;
  end
  else if SameText(Path, '/') or SameText(Path, '/legacy') then
  begin
    // Compatibilidade com clientes antigos: mantém HTML contendo o objeto
    // {"rs":{"peso":"..."}} que era retornado pela aplicação original.
    LegacyHtml :=
      '<html>' + LineEnding +
      '<head>' + LineEnding +
      '<title>Meu SRV</title>' + LineEnding +
      '</head>' + LineEnding +
      '<body>' + LineEnding +
      FScaleApi.LegacyJson + LineEnding +
      '</body>' + LineEnding +
      '</html>' + LineEnding;

    AResponseInfo.ResponseNo := 200;
    AResponseInfo.ContentType := 'text/html; charset=utf-8';
    AResponseInfo.ContentText := LegacyHtml;
  end
  else
  begin
    AResponseInfo.ResponseNo := 404;
    AResponseInfo.ContentType := 'application/json; charset=utf-8';
    AResponseInfo.ContentText := FScaleApi.NotFoundJson(Path);
  end;
end;

procedure Tfrmmain.LazSerial1BlockSerialStatus(Sender: TObject;
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

procedure Tfrmmain.LazSerial1RxData(Sender: TObject);
begin
  if Assigned(FScaleDevice) then
    FScaleDevice.ProcessIncoming;
end;

procedure Tfrmmain.LazSerial1Status(Sender: TObject; Reason: THookSerialReason;
  const Value: string);
begin

end;

procedure Tfrmmain.LTCPComponent1Connect(aSocket: TLSocket);
begin
  aSocket.SendMessage('Connected!');
  //frmLog.Log('Connected:'+aSocket.PeerAddress);
end;

procedure Tfrmmain.LTCPComponent1Receive(aSocket: TLSocket);
var
  mensagem : string;
  strnro : string;
  posicao : integer;
begin
  //Mensagem recebida padrao Fila:nro+#13
  aSocket.GetMessage(mensagem);
  //PopupNotifier1.Text:=mensagem;
  //PopupNotifier1.Show;
  //frmlog.Log('Receive:'+aSocket.PeerAddress+',msg:'+mensagem);
  //if (mensagem <> '') then
  //if (pos(mensagem,'GET / HTTP/1.1')<>-1) then
  begin
     frmlog.Log('rec:'+mensagem);
     (*
      if (POS(mensagem, 'PESO:')>=0) then
      begin
        aSocket.SendMessage('PESO:'+ frmPeso.lbPeso.Caption +#13);  //Vou implementar aqui
        aSocket.Disconnect(true);
      end;
      *)
     getPage(aSocket, aSocket.PeerAddress, mensagem);
  end;
  //aSocket.Disconnect(true);
  LTCPComponent1.CallAction();
end;

procedure Tfrmmain.MenuItem1Click(Sender: TObject);
begin
  show();
end;

procedure Tfrmmain.MenuItem2Click(Sender: TObject);
begin
       Setup();
end;

procedure Tfrmmain.MenuItem3Click(Sender: TObject);
begin
  frmPeso.show();
end;

procedure Tfrmmain.SdpoSerial1BlockSerialStatus(Sender: TObject;
  Reason: THookSerialReason; const Value: string);
begin

end;

procedure Tfrmmain.SdpoSerial1RxData(Sender: TObject);
begin
end;

procedure Tfrmmain.Timer1StartTimer(Sender: TObject);
begin
  lbstatus.Caption:= 'Lendo...';
end;

procedure Tfrmmain.Timer1StopTimer(Sender: TObject);
begin
 lbstatus.Caption:= 'Não Lendo';
end;

procedure Tfrmmain.Timer1Timer(Sender: TObject);
begin
  if Assigned(FScaleDevice) then
    FScaleDevice.RequestWeight;
  Application.ProcessMessages();
end;

procedure Tfrmmain.Button1Click(Sender: TObject);
begin
   //PegaSerial();
end;

procedure Tfrmmain.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  //if QuestionDlg('Sair?','Deseja sair? ',);
  canClose := false;
  hide;
  if(not TrayIcon1.Visible) then
  begin
     TrayIcon1.Visible:=true;
  end;
end;

procedure Tfrmmain.btConectarClick(Sender: TObject);
begin
  FScaleDevice.Config.Port := FSETMAIN.COMPORT;
  FScaleDevice.Config.BaudRate := FSETMAIN.BAUDRATE;
  FScaleDevice.Config.DataBits := FSETMAIN.DATABIT;
  FScaleDevice.Config.Parity := FSETMAIN.PARIDADE;
  FScaleDevice.Config.StopBits := FSETMAIN.STOPBIT;

  try
    FScaleDevice.Connect;
    Application.ProcessMessages();
  finally
    Timer1.Enabled := not Timer1.Enabled;
    TrayIcon1.Visible := true;
    TrayIcon1.Hint := 'Connected';
    IdHTTPServer1.Active := true;
    Hide;
  end;
end;

procedure Tfrmmain.btDesconectar1Click(Sender: TObject);
begin
  Timer1.Enabled := false;
  if Assigned(FScaleDevice) then
    FScaleDevice.Disconnect;
  Application.ProcessMessages();
end;

procedure Tfrmmain.btlogClick(Sender: TObject);
begin
  frmLog.show;
end;

procedure Tfrmmain.btsairChange(Sender: TObject);
begin
     Application.Terminate;
end;

procedure Tfrmmain.btSetupClick(Sender: TObject);
begin
     Setup();
end;

procedure Tfrmmain.btTestaClick(Sender: TObject);
begin

end;

procedure Tfrmmain.ListDev();
begin
  //cbserial.Text :=  PegaSerial();
end;

function Tfrmmain.PegaSerial(): String;
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

procedure Tfrmmain.SalvarContexto();
begin
  (*
  FSETMAIN.empresa := edEmpresa.text;
  FSETMAIN.Localizacao :=  edlocalizacao.text;
  FSETMAIN.Tipo1 :=  edTipo1.text;
  FSETMAIN.Tipo2 := edTipo2.text;
  FSETMAIN.Tipo3 := edTipo3.text;
  FSETMAIN.Contagem1 :=  strtoint(edCont1.text);
  FSETMAIN.Contagem2 := strtoint(edCont2.text);
  FSETMAIN.Contagem3 := strtoint( edCont3.text);
  *)
  FSETMAIN.posx := self.left;
  FSetMain.posy := self.top;
  (*
  FSetmain.painel:= edPainel.text;
  Fsetmain.tipoimp := cbTipoImp.ItemIndex;
  Fsetmain.modeloimp := cbModeImp.ItemIndex;
  *)
  //FSetmain.COMPORT := cbserial.text;
  (*
  Fsetmain.EXEC:= cbIniciar.Checked;
  *)
  FSETMAIN.SalvaContexto();

end;

procedure Tfrmmain.Setup();
begin
  frmSetup.edSerialPort.text := FSETMAIN.COMPORT;
  frmSetup.cbBaudrate.ItemIndex:= FSETMAIN.BAUDRATE;
  frmSetup.cbDatabits.ItemIndex:= FSETMAIN.DATABIT;
  frmSetup.rgParity.ItemIndex:= FSETMAIN.PARIDADE;
  //frmSetup.rgFlowControl.ItemIndex:=FSETMAIN.;
  frmSetup.rgStopbit.ItemIndex := FSETMAIN.STOPBIT;
  frmSetup.show();
end;

procedure Tfrmmain.RespostaHTMLCabecalho(aSocket: TLSocket);
var
  buffer : string;
begin

 buffer :='HTTP/1.1 200 OK '+#10;
 buffer := buffer +'Content-Type: text/html'+#10;
 buffer := buffer + '<!DOCTYPE HTML>'+#10;
 buffer := buffer + '<html>'+#10;
 buffer := buffer + '<head>'+#10;
 buffer := buffer + '<title>Meu SRV</title>'+#10;
 buffer := buffer + '</head>'+#10;
 buffer := buffer + '<body>'+#10;
 buffer := buffer + 'hello'+#10;
 buffer := buffer + '</body>'+#10;
 buffer := buffer + '</html>'+#10;

 //aSocket.SendMessage('Connection: close'+#10+#13);
 //aSocket.Send(UTF8Char(buffer),length(buffer));

end;

procedure Tfrmmain.getPage(aSocket: TLSocket; PeerAddress: string;
  mensagem: string);
var
  buffer : WIDEstring;
begin

  RespostaHTMLCabecalho(aSocket);
  //aSocket.SendMessage('Host:'+ServerName+' '+#10+#13);
  //buffer := buffer + 'Refresh: 5';
  //buffer := buffer + #13#10;
  (*
  aSocket.SendMessage('<!DOCTYPE HTML>'+#10+#13);
  aSocket.SendMessage('<html>'+#10+#13);
  aSocket.SendMessage('<head>'+#10+#13);
  aSocket.SendMessage('</head>'+#10+#13);
  aSocket.SendMessage('<body>'+#10+#13);
  aSocket.SendMessage('hello '+#10+#13);
  aSocket.SendMessage('</body>'+#10+#13);
  aSocket.SendMessage('</html>'+#10+#13);
  //aSocket.Send(buffer,sizeof(buffer));
  frmLog.Log('ENV:'+buffer);
  //aSocket.SendMessage(buffer);
  //LTCPComponent1.CallAction();
  *)
end;

end.

