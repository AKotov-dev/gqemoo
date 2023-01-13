unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  CheckLst, IniPropStorage, Process, DefaultTranslator, FileCtrl, ExtCtrls,
  ClipBrd, Menus;

type

  { TMainForm }

  TMainForm = class(TForm)
    AllDevBox: TCheckListBox;
    ClearBtn: TSpeedButton;
    DevBox: TComboBox;
    Edit1: TEdit;
    Edit2: TEdit;
    EFICheckBox: TCheckBox;
    FileListBox1: TFileListBox;
    ImageList1: TImageList;
    ImageList2: TImageList;
    IniPropStorage1: TIniPropStorage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    ListBox1: TListBox;
    LogMemo: TMemo;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    Separator1: TMenuItem;
    OpenBtn1: TSpeedButton;
    OpenBtn2: TSpeedButton;
    OpenDialog1: TOpenDialog;
    OpenDialog2: TOpenDialog;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    PopupMenu1: TPopupMenu;
    ReloadBtn: TSpeedButton;
    RemoveBtn: TSpeedButton;
    RenameBtn: TSpeedButton;
    SelectAllBtn: TSpeedButton;
    ScriptBtn: TSpeedButton;
    Splitter1: TSplitter;
    Splitter3: TSplitter;
    StartBtn: TSpeedButton;
    StaticText2: TStaticText;
    procedure ClearBtnClick(Sender: TObject);
    procedure DevBoxChange(Sender: TObject);
    procedure FileListBox1DblClick(Sender: TObject);
    procedure FileListBox1DrawItem(Control: TWinControl; Index: integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure FormKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure ListBox1Click(Sender: TObject);
    procedure ListBox1DrawItem(Control: TWinControl; Index: integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure MenuItem1Click(Sender: TObject);
    procedure MenuItem2Click(Sender: TObject);
    procedure OpenBtn1Click(Sender: TObject);
    procedure OpenBtn2Click(Sender: TObject);
    procedure RemoveBtnClick(Sender: TObject);
    procedure RenameBtnClick(Sender: TObject);
    procedure SelectAllBtnClick(Sender: TObject);
    procedure ScriptBtnMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: integer);
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
  SDeleteImages = 'Delete selected images?';
  SNotUsed = 'not used';
  SCaptRenameImage = 'Rename an image';
  SInputNewImageName = 'Enter a new image name:';
  SFileExists = 'The file exists! Specify a different name!';
  SUserNotInGroup = 'User outside Group disk! Run: usermod -aG disk $LOGNAME';
  SStartVM = 'Starting a virtual machine...';
  SRemoteViewerNotFound =
    'remote-viewer not found! Install the virt-viewer package!';
  SKillAllQEMU = 'Forcibly reset all QEMU processes?';
  SWaitingSPICE = 'waiting for spice-server on 127.0.0.1:';
  SWaitingSpiceSec = 'of 5 sec)';
  SInstallationWithUEFI = 'Installation with UEFI';

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
end;

//Запуск VM
procedure TMainForm.StartBtnClick(Sender: TObject);
const   //Заменять эти символы в имени
  BadSym = ' ={}$\/:*?"<>|@^#%&~''';
var
  i, b: integer;
  CFG: TStringList;
  dev, Value, Capt: string;
  FStartVM: TThread;
begin
  try
    Value := '';
    CFG := TStringList.Create;

    //Определяем источник загрузки
    if DevBox.ItemIndex <> DevBox.Items.Count - 1 then
      dev := Copy(DevBox.Text, 1, Pos(' ', DevBox.Text) - 1)
    else
    if Edit1.Text <> '' then
      dev := '"' + Edit1.Text + '"'
    else
      Exit;

    //Если Режим = Установка
    if ListBox1.ItemIndex = 1 then
    begin
      //Продолжаем спрашивать имя образа, если пусто
      repeat
        if EfiCheckBox.Checked then Capt := SInstallationWithUEFI
        else
          Capt := SInstallation;

        if not InputQuery(Capt, SInputNewImageName, Value) then exit;
      until Trim(Value) <> '';

      //Заменяем неразрешенные символы
      Value := Trim(Value);
      for i := 1 to Length(Value) do
        if Pos(Value[i], BadSym) > 0 then
          Value[i] := '_';

      //Если файл существует - выход
      if FileExists(Value + '.qcow2') then
      begin
        MessageDlg(SFileExists, mtWarning, [mbOK], 0);
        exit;
      end
      else
      //Иначе - если установка НЕ EFI - создать флаг ~/.gqemoo/value.qcow2
      if not EFICheckBox.Checked then
        CFG.SaveToFile(GetUserDir + '.gqemoo/' + Value + '.qcow2');
    end;

    //Пишем конфиг ~/.gqemoo/qemoo.cfg: имя нового образа и дисплей qxl + кол-во CPU
    CFG.Add('QEMUADD="-vga qxl -smp 2"');
    CFG.Add('QCOW2=' + '''' + Value + '.qcow2' + '''');
    CFG.SaveToFile(GetUserDir + '.gqemoo/qemoo.cfg');

    //Формируем команду: работаем с конфигом
    command := 'qemoo --qemoocfg ' + GetUserDir + '/.gqemoo/qemoo.cfg';

    //EFI?
    if not EFICheckBox.Checked then
      case ListBox1.ItemIndex of
        0: command := command + ' -d ' + dev;
        1: command := command + ' -d -i ' + dev;
      end
    else
      case ListBox1.ItemIndex of
        0: command := command + ' -d -e ' + dev;
        1: command := command + ' -d -e -i ' + dev;
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

    //Запуск VM
    FStartVM := StartVM.Create(False);
    FStartVM.Priority := tpNormal;

  finally
    CFG.Free;
  end;
end;

//Очистка пути к образу для подключения
procedure TMainForm.ClearBtnClick(Sender: TObject);
begin
  Edit2.Clear;
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
  if FileListBox1.Count <> 0 then
  begin
    //Переключение режима в Загрузку
    ListBox1.ItemIndex := 0;

    //Выключение EFI, если есть флаг: ~/.gqemoo/image_name.qcow2
    if FileExists(GetUserDir + '/.gqemoo/' +
      FileListBox1.Items[FileListBox1.ItemIndex]) then EFICheckBox.Checked := False
    else
      EFICheckBox.Checked := True;

    //Имя образа из списка в строку запуска
    Edit1.Text := FileListBox1.FileName;

    //Образ выбран, обнулить флешку
    if DevBox.ItemIndex <> DevBox.Items.Count - 1 then
    begin
      DevBox.ItemIndex := DevBox.Items.Count - 1;
      ReloadAllDevices;
    end;

    //Запуск
    StartBtn.Click;
  end;
end;

//Иконки Установленных *.qcow2
procedure TMainForm.FileListBox1DrawItem(Control: TWinControl;
  Index: integer; ARect: TRect; State: TOwnerDrawState);
var
  BitMap: TBitMap;
begin
  try
    BitMap := TBitMap.Create;
    with FileListBox1 do
    begin
      Canvas.FillRect(aRect);

      //Название (текст по центру-вертикали)
      Canvas.TextOut(aRect.Left + 32, aRect.Top + ItemHeight div 2 -
        Canvas.TextHeight('A') div 2 + 1, Items[Index]);

      //Иконки EFI/NO
      if FileExists(GetUserDir + '.gqemoo/' + Items[Index]) then
        ImageList2.GetBitMap(0, BitMap)
      else
        ImageList2.GetBitMap(1, BitMap);

      Canvas.Draw(aRect.Left + 2, aRect.Top + (ItemHeight - 24) div 2 + 1, BitMap);
    end;
  finally
    BitMap.Free;
  end;
end;

//F12 - обновить список устройств, Ctrl+Q/q - принудительный сброс процессов remote-viewer и qemu
procedure TMainForm.FormKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
var
  s: ansistring;
begin
  //F12
  if Key = 123 then ReloadAllDevices;

  //Ctrl+Q/q
  if (Key = 81) and (Shift = [ssCtrl]) then
    if MessageDlg(SKillAllQEMU, mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      RunCommand('/bin/bash', ['-c', 'killall remote-viewer qemu-system-x86_64 &'], s);
end;

//Очистить источник, если попытка установить уже установленный образ из CurrentDirectory
procedure TMainForm.ListBox1Click(Sender: TObject);
begin
  if Edit1.Text <> '' then
    if (ListBox1.ItemIndex = 1) and (FileExists(ExtractFileName(Edit1.Text))) then
      Edit1.Text := '';
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

//Копировать в буфер команду монтирования ~/qemoo_tmp <-> ~/hostdir (Guest) + /etc/fstab
procedure TMainForm.MenuItem1Click(Sender: TObject);
begin
  // /etc/systemd/system/hostdir.service
  ClipBoard.AsText :=
    'pkexec bash -c ' + '''' +
    'clear; if [[ -f /etc/systemd/system/hostdir.service ]]; then umount -l hostdir; ' +
    'systemctl disable hostdir; rm -f /etc/systemd/system/hostdir.service; else test -d /home/$(logname)/hostdir '
    + '|| mkdir /home/$(logname)/hostdir && echo -e "[Unit]\nDescription=GQemoo shared directory ~/hostdir\n\n[Service]\nType='
    + 'oneshot\nExecStart=mount -t 9p -o trans=virtio,msize=100000000 hostdir /home/$(logname)/hostdir\n\n[Install]\nWantedBy='
    + 'multi-user.target" > /etc/systemd/system/hostdir.service; systemctl daemon-reload && systemctl start hostdir && '
    + 'systemctl enable hostdir; chown $(logname) -R /home/$(logname)/hostdir; fi'
    + '''';
end;

//Авторезайц окна VM (только для тех VM, которые сами не масштабируются)
procedure TMainForm.MenuItem2Click(Sender: TObject);
begin
  ClipBoard.AsText := 'pkexec bash -c ' + '''' +
    'if [ -f /bin/xresize ]; then killall xresize; ' +
    'rm -f /bin/xresize /etc/xdg/autostart/xresize.desktop; exit; fi; echo -e "#! /bin/bash\n\nwhile '
    + 'true\ndo\nxrandr --output \$(xrandr | grep \" connected\" | cut -f1 -d\" \") --auto\nsleep 2\ndone" > '
    + '/bin/xresize; chmod +x /bin/xresize; echo -e "[Desktop Entry]\nName=XResize\nExec=xresize '
    + '&\nType=Application\nTerminal=false" > /etc/xdg/autostart/xresize.desktop ' +
    '''' + '&& [ -f /bin/xresize ] && nohup xresize &';
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
procedure TMainForm.RemoveBtnClick(Sender: TObject);
var
  i: integer;
begin
  if FileListBox1.Count <> 0 then
  begin
    if MessageDlg(SDeleteImages, mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      for i := 0 to FileListBox1.Count - 1 do
        if FileListBox1.Selected[i] then
        begin
          DeleteFile(FileListBox1.Items[i]);
          DeleteFile(GetUserDir + '.gqemoo/' + FileListBox1.Items[i]);
        end;
      FileListBox1.UpdateFileList;

      if FileListBox1.Count <> 0 then
        FileListBox1.ItemIndex := 0;

      //Очистка Edit1 в любом случае; установленны образ мог находиться в загрузке
      Edit1.Clear;
    end;
  end;
end;

//Переименовать образ *.qcow2
procedure TMainForm.RenameBtnClick(Sender: TObject);
var
  i: integer;
  Value: string;
const
  BadSym = '={}$\/:*?"<>|@^#%&~'''; //Заменять эти символы
begin
  if FileListBox1.Count <> 0 then
  begin
    //Получаем имя без пути и расширения
    Value := Copy(ExtractFileName(FileListBox1.FileName), 1,
      Length(ExtractFileName(FileListBox1.FileName)) - 6);

    //Продолжаем спрашивать имя образа, если пусто
    repeat
      if not InputQuery(SCaptRenameImage, SInputNewImageName, Value) then exit;
    until Trim(Value) <> '';

    //Заменяем неразрешенные символы
    Value := Trim(Value);

    for i := 1 to Length(Value) do
      if Pos(Value[i], BadSym) > 0 then
        Value[i] := '_';

    //Если файл не существует - переименовать
    if not FileExists(ExtractFilePath(FileListBox1.FileName) + Value + '.qcow2') then
    begin
      //Если у файла из списка есть флаг EFI
      if FileExists(GetUserDir + '.gqemoo/' +
        FileListBox1.Items[FileListBox1.ItemIndex]) then
      begin
        //Удаляем флаг EFI выбранного в списке
        DeleteFile(GetUserDir + '.gqemoo/' + FileListBox1.Items[FileListBox1.ItemIndex]);
        //Создаём флаг EFI для нового имени
        FileListBox1.Items.SaveToFile(GetUserDir + '.gqemoo/' + Value + '.qcow2');
      end;

      //Переименовываем файл
      RenameFile(FileListBox1.FileName, Value + '.qcow2');

      FileListBox1.UpdateFileList;
      FileListBox1.ItemIndex := 0;
    end
    else
      MessageDlg(SFileExists, mtWarning, [mbOK], 0);
  end;
end;

//Выбрать все образы *.qcow2
procedure TMainForm.SelectAllBtnClick(Sender: TObject);
begin
  FileListBox1.SelectAll;
end;

//PopUpMenu на выбор скриптов
procedure TMainForm.ScriptBtnMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: integer);
var
  p: TPoint;
begin
  if Button = mbLeft then
  begin
    p := ScriptBtn.ClientToScreen(Point(X, Y));
    PopupMenu1.Popup(p.x, p.Y);
  end;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  IniPropStorage1.Restore;

  //Размеры для разных тем
  ReloadBtn.Width := DevBox.Height;
  OpenBtn1.Width := Edit1.Height;

  Edit2.Height := Edit1.Height;
  OpenBtn2.Width := Edit1.Height;
  ScriptBtn.Width := Edit1.Height;
  ClearBtn.Width := Edit1.Height;
  AllDevBox.Top := ListBox1.Top;
  //Panel1.Height := DevBox.Top + DevBox.Height + 5;

  //Наполняем список режимов
  with ListBox1.Items do
  begin
    Add(SLoading);
    Add(SInstallation);
  end;
  //Курсор в 0
  ListBox1.ItemIndex := 0;

  //Читаем флешки и подключаемые устройства
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
