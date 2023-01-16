unit clone_progress_trd;

{$mode objfpc}{$H+}

interface

uses
  Classes, Process, SysUtils, ComCtrls, Forms;

type
  StartClone = class(TThread)
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

procedure StartClone.Execute;
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

    ExProcess.Parameters.Add(clone_cmd);

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

//Запуск клонирования VM
procedure StartClone.StartProcess;
begin
  with MainForm do
  begin
    //Очищаем лог
    LogMemo.Clear;

    //Запомнить индекс из списка установленных образов
    findex := FileListBox1.ItemIndex;

    //Если есть флаг (NO)EFI ~/.gqemoo/image.qcow2 - создать такой же для клона
    if FileExists(GetUserDir + '.gqemoo/' +
      FileListBox1.Items[FileListBox1.ItemIndex]) then
      ListBox1.Items.SaveToFile(GetUserDir + '.gqemoo/' +
        Copy(clone_cmd, Pos('" ', clone_cmd) + 2, Length(clone_cmd)));

    LogMemo.Repaint;
  end;
end;

//Клонирование VM завершено
procedure StartClone.StopProcess;
begin
  with MainForm do
  begin
    Application.ProcessMessages;

    //Известить об окончании клонирования
    LogMemo.Append(SCloningComplete);
    LogMemo.Repaint;

    //Обновить список установленных образов
    MainForm.FileListBox1.UpdateFileList;

    //И вернуть курсор на прежнюю позицию в списке установленных образов
    FileListBox1.SetFocus;
    if FileListbox1.Count = 1 then FileListbox1.ItemIndex := 0
    else
      FileListbox1.ItemIndex := findex;
    FileListBox1.Click;

    //Подчистить флаг (NO)EFI в случае отмены/ошибки
    DeleteFile(GetUserDir + '.gqemoo/' +
        Copy(clone_cmd, Pos('" ', clone_cmd) + 2, Length(clone_cmd)));
  end;
end;

//Вывод лога
procedure StartClone.ShowLog;
var
  i: integer;
begin
  with MainForm do
  begin
    LogMemo.Clear;

    //Вывод построчно
    LogMemo.Append(SCloningMsg + ' ' + FileListBox1.Items[FileListBox1.ItemIndex] +
      ' -> ' + Copy(clone_cmd, Pos('" ', clone_cmd) + 2, Length(clone_cmd)));

    for i := 0 to Result.Count - 1 do
      MainForm.LogMemo.Lines.Append(Trim(Result[i]));
  end;
end;

end.
