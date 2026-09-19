unit log;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Menus;

type

  { TfrmLog }

  TfrmLog = class(TForm)
    meLog: TMemo;
    MenuItem1: TMenuItem;
    PopupMenu1: TPopupMenu;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure MenuItem1Click(Sender: TObject);
  private

  public
    Procedure Log(info : string);
    Procedure Salvar();
    Procedure Carregar();

  end;

var
  frmLog: TfrmLog;

implementation

{$R *.lfm}

procedure TfrmLog.FormCreate(Sender: TObject);
begin
  Carregar();
end;

procedure TfrmLog.FormDestroy(Sender: TObject);
begin
  // O arquivo é mantido pelo logger central; a janela apenas o visualiza.
end;

procedure TfrmLog.MenuItem1Click(Sender: TObject);
begin
  meLog.clear;
end;

procedure TfrmLog.Log(info: string);
begin
  meLog.Lines.Append(info);
end;

procedure TfrmLog.Salvar();
begin
  // Compatibilidade: persistência agora é responsabilidade de TAppLogger.
end;

procedure TfrmLog.Carregar();
var
  Fpath : string;
  arquivo : string;
begin
  {$IFDEF LINUX}
      //Fpath :='/home/';
      //Fpath := GetUserDir()
      Fpath :=GetAppConfigDir(false);
      if not(FileExists(FPATH)) then
      begin
         createdir(fpath);
      end;
  {$ENDIF}
  {$IFDEF WINDOWS}
      Fpath :=GetAppConfigDir(false);
      if not(FileExists(FPATH)) then
      begin
         createdir(fpath);
      end;
  {$ENDIF}
  arquivo := IncludeTrailingPathDelimiter(Fpath) + 'balanca.log';
  if (FileExists(arquivo)) then
  begin
    meLog.Lines.LoadFromFile(arquivo);
  end;

end;

end.

