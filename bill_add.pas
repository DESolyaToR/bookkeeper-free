unit bill_add;

{$mode delphi}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ButtonPanel, ZVDateTimePicker, CurrencyEdit, SQLiteTable3, splash, MyTools;

type
  { TBillAddForm }

  TBillAddForm = class(TForm)
   ButtonPanel1: TButtonPanel;
   BeginBillEdit: TCurrencyEdit;
   BillMemo: TEdit;
   Label3: TLabel;
   Label4: TLabel;
   Label5: TLabel;
   Label6: TLabel;
   Label7: TLabel;
   TypeComboBox: TComboBox;
   UserComboBox: TComboBox;
   ValutComboBox: TComboBox;
   Label2: TLabel;
   NameBillEdit: TEdit;
   GroupBox1: TGroupBox;
   Label1: TLabel;
   BillDateTimePicker: TZVDateTimePicker;
   procedure BeginBillEditChange(Sender: TObject);
   procedure FormShow(Sender: TObject);
   procedure NameBillEditKeyPress(Sender: TObject; var Key: char);
   procedure OKButtonClick(Sender: TObject);
   procedure UserComboBoxChange(Sender: TObject);
  private
  public
  end;

var
  BillAddForm: TBillAddForm;

implementation

uses Main;
{$R *.lfm}

procedure TBillAddForm.FormShow(Sender: TObject);
var
 count, count_2, i: integer;
 temp_table: TSQLiteTable;
 bill_ID: string;
 main_table: TSQLiteTable;
begin
 UserComboBox.Items.Clear;
 ValutComboBox.Items.Clear;
 TypeComboBox.Items.Clear;
 BeginBillEdit.Enabled:=true;

 BillDateTimePicker.MaxDate:=Date;

 if mode=amChlen then
  begin
   main_table:=SQL_db.GetTable('SELECT * FROM users WHERE id='+IntToStr(user_id));
   with UserComboBox do
   begin
   Items.Add(main_table.FieldAsString('name'));
   Items.Objects[0]:=TObject(main_table.FieldAsInteger('id'));
   ItemIndex:=0;
   Enabled:=false;
   end;
  end
 else
 begin
  main_table:=SQL_db.GetTable('SELECT * FROM users');
  // Проход по списку счетов
  for i:=0 to main_table.Count-1 do
   begin
    UserComboBox.Items.Add(main_table.FieldAsString('name'));
    UserComboBox.Items.Objects[i]:=TObject(main_table.FieldAsInteger('id'));
    main_table.Next;
   end;
 UserComboBox.ItemIndex:=0;
 end;

 // Выборка из таблицы валют
 main_table:=SQL_db.GetTable('SELECT * FROM valut');
 // Проход по списку пользователей
 for i:=0 to main_table.Count-1 do
   begin
    ValutComboBox.Items.Add(main_table.FieldAsString('abbr'));
    ValutComboBox.Items.Objects[i]:=TObject(main_table.FieldAsInteger('id'));
    main_table.Next;
   end;
 ValutComboBox.ItemIndex:=0;

 // Выборка из таблицы типов счетов
 main_table:=SQL_db.GetTable('SELECT * FROM type_bill');
 // Проход по списку пользователей
 for i:=0 to main_table.Count-1 do
   begin
    TypeComboBox.Items.Add(main_table.FieldAsString('name'));
    TypeComboBox.Items.Objects[i]:=TObject(main_table.FieldAsInteger('id'));
    main_table.Next;
   end;
 TypeComboBox.ItemIndex:=0;

 if Add_flag=false then
  begin
   // Загрузка данных
   bill_ID:=MainForm.BillGrid.Cells[0, MainForm.BillGrid.Row];
   main_table:=SQL_db.GetTable('SELECT * FROM bill WHERE id='+bill_ID+' LIMIT 1;');

   NameBillEdit.Text:=main_table.FieldAsString('name');

   if mode<>amChlen then
   begin
   for i:=0 to UserComboBox.Items.Count-1 do
    if (Integer(UserComboBox.Items.Objects[i])=main_table.FieldAsInteger('user')) then
     begin
      UserComboBox.ItemIndex:=i;
      break;
     end;
   end;

   for i:=0 to TypeComboBox.Items.Count-1 do
    if (Integer(TypeComboBox.Items.Objects[i])=main_table.FieldAsInteger('type')) then
     begin
      TypeComboBox.ItemIndex:=i;
      break;
     end;

   for i:=0 to ValutComboBox.Items.Count-1 do
    if (Integer(ValutComboBox.Items.Objects[i])=main_table.FieldAsInteger('valut')) then
     begin
      ValutComboBox.ItemIndex:=i;
      break;
     end;

   BeginBillEdit.Value:=main_table.FieldAsDouble('begin');
   BillDateTimePicker.Date:=main_table.FieldAsDateTime('date');
   BillMemo.Text:=main_table.FieldAsString('memo');

   temp_table:=SQL_db.GetTable('SELECT id FROM rashod WHERE bill='+bill_ID);
   count:=temp_table.Count;
   temp_table:=SQL_db.GetTable('SELECT id FROM dohod WHERE bill='+bill_ID);
   count_2:=temp_table.Count;

   if (count>0) or (count_2>0)
   then BeginBillEdit.Enabled:=false;

   Caption:='Изменение записи';
   ButtonPanel1.OKButton.Caption:='Изменить';
  end
 else
  begin
   Caption:='Добавление новой записи';
   ButtonPanel1.OKButton.Caption:='Добавить';
   NameBillEdit.Text:='';
   BeginBillEdit.Value:=0;
   BillDateTimePicker.Date:=Date;
   BillMemo.Clear;
  end;
 ButtonPanel1.OKButton.Enabled:=false;
end;

procedure TBillAddForm.NameBillEditKeyPress(Sender: TObject; var Key: char);
const
 lq: char = #171;
 rq: char = #187;
var
 NumOfQuotes: integer;
begin
 //
 if Key='"' then
  begin
   NumOfQuotes:=CntChRepet(NameBillEdit.Text, lq)+CntChRepet(NameBillEdit.Text, rq);
   if odd(NumOfQuotes)
    then Key:=rq
    else Key:=lq;
  end
end;

procedure TBillAddForm.BeginBillEditChange(Sender: TObject);
begin
 if (BeginBillEdit.Value<=0) or (Length(NameBillEdit.Text)<=2)
  then ButtonPanel1.OKButton.Enabled:=false
  else ButtonPanel1.OKButton.Enabled:=true;
end;

procedure TBillAddForm.OKButtonClick(Sender: TObject);
var
 bill_ID: string;
begin
  ButtonPanel1.OKButton.Enabled:=false;
  // Обновление записи в БД
  SQL_db.BeginTransaction;
  // В режиме редактирования ID берём из таблицы
  if not Add_flag
   then bill_ID:=MainForm.BillGrid.Cells[0, MainForm.BillGrid.Row]
   // В режиме добавления нового пользователя - не присваиваем (его определит MySQL)
   else
    begin
     // Ищем максимальный индекс
     bill_ID:=IntToStr(SQL_db.GetMaxValue('bill', 'id')+1);
     // Вставляем новую строку (с заданными ID и категорий)
     SQL_db.ExecSQL('INSERT INTO bill (id, name, type, valut, begin, balans, user, date, memo) VALUES ("'+bill_ID+'", "", "", "", "", "", "", "", "")');
    end;

  SQL_db.ExecSQL('UPDATE bill SET name = "'+NameBillEdit.Text+'" WHERE id ='+bill_ID);
  SQL_db.ExecSQL('UPDATE bill SET type = "'+IntToStr(Integer(TypeComboBox.Items.Objects[TypeComboBox.ItemIndex]))+'" WHERE id ='+bill_ID);
  SQL_db.ExecSQL('UPDATE bill SET valut = "'+IntToStr(Integer(ValutComboBox.Items.Objects[ValutComboBox.ItemIndex]))+'" WHERE id ='+bill_ID);

  if BeginBillEdit.Enabled=true then
   begin
    SQL_db.ExecSQL('UPDATE bill SET begin = "'+BeginBillEdit.Text+'" WHERE id ='+bill_ID);
    SQL_db.ExecSQL('UPDATE bill SET balans = "'+BeginBillEdit.Text+'" WHERE id ='+bill_ID);
   end;

  SQL_db.ExecSQL('UPDATE bill SET user = "'+IntToStr(Integer(UserComboBox.Items.Objects[UserComboBox.ItemIndex]))+'" WHERE id ='+bill_ID);
  SQL_db.ExecSQL('UPDATE bill SET date = "'+IntToStr(DateTimeToUnixTime(BillDateTimePicker.Date))+'" WHERE id ='+bill_ID);
  SQL_db.ExecSQL('UPDATE bill SET memo = "'+BillMemo.Text+'" WHERE id ='+bill_ID);
  SQL_db.Commit;

  // Обновление сетки в главном окне
  MainForm.GetBillList;
end;

procedure TBillAddForm.UserComboBoxChange(Sender: TObject);
begin
 if Add_flag=false then ButtonPanel1.OKButton.Enabled:=true;
end;

end.
