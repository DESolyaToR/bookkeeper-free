unit doh_cat_add;

{$mode delphi}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ComCtrls, ButtonPanel, MyTools, SQLiteTable3;

type

  { TAddCatForm }

  TAddCatForm = class(TForm)
   ButtonPanel1: TButtonPanel;
   CatComboBox: TComboBox;
   NameDohEdit: TEdit;
   GroupBox1: TGroupBox;
   Label1: TLabel;
   Label2: TLabel;
   procedure CancelButtonClick(Sender: TObject);
   procedure CatComboBoxChange(Sender: TObject);
   procedure NameDohEditChange(Sender: TObject);
   procedure NameDohEditKeyPress(Sender: TObject; var Key: char);
   procedure OKButtonClick(Sender: TObject);
  private
    { private declarations }
  public
   procedure AddCat(TreeCat: TTreeView; Table: string);
  end; 

var
  AddCatForm: TAddCatForm;

  TreeCat2: TTreeView;
  Table2: string;

implementation

uses Main;
{$R *.lfm}

{ TAddCatForm }

procedure TAddCatForm.NameDohEditChange(Sender: TObject);
begin
  if Length(NameDohEdit.Text)<=2
  then ButtonPanel1.OKButton.Enabled:=false
  else ButtonPanel1.OKButton.Enabled:=true;
end;

procedure TAddCatForm.NameDohEditKeyPress(Sender: TObject; var Key: char);
const
 lq: char = #171;
 rq: char = #187;
var
 NumOfQuotes: integer;
begin
 //
 if Key='"' then
  begin
   // Определяем тип поля редактирования и подсчитываем количество кавычек в нём
   if (Sender is TEdit)
    then NumOfQuotes:=CntChRepet((Sender as TEdit).Text, lq)+CntChRepet((Sender as TEdit).Text, rq);

   if odd(NumOfQuotes)
    then Key:=rq
    else Key:=lq;
  end;
end;

procedure TAddCatForm.CancelButtonClick(Sender: TObject);
begin
 Close;
end;

procedure TAddCatForm.CatComboBoxChange(Sender: TObject);
begin
 ButtonPanel1.OKButton.Enabled:=true;
end;

procedure TAddCatForm.OKButtonClick(Sender: TObject);
var
 cat_ID: string;
begin
 if Length(NameDohEdit.Text)<=2 then exit;
 ButtonPanel1.OKButton.Enabled:=false;

 // Обновление записи в БД
 SQL_db.BeginTransaction;
 // В режиме редактирования ID берём из таблицы
 if not Add_flag
 then cat_ID:=IntToStr(Integer(TreeCat2.Selected.Data))
 // В режиме добавления нового пользователя - не присваиваем (его определит MySQL)
  else
   begin
    // Ищем максимальный индекс
    cat_ID:=IntToStr(SQL_db.GetMaxValue(Table2, 'id')+1);
    // Вставляем новую строку (с заданными ID и категорий)
    SQL_db.ExecSQL('INSERT INTO '+Table2+' (id, name, parent, cat_order) VALUES ("'+cat_ID+'", "", "", "")');
   end;

  SQL_db.ExecSQL('UPDATE '+Table2+' SET name = "'+NameDohEdit.Text+'" WHERE id ='+cat_ID);
  if (Cat_flag=true)
   then SQL_db.ExecSQL('UPDATE '+Table2+' SET parent = -1 WHERE id ='+cat_ID)
   else SQL_db.ExecSQL('UPDATE '+Table2+' SET parent = "'+IntToStr(Integer(CatComboBox.Items.Objects[CatComboBox.ItemIndex]))+'" WHERE id ='+cat_ID);
  SQL_db.ExecSQL('UPDATE '+Table2+' SET cat_order = id WHERE id ='+cat_ID);

  SQL_db.Commit;

  if not Add_flag
   then TreeCat2.Selected.Text:=NameDohEdit.Text
   else MainForm.GetDohList(TreeCat2,Table2);
  Close;
end;

procedure TAddCatForm.AddCat(TreeCat: TTreeView; Table: string);
var
  i, CurID: integer;
  main_table: TSQLiteTable;
begin
 // показываем\скрываем компоненты
 Label2.Visible:=(Cat_flag=false);
 CatComboBox.Visible:=(Cat_flag=false);

 // очистка списка категорий
 CatComboBox.Items.Clear;

 // Выборка из таблицы категорий доходов
 if (Cat_flag=false) then
  begin
   if (Table='cat_doh') then GroupBox1.Caption:='Данные о подкатегории дохода'
   else GroupBox1.Caption:='Данные о подкатегории расхода';

   // ID категории, выбранной в главном окне
   if (TreeCat.Selected.Parent=nil)
    then CurID:=Integer(TreeCat.Selected.Data)
    else CurID:=Integer(TreeCat.Selected.Parent.Data);
   // Заполняем список категорий
   if Table='cat_ras'
    then main_table:=SQL_db.GetTable('SELECT * FROM '+Table+' WHERE (parent=-1) and (id!=0) and (id!=1)')
    else main_table:=SQL_db.GetTable('SELECT * FROM '+Table+' WHERE (parent=-1) and (id!=0)');

   for i:=0 to main_table.Count-1 do
    begin
     CatComboBox.Items.Add(main_table.FieldAsString('name'));
     CatComboBox.Items.Objects[i]:=TObject(main_table.FieldAsInteger('id'));
     // Выделение текущего пункта
     if main_table.FieldAsInteger('id')=CurID then CatComboBox.ItemIndex:=i;
     //
     main_table.Next;
    end; // for
  end // if cat_flag
 else
 if (Table='cat_doh') then GroupBox1.Caption:='Данные о категории дохода'
 else GroupBox1.Caption:='Данные о категории расхода';

 // Если редактируем существующую запись
 if Add_flag=false then
  begin
   CurID:=Integer(TreeCat.Selected.Data);
   main_table:=SQL_db.GetTable('SELECT * FROM '+Table+' WHERE id='+IntToStr(CurID));
   NameDohEdit.Text:=main_table.FieldAsString('name');
   Caption:='Изменение записи';
   ButtonPanel1.OKButton.Caption:='Изменить';
  end
 // Если добавляем новую запись
 else
  begin
   Caption:='Добавление новой записи';
   ButtonPanel1.OKButton.Caption:='Добавить';
   NameDohEdit.Text:='';
  end;

  ButtonPanel1.OKButton.Enabled:=false;

  AddCatForm.Show;

  TreeCat2:=TreeCat;
  Table2:=Table;
end;

end.

