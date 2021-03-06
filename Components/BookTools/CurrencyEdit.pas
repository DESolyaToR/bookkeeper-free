unit CurrencyEdit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, FileUtil, StdCtrls, LCLType;

type

  { TCurrencyEdit }

  TCurrencyEdit = class(TEdit)
  private
    constructor Create(AOwner: TEdit);
  protected
    { Protected declarations }
  public
    procedure CreateParams(var Params: TCreateParams); override;
    procedure KeyPress(var Key: Char); override;
    procedure Change; override;
    procedure SetValue(val: currency);
     function GetValue: currency;
  published
    property Value: Currency read GetValue write SetValue;
  end;

procedure Register;

implementation

constructor TCurrencyEdit.Create(AOwner: TEdit);
begin
  inherited Create(AOwner);
end;

procedure TCurrencyEdit.CreateParams(var Params: TCreateParams);
begin
 inherited CreateParams(Params);
 Text:='0'; // задаём начальное значение
 //SelStart:=Length(Text); // перевод курсора в конец строки
end;

procedure TCurrencyEdit.KeyPress(var Key: Char);
begin
 inherited KeyPress(Key);
 //
 if (Key='/') or (Key='?') or (Key='<') then Key:='.';
 if (SysToUTF8(key)='б') or (SysToUTF8(key)='Б') or (SysToUTF8(key)='ю') or (SysToUTF8(key)='Ю') then Key:='.';

 // фильтрация вводимых символов
 case Key of
  // разрешаем ввод цифр
  '0'..'9': key:=key;
  // разрешаем ввод всего, что похоже на десятичный разделитель
  '.', ',': //with (Owner as TEdit) do
   begin
    // запрещаем ввод более 1 десятичного разделителя
    if (Pos('.', Text)=0) and (Pos(',', Text)=0)
     then key:='.'
     else key:=#0;
   end;
  // разрешаем использование клавиш BackSpace и Delete
   #8: key:=key;
  // "гасим" все прочие клавиши
  else key:=#0;
 end; // case
end;

procedure TCurrencyEdit.Change;
var
  val: currency;
begin
 inherited Change;

 // проверка входящего значения
 if TryStrToCurr(Text, val)=false then text:='0';

 // при попытке полностью очистить поле - заполняем его нулём
 if Length(Text)<=0 then
  begin
   Text:='0';
   SelStart:=Length(Text); // перевод курсора в конец строки
  end
 else
 // убираем ведущие нули (если сразу после них нет десятичного разделителя)
 if (Length(Text)>1) and (Text[1]='0') and ((Text[2]<>'.')) then
  begin
   Text:=Copy(Text, 2, Length(text));
   SelStart:=Length(Text); // перевод курсора в конец строки
  end
 else if (Length(Text)=1) then SelStart:=Length(Text);

end;

procedure TCurrencyEdit.SetValue(val: currency);
var
  fs: TFormatSettings;
begin
  fs.DecimalSeparator:='.';
  Text:= CurrToStr(val, fs);// FValue;
end;

function TCurrencyEdit.GetValue: currency;
var
  val: currency;
begin
 if TryStrToCurr(Text, val)=true then Result:=StrToCurr(Text)
 else
  begin
   text:='0';
   Result:=0;
  end;
end;

procedure Register;
begin
  {$I CurrencyEdit_icon.lrs}
  RegisterComponents('BookTools',[TCurrencyEdit]);
end;

end.
