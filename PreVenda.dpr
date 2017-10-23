program PreVenda;

uses
  System.StartUpCopy,
  FMX.Forms,
  uMain in 'uMain.pas' {FMain},
  UPreencheItens in 'UPreencheItens.pas',
  UItem in 'UItem.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFMain, FMain);
  Application.Run;
end.
