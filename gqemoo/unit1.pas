unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, EditBtn, StdCtrls,
  Buttons, CheckLst, IniPropStorage, Process, DefaultTranslator;

type

  { TMainForm }

  TMainForm = class(TForm)
    IniPropStorage1: TIniPropStorage;
    LogMemo: TMemo;
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
    procedure FileNameEdit1AcceptFileName(Sender: TObject; var Value: string);
    procedure StartBtnClick(Sender: TObject);
    procedure DevBoxChange(Sender: TObject);
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
        '> ~/.gqemoo/devlist_all; lsblk -ldn > ~/.gqemoo/devlist_all')
    else
      ExProcess.Parameters.Add(
        '> ~/.gqemoo/devlist_all; lsblk -ldn | grep -v $(echo ' +
        Copy(DevBox.Text, 1, Pos(' ', DevBox.Text) - 1) +
        ' | cut -f3 -d"/" | cut -f1 -d" ") > ~/.gqemoo/devlist_all');

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
      '> ~/.gqemoo/devlist; dev=$(lsblk -ldn | cut -f1 -d" ");' +
      'for i in $dev; do if [[ $(cat /sys/block/$i/removable) -eq 1 ]]; then ' +
      'echo "/dev/$(lsblk -ld | grep $i | awk ' + '''' + '{print $1,$4}' +
      '''' + ')" | grep -Ev "\/dev\/sr|0B" >> ~/.gqemoo/devlist; fi; done; echo "' +
      SNotUsed + '" >> ~/.gqemoo/devlist');

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
  if not DirectoryExists(GetUserDir + '.gqemoo') then mkDir(GetUserDir + '.gqemoo');
  if not DirectoryExists(GetUserDir + 'qemoo_tmp') then mkDir(GetUserDir + 'qemoo_tmp');

  IniPropStorage1.IniFileName := GetUserDir + '.gqemoo/gqemoo.ini';


  //Рабочая директория
  SetCurrentDir(GetUserDir + 'qemoo_tmp');

  MainForm.Caption := Application.Title;
  ReloadBtn.Width := DevBox.Height;
  FileNameEdit1.ButtonWidth := FileNameEdit1.Height;
end;

procedure TMainForm.DevBoxChange(Sender: TObject);
begin
  FileNameEdit1.Clear;
  ReloadAllDevices;
end;

procedure TMainForm.StartBtnClick(Sender: TObject);
var
  FStartVM: TThread;
  i, b: integer;
  dev: string;
begin
  //Определяем источник загрузки
  if FileNameEdit1.Text = '' then
    if DevBox.ItemIndex <> DevBox.Items.Count - 1 then
      dev := Copy(DevBox.Text, 1, Pos(' ', DevBox.Text) - 1)
    else
      exit
  else
    dev := FileNameEdit1.Text;

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

  if b <> 0 then
  begin
    command := command + ' -a ';

    //Пробрасываем блочные устройства (если выбраны)
    for i := 0 to AllDevBox.Items.Count - 1 do
      if AllDevBox.Checked[i] then
        command := command + '/dev/' + Copy(AllDevBox.Items[i], 1,
          Pos(' ', AllDevBox.Items[i]) - 1) + ',';

    //Удаляем последнюю запятую
    Delete(command, Length(command), 1);
  end;

  FStartVM := StartVM.Create(False);
  FStartVM.Priority := tpHighest;
end;

procedure TMainForm.FileNameEdit1AcceptFileName(Sender: TObject; var Value: string);
begin
  if DevBox.ItemIndex <> DevBox.Items.Count - 1 then
  begin
    DevBox.ItemIndex := DevBox.Items.Count - 1;
    ReloadAllDevices;
  end;
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

  ListBox1.ItemIndex := 0;

  ReloadUSBDevices;
  ReloadAllDevices;
end;

procedure TMainForm.ReloadBtnClick(Sender: TObject);
begin
  ReloadUSBDevices;
  ReloadAllDevices;

  if DevBox.Items.Count > 1 then FileNameEdit1.Clear;
end;

end.
