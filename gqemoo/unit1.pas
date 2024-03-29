unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  CheckLst, IniPropStorage, Process, DefaultTranslator, FileCtrl, ExtCtrls,
  ClipBrd, Menus, FileUtil;

type

  { TMainForm }

  TMainForm = class(TForm)
    AllDevBox: TCheckListBox;
    ClearBtn: TSpeedButton;
    DevBox: TComboBox;
    LoadImageEdit: TEdit;
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
    SetBtn: TSpeedButton;
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
    CloneBtn: TSpeedButton;
    Splitter1: TSplitter;
    Splitter3: TSplitter;
    StartBtn: TSpeedButton;
    StaticText2: TStaticText;
    procedure ClearBtnClick(Sender: TObject);
    procedure DevBoxChange(Sender: TObject);
    procedure FileListBox1DblClick(Sender: TObject);
    procedure FileListBox1DrawItem(Control: TWinControl; Index: integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
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
    procedure CloneBtnClick(Sender: TObject);
    procedure SetBtnClick(Sender: TObject);
    procedure StartBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ReloadBtnClick(Sender: TObject);
    procedure ReloadUSBDevices;
    procedure ReloadAllDevices;
    procedure KillAllRsync;
  private

  public

  end;

var
  MainForm: TMainForm;
  command, clone_cmd: string;

resourcestring
  SLoading = 'Loading';
  SInstallation = 'Installation';
  SDeleteImages = 'Delete selected images?';
  SNotUsed = 'not used';
  SCaptRenameImage = 'Rename an image';
  SInputNewImageName = 'Enter a new image name:';
  SFileExists = 'The file exists! Specify a different name!';
  SUserNotInGroup =
    'User outside Groups disk and kvm! Run: usermod -aG disk,kvm $LOGNAME and reboot...';
  SStartVM = 'Starting a virtual machine...';
  SRemoteViewerNotFound =
    'remote-viewer not found! Install the virt-viewer package!';
  SKillAllQEMU = 'Forcibly reset all QEMU processes?';
  SWaitingSPICE = 'waiting for spice-server on 127.0.0.1:';
  SWaitingSpiceSec = 'of 5 sec)';
  SInstallationWithUEFI = 'Installation (EFI)';
  SCaptCloneImage = 'Сloning an image';
  SInputCloneImageName = 'Enter the clone name:';
  SCloningMsg = 'Cloning:';
  SCloningComplete = 'Cloning is complete';
  SCancelCloning = 'Cloning started! Terminate?';

implementation

uses start_trd, clone_progress_trd, set_unit;

{$R *.lfm}

{ TMainForm }

//Детоксикация имени qcow2 (замена пробелов и т.д.)
function Detox(Value: string): string;
var
  i: integer;
const //Заменять эти символы в имени
  BadSym = ' =,{}$\/:*?"<>|@^#%&~''';
begin
  //Заменяем неразрешенные символы
  Result := Trim(Value);
  for i := 1 to Length(Result) do
    if Pos(Result[i], BadSym) > 0 then
      Result[i] := '_';
end;

//Отмена клонирования и удаление {образ.qcow.conf,образ.qcow2.nvram}
procedure TMainForm.KillAllRsync;
var
  s: ansistring;
begin
  RunCommand('/bin/bash', ['-c', 'if [[ $(pidof rsync) ]]; then killall rsync; rm -f ' +
    GetUserDir + 'qemoo_tmp/' + Copy(clone_cmd, Pos('" ', clone_cmd) +
    2, Length(clone_cmd)) + '.nvram ' + GetUserDir + 'qemoo_tmp/' +
    Copy(clone_cmd, Pos('" ', clone_cmd) + 2, Length(clone_cmd)) +
    '.conf ' + '; fi; exit 0'], s);
end;

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
    if LoadImageEdit.Text <> '' then
      dev := '"' + LoadImageEdit.Text + '"'
    else
      Exit;

    //-- Создаём ~/.gqemoo/qemoo.cfg для перекрытия /etc/qemoo.cfg

    //Stage_1 = Запуск: Разбираемся с EFI
    if ListBox1.ItemIndex = 0 then
    begin
      //Если запускается установленный образ *.qcow2 - проверить чекбокса EFI (могли снять или наоборот)
      if (LoadImageEdit.Text = FileListBox1.FileName) and (LoadImageEdit.Text <> '') then
        //Включение EFI если есть: ~/qemoo_tmp/image_name.qcow2.nvram
        if FileExists(FileListBox1.FileName + '.nvram') then
          EFICheckBox.Checked := True
        else
          EFICheckBox.Checked := False;

      //EFI?
      if EFICheckBox.Checked then
      begin
        //Если запуск установленных образов qcow2 + NVRAM
        if (LoadImageEdit.Text = FileListBox1.FileName) and
          (LoadImageEdit.Text <> '') then
          CFG.Add(
            'EFI="-drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE.fd -drive if=pflash,format=raw,file='
            + FileListBox1.FileName + '.nvram"')
        else
          //Иначе - запуск EFI-образов/флешек извне без NVRAM
          CFG.Add('EFI="-bios /usr/share/OVMF/OVMF_CODE.fd"');
      end
      else
        //Иначе - EFI не используется (BIOS)
        CFG.Add('EFI=""');
    end
    else
    begin  //Stage_2: Установка
      //Вводим имя образа qcow2 для установки
      repeat
        if EfiCheckBox.Checked then Capt := SInstallationWithUEFI
        else
          Capt := SInstallation;

        if not InputQuery(Capt, SInputNewImageName, Value) then exit;
      until Trim(Value) <> '';

      //Заменяем неразрешенные символы в имени образа
      Value := Detox(Value);

      //Если файл образа *.qcow2 существует - Выход
      if FileExists(Value + '.qcow2') then
      begin
        MessageDlg(SFileExists, mtWarning, [mbOK], 0);
        exit;
      end;

      //Отключаем дополнительные устройства, если выбраны; нужна чистая установка без подключений
      AllDevBox.CheckAll(cbUnchecked);
      ClearBtn.Click;

      //Если Устанавка с EFI - добавляем указание на имя_образа.qcow2.nvram
      if EFICheckBox.Checked then
        CFG.Add(
          'EFI="-drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE.fd -drive if=pflash,format=raw,file='
          + GetUserDir + 'qemoo_tmp/' + Value + '.qcow2.nvram"')
      else
        //Иначе - Установка без EFI (BIOS)
        CFG.Add('EFI=""');
    end;

    //Пишем конфиг ~/.gqemoo/qemoo.cfg: дисплей qxl + кол-во CPU, имя нового образа, размер qcow2=20GB и т.д.
    //CFG.Add('QEMUADD="-vga qxl -smp 2"'); //qemoo-v1.5, spice-agent работает с -vga virtio
    //CFG.Add('SIZE=' + '''' + '20' + '''');
    CFG.Add('QCOW2=' + '''' + GetUserDir + 'qemoo_tmp/' + Value + '.qcow2' + '''');
    //CFG.Add('ACTION=' + '''' + 'run' + '''');  //не создаёт *.qcow2.nvram?
    //CFG.Add('RAM="auto"');
    //CFG.Add('ADD=""');
    CFG.Add('PORT=""');
    //CFG.Add('REDIRUSB=""');
    //CFG.Add('LOSETUP=""');
    CFG.Add('SPICE="yes"');
    //CFG.Add('SHARE="' + GetUserDir + 'qemoo_tmp"');

    //Сохраняем конфиг
    CFG.SaveToFile(GetUserDir + '.gqemoo/qemoo.cfg');

    //Формируем команду: режим демона + персональный конфиг
    command := 'qemoo --daemon --config ' + GetUserDir + '.gqemoo/qemoo.cfg';

    //EFI?
    if not EFICheckBox.Checked then
      case ListBox1.ItemIndex of
        0: command := command + ' ' + dev;
        1: command := command + ' -i ' + dev;
      end
    else
      case ListBox1.ItemIndex of
        0: command := command + ' -e ' + dev;
        1: command := command + ' -e -i ' + dev;
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
  LoadImageEdit.Clear;
  ReloadAllDevices;
end;

//Старт установленного образа
procedure TMainForm.FileListBox1DblClick(Sender: TObject);
begin
  if FileListBox1.Count <> 0 then
  begin
    //Переключение режима в Загрузку
    ListBox1.ItemIndex := 0;

    //Имя образа из списка в строку запуска
    LoadImageEdit.Text := FileListBox1.FileName;

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
      if FileExists(GetUserDir + 'qemoo_tmp/' + Items[Index] + '.nvram') then
        ImageList2.GetBitMap(1, BitMap)
      else
        ImageList2.GetBitMap(0, BitMap);

      Canvas.Draw(aRect.Left + 2, aRect.Top + (ItemHeight - 24) div 2 + 1, BitMap);
    end;
  finally
    BitMap.Free;
  end;
end;

//Если клонирование в процессе - Запрос на продолжение или отмена с закрытием формы
procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: boolean);
var
  s: ansistring;
begin
  RunCommand('/bin/bash', ['-c', '[[ $(pidof rsync) ]] && echo "yes"'], s);

  if Trim(s) = 'yes' then
  begin
    if MessageDlg(SCancelCloning, mtWarning, [mbYes, mbNo], 0) = mrYes then
      KillAllRsync
    else
      CanClose := False;
  end;
end;

//F12 - обновить список устройств, Ctrl+Q/q - принудительный сброс процессов remote-viewer и qemu
procedure TMainForm.FormKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
var
  s: ansistring;
begin
  //F12 - перечитать список устройств для подключения
  if Key = 123 then ReloadAllDevices;

  //Ctrl+Q/q - Принудительный сброс всех процессов remote-viewer и qemu-system-x86_64
  if (Key = 81) and (Shift = [ssCtrl]) then
    if MessageDlg(SKillAllQEMU, mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      RunCommand('/bin/bash', ['-c', 'killall remote-viewer qemu-system-x86_64 &'], s);

  //Esc - отмена клонирования и удаление *.conf,*.nvram
  if Key = 27 then KillAllRsync;
end;

//Очистить источник, если попытка установить уже установленный образ из CurrentDirectory
procedure TMainForm.ListBox1Click(Sender: TObject);
begin
  if LoadImageEdit.Text <> '' then
    if (ListBox1.ItemIndex = 1) and
      (FileExists(ExtractFileName(LoadImageEdit.Text))) then
      LoadImageEdit.Text := '';
end;

//Вставка иконок в ListBox (Загрузка/Установка)
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
    'clear; if [ -f /bin/xresize ]; then killall xresize; ' +
    'rm -f /bin/xresize /etc/xdg/autostart/xresize.desktop; else echo -e "#! /bin/bash\n\nwhile '
    + 'true\ndo\nxrandr --output \$(xrandr | grep \" connected\" | cut -f1 -d\" \") --auto\nsleep 2\ndone" > '
    + '/bin/xresize; chmod +x /bin/xresize; echo -e "[Desktop Entry]\nName=XResize\nExec=xresize '
    + '&\nType=Application\nTerminal=false" > /etc/xdg/autostart/xresize.desktop; fi ' +
    '''' + '; if [ -f /bin/xresize ]; then [ $UID == 0 ] && echo "UID=0; XResize will be enabled after reboot..."; ' + '[ -f /bin/xresize ] && nohup xresize >/dev/null 2>&1 & fi';
end;

//Выбрать образ загрузки
procedure TMainForm.OpenBtn1Click(Sender: TObject);
begin
  if OpenDialog1.Execute then
  begin
    LoadImageEdit.Text := OpenDialog1.FileName;

    //Образ выбран, обнулить флешку
    if DevBox.ItemIndex <> DevBox.Items.Count - 1 then
    begin
      DevBox.ItemIndex := DevBox.Items.Count - 1;
      ReloadAllDevices;
    end;

    //Если образ загрузки = образу подключения - очистить образ подключения
    if LoadImageEdit.Text = Edit2.Text then Edit2.Clear;
  end;
end;

//Выбрать образ подключения
procedure TMainForm.OpenBtn2Click(Sender: TObject);
begin
  if OpenDialog2.Execute then
  begin
    Edit2.Text := OpenDialog2.FileName;

    //Если образ подключения = образу загрузки - очистить образ загрузки
    if Edit2.Text = LoadImageEdit.Text then LoadImageEdit.Clear;
  end;
end;

//Удаление установленных образов
procedure TMainForm.RemoveBtnClick(Sender: TObject);
var
  i: integer;
begin
  if FileListBox1.SelCount <> 0 then
  begin
    if MessageDlg(SDeleteImages, mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      for i := 0 to FileListBox1.Count - 1 do
        if FileListBox1.Selected[i] then
        begin
          //Удаление образа
          DeleteFile(FileListBox1.Items[i]);
          //Удаление конфига образа
          DeleteFile(FileListBox1.Items[i] + '.conf');
          //Удаление nvram
          DeleteFile(GetUserDir + 'qemoo_tmp/' + FileListBox1.Items[i] + '.nvram');
        end;
      FileListBox1.UpdateFileList;

      if FileListBox1.Count <> 0 then
        FileListBox1.ItemIndex := 0;

      //Очистка LoadImageEdit в любом случае; установленны образ мог находиться в загрузке
      LoadImageEdit.Clear;
    end;
  end;
end;

//Переименовать образ *.qcow2
procedure TMainForm.RenameBtnClick(Sender: TObject);
var
  Value: string;
begin
  if FileListBox1.SelCount <> 0 then
  begin
    //Получаем имя без пути и расширения
    Value := Copy(ExtractFileName(FileListBox1.FileName), 1,
      Length(ExtractFileName(FileListBox1.FileName)) - 6);

    //Вводим имя образа
    repeat
      if not InputQuery(SCaptRenameImage, SInputNewImageName, Value) then exit;
    until Trim(Value) <> '';

    //Заменяем неразрешенные символы
    Value := Detox(Value);

    //Если файл не существует - переименовать образ, конфиг образ.conf и образ.qcow2.nvram
    if not FileExists(ExtractFilePath(FileListBox1.FileName) + Value + '.qcow2') then
    begin
      //Переименовываем образ
      RenameFile(FileListBox1.FileName, GetUserDir + 'qemoo_tmp/' + Value + '.qcow2');

      //Переименовываем nvram
      RenameFile(FileListBox1.Items[FileListBox1.ItemIndex] + '.nvram',
        GetUserDir + 'qemoo_tmp/' + Value + '.qcow2.nvram');

      //Переименовываем конфигурацию образ.qcow2.conf
      RenameFile(FileListBox1.Items[FileListBox1.ItemIndex] + '.conf',
        GetUserDir + 'qemoo_tmp/' + Value + '.qcow2.conf');

      FileListBox1.UpdateFileList;

      //Установка курсора на переименованный файл
      if FileListBox1.Items.IndexOf(Value + '.qcow2') <> -1 then
        FileListBox1.ItemIndex := (FileListBox1.Items.IndexOf(Value + '.qcow2'))
      else
        FileListBox1.ItemIndex := 0;
    end
    else
      //Иначе - файл существует - Выход
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

//Клонирование образа *.qcow2
procedure TMainForm.CloneBtnClick(Sender: TObject);
var
  Value: string;
  FStartClone: TThread;
begin
  if FileListBox1.SelCount <> 0 then
  begin
    //Получаем имя без пути и расширения, добавляем _clone
    Value := Copy(ExtractFileName(FileListBox1.FileName), 1,
      Length(ExtractFileName(FileListBox1.FileName)) - 6) + '_clone';

    //Вводим имя образа
    repeat
      if not InputQuery(SCaptCloneImage, SInputCloneImageName, Value) then exit;
    until Trim(Value) <> '';

    //Заменяем неразрешенные символы
    Value := Detox(Value);

    //Файл существует - Выход
    if FileExists(ExtractFilePath(FileListBox1.FileName) + Value + '.qcow2') then
    begin
      MessageDlg(SFileExists, mtWarning, [mbOK], 0);
      Exit;
    end;

    //Копируем конфиг клона в образ.qcow2.conf
    CopyFile(FileListBox1.FileName + '.conf', Value + '.qcow2.conf', False);

    //Копируем образ.qcow2.nvram
    CopyFile(FileListBox1.FileName + '.nvram', GetUserDir + 'qemoo_tmp/' +
      Value + '.qcow2.nvram', False);

    //Формируем команду клонирования
    clone_cmd := 'nice -n 19 rsync --progress "' + FileListBox1.FileName +
      '" ' + Value + '.qcow2';

    //Запуск клонирования VM
    FStartClone := StartClone.Create(False);
    FStartClone.Priority := tpLower;
  end;
end;

//Показать диалог настроек модально
procedure TMainForm.SetBtnClick(Sender: TObject);
begin
  SetForm := TSetForm.Create(nil);
  SetForm.ShowModal;

  FreeAndNil(SetForm);
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  IniPropStorage1.Restore;

  //Размеры для разных тем
  ReloadBtn.Width := DevBox.Height;
  OpenBtn1.Width := LoadImageEdit.Height;

  Edit2.Height := LoadImageEdit.Height;
  OpenBtn2.Width := LoadImageEdit.Height;
  ScriptBtn.Width := LoadImageEdit.Height;
  ClearBtn.Width := LoadImageEdit.Height;
  AllDevBox.Top := ListBox1.Top;

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

  if DevBox.Items.Count > 1 then LoadImageEdit.Clear;
end;

end.
