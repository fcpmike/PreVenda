unit UItem;

interface

uses System.Generics.Collections, System.SysUtils, System.JSON;

type
  TItem = class
  private
    { private declaractions }
    FID: Integer;
    FSequencia: Integer;
    FGrupo: Integer;
    FDescricao: String;
    FCodigoInterno: String;
    FValor1: Extended;
    FQuantidade: Extended;
    FSubTotal: Extended;
    function ToJSON: TJSONValue; virtual;
    class function JSONToObject<O: class>(json: TJSONValue): O;
  protected
    { protected declaractions }
    procedure SetID(const vValue: Integer);
    procedure SetSequencia(const vValue: Integer);
    procedure SetGrupo(const vValue: Integer);
    procedure SetDescricao(const vValue: String);
    procedure SetCodigoInterno(const vValue: String);
    procedure SetValor1(const vValue: Extended);
    procedure SetQuantidade(const vValue: Extended);
    procedure SetSubTotal(const vValue: Extended);
  public
    { public declaractions }
    constructor Create;
    function ToJSONString: string;
    class function JSONStringToObj<O: class>(jString: string): O;
  published
    { published declaractions }
    property Id: Integer read FID write SetID;
    property Sequencia: Integer read FSequencia write SetSequencia;
    property Secao: Integer read FGrupo write SetGrupo;
    property Descricao: String read FDescricao write SetDescricao;
    property CodigoInterno: String read FCodigoInterno write SetCodigoInterno;
    property Valor1: Extended read FValor1 write SetValor1;
    property Quantidade: Extended read FQuantidade write SetQuantidade;
    property SubTotal: Extended read FSubTotal write SetSubTotal;
  end;

  { TVenda }

  TVenda = class
  private
    { private declarations }
    FIDVenda: Integer;
    FData: TDateTime;
    FListaVendaItem: TObjectList<TItem>;
  public
    { public declarations }
    constructor Create;
    destructor Destroy; override;
    procedure VendeItem(vItem: TItem; vQtd: Extended);
    function ConsultaItem(pItem: TItem): TItem; overload;
    function ConsultaItem(pCod: String): TItem; overload;
  published
    { published declarations }
    property IDVenda: Integer read FIDVenda write FIDVenda;
    property Data: TDateTime read FData write FData;
    property ListaVendaItem: TObjectList<TItem> read FListaVendaItem write FListaVendaItem;
  end;

implementation

uses Data.DBXJSONReflect;

{ TItem }

constructor TItem.Create;
begin
  inherited Create;
end;

procedure TItem.SetID(const vValue: Integer);
begin
  FID := vValue;
end;

procedure TItem.SetCodigoInterno(const vValue: String);
begin
  FCodigoInterno := vValue;
end;

procedure TItem.SetDescricao(const vValue: String);
begin
  FDescricao := vValue;
end;

procedure TItem.SetQuantidade(const vValue: Extended);
begin
  FQuantidade := vValue;
end;

procedure TItem.SetGrupo(const vValue: Integer);
begin
  FGrupo := vValue;
end;

procedure TItem.SetSequencia(const vValue: Integer);
begin
  FSequencia := vValue;
end;

procedure TItem.SetSubTotal(const vValue: Extended);
begin
  FSubTotal := vValue;
end;

procedure TItem.SetValor1(const vValue: Extended);
begin
  FValor1 := vValue;
end;

function TItem.ToJSON: TJSONValue;
var
  Serializa: TJSONMarshal;
begin
  Serializa := TJSONMarshal.Create(TJSONConverter.Create);
  try
    Exit(Serializa.Marshal(Self));
  finally
    Serializa.Free;
  end;
end;

class function TItem.JSONToObject<O>(json: TJSONValue): O;
var
  Deserializa: TJSONUnMarshal;
begin
  if json is TJSONNull then
    Exit(nil);

  Deserializa := TJSONUnMarshal.Create;
  try
    Exit(O(Deserializa.Unmarshal(json))) finally Deserializa.Free;
  end;
end;

function TItem.ToJSONString: string;
var
  jValue: TJSONValue;
begin
  jValue := ToJSON;
  try
    Result := jValue.ToString;
  finally
    jValue.Free;
  end;
end;

class function TItem.JSONStringToObj<O>(jString: string): O;
var
  j: TJSONObject;
  obj: O;
begin
  j := TJSONObject.ParseJSONValue(TEncoding.ASCII.GetBytes(jString),0) as TJSONObject;
  try
    if Assigned(j) then
      Result := JSONToObject<O>(j)
    else
      Result := nil;
  except
    Result := nil;
  end;
end;

constructor TVenda.Create;
begin
  Inherited Create;
  FListaVendaItem := TObjectList<TItem>.Create;
end;

destructor TVenda.Destroy;
begin
  FreeAndNil(FListaVendaItem);
  inherited;
end;

procedure TVenda.VendeItem(vItem: TItem; vQtd: Extended);
var
  i: Integer;
  pItem: TItem;
begin
  pItem := ConsultaItem(vItem.CodigoInterno);
  if not Assigned(pItem) then
  begin
    pItem := vItem;
    pItem.Sequencia := FListaVendaItem.Count;
    FListaVendaItem.Add(pItem);
  end else
  begin
    pItem.Quantidade := pItem.Quantidade + vQtd;
    //FListaVendaItem.Items[pItem.Sequencia].Quantidade := pItem.Quantidade;
  end;
  {FListaVendaItem[I].IDVendaItem := I;
  FListaVendaItem[I].IDVenda     := FIDVenda;
  FListaVendaItem[I].Produto     := pProduto; }
end;

function TVenda.ConsultaItem(pItem: TItem): TItem;
var
  i: Integer;
begin
  Result := Nil;
  if Assigned(pItem) then
  begin
    for i := 0 to FListaVendaItem.Count - 1 do
      if FListaVendaItem.Items[i].CodigoInterno = pItem.CodigoInterno then
        Result := FListaVendaItem.Items[i];
  end;
end;

function TVenda.ConsultaItem(pCod: String): TItem;
var
  i: Integer;
begin
  Result := Nil;
  if pCod <> '' then
  begin
    for i := 0 to FListaVendaItem.Count - 1 do
      if FListaVendaItem.Items[i].CodigoInterno = pCod then
      begin
        Result := FListaVendaItem.Items[i];
        Break;
      end;
  end;
end;

end.
