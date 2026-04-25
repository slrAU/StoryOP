unit StoryOP;

(*
  StoryOP  -  Story Object Pascal
  =================================
  A StoryQ-inspired BDD wrapper for DUnitX.

  StoryOP is a flexible story-driven testing DSL that wraps DUnitX
  with a fluent Story > Scenario > Given / When / Then syntax.  It
  supports multiple narrative styles without enforcing any single
  development methodology.

  Narrative patterns (mix and match freely)
  -----------------------------------------

    BDD canonical (Role / Behaviour / Benefit)
      Story('Account Holder Withdraws Cash')
        .AsA('account holder')
        .IWant('to withdraw cash from the ATM')
        .SoThat('I have spending money')

    Classic BDD (In Order To / As A / I Want To)
      Story('Account Holder Withdraws Cash')
        .InOrderTo('have spending money')
        .AsA('account holder')
        .IWantTo('withdraw cash from the ATM')

    FDD (Action / Outcome / Entity)
      Story('Withdraw Cash From Account')
        .Action('withdraw a sum of money')
        .Outcome('the account balance is reduced')
        .Entity('bank account')

    Declarative / mixed
      Story('Account Holder Withdraws Cash')
        .AsA('account holder')
        .Action('withdraw cash from the ATM')
        .Outcome('the account balance is reduced')

    Plain string only
      Story('As an account holder I want to withdraw cash')

  All narrative methods append an ordered (label, text) pair.
  They may be called in any order, any number of times, and freely
  mixed.  The report prints them exactly as supplied.

  Step naming
  -----------
  Step procedures are declared as plain methods of the test fixture
  class (procedure of object).  Their names may use CamelCase,
  underscores, or a mixture; all are converted to lowercase
  space-separated narrative text.  All-uppercase tokens (acronyms)
  are preserved:

      AccountIsInCredit            ->  "account is in credit"
      Account_is_in_credit         ->  "account is in credit"
      CustomerWithdrawsFromATM     ->  "customer withdraws from ATM"
      RequestWithdrawalOf20        ->  "request withdrawal of 20"

  Step methods
  ------------
  Every step method (Given, When, Then_, AndAlso) accepts one of:

    1. A TStepMethod (procedure of object) — the primary path.
       The method name is extracted via RTTI by matching the code
       address against the fixture's RTTI method table.  This gives
       an exact, reliable name with no heuristic suffix-stripping:

           .Given(AccountIsInCredit)
           .When(CustomerRequestsAWithdrawalOf20)
           .Then_(AccountBalanceShouldBe80)

    2. A TProc (anonymous method) with a mandatory label string.
       RTTI extraction is bypassed; the label is used directly.
       Use this for inline anonymous methods or parameterised steps:

           .Given(procedure begin FAccount.Deposit(100) end,
                  'account starts with 100')

    3. A pre-built TBDDStep created via the Step() factory.
       The description is captured once at construction and stored
       permanently, making it safe to assign to a variable and reuse:

           var S: TBDDStep;
           S := Step(AccountIsInCredit);   // name captured here
           ...
           .Given(S)                       // description already stored

  Failure behaviour
  -----------------
    - A failing Given or When halts the scenario; all remaining
      steps are marked SKIPPED.
    - A failing Then is recorded; subsequent Thens still run.

  Reporting
  ---------
  Plain-text narrative is emitted via TDUnitX.CurrentRunner.Log,
  which appears in all registered DUnitX loggers (console, XML, etc.)
  and is visible in TestInsight.

  Compatibility
  -------------
  Delphi 2009+  (requires Rtti unit, generics not required).
  {$IFDEF FPC} guard included; RTTI behaviour under FPC/Lazarus
  may require adjustment.
*)

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Character,
  System.Rtti,
  System.Contnrs,
  DUnitX.TestFramework;

type
  // -----------------------------------------------------------------------
  //  Forward declarations
  // -----------------------------------------------------------------------
  TBDDStep     = class;
  TBDDScenario = class;
  TBDDStory    = class;

  // -----------------------------------------------------------------------
  //  TStepMethod
  //  The primary step procedure type.
  //  Declared as "procedure of object" so that Delphi passes it as a
  //  TMethod record (Code + Data) rather than as a managed interface.
  //  This allows reliable RTTI name lookup by code-address matching,
  //  and clean invocation via TMethod at run time.
  // -----------------------------------------------------------------------
  TStepMethod = procedure of object;

  TStepOutcome = (soNotRun, soPassed, soFailed, soSkipped);

  // -----------------------------------------------------------------------
  //  TNarrativeLine
  //  A single (label, text) pair in the story header.
  //  Stored in insertion order so the report reflects the developer's
  //  chosen narrative pattern exactly.
  // -----------------------------------------------------------------------
  TNarrativeLine = record
    Label_ : string;
    Text   : string;
  end;

  // -----------------------------------------------------------------------
  //  TBDDStep
  //  A self-describing, executable step.
  //
  //  Internally stores either:
  //    - A TMethod (Code + Data) for TStepMethod steps — primary path
  //    - A TProc for anonymous method steps — secondary path
  //  Exactly one of these will be set; the other will be nil/empty.
  //
  //  Construct via the module-level Step() factory or via the scenario
  //  step methods directly.
  // -----------------------------------------------------------------------
  TBDDStep = class
  private
    FDescription : string;
    FMethod      : TMethod;  // set for TStepMethod steps
    FProc        : TProc;    // set for anonymous method steps
    FKind        : string;
    FOutcome     : TStepOutcome;
    FErrorMessage: string;
  public
    // Construct from a typed method reference (primary path)
    constructor CreateFromMethod(const AMethod: TMethod;
                                 const ADescription: string);
    // Construct from an anonymous method (secondary path)
    constructor CreateFromProc(const AProc: TProc;
                               const ADescription: string);

    procedure Run;

    property Description  : string       read FDescription;
    property Kind         : string       read FKind         write FKind;
    property Outcome      : TStepOutcome read FOutcome      write FOutcome;
    property ErrorMessage : string       read FErrorMessage write FErrorMessage;
  end;

  // -----------------------------------------------------------------------
  //  TBDDScenario
  // -----------------------------------------------------------------------
  TBDDScenario = class
  private
    FStory    : TBDDStory;
    FTitle    : string;
    FSteps    : TObjectList;
    FLastKind : string;
    FHalted   : Boolean;

    procedure AddStep(const AKind: string; AStep: TBDDStep);

    // Internal wrappers that create TBDDStep from the two source types
    function  StepFromMethod(AMethod: TStepMethod): TBDDStep;
    function  StepFromProc  (AProc: TProc; const ALabel: string): TBDDStep;
  public
    constructor Create(AStory: TBDDStory; const ATitle: string);
    destructor  Destroy; override;

    // --- Primary overloads: TStepMethod (procedure of object) ---
    // Name is derived automatically via RTTI; no string required.
    function Given  (AMethod: TStepMethod): TBDDScenario; overload;
    function When   (AMethod: TStepMethod): TBDDScenario; overload;
    function Then_  (AMethod: TStepMethod): TBDDScenario; overload;
    function AndAlso(AMethod: TStepMethod): TBDDScenario; overload;

    // --- Anonymous method overloads: TProc + mandatory label ---
    // Use for inline anonymous methods or parameterised steps.
    function Given  (AProc: TProc; const ALabel: string): TBDDScenario; overload;
    function When   (AProc: TProc; const ALabel: string): TBDDScenario; overload;
    function Then_  (AProc: TProc; const ALabel: string): TBDDScenario; overload;
    function AndAlso(AProc: TProc; const ALabel: string): TBDDScenario; overload;

    // --- Pre-built step overloads: TBDDStep ---
    // Description is already stored; safe to reuse across scenarios.
    function Given  (AStep: TBDDStep): TBDDScenario; overload;
    function When   (AStep: TBDDStep): TBDDScenario; overload;
    function Then_  (AStep: TBDDStep): TBDDScenario; overload;
    function AndAlso(AStep: TBDDStep): TBDDScenario; overload;

    // Start a new sibling scenario on the same story
    function WithScenario(const ATitle: string): TBDDScenario;

    // Run all steps, emit report, free story, raise on failure
    procedure Execute;

    property Title : string    read FTitle;
    property Story : TBDDStory read FStory;
  end;

  // -----------------------------------------------------------------------
  //  TBDDStory
  // -----------------------------------------------------------------------
  TBDDStory = class
  private
    FTitle     : string;
    FNarrative : array of TNarrativeLine;
    FScenarios : TObjectList;

    procedure AddNarrative(const ALabel, AText: string);
    procedure WriteReport;
    function  OutcomeTag(AOutcome: TStepOutcome): string;
  public
    constructor Create(const ATitle: string);
    destructor  Destroy; override;

    // ---- BDD canonical ------------------------------------------------
    function AsA      (const AText: string): TBDDStory;  // "As a <role>"
    function IWantTo  (const AText: string): TBDDStory;  // "I want to <behaviour>"
    function IWant    (const AText: string): TBDDStory;  // "I want <behaviour>"
    function InOrderTo(const AText: string): TBDDStory;  // "In order to <benefit>"
    function SoThat   (const AText: string): TBDDStory;  // "So that <benefit>"

    // ---- FDD / Action-Outcome-Entity ----------------------------------
    function Action   (const AText: string): TBDDStory;  // "Action <behaviour>"
    function Outcome  (const AText: string): TBDDStory;  // "Outcome <result>"
    function Entity   (const AText: string): TBDDStory;  // "Entity <object/role>"

    // ---- Escape hatch -------------------------------------------------
    function Narrative(const ALabel, AText: string): TBDDStory;

    // ---- Scenario chain -----------------------------------------------
    function WithScenario(const ATitle: string): TBDDScenario;

    property Title : string read FTitle;
  end;

// -----------------------------------------------------------------------
//  Module-level helpers
// -----------------------------------------------------------------------

{ Step factory — TStepMethod primary path.
  Name derived from the method via RTTI; stored on the TBDDStep.
  Use when you want to pre-build a step and assign it to a variable. }
function Step(AMethod: TStepMethod): TBDDStep; overload;

{ Step factory — TProc secondary path.
  ALabel is required (no RTTI name extraction for anonymous methods). }
function Step(AProc: TProc; const ALabel: string): TBDDStep; overload;

{ Top-level story factory. }
function Story(const ATitle: string): TBDDStory;

{ Name-conversion utilities — exposed for independent unit-testing. }
function MethodNameFromRtti(const AMethod: TMethod) : string;
function IdentifierToWords (const AName: string)    : string;
function CamelCaseToWords  (const AName: string)    : string;
function UnderscoreToWords (const AName: string)    : string;

implementation

// ==========================================================================
//  Name conversion
// ==========================================================================

{
  CamelCaseToWords
  ----------------
  Splits a CamelCase / PascalCase identifier into space-separated words.

  Boundary rules applied left-to-right:
    1. Lowercase or digit -> Uppercase      "accountBalance" -> "account Balance"
    2. Uppercase run before Upper+Lower     "ATMCard"        -> "ATM Card"
    3. Letter <-> Digit transition          "Of20GBP"        -> "Of 20 GBP"

  Post-processing:
    All-uppercase tokens of length > 1 are treated as acronyms and
    preserved as-is; all other tokens are lowercased.
}
function CamelCaseToWords(const AName: string): string;
var
  I                           : Integer;
  Len                         : Integer;
  Words                       : TStringList;
  Token                       : string;
  Prev, Curr, Next, AfterNext : Char;
  CurrUp, NextUp, AfterNextLo : Boolean;
  PrevDigit, CurrDigit        : Boolean;
begin
  Result := '';
  Len    := Length(AName);
  if Len = 0 then Exit;

  Words := TStringList.Create;
  try
    Token := AName[1];

    for I := 2 to Len do
    begin
      Prev := AName[I - 1];
      Curr := AName[I];

      Next      := #0;
      AfterNext := #0;
      if I < Len     then Next      := AName[I + 1];
      if I < Len - 1 then AfterNext := AName[I + 2];

      CurrUp      := TCharacter.IsUpper(Curr);
      NextUp      := (Next <> #0) and TCharacter.IsUpper(Next);
      AfterNextLo := (AfterNext <> #0) and TCharacter.IsLower(AfterNext);
      PrevDigit   := TCharacter.IsDigit(Prev);
      CurrDigit   := TCharacter.IsDigit(Curr);

      // Rule 3: letter <-> digit boundary
      if CurrDigit <> PrevDigit then
      begin
        Words.Add(Token);
        Token := Curr;
        Continue;
      end;

      // Rule 1: lowercase/digit -> uppercase
      if CurrUp and (TCharacter.IsLower(Prev) or PrevDigit) then
      begin
        Words.Add(Token);
        Token := Curr;
        Continue;
      end;

      // Rule 2: end of uppercase run before Upper+Lower (e.g. "ATM" + "Card")
      if CurrUp and NextUp and AfterNextLo then
      begin
        Words.Add(Token);
        Token := Curr;
        Continue;
      end;

      Token := Token + Curr;
    end;

    if Token <> '' then
      Words.Add(Token);

    for I := 0 to Words.Count - 1 do
    begin
      Token := Words[I];
      if Result <> '' then
        Result := Result + ' ';
      // Preserve acronyms (all-uppercase tokens of length > 1)
      if (Length(Token) > 1) and (Token = UpperCase(Token)) then
        Result := Result + Token
      else
        Result := Result + LowerCase(Token);
    end;

  finally
    Words.Free;
  end;
end;

function UnderscoreToWords(const AName: string): string;
begin
  Result := StringReplace(AName, '_', ' ', [rfReplaceAll]);
end;

{
  IdentifierToWords
  -----------------
  If the identifier contains underscores, splits on them first and
  applies CamelCaseToWords to each token.  Otherwise applies
  CamelCaseToWords directly.  Handles mixed forms such as
  "Account_IsInCredit" naturally.
}
function IdentifierToWords(const AName: string): string;
var
  Parts : TStringList;
  I     : Integer;
  Part  : string;
begin
  Result := '';
  if AName = '' then Exit;

  if Pos('_', AName) > 0 then
  begin
    Parts := TStringList.Create;
    try
      Parts.Delimiter       := '_';
      Parts.StrictDelimiter := True;
      Parts.DelimitedText   := AName;

      for I := 0 to Parts.Count - 1 do
      begin
        Part := Trim(Parts[I]);
        if Part = '' then Continue;
        if Result <> '' then Result := Result + ' ';
        Result := Result + CamelCaseToWords(Part);
      end;
    finally
      Parts.Free;
    end;
  end
  else
    Result := CamelCaseToWords(AName);

  Result := Trim(Result);
end;

// ==========================================================================
//  RTTI name extraction
// ==========================================================================

{
  MethodNameFromRtti
  ------------------
  Extracts the human-readable name of a step procedure using RTTI.

  Because TStepMethod is "procedure of object", Delphi passes it as a
  TMethod record containing:
    .Data  — pointer to the object instance (the test fixture)
    .Code  — pointer to the procedure's machine code

  We obtain the fixture's RTTI type via .Data, then walk its method
  table looking for a method whose CodeAddress matches .Code.  This is
  an exact address match — no heuristic suffix-stripping required.

  The matched method name is then passed through IdentifierToWords to
  produce the narrative text.
}
function MethodNameFromRtti(const AMethod: TMethod): string;
var
  Ctx      : TRttiContext;
  RType    : TRttiType;
  RMethod  : TRttiMethod;
  Instance : TObject;
begin
  Result := '(unnamed step)';

  if (AMethod.Data = nil) or (AMethod.Code = nil) then
    Exit;

  Instance := TObject(AMethod.Data);

  Ctx   := TRttiContext.Create;
  RType := Ctx.GetType(Instance.ClassType);

  while Assigned(RType) do
  begin
    for RMethod in RType.GetDeclaredMethods do
    begin
      if RMethod.CodeAddress = AMethod.Code then
      begin
        Result := IdentifierToWords(RMethod.Name);
        Exit;
      end;
    end;

    // Move up to the parent class
    RType := RType.BaseType;
  end;
end;

// ==========================================================================
//  Module-level factories
// ==========================================================================

function Step(AMethod: TStepMethod): TBDDStep;
var
  M    : TMethod;
  Desc : string;
begin
  M    := TMethod(AMethod);
  Desc := MethodNameFromRtti(M);
  Result := TBDDStep.CreateFromMethod(M, Desc);
end;

function Step(AProc: TProc; const ALabel: string): TBDDStep;
begin
  Result := TBDDStep.CreateFromProc(AProc, ALabel);
end;

function Story(const ATitle: string): TBDDStory;
begin
  Result := TBDDStory.Create(ATitle);
end;

// ==========================================================================
//  TBDDStep
// ==========================================================================

constructor TBDDStep.CreateFromMethod(const AMethod: TMethod;
                                      const ADescription: string);
begin
  inherited Create;
  FMethod       := AMethod;
  FProc         := nil;
  FDescription  := ADescription;
  FOutcome      := soNotRun;
  FErrorMessage := '';
  FKind         := '';
end;

constructor TBDDStep.CreateFromProc(const AProc: TProc;
                                    const ADescription: string);
begin
  inherited Create;
  FMethod.Data  := nil;
  FMethod.Code  := nil;
  FProc         := AProc;
  FDescription  := ADescription;
  FOutcome      := soNotRun;
  FErrorMessage := '';
  FKind         := '';
end;

procedure TBDDStep.Run;
begin
  if FOutcome = soSkipped then Exit;
  try
    // Primary path: invoke via TMethod
    if Assigned(FMethod.Code) then
      TStepMethod(FMethod)()
    // Secondary path: invoke anonymous method
    else if Assigned(FProc) then
      FProc;

    FOutcome := soPassed;
  except
    on E: Exception do
    begin
      FOutcome      := soFailed;
      FErrorMessage := E.Message;
    end;
  end;
end;

// ==========================================================================
//  TBDDScenario
// ==========================================================================

constructor TBDDScenario.Create(AStory: TBDDStory; const ATitle: string);
begin
  inherited Create;
  FStory    := AStory;
  FTitle    := ATitle;
  FSteps    := TObjectList.Create(True);
  FLastKind := 'Given';
  FHalted   := False;
end;

destructor TBDDScenario.Destroy;
begin
  FSteps.Free;
  inherited;
end;

function TBDDScenario.StepFromMethod(AMethod: TStepMethod): TBDDStep;
var
  M    : TMethod;
  Desc : string;
begin
  M    := TMethod(AMethod);
  Desc := MethodNameFromRtti(M);
  Result := TBDDStep.CreateFromMethod(M, Desc);
end;

function TBDDScenario.StepFromProc(AProc: TProc;
                                   const ALabel: string): TBDDStep;
begin
  Result := TBDDStep.CreateFromProc(AProc, ALabel);
end;

procedure TBDDScenario.AddStep(const AKind: string; AStep: TBDDStep);
begin
  AStep.Kind := AKind;

  if FHalted then
  begin
    AStep.Outcome := soSkipped;
    FSteps.Add(AStep);
    Exit;
  end;

  FSteps.Add(AStep);
  AStep.Run;

  // Halt on failure of any Given or When (including their And continuations)
  if AStep.Outcome = soFailed then
    if (AKind = 'Given')       or (AKind = 'When') or
       (AKind = 'And (Given)') or (AKind = 'And (When)') then
      FHalted := True;
end;

// --- TStepMethod overloads ------------------------------------------------

function TBDDScenario.Given(AMethod: TStepMethod): TBDDScenario;
begin
  FLastKind := 'Given';
  AddStep('Given', StepFromMethod(AMethod));
  Result := Self;
end;

function TBDDScenario.When(AMethod: TStepMethod): TBDDScenario;
begin
  FLastKind := 'When';
  AddStep('When', StepFromMethod(AMethod));
  Result := Self;
end;

function TBDDScenario.Then_(AMethod: TStepMethod): TBDDScenario;
begin
  FLastKind := 'Then';
  AddStep('Then', StepFromMethod(AMethod));
  Result := Self;
end;

function TBDDScenario.AndAlso(AMethod: TStepMethod): TBDDScenario;
begin
  AddStep('And (' + FLastKind + ')', StepFromMethod(AMethod));
  Result := Self;
end;

// --- TProc overloads -------------------------------------------------------

function TBDDScenario.Given(AProc: TProc; const ALabel: string): TBDDScenario;
begin
  FLastKind := 'Given';
  AddStep('Given', StepFromProc(AProc, ALabel));
  Result := Self;
end;

function TBDDScenario.When(AProc: TProc; const ALabel: string): TBDDScenario;
begin
  FLastKind := 'When';
  AddStep('When', StepFromProc(AProc, ALabel));
  Result := Self;
end;

function TBDDScenario.Then_(AProc: TProc; const ALabel: string): TBDDScenario;
begin
  FLastKind := 'Then';
  AddStep('Then', StepFromProc(AProc, ALabel));
  Result := Self;
end;

function TBDDScenario.AndAlso(AProc: TProc; const ALabel: string): TBDDScenario;
begin
  AddStep('And (' + FLastKind + ')', StepFromProc(AProc, ALabel));
  Result := Self;
end;

// --- TBDDStep overloads ----------------------------------------------------

function TBDDScenario.Given(AStep: TBDDStep): TBDDScenario;
begin
  FLastKind := 'Given';
  AddStep('Given', AStep);
  Result := Self;
end;

function TBDDScenario.When(AStep: TBDDStep): TBDDScenario;
begin
  FLastKind := 'When';
  AddStep('When', AStep);
  Result := Self;
end;

function TBDDScenario.Then_(AStep: TBDDStep): TBDDScenario;
begin
  FLastKind := 'Then';
  AddStep('Then', AStep);
  Result := Self;
end;

function TBDDScenario.AndAlso(AStep: TBDDStep): TBDDScenario;
begin
  AddStep('And (' + FLastKind + ')', AStep);
  Result := Self;
end;

// --- Scenario chain --------------------------------------------------------

function TBDDScenario.WithScenario(const ATitle: string): TBDDScenario;
begin
  Result := FStory.WithScenario(ATitle);
end;

// --- Execute ---------------------------------------------------------------

procedure TBDDScenario.Execute;
var
  AllPassed : Boolean;
  FailMsgs  : TStringList;
  I, J      : Integer;
  Scenario  : TBDDScenario;
  S         : TBDDStep;
begin
  FStory.WriteReport;

  AllPassed := True;
  FailMsgs  := TStringList.Create;
  try
    for I := 0 to FStory.FScenarios.Count - 1 do
    begin
      Scenario := TBDDScenario(FStory.FScenarios[I]);
      for J := 0 to Scenario.FSteps.Count - 1 do
      begin
        S := TBDDStep(Scenario.FSteps[J]);
        if S.Outcome = soFailed then
        begin
          AllPassed := False;
          FailMsgs.Add(
            '[' + Scenario.Title + '] ' +
            S.Kind + ' ' + S.Description + ': ' + S.ErrorMessage
          );
        end;
      end;
    end;

    if not AllPassed then
      Assert.Fail('StoryOP scenario failures:' + sLineBreak + FailMsgs.Text);

  finally
    FailMsgs.Free;
    FStory.Free;   // owns all scenarios (including Self) and their steps
  end;
end;

// ==========================================================================
//  TBDDStory
// ==========================================================================

constructor TBDDStory.Create(const ATitle: string);
begin
  inherited Create;
  FTitle     := ATitle;
  FScenarios := TObjectList.Create(True);
  SetLength(FNarrative, 0);
end;

destructor TBDDStory.Destroy;
begin
  FScenarios.Free;
  inherited;
end;

procedure TBDDStory.AddNarrative(const ALabel, AText: string);
var
  Idx: Integer;
begin
  Idx := Length(FNarrative);
  SetLength(FNarrative, Idx + 1);
  FNarrative[Idx].Label_ := ALabel;
  FNarrative[Idx].Text   := AText;
end;

// ---- BDD canonical -------------------------------------------------------

function TBDDStory.AsA(const AText: string): TBDDStory;
begin AddNarrative('As a', AText);       Result := Self; end;

function TBDDStory.IWantTo(const AText: string): TBDDStory;
begin AddNarrative('I want to', AText);  Result := Self; end;

function TBDDStory.IWant(const AText: string): TBDDStory;
begin AddNarrative('I want', AText);     Result := Self; end;

function TBDDStory.InOrderTo(const AText: string): TBDDStory;
begin AddNarrative('In order to', AText); Result := Self; end;

function TBDDStory.SoThat(const AText: string): TBDDStory;
begin AddNarrative('So that', AText);    Result := Self; end;

// ---- FDD / Action-Outcome-Entity -----------------------------------------

function TBDDStory.Action(const AText: string): TBDDStory;
begin AddNarrative('Action', AText);     Result := Self; end;

function TBDDStory.Outcome(const AText: string): TBDDStory;
begin AddNarrative('Outcome', AText);    Result := Self; end;

function TBDDStory.Entity(const AText: string): TBDDStory;
begin AddNarrative('Entity', AText);     Result := Self; end;

// ---- Escape hatch --------------------------------------------------------

function TBDDStory.Narrative(const ALabel, AText: string): TBDDStory;
begin AddNarrative(ALabel, AText);       Result := Self; end;

// ---- Scenario chain ------------------------------------------------------

function TBDDStory.WithScenario(const ATitle: string): TBDDScenario;
var
  Scenario: TBDDScenario;
begin
  Scenario := TBDDScenario.Create(Self, ATitle);
  FScenarios.Add(Scenario);
  Result := Scenario;
end;

// ---- Reporting -----------------------------------------------------------

function TBDDStory.OutcomeTag(AOutcome: TStepOutcome): string;
begin
  case AOutcome of
    soPassed  : Result := '[PASSED]';
    soFailed  : Result := '[FAILED]';
    soSkipped : Result := '[SKIPPED]';
  else
    Result := '[NOT RUN]';
  end;
end;

procedure TBDDStory.WriteReport;
const
  COL_WIDTH = 62;
var
  Lines    : TStringList;
  I, J     : Integer;
  Scenario : TBDDScenario;
  S        : TBDDStep;
  Line     : string;
begin
  Lines := TStringList.Create;
  try
    Lines.Add('');
    Lines.Add('Story: ' + FTitle);

    for I := Low(FNarrative) to High(FNarrative) do
      Lines.Add('  ' + FNarrative[I].Label_ + ' ' + FNarrative[I].Text);

    for I := 0 to FScenarios.Count - 1 do
    begin
      Lines.Add('');
      Scenario := TBDDScenario(FScenarios[I]);
      Lines.Add('  Scenario: ' + Scenario.Title);

      for J := 0 to Scenario.FSteps.Count - 1 do
      begin
        S    := TBDDStep(Scenario.FSteps[J]);
        Line := '    ' + S.Kind + ' ' + S.Description;

        while Length(Line) < COL_WIDTH do
          Line := Line + ' ';

        Line := Line + OutcomeTag(S.Outcome);
        Lines.Add(Line);

        if S.Outcome = soFailed then
          Lines.Add('      *** ' + S.ErrorMessage);
      end;
    end;

    Lines.Add('');

    for I := 0 to Lines.Count - 1 do
      TDUnitX.CurrentRunner.Log(TLogLevel.Information, Lines[I]);

  finally
    Lines.Free;
  end;
end;

end.
