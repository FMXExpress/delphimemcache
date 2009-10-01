program MemCacheTest;

uses
  Forms,
  uMainForm in 'uMainForm.pas' {frmMemCacheTest},
  MemCache in '..\MemCache.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMemCacheTest, frmMemCacheTest);
  Application.Run;
end.
