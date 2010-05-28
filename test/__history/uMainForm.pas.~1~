unit uMainForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, MemCache, ComCtrls;

type
  TfrmMemCacheTest = class(TForm)
    PageControl1: TPageControl;
    tsServers: TTabSheet;
    tsFunctions: TTabSheet;
    btnStore: TButton;
    Label1: TLabel;
    edtKey: TEdit;
    Label2: TLabel;
    edtValue: TEdit;
    btnLookup: TButton;
    btnDelete: TButton;
    btnIncrement: TButton;
    btnDecrement: TButton;
    btnAppend: TButton;
    btnPrepend: TButton;
    btnInsert: TButton;
    btnReplace: TButton;
    Label3: TLabel;
    txtServers: TMemo;
    Button10: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button10Click(Sender: TObject);
    procedure btnStoreClick(Sender: TObject);
    procedure btnLookupClick(Sender: TObject);
    procedure btnInsertClick(Sender: TObject);
    procedure btnAppendClick(Sender: TObject);
    procedure btnPrependClick(Sender: TObject);
    procedure btnReplaceClick(Sender: TObject);
    procedure btnIncrementClick(Sender: TObject);
    procedure btnDecrementClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmMemCacheTest: TfrmMemCacheTest;
  MemCache : TMemCache;

implementation

{$R *.dfm}

procedure TfrmMemCacheTest.btnAppendClick(Sender: TObject);
begin
  MemCache.Append(edtKey.Text, edtValue.Text);
end;

procedure TfrmMemCacheTest.btnDecrementClick(Sender: TObject);
begin
  edtValue.Text := IntToStr(MemCache.Decrement(edtKey.Text));
end;

procedure TfrmMemCacheTest.btnDeleteClick(Sender: TObject);
begin
  MemCache.Delete(edtKey.Text);
end;

procedure TfrmMemCacheTest.btnIncrementClick(Sender: TObject);
begin
  edtValue.Text := IntToStr(MemCache.Increment(edtKey.Text));
end;

procedure TfrmMemCacheTest.btnInsertClick(Sender: TObject);
begin
  MemCache.Insert(edtKey.Text, edtValue.Text);
end;

procedure TfrmMemCacheTest.btnLookupClick(Sender: TObject);
begin
  edtValue.Text := MemCache.Lookup(edtKey.Text).Value;
end;

procedure TfrmMemCacheTest.btnPrependClick(Sender: TObject);
begin
  MemCache.Prepend(edtKey.Text, edtValue.Text);
end;

procedure TfrmMemCacheTest.btnReplaceClick(Sender: TObject);
begin
  MemCache.Replace(edtKey.Text, edtValue.Text);
end;

procedure TfrmMemCacheTest.btnStoreClick(Sender: TObject);
begin
  MemCache.Store(edtKey.Text, edtValue.Text);
end;

procedure TfrmMemCacheTest.Button10Click(Sender: TObject);
begin
  FreeAndNil(MemCache);
  MemCache := TMemCache.Create(txtServers.Lines);
end;

procedure TfrmMemCacheTest.FormCreate(Sender: TObject);
begin
  PageControl1.ActivePageIndex := 0;
  MemCache := TMemCache.Create;
end;

procedure TfrmMemCacheTest.FormDestroy(Sender: TObject);
begin
  MemCache.Free;
end;

end.
