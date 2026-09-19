unit legacyapi;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, scalejson;

function BuildLegacyWeightJson(const AWeight: string): string;
function BuildLegacyHtmlResponse(const AWeight: string): string;

implementation

function BuildLegacyWeightJson(const AWeight: string): string;
begin
  Result := BuildLegacyJson(AWeight);
end;

function BuildLegacyHtmlResponse(const AWeight: string): string;
begin
  Result :=
    '<html>' + LineEnding +
    '<head>' + LineEnding +
    '<title>Meu SRV</title>' + LineEnding +
    '</head>' + LineEnding +
    '<body>' + LineEnding +
    BuildLegacyWeightJson(AWeight) + LineEnding +
    '</body>' + LineEnding +
    '</html>' + LineEnding;
end;

end.
