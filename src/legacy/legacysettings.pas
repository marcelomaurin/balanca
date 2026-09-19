unit legacysettings;

{$mode objfpc}{$H+}

interface

type
  { TLegacySettings }
  TLegacySettings = class
  public
    Empresa: string;
    Localizacao: string;
    Tipo1: string;
    Tipo2: string;
    Tipo3: string;
    Contagem1: Integer;
    Contagem2: Integer;
    Contagem3: Integer;
    Painel: string;
    TipoImp: Integer;
    ModeloImp: Integer;

    constructor Create;
    procedure ResetDefaults;
  end;

implementation

constructor TLegacySettings.Create;
begin
  inherited Create;
  ResetDefaults;
end;

procedure TLegacySettings.ResetDefaults;
begin
  Empresa := 'maurinsoft';
  Localizacao := 'nothing';
  Tipo1 := 'Normal';
  Tipo2 := 'Idoso';
  Tipo3 := 'Especial';
  Contagem1 := 0;
  Contagem2 := 0;
  Contagem3 := 0;
  Painel := '192.168.0.108';
  TipoImp := 0;
  ModeloImp := 0;
end;

end.
