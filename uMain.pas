unit uMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Layouts, FMX.ListView.Types,
  FMX.ListView.Appearances, FMX.ListView.Adapters.Base, FMX.ListView,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.ExprFuncs, FireDAC.FMXUI.Wait, FireDAC.Stan.Param, FireDAC.DatS,
  FireDAC.DApt.Intf, FireDAC.DApt, Data.DB, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client, FMX.TabControl, System.Rtti,
  UPreencheItens, UItem, FireDAC.Phys.FB, FireDAC.Phys.FBDef;

type
  TFMain = class(TForm)
    ToolBar1: TToolBar;
    Label1: TLabel;
    layoutPrincipal: TLayout;
    layoutBobina: TLayout;
    layoutGrupo: TLayout;
    layoutProdutos: TLayout;
    ListViewItens: TListView;
    PrevendaConnection: TFDConnection;
    GrupoTable: TFDQuery;
    ProdutoTable: TFDQuery;
    TabControlGrupo: TTabControl;
    TabControlProduto: TTabControl;
    Resources1: TStyleBook;
    procedure FormCreate(Sender: TObject);
    procedure PreencheGrupos;
    procedure AtualizaProdutos(vSecao: String);
    procedure LimpaTabControl(vTab: TTabControl);
    procedure CriaItem(vX, vY: Integer; vTexto: String; vItem: TItem; vTab: TTabItem; vControl: TTabControl);
    procedure ItemClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure DoGrupoClick(Sender: TObject);
  private
    { Private declarations }
    GrupoThread, ProdutoThread: TPreencheItens;
    Venda: TVenda;
  public
    { Public declarations }
  end;

var
  FMain: TFMain;

implementation

{$R *.fmx}

function FindItemParent(Obj: TFmxObject; ParentClass: TClass): TFmxObject;
begin
  Result := nil;
  if Assigned(Obj.Parent) then
    if Obj.Parent.ClassType = ParentClass then
      Result := Obj.Parent
    else
      Result := FindItemParent(Obj.Parent, ParentClass);
end;

procedure TFMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if PrevendaConnection.Connected then
    PrevendaConnection.Connected := False;
  if Assigned(Venda) then
    FreeAndNil(Venda);
end;

procedure TFMain.FormCreate(Sender: TObject);
begin
  if not PrevendaConnection.Connected then
    PrevendaConnection.Connected := True;
  if not Assigned(Venda) then
    Venda := TVenda.Create;
  PreencheGrupos;
end;

procedure TFMain.LimpaTabControl(vTab: TTabControl);
var
  i, j: Integer;
  c: TControl;
begin
  for i := (vTab.TabCount - 1) downto 0 do
  begin
    {for j := (vTab.Tabs[i].ControlsCount - 1) downto 0 do
    begin
      c := vTab.Tabs[i].Controls[j];
      c.Free;
    end;}
    vTab.Tabs[i].Free;
  end;
  vTab.Repaint;
end;

procedure TFMain.PreencheGrupos;
var
  vSecao: String;
begin
  try
    if PrevendaConnection.Connected then
    begin
      try
        GrupoTable.Connection := PrevendaConnection;
        GrupoTable.Close;
        GrupoTable.SQL.Text := 'SELECT * FROM grupo';
        GrupoTable.Open;
        LimpaTabControl(TabControlGrupo);
        if not GrupoTable.IsEmpty then
        begin
          GrupoTable.SaveToFile('grupos.adb', sfBinary);
          if not Assigned(GrupoThread) then
            GrupoThread := TPreencheItens.Create;
          try
            with GrupoThread do
            begin
              Tabela := 'grupos';
              Tab := TabControlGrupo;
              Start;
            end;
          except on EConvertError do
            begin
              GrupoThread.Free;
              ShowMessage('Erro.');
            end;
          end;
          GrupoTable.First;
          vSecao := GrupoTable.FieldByName('NOME').AsString;
          //AtualizaProdutos(vSecao);
        end;
        GrupoTable.Close;
      finally
        TabControlGrupo.ActiveTab := TabControlGrupo.Tabs[0];
      end;
    end;
  except
    raise Exception.Create('Error Message');
  end;
end;

procedure TFMain.AtualizaProdutos(vSecao: String);
begin
  if vSecao <> '' then
  begin
    try
      if PrevendaConnection.Connected then
      begin
        try
          ProdutoTable.Connection := PrevendaConnection;
          ProdutoTable.Close;
          ProdutoTable.SQL.Text := 'SELECT * FROM produto' +
               ' WHERE GRUPO = :pSecao';
          ProdutoTable.ParamByName('pSECAO').AsString := vSecao;
          ProdutoTable.Open;
          LimpaTabControl(TabControlProduto);
          if not ProdutoTable.IsEmpty then
          begin
            ProdutoTable.SaveToFile('produtos.adb', sfBinary);
            if not Assigned(ProdutoThread) then
              ProdutoThread := TPreencheItens.Create;
            try
              with ProdutoThread do
              begin
                Tabela := 'produtos';
                Tab := TabControlProduto;
                ListaVenda := Venda.ListaVendaItem;
                Start;
              end;
            except on EConvertError do
              begin
                ProdutoThread.Free;
                ShowMessage('Erro.');
              end;
            end;
          end;
          ProdutoTable.Close;
        finally
          TabControlProduto.ActiveTab := TabControlProduto.Tabs[0];
        end;
      end;
    except
      raise Exception.Create('Error Message');
    end;
  end;
end;

procedure TFMain.CriaItem(vX, vY: Integer; vTexto: String; vItem: TItem;
  vTab: TTabItem; vControl: TTabControl);
var
  itemAdd: TPanel;
begin
  itemAdd := TPanel.Create(vTab);
  itemAdd.Parent := vTab;
  itemAdd.Height := 80;
  itemAdd.Width := 160;
  itemAdd.Position.X := vX;
  itemAdd.Position.Y := vY;
  if vTab <> nil then
    itemAdd.Data := TObject(vItem);
  if vControl = TabControlGrupo then
  begin
    itemAdd.StyleLookup := 'GrupoItem';
    itemAdd.StylesData['text'] := vTexto;
    itemAdd.StylesData['image.OnClick'] := TValue.From<TNotifyEvent>(DoGrupoClick); // set OnClick value
    itemAdd.StylesData['text.OnClick'] := TValue.From<TNotifyEvent>(DoGrupoClick); // set OnClick value
  end else
  if vControl = TabControlProduto then
  begin
    itemAdd.StyleLookup := 'CustomItem';
    if vItem <> nil then
    begin
      if Length(vItem.Descricao) > 12 then
      begin
        itemAdd.StylesData['text.Margins.Left'] := 3;
        itemAdd.StylesData['text.Margins.Right'] := 3;
      end
      else if Length(vItem.Descricao) > 7 then
      begin
        itemAdd.StylesData['text.Margins.Left'] := 10;
        itemAdd.StylesData['text.Margins.Right'] := 10;
      end else
      begin
        itemAdd.StylesData['text.Margins.Left'] := 30;
        itemAdd.StylesData['text.Margins.Right'] := 30;
      end;
      itemAdd.TagString := vItem.ToJSONString;
      //itemAdd.TagString := TJson.ObjectToJsonString(vItem);
    end;
    itemAdd.OnClick := ItemClick;
    //itemAdd.ItemData.Bitmap := Image1.Bitmap;
    itemAdd.StylesData['text'] := vItem.Descricao;
    itemAdd.StylesData['valor'] := FormatFloat('R$ ,.00####',vItem.Valor1);
    itemAdd.StylesData['visible'] := True;
    itemAdd.StylesData['info.Visible'] := vItem.Sequencia > -1;
    if vItem.Quantidade > 0 then
      itemAdd.StylesData['quantidade'] := FormatFloat(',.######', vItem.Quantidade)
    else
      itemAdd.StylesData['quantidade'] := '';
  end;
end;

procedure TFMain.DoGrupoClick(Sender: TObject);
var
  Item : TPanel;
begin
  if Assigned(ProdutoThread) then
  begin
    ProdutoThread.Terminate;
    ProdutoThread.WaitFor;
    FreeAndNil(ProdutoThread);
  end;
  Item := TPanel(FindItemParent(Sender as TFmxObject,TPanel));
  if Assigned(Item) then
    AtualizaProdutos(Item.StylesData['text'].AsString);
end;

procedure TFMain.ItemClick(Sender: TObject);
var
  item : TPanel;
  i: TItem;
  itemAdd: TListViewItem;
begin
  if not Assigned(Sender) then
    Exit;
  item := Sender as TPanel;
  if Assigned(item) then
  begin
    i := TItem.JSONStringToObj<TItem>(item.TagString);
    //i := TJson.JsonToObject<TItem>(item.TagString);
    i.Quantidade := i.Quantidade + 1;
    Item.StylesData['info.Visible'] := True;
    Item.StylesData['quantidade'] := FormatFloat(',.######',i.Quantidade);
{$IFDEF MSWINDOWS}
    ListViewItens.BeginUpdate;
    if i.Sequencia <> -1 then
    begin
      itemAdd := ListViewItens.Items[i.Sequencia];
    end else
    begin
      itemAdd := ListViewItens.Items.Add;
      i.Sequencia := itemAdd.Index;
      itemAdd.Data['cod'] := i.CodigoInterno;
    end;
    itemAdd.Data['qtd'] := i.Quantidade;
    itemAdd.Text := i.Descricao + ' - ' + ' ' + FormatFloat(',.######', i.Quantidade) +
     ' x ' + FormatFloat('R$ ,.00####',i.Valor1);
    ListViewItens.EndUpdate;
    item.TagString := i.ToJSONString;
    if not Assigned(Venda) then
      Venda := TVenda.Create;
    Venda.VendeItem(i, 1);
    //itemAdd.TagString := TJson.ObjectToJsonString(i);
{$ENDIF}
  end;
end;

end.
