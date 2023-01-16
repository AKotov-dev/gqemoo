program gqemoo;

{$mode objfpc}{$H+}

uses
 {$IFDEF UNIX}
  cthreads,
          {$ENDIF} {$IFDEF HASAMIGA}
  athreads,
          {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms,
  Unit1,
  start_trd,
  clone_progress_trd;

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Title:='GQemoo v1.8';
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
