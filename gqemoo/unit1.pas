unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  CheckLst, IniPropStorage, Process, DefaultTranslator, Menus, FileCtrl, Types;

type

  { TMainForm }

  TMainForm = class(TForm)
    ClearBtn1: TSpeedButton;
    EFICheckBox: TCheckBox;
    Edit1: TEdit;
    Edit2: TEdit;
    FileListBox1: TFileListBox;
    ImageList1: TImageList;
    ImageList2: TImageList;
    IniPropStorage1: TIniPropStorage;
    Label1: TLabel;
    LogMemo: TMemo;
    ClearBtn: TSpeedButton;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    OpenDialog1: TOpenDialog;
    OpenDialog2: TOpenDialog;
    PopupMenu1: TPopupMenu;
    OpenBtn1: TSpeedButton;
    OpenBtn2: TSpeedButton;
    SpeedButton1: TSpeedButton;
    SpeedButton3: TSpeedButton;
    VGABtn: TSpeedButton;
    AllDevBox: TCheckListBox;
    DevBox: TComboBox;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    ListBox1: TListBox;
    ReloadBtn: TSpeedButton;
    StartBtn: TSpeedButton;
    StaticText2: TStaticText;
    procedure ClearBtn1Click(Sender: TObject);
    procedure ClearBtnClick(Sender: TObject);
    procedure DevBoxChange(Sender: TObject);
    procedure FileListBox1DblClick(Sender: TObject);
    procedure FileListBox1DrawItem(Control: TWinControl; Index: Integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure FormKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure ListBox1DblClick(Sender: TObject);
    procedure ListBox1DrawItem(Control: TWinControl; Index: integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure MenuItem1Click(Sender: TObject);
    procedure OpenBtn1Click(Sender: TObject);
    procedure OpenBtn2Click(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton3Click(Sender: TObject);
    procedure StartBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ReloadBtnClick(Sender: TObject);
    procedure ReloadUSBDevices;
    procedure ReloadAllDevices;
    procedure VGABtnMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: integer);
  private

  public

  end;

var
  MainForm: TMainForm;
  command: string;

resourcestring
  SLoading = 'Loading';
  SInstallation = 'Installation';
  SDeleteImages = 'Delete selected images?';
  SNotUsed = 'not used';
  SUserNotInGroup = 'User outside Group disk! Run:';

implementation

uses start_trd;

{$R *.lfm}

{ TMainForm }

//Начитываем все устройства
procedure TMainForm.ReloadAllDevices;
var
  ExProcess: TProcess;
begin
  Application.ProcessMessages;

  ExProcess := TProcess.Create(nil);
  try
    ExProcess.Executable := 'bash';
    ExProcess.Parameters.Add('-c');

    if DevBox.ItemIndex = DevBox.Items.Count - 1 then
      ExProcess.Parameters.Add(
        '> ~/.gqemoo/devlist_all; lsblk -ldnp -I 8,11,65,66,259 -o NAME,MAJ:MIN,RM,SIZE,TYPE,MODEL > ~/.gqemoo/devlist_all')
    else
      ExProcess.Parameters.Add(
        '> ~/.gqemoo/devlist_all; lsblk -ldnp -I 8,11,65,66,259 -o NAME,MAJ:MIN,RM,SIZE,TYPE,MODEL | grep -v $(echo '
        + Copy(DevBox.Text, 1, Pos(' ', DevBox.Text) - 1) +
        ' | cut -f1 -d" ") > ~/.gqemoo/devlist_all');

    ExProcess.Options := ExProcess.Options + [poWaitOnExit];
    ExProcess.Execute;

    AllDevBox.Items.LoadFromFile(GetUserDir + '.gqemoo/devlist_all');

    if AllDevBox.Items.Count <> 0 then AllDevBox.ItemIndex := 0;

  finally
    ExProcess.Free;
  end;
end;

//Список режимов vga
procedure TMainForm.VGABtnMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: integer);
var
  p: TPoint;
begin
  if Button = mbLeft then
  begin
    p := VGABtn.ClientToScreen(Point(X, Y));
    PopupMenu1.Popup(p.x, p.Y);
  end;
end;

//Начитываем removable devices (флешки)
procedure TMainForm.ReloadUSBDevices;
var
  ExProcess: TProcess;
begin
  Application.ProcessMessages;

  ExProcess := TProcess.Create(nil);
  try
    ExProcess.Executable := 'bash';
    ExProcess.Parameters.Add('-c');

    ExProcess.Parameters.Add(
      '> ~/.gqemoo/devlist; echo "$(lsblk -ldnp -I 8 | awk ' + '''' +
      '$3 == "1" && $4 != "0B" {print $1, $4}' + '''' + '; echo "' +
      SNotUsed + '")" > ~/.gqemoo/devlist');

    ExProcess.Options := ExProcess.Options + [poWaitOnExit];
    ExProcess.Execute;

    DevBox.Clear;
    DevBox.Items.LoadFromFile(GetUserDir + '.gqemoo/devlist');

    //Курсор верх
    if DevBox.Items.Count <> 0 then DevBox.ItemIndex := 0;

  finally
    ExProcess.Free;
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  MainForm.Caption := Application.Title;

  if not DirectoryExists(GetUserDir + '.gqemoo') then mkDir(GetUserDir + '.gqemoo');
  if not DirectoryExists(GetUserDir + 'qemoo_tmp') then mkDir(GetUserDir + 'qemoo_tmp');

  //Список установленных ОС
  FileListBox1.Directory := GetUserDir + 'qemoo_tmp';
  if FileListBox1.Items.Count <> 0 then
    FileListBox1.ItemIndex := 0;

  IniPropStorage1.IniFileName := GetUserDir + '.gqemoo/gqemoo.ini';

  //Рабочая директория
  SetCurrentDir(GetUserDir + 'qemoo_tmp');

  //Размеры для разных тем
  ReloadBtn.Width := DevBox.Height;
  OpenBtn1.Width := Edit1.Height;

  Edit2.Height := Edit1.Height;
  OpenBtn2.Width := Edit1.Height;
  ClearBtn.Width := Edit1.Height;
end;

//Запуск VM
procedure TMainForm.StartBtnClick(Sender: TObject);
var
  dev: string;
  i, b: integer;
  FStartVM: TThread;
begin
  //Определяем источник загрузки
  if DevBox.ItemIndex <> DevBox.Items.Count - 1 then
    dev := Copy(DevBox.Text, 1, Pos(' ', DevBox.Text) - 1)
  else
  if Edit1.Text <> '' then
    dev := '"' + Edit1.Text + '"'
  else
  if FileListBox1.SelCount <> 0 then
  begin
    ListBox1.ItemIndex := 0;
    dev := '"' + FileListBox1.FileName + '"';
  end
  else
    Exit;

  //EFI?
  if not EFICheckBox.Checked then
    case ListBox1.ItemIndex of
      0: command := 'qemoo ' + dev;
      1: command := 'qemoo -i ' + dev;
    end
  else
    case ListBox1.ItemIndex of
      0: command := 'qemoo -e ' + dev;
      1: command := 'qemoo -e -i ' + dev;
    end;

  //Счетчик выбранных устройств
  b := 0;
  //Узнаём количество выбранных
  for i := 0 to AllDevBox.Items.Count - 1 do
    if AllDevBox.Checked[i] then Inc(b);

  //Подключаем блочные устройства (если выбраны)
  if b <> 0 then
  begin
    command := command + ' -a ';

    for i := 0 to AllDevBox.Items.Count - 1 do
      if AllDevBox.Checked[i] then
        command := command + Copy(AllDevBox.Items[i], 1,
          Pos(' ', AllDevBox.Items[i]) - 1) + ',';
  end;

  //Подключаем образ к VM (если указан)
  if (Edit2.Text <> '') and (b <> 0) then
    command := command + '"' + Edit2.Text + '",'
  else
  if Edit2.Text <> '' then
    command := command + ' -a "' + Edit2.Text + '",';

  //Удаляем последнюю запятую
  if command[Length(command)] = ',' then
    Delete(command, Length(command), 1);

  //Выбор дисплея; 0 - не добавлять команду (default), начинать с индекса 1
  case IniPropStorage1.StoredValue['vga'] of
    '1': command := command + ' ' + '-- -vga std -display sdl';
    '2': command := command + ' ' + '-- -vga qxl -display sdl';
    '3': command := command + ' ' + '-- -vga virtio -display sdl';
  end;

  //Запуск VM
  FStartVM := StartVM.Create(False);
  FStartVM.Priority := tpNormal;
end;

//Очистка пути к образу для подключения
procedure TMainForm.ClearBtnClick(Sender: TObject);
begin
  Edit2.Clear;
end;

//Очистка пути к образу для загрузки
procedure TMainForm.ClearBtn1Click(Sender: TObject);
begin
  Edit1.Clear;
end;

//Выбор флешки
procedure TMainForm.DevBoxChange(Sender: TObject);
begin
  Edit1.Clear;
  ReloadAllDevices;
end;

//Старт установленного образа
procedure TMainForm.FileListBox1DblClick(Sender: TObject);
begin
  //Переключение режима в Загрузку
  ListBox1.ItemIndex := 0;
  //Имя образа из списка в строку запуска
  Edit1.Text := FileListBox1.Items[FileListBox1.ItemIndex];

  //Образ выбран, обнулить флешку
  if DevBox.ItemIndex <> DevBox.Items.Count - 1 then
  begin
    DevBox.ItemIndex := DevBox.Items.Count - 1;
    ReloadAllDevices;
  end;

  //Запуск
  StartBtn.Click;
end;

procedure TMainForm.FileListBox1DrawItem(Control: TWinControl; Index: Integer;
  ARect: TRect; State: TOwnerDrawState);
var
  BitMap: TBitMap;
begin
  try
    BitMap := TBitMap.Create;
    with FileListBox1 do
    begin
      Canvas.FillRect(aRect);

      //Название (текст по центру-вертикали)
      Canvas.TextOut(aRect.Left + 35, aRect.Top + ItemHeight div 2 -
        Canvas.TextHeight('A') div 2 + 1, Items[Index]);

      //Иконка
        ImageList2.GetBitMap(0, BitMap);

      Canvas.Draw(aRect.Left + 2, aRect.Top + (ItemHeight - 24) div 2 + 1, BitMap);
    end;
  finally
    BitMap.Free;
  end;
end;

//F12 - обновить список устройств
procedure TMainForm.FormKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
begin
  if Key = $7B then ReloadAllDevices;
end;

//Запуск двойным щелчком в меню
procedure TMainForm.ListBox1DblClick(Sender: TObject);
begin
  StartBtn.Click;
end;

//Вставка иконок в ListBox
procedure TMainForm.ListBox1DrawItem(Control: TWinControl; Index: integer;
  ARect: TRect; State: TOwnerDrawState);
var
  BitMap: TBitMap;
begin
  try
    BitMap := TBitMap.Create;
    with ListBox1 do
    begin
      Canvas.FillRect(aRect);

      //Название (текст по центру-вертикали)
      Canvas.TextOut(aRect.Left + 40, aRect.Top + ItemHeight div 2 -
        Canvas.TextHeight('A') div 2 + 1, Items[Index]);

      //Иконка
      if (Index mod 2) = 0 then
        ImageList1.GetBitMap(0, BitMap)
      else
        ImageList1.GetBitMap(1, BitMap);

      Canvas.Draw(aRect.Left + 2, aRect.Top + (ItemHeight - 32) div 2 + 1, BitMap);
    end;
  finally
    BitMap.Free;
  end;
end;

//Установка и запись чекера PopUpMenu; параметр vga
procedure TMainForm.MenuItem1Click(Sender: TObject);
var
  i: integer;
begin
  with (Sender as TMenuItem) do
  begin
    //go through the list and make sure *only* the clicked item is checked
    for i := 0 to (GetParentComponent as TPopupMenu).Items.Count - 1 do
    begin
      (GetParentComponent as TPopupMenu).Items[i].Checked := (i = MenuIndex);
      //Сохраняем индекс vga

      if (GetParentComponent as TPopupMenu).Items[i].Checked then
        INIPropStorage1.StoredValue['vga'] := IntToStr(i);

    end;  //for each item in the popup
  end;  //with
end;

//Выбрать образ загрузки
procedure TMainForm.OpenBtn1Click(Sender: TObject);
begin
  if OpenDialog1.Execute then
  begin
    Edit1.Text := OpenDialog1.FileName;

    //Образ выбран, обнулить флешку
    if DevBox.ItemIndex <> DevBox.Items.Count - 1 then
    begin
      DevBox.ItemIndex := DevBox.Items.Count - 1;
      ReloadAllDevices;
    end;

    //Если образ загрузки = образу подключения - очистить образ подключения
    if Edit1.Text = Edit2.Text then Edit2.Clear;
  end;
end;

//Выбрать образ подключения
procedure TMainForm.OpenBtn2Click(Sender: TObject);
begin
  if OpenDialog2.Execute then
  begin
    Edit2.Text := OpenDialog2.FileName;

    //Если образ подключения = образу загрузки - очистить образ загрузки
    if Edit2.Text = Edit1.Text then Edit1.Clear;
  end;
end;

//Удаление установленных образов
procedure TMainForm.SpeedButton1Click(Sender: TObject);
var
  i: integer;
begin
  if MessageDlg(SDeleteImages, mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    for i := 0 to FileListBox1.Count - 1 do
      if FileListBox1.Selected[i] then
        DeleteFile(FileListBox1.Items[i]);
    FileListBox1.UpdateFileList;

    if FileListBox1.Count <> 0 then
      FileListBox1.ItemIndex := 0;
  end;
end;

procedure TMainForm.SpeedButton3Click(Sender: TObject);
begin
  FileListBox1.SelectAll;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  IniPropStorage1.Restore;

  //Читаем vga - индекс PopUpMenu - выбор дисплея
  PopUPMenu1.Items[StrToInt(IniPropStorage1.StoredValue['vga'])].Checked := True;

  //Наполняем список режимов
  with ListBox1.Items do
  begin
    Add(SLoading);
    Add(SInstallation);
  {  Add(SLoadingEFI);
    Add(SInstallationEFI);}
  end;
  //Курсор в 0
  ListBox1.ItemIndex := 0;

  //Читаем заголовок диалога выбора образа
 { FileNameEdit1.DialogTitle := FileNameEdit1.ButtonHint;
  FileNameEdit2.DialogTitle := FileNameEdit2.ButtonHint;
  }
  ReloadUSBDevices;
  ReloadAllDevices;
end;

//Обновление списка флешек и всех устройств
procedure TMainForm.ReloadBtnClick(Sender: TObject);
begin
  ReloadUSBDevices;
  ReloadAllDevices;

  if DevBox.Items.Count > 1 then Edit1.Clear;
end;

end.
