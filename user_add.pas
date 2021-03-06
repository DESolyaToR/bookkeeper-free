unit user_add;

{$mode delphi}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ButtonPanel, SQLiteTable3, md5, MyTools;

type

  { TUserAddForm }

  TUserAddForm = class(TForm)
   ButtonPanel1: TButtonPanel;
   StatusComboBox: TComboBox;
   NameUserEdit: TEdit;
   PasUserEdit: TEdit;
   GroupBox1: TGroupBox;
   Label1: TLabel;
   Label2: TLabel;
   Label3: TLabel;
   procedure FormShow(Sender: TObject);
   procedure NameUserEditChange(Sender: TObject);
   procedure NameUserEditKeyPress(Sender: TObject; var Key: char);
   procedure OKButtonClick(Sender: TObject);
   procedure PasUserEditChange(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  UserAddForm: TUserAddForm;

implementation

uses Main;
{$R *.lfm}

{ TUserAddForm }

procedure TUserAddForm.FormShow(Sender: TObject);
var
  tmp_table: TSQLiteTable;
  main_table: TSQLiteTable;
begin

 if Add_flag=false then
  begin
   // Загрузка данных
   main_table:=SQL_db.GetTable('SELECT * FROM users WHERE id='+MainForm.UserGrid.Cells[0, MainForm.UserGrid.Row]+' LIMIT 1;');
   // Заполняем поле "имя"
   NameUserEdit.Text:=main_table.FieldAsString('name');
   // заполняем поле "пароль"
   if (main_table.FieldAsString('pass')='0')
    then PasUserEdit.Text:=''
    else PasUserEdit.Text:='*****'; // необходимо указать, что число символов - номинальное
   // выбираем нужный статус
   tmp_table:=SQL_db.GetTable('SELECT id FROM users WHERE type=0');
   if (tmp_table.Count<=1) and (main_table.FieldAsInteger('type')=0) then
    begin
     // устанавливаем неизменяемый статус "Глава семьи" для единственного пользователя с таким статусом
     StatusComboBox.ItemIndex:=0;
     StatusComboBox.Enabled:=false;
     StatusComboBox.Hint:='Как минимум 1 пользователь должен иметь статус "Глава семьи".';
    end
   else
    begin
     // Выбираем статус для прочих пользователей
     StatusComboBox.ItemIndex:=main_table.FieldAsInteger('type');
     StatusComboBox.Enabled:=true;
     StatusComboBox.Hint:='Статус определяет, какие из функций программы будут доступны пользователю.';
    end;

   Caption:='Изменение пользователя';
   ButtonPanel1.OKButton.Caption:='Изменить';
  end
 else
  begin
   Caption:='Добавление нового пользователя';
   ButtonPanel1.OKButton.Caption:='Добавить';
   NameUserEdit.Text:='';
   PasUserEdit.Text:='';
   StatusComboBox.ItemIndex:=1;
   StatusComboBox.Enabled:=true;
  end;
 ButtonPanel1.OKButton.Enabled:=false;
end;

procedure TUserAddForm.NameUserEditChange(Sender: TObject);
begin
   if Length(NameUserEdit.Text)<1
   then ButtonPanel1.OKButton.Enabled:=false
   else ButtonPanel1.OKButton.Enabled:=true;
end;

procedure TUserAddForm.NameUserEditKeyPress(Sender: TObject; var Key: char);
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

procedure TUserAddForm.PasUserEditChange(Sender: TObject);
begin
 if Add_flag=false then ButtonPanel1.OKButton.Enabled:=true;
end;

procedure TUserAddForm.OKButtonClick(Sender: TObject);
var
 user_ID_2, pas: string;
begin
 ButtonPanel1.OKButton.Enabled:=false;
   // Обновление записи в БД
   SQL_db.BeginTransaction;
   // В режиме редактирования ID берём из таблицы
   if not Add_flag
    then user_ID_2:=MainForm.UserGrid.Cells[0, MainForm.UserGrid.Row]
    // В режиме добавления нового пользователя - не присваиваем (его определит MySQL)
    else
     begin
      // Ищем максимальный индекс
      user_ID_2:=IntToStr(SQL_db.GetMaxValue('users', 'id')+1);
      // Вставляем новую строку (с заданными ID и категорий)
      SQL_db.ExecSQL('INSERT INTO users (id, name, pass, type) VALUES ("'+user_ID_2+'", "", "", "")');
     end;

   if Length(PasUserEdit.Text)<1
    then pas:='0'
    else pas:=MD5Print(MD5String(PasUserEdit.Text));

   SQL_db.ExecSQL('UPDATE users SET pass = "'+pas+'" WHERE id ='+user_ID_2);
   SQL_db.ExecSQL('UPDATE users SET name = "'+NameUserEdit.Text+'" WHERE id ='+user_ID_2);
   SQL_db.ExecSQL('UPDATE users SET type = "'+IntToStr(StatusComboBox.ItemIndex)+'" WHERE id ='+user_ID_2);
   SQL_db.Commit;

   // Обновление сетки в главном окне
   MainForm.GetUserList;
   // если редактируется текущий пользователь - обновляем заголовок
   if user_id=StrToInt(user_ID_2) then MainForm.SetFormCaption(NameUserEdit.Text);
end;
end.
