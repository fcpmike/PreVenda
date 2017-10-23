unit UPreencheItens;

interface

uses System.Classes, System.SysUtils, FMX.StdCtrls, FMX.TabControl,
  System.Generics.Collections, FireDAC.Comp.Client, FireDAC.Stan.StorageBin, FMX.Dialogs,
  UItem;

type
  TPreencheItens = class(TThread)
  private
    FTabControl: TTabControl;
    FTabela: String;
    FListaVenda: TObjectList<TItem>;
    fCDS: TFDMemTable;
    procedure SetTabela(const vValue: String);
    procedure SetTabControl(const vValue: TTabControl);
    procedure SetListaVenda(const vValue: TObjectList<TItem>);
    function ConsultaItem(vCod: String): TItem;
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; overload;
    property Tabela: String read FTabela write SetTabela;
    property Tab: TTabControl read FTabControl write SetTabControl;
    property ListaVenda: TObjectList<TItem> read FListaVenda write SetListaVenda;
  end;

implementation

{ TPreencheItens }

uses UMain;

constructor TPreencheItens.Create;
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FListaVenda := TObjectList<TItem>.Create;
end;

destructor TPreencheItens.Destroy;
begin
  if Assigned(FListaVenda) then
    FreeAndNil(FListaVenda);
  inherited;
end;

procedure TPreencheItens.Execute;
var
  i, j: Integer;
  itemAdd: TPanel;
  tsAdd: TTabItem;
  item: TItem;
begin
  inherited;
  fCDS := TFDMemTable.Create(nil);
  try
    if FileExists(FTabela + '.adb') then
    begin
      fCDS.LoadFromFile(FTabela + '.adb');
      fCDS.Active := True;
    end;
    if not fCDS.IsEmpty then
    begin
      fCDS.First;
      i := 0;
      j := 0;
      while not fCDS.Eof do
      begin
        if Terminated then
          Break;
        if AnsiUpperCase(Tabela) = 'PRODUTOS' then
        begin
          item := ConsultaItem(fCDS.FieldByName('CODIGO').AsString);
          if not Assigned(item) then
          begin
            item := TItem.Create;
            item.Sequencia := -1;
            item.Id := fCDS.FieldByName('ID').AsInteger;
            item.CodigoInterno := fCDS.FieldByName('CODIGO').AsString;
            item.Descricao := fCDS.FieldByName('NOME').AsString;
            item.Valor1 := fCDS.FieldByName('VALOR1').AsFloat;
          end;
        end;
        if (j > Tab.Height) or ((i = 0) and (j = 0))then
        begin
          tsAdd := TTabItem.Create(Tab);
          tsAdd.Parent := Tab;
          //tsAdd.Index := Tab.TabCount - 1;
        end;
        Synchronize(nil, procedure
          begin
            if AnsiUpperCase(Tabela) = 'GRUPOS' then
              FMain.CriaItem(i, j, fCDS.FieldByName('NOME').AsString, nil, tsAdd, Tab)
            else if AnsiUpperCase(Tabela) = 'PRODUTOS' then
              FMain.CriaItem(i, j, '', item, tsAdd, Tab);
          end);
        i := i + 162;
        if (i + 161 > Tab.Width) then
        begin
          i := 0;
          j := j + 82;
          if (j + 81 > Tab.Height) then
            j := 0;
        end;
        Sleep(1);
        if AnsiUpperCase(Tabela) = 'PRODUTOS' then
          FreeAndNil(item);
        fCDS.Next;
      end;
    end;
  finally
    Terminate;
    FreeAndNil(fCDS);
    if FileExists(FTabela + '.adb') then
      DeleteFile(FTabela + '.adb')
  end;
end;

procedure TPreencheItens.SetListaVenda(const vValue: TObjectList<TItem>);
begin
  FListaVenda := vValue;
end;

procedure TPreencheItens.SetTabControl(const vValue: TTabControl);
begin
  FTabControl := vValue;
end;

procedure TPreencheItens.SetTabela(const vValue: String);
begin
  FTabela := vValue;
end;

function TPreencheItens.ConsultaItem(vCod: String): TItem;
var
  i: Integer;
begin
  Result := Nil;
  if (vCod <> '') and (Assigned(FListaVenda)) then
  begin
    for i := 0 to FListaVenda.Count - 1 do
      if FListaVenda.Items[i].CodigoInterno = vCod then
      begin
        Result := FListaVenda.Items[i];
        Break;
      end;
  end;
end;

end.
