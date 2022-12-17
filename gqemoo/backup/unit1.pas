unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, EditBtn, StdCtrls,
  Buttons, CheckLst, IniPropStorage, Process, DefaultTranslator;

type

  { TMainForm }

  TMainForm = class(TForm)
    FileNameEdit2: TFileNameEdit;
    IniPropStorage1: TIniPropStorage;
    LogMemo: TMemo;
    ClearBtn: TSpeedButton;
    StartBtn: TBitBtn;
    AllDevBox: TCheckListBox;
    DevBox: TComboBox;
    FileNameEdit1: TFileNameEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    ListBox1: TListBox;
    ReloadBtn: TSpeedButton;
    StaticText2: TStaticText;
    procedure ClearBtnClick(Sender: TObject);
    procedure DevBoxChange(Sender: TObject);
    procedure FileNameEdit1AcceptFileName(Sender: TObject; var Value: string);
    procedure FileNameEdit1Change(Sender: TObject);
    procedure FileNameEdit2Change(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure StartBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ReloadBtnClick(Sender: TObject);
    procedure ReloadUSBDevices;
    procedure ReloadAllDevices;

  private

  public

  end;

var
  MainForm: TMainForm;
  command: string;

resourcestring
  SLoading = 'Loading';
  SInstallation = 'Installation';
  SLoadingEFI = 'Loading (EFI)';
  SInstallationEFI = 'Installation (EFI)';
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
        '> ~/.gqemoo/devlist_all; lsblk -ldnp -I 8,11,65,66 > ~/.gqemoo/devlist_all')
    else
      ExProcess.Parameters.Add(
        '> ~/.gqemoo/devlist_all; lsblk -ldnp -I 8,11,65,66 | grep -v $(echo ' +
        Copy(DevBox.Text, 1, Pos(' ', DevBox.Text) - 1) +
        ' | cut -f1 -d" ") > ~/.gqemoo/devlist_all');

    ExProcess.Options := ExProcess.Options + [poWaitOnExit];
    ExProcess.Execute;

    AllDevBox.Items.LoadFromFile(GetUserDir + '.gqemoo/devlist_all');

    if AllDevBox.Items.Count <> 0 then AllDevBox.ItemIndex := 0;

  finally
    ExProcess.Free;
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

  IniPropStorage1.IniFileName := GetUserDir + '.gqemoo/gqemoo.ini';

  //Рабочая директория
  SetCurrentDir(GetUserDir + 'qemoo_tmp');

  //Размеры для разных тем
  ReloadBtn.Width := DevBox.Height;
  FileNameEdit1.ButtonWidth := FileNameEdit1.Height;
  FileNameEdit2.ButtonWidth := FileNameEdit2.Height;
  ClearBtn.Width := FileNameEdit2.Height;
end;

//Запуск VM
procedure TMainForm.StartBtnClick(Sender: TObject);
var
  dev: string;
  i, b: integer;
  FStartVM: TThread;
begin
  //Определяем источник загрузки
  if FileNameEdit1.Text = '' then
    if DevBox.ItemIndex <> DevBox.Items.Count - 1 then
      dev := Copy(DevBox.Text, 1, Pos(' ', DevBox.Text) - 1)
    else
      exit
  else
    dev := '"' + FileNameEdit1.Text + '"';

  case ListBox1.ItemIndex of
    0: command := 'qemoo ' + dev;
    1: command := 'qemoo -i ' + dev;
    2: command := 'qemoo -e ' + dev;
    3: command := 'qemoo -e -i ' + dev;
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
  if (FileNameEdit2.Text <> '') and (b <> 0) then
    command := command + '"' + FileNameEdit2.Text + '",'
  else
  if FileNameEdit2.Text <> '' then
    command := command + ' -a "' + FileNameEdit2.Text + '",';

  //Удаляем последнюю запятую
  if command[Length(command)] = ',' then
    Delete(command, Length(command), 1);

  ShowMessage(command);

  FStartVM := StartVM.Create(False);
  FStartVM.Priority := tpHighest;
end;

//Если путь к образу получен - убрать из загрузки флешку
procedure TMainForm.FileNameEdit1AcceptFileName(Sender: TObject; var Value: string);
begin
  if DevBox.ItemIndex <> DevBox.Items.Count - 1 then
  begin
    DevBox.ItemIndex := DevBox.Items.Count - 1;
    ReloadAllDevices;
  end;
end;

//Если загрузочный образ = образу для подключения = очистить образ для подключения
procedure TMainForm.FileNameEdit1Change(Sender: TObject);
begin
  if FileNameEdit1.FileName = FileNameEdit2.FileName then FileNameEdit2.Clear;
end;

//Если образ для полключения = загрузочному образу = очистить загрузочный образ
procedure TMainForm.FileNameEdit2Change(Sender: TObject);
begin
  if FileNameEdit2.FileName = FileNameEdit1.FileName then FileNameEdit1.Clear;
end;

//Очистка пути к образу для подключения
procedure TMainForm.ClearBtnClick(Sender: TObject);
begin
  FileNameEdit2.Clear;
end;

//Выбор флешки
procedure TMainForm.DevBoxChange(Sender: TObject);
begin
  FileNameEdit1.Clear;
  ReloadAllDevices;
end;

//F12 - обновить список устройств
procedure TMainForm.FormKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
begin
  if Key = $7B then ReloadAllDevices;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  IniPropStorage1.Restore;

  //Наполняем список режимов
  with ListBox1.Items do
  begin
    Add(SLoading);
    Add(SInstallation);
    Add(SLoadingEFI);
    Add(SInstallationEFI);
  end;
  //Курсор в 0
  ListBox1.ItemIndex := 0;

  //Читаем заголовок диалога выбора образа
  FileNameEdit1.DialogTitle := FileNameEdit1.ButtonHint;
  FileNameEdit2.DialogTitle := FileNameEdit2.ButtonHint;

  ReloadUSBDevices;
  ReloadAllDevices;
end;

//Обновление списка флешек и всех устройств
procedure TMainForm.ReloadBtnClick(Sender: TObject);
begin
  ReloadUSBDevices;
  ReloadAllDevices;

  if DevBox.Items.Count > 1 then FileNameEdit1.Clear;
end;

end.
