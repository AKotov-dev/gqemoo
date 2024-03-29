unit set_unit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons, Process;

type

  { TSetForm }

  TSetForm = class(TForm)
    ADDBox: TComboBox;
    SIZEBox: TComboBox;
    RAMBox: TComboBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    SetBtn: TSpeedButton;
    DefaultBtn: TSpeedButton;
    procedure DefaultBtnClick(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: char);
    procedure FormShow(Sender: TObject);
    procedure SetBtnClick(Sender: TObject);
  private

  public

  end;

var
  SetForm: TSetForm;

implementation

{$R *.lfm}

{ TSetForm }

//Чтение параметров из /etc/qemoo.cfg
procedure TSetForm.FormShow(Sender: TObject);
var
  S: ansistring;
begin
  SetForm.Height := ADDBox.Top + ADDBox.Height + 8;
  RAMBox.SetFocus;

  //RAM
  RunCommand('/bin/bash', ['-c', 'grep "^RAM=" /etc/qemoo.cfg | sed s/[^0-9]//g'], S);
  RAMBox.Text := Trim(S);

  //SIZE
  RunCommand('/bin/bash', ['-c', 'grep "^SIZE=" /etc/qemoo.cfg | sed s/[^0-9]//g'], S);
  SIZEBox.Text := Trim(S);

  //QEMUADD
  RunCommand('/bin/bash', ['-c',
    'grep "^QEMUADD=" /etc/qemoo.cfg | sed "s/QEMUADD=//" | tr -d \"\' + ''''], S);
  ADDBox.Text := Trim(S);
end;

//Default
procedure TSetForm.DefaultBtnClick(Sender: TObject);
begin
  RAMBox.Clear;
  SIZEBox.Clear;
  ADDBox.Clear;

  SetBtn.Click;
end;

//Нажатие Enter = Apply
procedure TSetForm.FormKeyPress(Sender: TObject; var Key: char);
begin
  if Key = #13 then SetBtn.Click;
end;

//Сохранение конфига
procedure TSetForm.SetBtnClick(Sender: TObject);
var
  S: TStringList;
  UserDir: string;
  Output: ansistring;
begin
  //Убираем крайние пробелы
  RAMBox.Text := Trim(RAMBox.Text);
  SIZEBox.Text := Trim(SIZEBox.Text);
  ADDBox.Text := Trim(ADDBox.Text);

  try
    S := TStringList.Create;

    S.Add('# Setup parameters for qemoo');
    S.Add('');

    S.Add('# additional parameters for qemu');
    if ADDBox.Text <> '' then
      S.Add('QEMUADD="' + Trim(ADDBox.Text) + '"')
    else
      S.Add('#QEMUADD="-vga qxl -smp 2"');
    S.Add('');

    S.Add('# what to do (run or install, default:  run)');
    S.Add('#ACTION=' + '''' + 'run' + '''');
    S.Add('');
    S.Add('# name for qcow2 image to install (default: auto)');
    S.Add('#QCOW2=' + '''' + 'my_machine.qcow2' + '''');
    S.Add('');

    S.Add('# size (Gb) for qcow2 image to install (default: 20)');
    if SIZEBox.Text <> '' then
      S.Add('SIZE=' + '''' + Trim(SIZEBox.Text) + '''')
    else
      S.Add('#SIZE=' + '''' + '10' + '''');
    S.Add('');

    S.Add('# size of ram (MB) for guest machine (default: RAM / 2, but not greater than 4 GB)');
    if RAMBox.Text <> '' then
      S.Add('RAM=' + '''' + Trim(RAMBox.Text) + '''')
    else
      S.Add('#RAM=' + '''' + '2000' + '''');

    S.Add('');
    S.Add('# efi firmware emulator for current architicture');
    S.Add('#EFI_FIRMWARE=' + '''' + '-bios /usr/share/OVMF/OVMF_CODE.fd' + '''');
    S.Add('');
    S.Add('# host dir to share');
    S.Add('#SHARE=/home');

    //Сохраняем ~/.gqemoo/qemoo_dist.cfg
    S.SaveToFile(GetUserDir + '.gqemoo/qemoo_dist.cfg');

    Application.ProcessMessages;

    UserDir := GetUserDir;

    //Замена ~/.gqemoo/qemoo_dist.cfg > /etc/qemoo.cfg через pkexec
    RunCommand('/bin/bash',
      ['-c', 'pkexec /bin/bash -c "cp -f ' + UserDir +
      '.gqemoo/qemoo_dist.cfg /etc/qemoo.cfg"; echo $?'],
      Output);

    //Ловим отмену и ошибку аутентификации pkexec
    //if (Trim(S) <> '126') and (Trim(S) <> '127') then

  finally
    S.Free;
  end;
  SetForm.Close;
end;

end.
