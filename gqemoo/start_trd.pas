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
    procedure StartProgress;
    procedure StopProgress;

  end;

implementation

uses Unit1;

{ TRD }

procedure StartVM.Execute;
var
  ExProcess: TProcess;
begin
  try //Вывод лога и прогресса
    Synchronize(@StartProgress);

    FreeOnTerminate := True; //Уничтожить по завершении
    Result := TStringList.Create;

    //Рабочий процесс
    ExProcess := TProcess.Create(nil);

    //Создаём раздел ${usb}1
    ExProcess.Executable := 'bash';
    ExProcess.Parameters.Add('-c');
    //Группа команд (parted)
    ExProcess.Parameters.Add(command);

    ExProcess.Options := [poUsePipes, poStderrToOutPut];
    //, poWaitOnExit (синхронный вывод)

    ExProcess.Execute;

    //Выводим лог динамически
    while ExProcess.Running do
    begin
      Result.LoadFromStream(ExProcess.Output);

      //Выводим лог
      if Result.Count <> 0 then
        Synchronize(@ShowLog);
    end;

  finally
    Synchronize(@StopProgress);
    Result.Free;
    ExProcess.Free;
    Terminate;
  end;
end;

{ БЛОК ОТОБРАЖЕНИЯ ЛОГА }

//Старт индикатора
procedure StartVM.StartProgress;
begin
  with MainForm do
  begin
    LogMemo.Clear;
   { Application.ProcessMessages;
    DevBox.Enabled := False;
    ReloadBtn.Enabled := False;
    FileNameEdit1.Enabled := False;
    StartBtn.Enabled := False;}
  end;
end;

//Стоп индикатора
procedure StartVM.StopProgress;
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

  //Вывод пачками
  //MainForm.LogMemo.Lines.Assign(Result);
end;

end.
