program StoryOP.Tests;

{$IFNDEF TESTINSIGHT}
  {$IFDEF TESTGUI}
    {$APPTYPE GUI}
  {$ELSE}
    {$APPTYPE CONSOLE}
  {$ENDIF}
{$ENDIF}
{$STRONGLINKTYPES ON}

{$R *.res}

uses
  System.SysUtils,
  System.IOUtils,
  System.Classes,
  DUnitX.TestFramework,
  {$IF DEFINED(TESTINSIGHT)}
  TestInsight.DUnitX,
  {$ELSEIF DEFINED(TESTGUI)}
  DUnitX.Loggers.GUI.VCL,
  {$ELSE}
  DUnitX.Loggers.Console,
  DunitX.loggers.XML.NUnit,
  {$ENDIF}
  StoryOP in 'StoryOP.pas',
  StoryOP.BankAccount.Tests in 'StoryOP.BankAccount.Tests.pas';

{ keep comment here to protect the following conditional from being removed by the IDE when adding a unit }
{$IFNDEF TESTINSIGHT}
var
  Runner   : ITestRunner;
  Results  : IRunResults;
  Logger   : ITestLogger;
  XMLLogger: ITestLogger;
{$ENDIF}
begin
{$IFDEF TESTINSIGHT}
  TestInsight.DUnitX.RunRegisteredTests;
{$ELSEIF DEFINED(TESTGUI)}
  TDUnitX.Run;
{$ELSE}
  try
    TDUnitX.RegisterTestFixture(TBankAccountTests);

    Runner := TDUnitX.CreateRunner;
    Runner.UseRTTI := True;

    // Console logger — shows narrative output and pass/fail summary
    Logger := TDUnitXConsoleLogger.Create(True);
    Runner.AddLogger(Logger);

    // NUnit-compatible XML log — useful for CI pipelines
    XMLLogger := TDUnitXXmlNUnitLogger.Create(
      TFileStream.Create(
        TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
                    'StoryOP.Tests.Results.xml'),
                    fmCreate or fmShareDenyWrite
                    )
    );
    Runner.AddLogger(XMLLogger);

    Runner.FailsOnNoAsserts := False;

    Results := Runner.Execute;

    if not Results.AllPassed then
      System.ExitCode := EXIT_ERRORS;

    {$IFNDEF CI}
    // Pause at the console when running interactively
    WriteLn;
    WriteLn('Press <Enter> to exit...');
    ReadLn;
    {$ENDIF}

  except
    on E: Exception do
    begin
      WriteLn(E.ClassName, ': ', E.Message);
      System.ExitCode := EXIT_ERRORS;
    end;
  end;
{$IFEND}
end.

