unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  ExtCtrls, Menus, PopupNotifier, LazSerial, LazSynaSer,
  synaser, IdHTTPServer, lNetComponents, LedNumber, setmain, registro, peso,
  setup, lNet, log, IdCustomHTTPServer, IdCompressionIntercept,
  IdSSLOpenSSL, IdSchedulerOfThreadDefault, IdContext, scaleapplication,
  httprouter;

Const
    Version : string =  '0.04';
    PortBalanca = 8097;
    PortWebSocket = 8098;
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
    procedure IdHTTPServer1CommandOther(AContext: TIdContext;
      ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
    procedure LazSerial1BlockSerialStatus(Sender: TObject;
      Reason: THookSerialReason; const Value: string);
    procedure LazSerial1RxData(Sender: TObject);
    procedure LazSerial1Status(Sender: TObject; Reason: THookSerialReason;
      const Value: string);
    procedure LTCPComponent1Connect(aSocket: TLSocket);
    procedure LTCPComponent1Disconnect(aSocket: TLSocket);
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
    FScaleApp: TScaleApplication;
    FHttpRouter: TScaleHttpRouter;
    FWebSocketStarted: Boolean;
    procedure ScaleWeight(Sender: TObject; const AWeight: string);
    procedure ScaleConnectionState(Sender: TObject;
      AState: TScaleConnectionState; const AMessage: string);
    procedure SalvarContexto();
    procedure Setup();
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
end;

procedure Tfrmmain.ScaleConnectionState(Sender: TObject;
  AState: TScaleConnectionState; const AMessage: string);
begin
  case AState of
    scsStopped:
      begin
        lbstatus.Caption := 'Desconectado';
        TrayIcon1.Hint := 'Disconnected';
      end;
    scsConnecting:
      begin
        lbstatus.Caption := 'Conectando...';
        TrayIcon1.Hint := 'Connecting';
      end;
    scsConnected:
      begin
        lbstatus.Caption := 'Conectado';
        TrayIcon1.Hint := 'Connected';
      end;
    scsWaitingReconnect:
      begin
        lbstatus.Caption := 'Reconectando...';
        TrayIcon1.Hint := 'Reconnecting';
      end;
  end;

  if Assigned(frmlog) and (AMessage <> '') then
    frmlog.Log(AMessage);
end;

procedure Tfrmmain.FormCreate(Sender: TObject);
begin
  frmlog := TfrmLog.create(self);
  frmsetup := Tfrmsetup.create(self);
  Fsetmain := TSetmain.create();
  FScaleApp := TScaleApplication.Create(LazSerial1, Fsetmain);
  FScaleApp.OnWeight := @ScaleWeight;
  FScaleApp.OnConnectionState := @ScaleConnectionState;
  FHttpRouter := TScaleHttpRouter.Create(FScaleApp);
  FWebSocketStarted := False;
  self.left := Fsetmain.posx;
  self.top := fsetmain.posy;
  frmSetup.edSerialPort.text := FSETMAIN.COMPORT;
  frmRegistrar := TfrmRegistrar.Create(self);
  frmRegistrar.Identifica();
  frmpeso := TFrmpeso.create(self);
  frmpeso.show();
  lbVersao.Caption:= Version;
end;

procedure Tfrmmain.FormDestroy(Sender: TObject);
begin
  SalvarContexto();
  FHttpRouter.Free;
  FScaleApp.Free;
  Fsetmain.free();
  frmlog.free;
  frmRegistrar.free;
  frmSetup.free;
end;

procedure Tfrmmain.IdHTTPServer1CommandGet(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
begin
  FHttpRouter.HandleGet(ARequestInfo, AResponseInfo);
end;

procedure Tfrmmain.IdHTTPServer1CommandOther(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
begin
  FHttpRouter.HandleOther(ARequestInfo, AResponseInfo);
end;

procedure Tfrmmain.LazSerial1BlockSerialStatus(Sender: TObject;
  Reason: THookSerialReason; const Value: string);
begin
  if Assigned(FScaleApp) and FScaleApp.Snapshot.Connected then
    lbstatus.Caption := 'Conectado'
  else
    lbstatus.Caption := 'Desconectado';
end;

procedure Tfrmmain.LazSerial1RxData(Sender: TObject);
begin
  if Assigned(FScaleApp) then
    FScaleApp.ProcessSerial;
end;

procedure Tfrmmain.LazSerial1Status(Sender: TObject; Reason: THookSerialReason;
  const Value: string);
begin

end;

procedure Tfrmmain.LTCPComponent1Connect(aSocket: TLSocket);
begin
  FScaleApp.WebSocketClientConnected(aSocket);
end;

procedure Tfrmmain.LTCPComponent1Disconnect(aSocket: TLSocket);
begin
  FScaleApp.WebSocketClientDisconnected(aSocket);
end;

procedure Tfrmmain.LTCPComponent1Receive(aSocket: TLSocket);
begin
  FScaleApp.WebSocketClientData(aSocket);
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
  if Assigned(FScaleApp) then
    FScaleApp.Tick;
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
  Timer1.Enabled := True;
  TrayIcon1.Visible := True;
  IdHTTPServer1.Active := True;

  if not FWebSocketStarted then
  begin
    LTCPComponent1.Listen(PortWebSocket);
    FWebSocketStarted := True;
  end;

  if not FScaleApp.Connect then
    lbstatus.Caption := 'Reconectando...';

  Hide;
end;

procedure Tfrmmain.btDesconectar1Click(Sender: TObject);
begin
  Timer1.Enabled := False;
  if Assigned(FScaleApp) then
    FScaleApp.Disconnect;
  lbstatus.Caption := 'Não conectado';
  TrayIcon1.Hint := 'Disconnected';
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

end.

