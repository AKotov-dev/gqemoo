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
    findex: integer;

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

    //Проверка юзера в группе disk, наличие remote-viewer, запуск > 1 VM
    //Иначе - ожидание 15 sec localhost:3001 для подключения spice-vdagent/spice-guest-tools извне
    ExProcess.Parameters.Add(
      'if [[ -z $(groups | grep disk) ]]; then echo "' + SUserNotInGroup +
      '"; exit 1; fi; if [[ ! $(type -f remote-viewer 2>/dev/null) ]]; then echo "' +
      SRemoteViewerNotFound + '"; exit 1; fi; ' +
      'if [[ $(ss -ltn | grep 3001) ]]; then echo "' + SAnotherVMRunning +
      '"; exit 1; fi; ' + command +
      ' & i=0; while [[ -z $(ss -ltn | grep 3001) ]]; do sleep 1; ((i++)); ' +
      'echo "waiting for spice-server on 127.0.0.1:3001 ($i of 15 sec)..."; if [[ $i == 15 ]]; then break; fi; done '
      + '&& remote-viewer -v spice://localhost:3001 && [[ $(pidof qemu-system-x86_64) ]] && killall qemu-system-x86_64');

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

    //Запомнить индекс из списка установленных образов
    findex := FileListBox1.ItemIndex;

    //Если запуск с флешки - попытка размонтировать /dev/xxx{1..4}
    if DevBox.ItemIndex <> DevBox.Items.Count - 1 then
    begin
      usb := Copy(DevBox.Text, 1, Pos(' ', DevBox.Text) - 1);
      RunCommand('/bin/bash', ['-c', 'umount -l ' + usb + '1 ' + usb +
        '2 ' + usb + '3 ' + usb + '4'], s);
    end;

    LogMemo.Repaint;
  end;
end;

//Запуск VM завершен
procedure StartVM.StopProcess;
begin
  with MainForm do
  begin
    Application.ProcessMessages;
    LogMemo.Repaint;

    //Если появился новый образ - обновить
    FileListBox1.UpdateFileList;

    //И вернуть курсор на прежнюю позицию в списке установленных образов
    FileListBox1.SetFocus;
    if FileListbox1.Count = 1 then FileListbox1.ItemIndex := 0
    else
      FileListbox1.ItemIndex := findex;
    FileListBox1.Click;
  end;
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
