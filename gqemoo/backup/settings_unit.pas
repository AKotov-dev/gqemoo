unit settings_unit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, EditBtn,
  IniPropStorage, Spin, Buttons, Process;

type

  { TSettingsForm }

  TSettingsForm = class(TForm)
    ComboBox1: TComboBox;
    ComboBox2: TComboBox;
    ComboBox3: TComboBox;
    ComboBox5: TComboBox;
    DirectoryEdit1: TDirectoryEdit;
    FileNameEdit1: TFileNameEdit;
    IniPropStorage1: TIniPropStorage;
    Label1: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    CloseBtn: TSpeedButton;
    ApplyBtn: TSpeedButton;
    Label6: TLabel;
    Label7: TLabel;
    procedure ApplyBtnClick(Sender: TObject);
    procedure CloseBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private

  public

  end;

var
  SettingsForm: TSettingsForm;

implementation

uses unit1;

{$R *.lfm}

{ TSettingsForm }


procedure TSettingsForm.FormCreate(Sender: TObject);
begin
  IniPropStorage1.IniFileName := MainForm.IniPropStorage1.IniFileName;
  FileNameEdit1.ButtonWidth := FileNameEdit1.Height;
  DirectoryEdit1.ButtonWidth := DirectoryEdit1.Height;
end;

//Создаём конфиг ~/.config/qemoo.cfg
procedure TSettingsForm.ApplyBtnClick(Sender: TObject);
var
  S: TStringList;
begin
  S := TStringList.Create;

  try
    //#QEMUADD=
    S.Add('# Setup parameters for qemoo');
    S.Add('');
    S.Add('# additional parameters for qemu');
    if ComboBox1.Text = 'auto' then
      S.Add('#QEMUADD="-vga std -smp 2"')
    else
      S.Add('QEMUADD="' + ComboBox1.Text + '"');

    //#ACTION=(select from GUI)
    S.Add('');
    S.Add('# what to do (run or install, default:  run)');
    S.Add('#ACTION=' + '''' + 'run' + '''');

    //#QCOW2=
    s.Add('');
    S.Add('# name for qcow2 image to install (default: q${RANDOM}.qcow2)');
    if ComboBox5.Text = 'auto' then
      S.Add('#QCOW2=' + '''' + 'my_machine.qcow2' + '''')
    else
      S.Add('QCOW2=' + '''' + ComboBox5.Text + '''');

    //#SIZE=
    S.Add('');
    S.Add('# size (Gb) for qcow2 image to install (default: 10)');
    if (ComboBox3.Text = 'auto') then
      S.Add('#SIZE=' + '''' + '10' + '''')
    else
      S.Add('SIZE=' + '''' + ComboBox3.Text + '''');

    //#RAM=
    S.Add('');
    S.Add('# size of ram (Gb) for guest machine (default: RAM / 2, but not greater than 4)');
    if (ComboBox2.Text = 'auto') then
      S.Add('#RAM=' + '''' + '4' + '''')
    else
      S.Add('RAM=' + '''' + ComboBox2.Text + '''');

    //#EFI_FIRMWARE=
    S.Add('');
    S.Add('# efi firmware emulator for current architicture');
    if FileNameEdit1.Text = '/usr/share/OVMF/OVMF_CODE.fd' then
      S.Add('#EFI_FIRMWARE=' + '''' + '-bios /usr/share/OVMF/OVMF_CODE.fd' + '''')
    else
      S.Add('EFI_FIRMWARE=' + '''' + '-bios ' + FileNameEdit1.Text + '''');

    S.Add('');
    S.Add('# host dir to share');
    if DirectoryEdit1.Text = '/home' then
      S.Add('#SHARE=/home')
    else
      S.Add('SHARE=' + DirectoryEdit1.Text);

    //Сохранение конфигурации
    S.SaveToFile(GetUserDir + '.config/qemoo.cfg');
  finally
    S.Free;
    Close;
  end;
end;

procedure TSettingsForm.CloseBtnClick(Sender: TObject);
begin
  Close;
end;

//Автовысота формы
procedure TSettingsForm.FormShow(Sender: TObject);
var
  s: ansistring;
begin
  SettingsForm.Height := ApplyBtn.Top + ApplyBtn.Height + 8;

  //Начитываем параметры из конфига, если есть - иначе всё "auto"
  if FileExists(GetUserDir + '.config/qemoo.cfg') then
  begin
    //#QEMUADD=
    RunCommand('/bin/bash', ['-c',
      'grep "^QEMUADD=*" ~/.config/qemoo.cfg | cut -f2 -d"\""'], s);
    if s = '' then ComboBox1.Text := 'auto'
    else
      ComboBox1.Text := Trim(s);

    //#QCOW2=
    RunCommand('/bin/bash', ['-c',
      'grep "^QCOW2=*" ~/.config/qemoo.cfg | cut -f2 -d"' + '''' + '"'], s);
    if s = '' then ComboBox5.Text := 'auto'
    else
      ComboBox5.Text := Trim(s);

    //#SIZE=
    RunCommand('/bin/bash', ['-c',
      'grep "^SIZE=*" ~/.config/qemoo.cfg | cut -f2 -d"' + '''' + '"'], s);
    if s = '' then ComboBox3.Text := 'auto'
    else
      ComboBox3.Text := Trim(s);

    //#RAM=
    RunCommand('/bin/bash', ['-c',
      'grep "^RAM=*" ~/.config/qemoo.cfg | cut -f2 -d"' + '''' + '"'], s);
    if s = '' then ComboBox2.Text := 'auto'
    else
      ComboBox2.Text := Trim(s);

    //#EFI_FIRMWARE=
    RunCommand('/bin/bash', ['-c',
      'grep "^EFI_FIRMWARE=*" ~/.config/qemoo.cfg | cut -f2 -d"' +
      '''' + '" | cut -f2 -d" "'], s);
    if s = '' then FileNameEdit1.Text := '/usr/share/OVMF/OVMF_CODE.fd'
    else
      FileNameEdit1.Text := Trim(s);

    //#SHARE=
    RunCommand('/bin/bash', ['-c',
      'grep "^SHARE=*" ~/.config/qemoo.cfg | cut -f2 -d"' + '=' + '"'], s);
    if s = '' then DirectoryEdit1.Text := '/home'
    else
      DirectoryEdit1.Text := Trim(s);
  end;
end;

end.
