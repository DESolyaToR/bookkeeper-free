unit cur_add;

{$mode delphi}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Dialogs, ButtonPanel,
  StdCtrls, ComCtrls, Buttons, ExtCtrls, Grids, CurrencyEdit, MyTools,
  SQLiteTable3;

type

  { TCurAddForm }

  TCurAddForm = class(TForm)
  ButtonPanel1: TButtonPanel;
  KursCurEdit: TCurrencyEdit;
  NameCurEdit: TEdit;
  AbbrCurEdit: TEdit;
  GroupBox1: TGroupBox;
  Label1: TLabel;
  Label2: TLabel;
  Label3: TLabel;
  MoreButton: TSpeedButton;
  CurConstGrid: TStringGrid;
  UpdateCurButton: TSpeedButton;
  ToolBar1: TToolBar;
  procedure CurConstGridClick(Sender: TObject);
  procedure FormShow(Sender: TObject);
  procedure KursCurEditChange(Sender: TObject);
  procedure NameCurEditKeyPress(Sender: TObject; var Key: char);
  procedure OKButtonClick(Sender: TObject);
  procedure MoreButtonClick(Sender: TObject);
  procedure UpdateCurButtonClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  CurAddForm: TCurAddForm;

implementation

uses Main;
{$R *.lfm}

procedure TCurAddForm.FormShow(Sender: TObject);
var
  main_table: TSQLiteTable;
begin
 CurConstGrid.Visible:=false;

 if Add_flag=false then
  begin
   // Загрузка данных
   main_table:=SQL_db.GetTable('SELECT * FROM valut WHERE id='+MainForm.CurGrid.Cells[0, MainForm.CurGrid.Row]+' LIMIT 1;');
   NameCurEdit.Text:=main_table.FieldAsString('name');
   AbbrCurEdit.Text:=main_table.FieldAsString('abbr');
   KursCurEdit.Text:=main_table.FieldAsString('kurs');

   Caption:='Изменение записи';
   ButtonPanel1.OKButton.Caption:='Изменить';
  end
 else
  begin
   Caption:='Добавление новой записи';
   ButtonPanel1.OKButton.Caption:='Добавить';
   NameCurEdit.Text:='';
   AbbrCurEdit.Text:='';
   KursCurEdit.Value:=0;
  end;
 ButtonPanel1.OKButton.Enabled:=false;
end;

procedure TCurAddForm.KursCurEditChange(Sender: TObject);
begin
 if (KursCurEdit.Value<=0) or (Length(AbbrCurEdit.Text)<1) or (Length(NameCurEdit.Text)<=2)
  then ButtonPanel1.OKButton.Enabled:=false
  else ButtonPanel1.OKButton.Enabled:=true;
end;

procedure TCurAddForm.NameCurEditKeyPress(Sender: TObject; var Key: char);
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

// Выбор валюты из таблицы готовых
procedure TCurAddForm.CurConstGridClick(Sender: TObject);
begin
 if (CurConstGrid.Cells[0, CurAddForm.CurConstGrid.Row]='0')
 then
  begin
   UpdateCurButton.Enabled:=false;
   CurConstGrid.Visible:=false;

   NameCurEdit.Text:='';
   AbbrCurEdit.Text:='';
   KursCurEdit.Value:=0;
  end
 else
  begin
   NameCurEdit.Text:=CurConstGrid.Cells[1, CurAddForm.CurConstGrid.Row];
   AbbrCurEdit.Text:=CurConstGrid.Cells[0, CurAddForm.CurConstGrid.Row];

   CurConstGrid.Visible:=false;
   UpdateCurButton.Enabled:=true;

   NameCurEdit.Enabled:=false;
   AbbrCurEdit.Enabled:=false;
  end;
end;

procedure TCurAddForm.OKButtonClick(Sender: TObject);
var
 valut_ID: string;
begin
 ButtonPanel1.OKButton.Enabled:=false;
 // Обновление записи в БД
 SQL_db.BeginTransaction;
 // В режиме редактирования ID берём из таблицы
 if not Add_flag
  then valut_ID:=MainForm.CurGrid.Cells[0, MainForm.CurGrid.Row]
  // В режиме добавления нового пользователя - не присваиваем (его определит MySQL)
  else
   begin
    // Ищем максимальный индекс
    valut_ID:=IntToStr(SQL_db.GetMaxValue('valut', 'id')+1);
    // Вставляем новую строку (с заданными ID и категорий)
    SQL_db.ExecSQL('INSERT INTO valut (id, name, abbr, kurs) VALUES ("'+valut_ID+'", "", "", "")');
   end;

 SQL_db.ExecSQL('UPDATE valut SET name = "'+NameCurEdit.Text+'" WHERE id ='+valut_ID);
 SQL_db.ExecSQL('UPDATE valut SET abbr = "'+AbbrCurEdit.Text+'" WHERE id ='+valut_ID);
 SQL_db.ExecSQL('UPDATE valut SET kurs = "'+KursCurEdit.Text+'" WHERE id ='+valut_ID);
 SQL_db.Commit;

 // Обновление сетки в главном окне
 MainForm.GetCurList;
end;

procedure TCurAddForm.MoreButtonClick(Sender: TObject);
begin
 CurConstGrid.Visible:=true;
end;

procedure TCurAddForm.UpdateCurButtonClick(Sender: TObject);
begin
 KursCurEdit.Value:=GetCurFromWeb(AbbrCurEdit.Text);
end;
end.
