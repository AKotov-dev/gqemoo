unit start_trd;

{$mode objfpc}{$H+}

interface

uses
  Classes, Process, SysUtils, ComCtrls, Forms;

type
  StartVM = class(TThread)
  private

    { Private declarations }
  protected
  var
    Result: TStringList;

    procedure Execute; override;

    procedure ShowLog;
    procedure StartProcess;
    procedure StopProcess;

  end;

implementation

uses Unit1;

{ TRD }

procedure StartVM.Execute;
var
  ExProcess: TProcess;
begin
  try //Вывод лога и прогресса
    Synchronize(@StartProcess);

    FreeOnTerminate := True; //Уничтожить по завершении
    Result := TStringList.Create;

    //Рабочий процесс
    ExProcess := TProcess.Create(nil);

    ExProcess.Executable := 'bash';
    ExProcess.Parameters.Add('-c');

    ExProcess.Parameters.Add(command);

    ExProcess.Options := [poUsePipes, poStderrToOutPut];
    //, poWaitOnExit (синхронный вывод)

    ExProcess.Execute;

    //Выводим лог динамически
    while ExProcess.Running do
    begin
      Result.LoadFromStream(ExProcess.Output);

      if Result.Count <> 0 then
        Synchronize(@ShowLog);
    end;

  finally
    Synchronize(@StopProcess);
    Result.Free;
    ExProcess.Free;
    Terminate;
  end;
end;

{ БЛОК ОТОБРАЖЕНИЯ ЛОГА }

//Запуск VM
procedure StartVM.StartProcess;
var
  usb: string;
  s: ansistring;
begin
  with MainForm do
  begin
    //Очищаем лог
    LogMemo.Clear;

    //Если запуск с флешки - попытка размонтировать /dev/xxx{1..4}
    if DevBox.ItemIndex <> DevBox.Items.Count - 1 then
    begin
      usb := Copy(DevBox.Text, 1, Pos(' ', DevBox.Text) - 1);
      RunCommand('/bin/bash', ['-c', 'umount -l ' + usb + '1 ' + usb +
        '2 ' + usb + '3 ' + usb + '4'], s);
    end;

    //Пользователь в группе disk? Нет - команда на выход
    RunCommand('/bin/bash', ['-c', 'groups | grep disk'], s);
    if Trim(s) = '' then command :=
        'echo "The user is not in group disk! Run: usermod -aG disk ' +
        GetEnvironmentVariable('USER') + '; reboot"; exit 1';

    LogMemo.Repaint;
  end;
end;

//Запуск VM завершен
procedure StartVM.StopProcess;
begin
 { with MainForm do
  begin
    Application.ProcessMessages;
    DevBox.Enabled := True;
    ReloadBtn.Enabled := True;
    FileNameEdit1.Enabled := True;
    StartBtn.Enabled := True;
  end;}
end;

//Вывод лога
procedure StartVM.ShowLog;
var
  i: integer;
begin
  //Вывод построчно
  for i := 0 to Result.Count - 1 do
    MainForm.LogMemo.Lines.Append(Result[i]);

  //Промотать список вниз
  MainForm.LogMemo.SelStart := Length(MainForm.LogMemo.Text);
  MainForm.LogMemo.SelLength := 0;
end;

end.
