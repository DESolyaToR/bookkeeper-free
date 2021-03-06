unit cur_trans;

{$mode delphi}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ButtonPanel, ExtCtrls, ZVDateTimePicker, CurrencyEdit, splash,
  SQLiteTable3, Windows;

type

  { TTransCurForm }

  TTransCurForm = class(TForm)
   ButtonPanel1: TButtonPanel;
   CommLabel: TLabel;
   CurRadioButton: TRadioButton;
   CommEdit: TCurrencyEdit;
   SumEdit: TCurrencyEdit;
   Label4: TLabel;
   Label5: TLabel;
   Label7: TLabel;
   NoRadioButton: TRadioButton;
   OutBillBox: TComboBox;
   InBillBox: TComboBox;
   Panel1: TPanel;
   ProcRadioButton: TRadioButton;
   GroupBox1: TGroupBox;
   Label1: TLabel;
   Label2: TLabel;
   Label3: TLabel;
   TransDateTimePicker: TZVDateTimePicker;
   procedure FormShow(Sender: TObject);
   procedure InBillBoxDrawItem(Control: TWinControl; Index: Integer;
    ARect: TRect; State: TOwnerDrawState);
   procedure NoRadioButtonClick(Sender: TObject);
   procedure OKButtonClick(Sender: TObject);
   procedure OutBillBoxChange(Sender: TObject);
   procedure OutBillBoxDrawItem(Control: TWinControl; Index: Integer;
    ARect: TRect; State: TOwnerDrawState);
   procedure SumEditChange(Sender: TObject);
  private
  public
   function SelectValut(bill_ID: integer): string;
  end; 

var
  TransCurForm: TTransCurForm;

  balans_out: currency;

implementation

uses Main, doh_add;

{$R *.lfm}

{ TTransCurForm }

procedure TTransCurForm.FormShow(Sender: TObject);
var
 i: integer;
 main_table: TSQLiteTable;
begin
  OutBillBox.Items.Clear;
  InBillBox.Items.Clear;
  TransDateTimePicker.MaxDate:=Date;
  CommEdit.Text:='';
  CommLabel.Caption:='';

  if mode=amChlen
   then main_table:=SQL_db.GetTable('SELECT id, name FROM bill WHERE user='+IntToStr(user_id))
   else main_table:=SQL_db.GetTable('SELECT id, name FROM bill');

   if main_table.Count<>0 then
   begin
    // Проход по списку пользователей
    for i:=0 to main_table.Count-1 do
     begin
      OutBillBox.Items.Add(main_table.FieldAsString('name')+'|'+TransCurForm.SelectValut(main_table.FieldAsInteger('id')));
      OutBillBox.Items.Objects[i]:=TObject(main_table.FieldAsInteger('id'));

      InBillBox.Items.Add(main_table.FieldAsString('name')+'|'+TransCurForm.SelectValut(main_table.FieldAsInteger('id')));
      InBillBox.Items.Objects[i]:=TObject(main_table.FieldAsInteger('id'));

      main_table.Next;
     end;
   end;

  OutBillBox.ItemIndex:=0;
  InBillBox.ItemIndex:=0;

  SumEdit.Value:=0;
  CommEdit.Text:='0';
  TransDateTimePicker.Date:=Date;
  OutBillBoxChange(self);
  NoRadioButtonClick(self);

  Caption:='Перевод средств';
  ButtonPanel1.OKButton.Caption:='Перевести';
  ButtonPanel1.OKButton.Enabled:=false;
end;

procedure TTransCurForm.InBillBoxDrawItem(Control: TWinControl; Index: Integer;
 ARect: TRect; State: TOwnerDrawState);
begin
 AddDohForm.BillBoxDraw(Control, Index, ARect, State);
end;

procedure TTransCurForm.NoRadioButtonClick(Sender: TObject);
begin
  CurRadioButton.Caption:=SelectValut(Integer(OutBillBox.Items.Objects[OutBillBox.ItemIndex]));
  if NoRadioButton.Checked=true
  then
   begin
    CommEdit.Visible:=false;
    CommLabel.Visible:=false;
   end
  else
   begin
    CommEdit.Visible:=true;
    CommLabel.Visible:=true;
    if ProcRadioButton.Checked=true
    then CommLabel.Caption:='%'
    else
     begin
      CommLabel.Caption:=CurRadioButton.Caption;
     end;
  end;
end;

procedure TTransCurForm.OKButtonClick(Sender: TObject);
var
 doh_ID, ras_ID: string;
 temp_balans, comm, balans_in: real;
 main_table: TSQLiteTable;
begin
 ButtonPanel1.OKButton.Enabled:=false;

 temp_balans:=0;
 comm:=0;

 temp_balans:=SumEdit.Value;
 comm:=StrToCurr(CommEdit.Text);
 if ProcRadioButton.Checked=true
  then
   begin
    comm:=temp_balans*comm/100;
    temp_balans:=temp_balans+comm;
   end;
 if CurRadioButton.Checked=true then temp_balans:=temp_balans+comm;

 // Обновление записи в БД
 SQL_db.BeginTransaction;

 // Ищем максимальный индекс
 doh_ID:=IntToStr(SQL_db.GetMaxValue('dohod', 'id')+1);
 // Вставляем новую строку (с заданными ID и категорий)
 SQL_db.ExecSQL('INSERT INTO dohod (id, cat, bill, sum, date, sourse, memo) VALUES ("'+doh_ID+'", 0, "", "", "", "", "")');

 // Записываем данные в БД
 SQL_db.ExecSQL('UPDATE bill SET balans = "'+CurrToStr(balans_out-temp_balans)+'" WHERE id ='+IntToStr(Integer(OutBillBox.Items.Objects[OutBillBox.ItemIndex])));

 main_table:=SQL_db.GetTable('SELECT balans FROM bill WHERE id='+IntToStr(Integer(InBillBox.Items.Objects[InBillBox.ItemIndex])));
 balans_in:=StrToCurr(main_table.FieldAsString('balans'));
 main_table:=SQL_db.GetTable('SELECT valut FROM bill WHERE id='+IntToStr(Integer(InBillBox.Items.Objects[InBillBox.ItemIndex])));

 SQL_db.ExecSQL('UPDATE bill SET balans = "'+CurrToStr(balans_in+MainForm.DrawValut(Integer(OutBillBox.Items.Objects[OutBillBox.ItemIndex]),main_table.FieldAsInteger('valut'), SumEdit.Value))+'" WHERE id ='+IntToStr(Integer(InBillBox.Items.Objects[InBillBox.ItemIndex])));

 SQL_db.ExecSQL('UPDATE dohod SET bill = "'+IntToStr(Integer(InBillBox.Items.Objects[InBillBox.ItemIndex]))+'" WHERE id ='+doh_ID);
 SQL_db.ExecSQL('UPDATE dohod SET sum = "'+SumEdit.Text+'" WHERE id ='+doh_ID);
 SQL_db.ExecSQL('UPDATE dohod SET date = "'+IntToStr(DateTimeToUnixTime(TransDateTimePicker.Date))+'" WHERE id ='+doh_ID);
 SQL_db.ExecSQL('UPDATE dohod SET memo = "Перевод средств со счёта '+OutBillBox.Text+'" WHERE id ='+doh_ID);

 // Ищем максимальный индекс
 ras_ID:=IntToStr(SQL_db.GetMaxValue('rashod', 'id')+1);

  // Вставляем новую строку (с заданными ID и категорий)
  SQL_db.ExecSQL('INSERT INTO rashod (id, cat, bill, price, num, izm, basket, date, item, agent, memo) VALUES ("'+ras_ID+'", 0, "", "", "", "", -1, "", "", "", "")');
  SQL_db.ExecSQL('UPDATE rashod SET bill = "'+IntToStr(Integer(OutBillBox.Items.Objects[OutBillBox.ItemIndex]))+'" WHERE id ='+ras_ID);
  SQL_db.ExecSQL('UPDATE rashod SET price = "'+SumEdit.Text+'" WHERE id ='+ras_ID);
  SQL_db.ExecSQL('UPDATE rashod SET num = 1 WHERE id ='+ras_ID);
  SQL_db.ExecSQL('UPDATE rashod SET izm = -1 WHERE id ='+ras_ID);
  SQL_db.ExecSQL('UPDATE rashod SET date = "'+IntToStr(DateTimeToUnixTime(TransDateTimePicker.Date))+'" WHERE id ='+ras_ID);
  SQL_db.ExecSQL('UPDATE rashod SET memo = "Перевод средств на счёт '+InBillBox.Text+'" WHERE id ='+ras_ID);

  if comm<>0 then
  begin
   ras_ID:=IntToStr(StrToInt(ras_ID)+1);
   SQL_db.ExecSQL('INSERT INTO rashod (id, cat, bill, price, num, izm, basket, date, item, agent, memo) VALUES ("'+ras_ID+'", 1, "", "", "", "", -1, "", "", "", "")');
   SQL_db.ExecSQL('UPDATE rashod SET bill = "'+IntToStr(Integer(OutBillBox.Items.Objects[OutBillBox.ItemIndex]))+'" WHERE id ='+ras_ID);
   SQL_db.ExecSQL('UPDATE rashod SET price = "'+CurrToStr(comm)+'" WHERE id ='+ras_ID);
   SQL_db.ExecSQL('UPDATE rashod SET num = 1 WHERE id ='+ras_ID);
   SQL_db.ExecSQL('UPDATE rashod SET izm = -1 WHERE id ='+ras_ID);
   SQL_db.ExecSQL('UPDATE rashod SET date = "'+IntToStr(DateTimeToUnixTime(TransDateTimePicker.Date))+'" WHERE id ='+ras_ID);
   SQL_db.ExecSQL('UPDATE rashod SET memo = "Комиссия за перевод средств" WHERE id ='+ras_ID);
  end;
 SQL_db.Commit;

 // Обновление сетки в главном окне
 MainForm.GetBillList;
 MainForm.GetMainTable;
 //MainForm.GetRasTable;
 MainForm.OutputBalans;
end;

procedure TTransCurForm.OutBillBoxChange(Sender: TObject);
var
 main_table: TSQLiteTable;
begin
 main_table:=SQL_db.GetTable('SELECT balans FROM bill WHERE id='+IntToStr(Integer(OutBillBox.Items.Objects[OutBillBox.ItemIndex])));
 balans_out:=StrToCurr(main_table.FieldAsString('balans'));
 if balans_out<0
  then Label5.Caption:='Нет доступных средств'
  else Label5.Caption:='Доступно: '+CurrToStr(balans_out)+' '+SelectValut(Integer(OutBillBox.Items.Objects[OutBillBox.ItemIndex]));

 SumEditChange(self);
 NoRadioButtonClick(self);
 //
 MainForm.UserComboBoxSelect(self);
end;

// Отрисовка ComboBox со списком счётов
procedure TTransCurForm.OutBillBoxDrawItem(Control: TWinControl; Index: Integer; ARect: TRect; State: TOwnerDrawState);
begin
 AddDohForm.BillBoxDraw(Control, Index, ARect, State);
end;

procedure TTransCurForm.SumEditChange(Sender: TObject);
begin
  if (SumEdit.Value<=0) or (OutBillBox.ItemIndex=InBillBox.ItemIndex) or (SumEdit.Value>balans_out)
  then
   begin
    ButtonPanel1.OKButton.Enabled:=false;
    SumEdit.Font.Color:=clRed;
   end
  else
   begin
    ButtonPanel1.OKButton.Enabled:=true;
    SumEdit.Font.Color:=clBlack;
   end;
end;

function TTransCurForm.SelectValut(bill_ID: integer): string;
var
 SQL_table_2: TSQLiteTable;
 valut_ID: integer;
begin
  // Загрузка данных
  SQL_table_2:=SQL_db.GetTable('SELECT valut FROM bill WHERE id='+IntToStr(bill_ID));
  valut_ID:=SQL_table_2.FieldAsInteger('valut');

  SQL_table_2:=SQL_db.GetTable('SELECT abbr FROM valut WHERE id='+IntToStr(valut_ID));
  Result:=SQL_table_2.FieldAsString('abbr');
end;
end.
