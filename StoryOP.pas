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
  Step procedures are methods of the test fixture class.
  Their names may use CamelCase, underscores, or a mixture:

      AccountIsInCredit            ->  "account is in credit"
      Account_is_in_credit         ->  "account is in credit"
      CustomerWithdrawsFromATM     ->  "customer withdraws from ATM"
      RequestWithdrawalOf20        ->  "request withdrawal of 20"

  Step method types
  -----------------
  Four generic step method types are supported, covering zero to
  four parameters.  Generic specialisation disambiguates them just
  as method overloading does:

      TStepMethod                        -- no parameters
      TStepMethod<T>                     -- one parameter
      TStepMethod<T1,T2>                 -- two parameters
      TStepMethod<T1,T2,T3>              -- three parameters
      TStepMethod<T1,T2,T3,T4>           -- four parameters

  Parameters are appended to the narrative in square brackets:

      .Given<Integer>(WithdrawAmount, 20)
      ->  "Given withdraw amount [20]"

      .Given<string,Integer>(NamedAccountWithBalance, 'Alice', 100)
      ->  "Given named account with balance [Alice, 100]"

  Step overloads
  --------------
  Every step method (Given, When, Then_, AndAlso) accepts:

    1. TStepMethod                 -- zero-parameter method reference
    2. TStepMethod<T..>            -- parameterised method reference
    3. TProc + mandatory label     -- anonymous method (no RTTI available)
    4. TBDDStep                    -- pre-built self-describing step

  Method visibility
  -----------------
  Step procedures must be public or published for RTTI name lookup
  to work.  Private/protected steps resolve to "(unnamed step)".
  To enable private/protected visibility add this to your test unit:

    {$RTTI EXPLICIT METHODS([vcPrivate,vcProtected,vcPublic,vcPublished])}

  Failure behaviour
  -----------------
    - A failing Given or When halts the scenario; all remaining
      steps are marked SKIPPED.
    - A failing Then is recorded; subsequent Thens still run.

  Reporting
  ---------
  Plain-text narrative emitted via TDUnitX.CurrentRunner.Log,
  appearing in all registered DUnitX loggers and TestInsight.

  Compatibility
  -------------
  Delphi 2009+  (Rtti unit, generics, anonymous methods required).
*)

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Contnrs,
  System.Character,
  System.Rtti,
  DUnitX.TestFramework;

type
  // -----------------------------------------------------------------------
  //  Forward declarations
  // -----------------------------------------------------------------------
  TBDDStep     = class;
  TBDDScenario = class;
  TBDDStory    = class;

  // -----------------------------------------------------------------------
  //  TStepMethod family
  //  Declared as "procedure [(...)] of object" so Delphi passes each as
  //  a TMethod record (Code + Data).  Generic specialisation with
  //  different type-parameter counts makes them distinct types, exactly
  //  as method overloads are distinct — no numeric suffixes needed.
  // -----------------------------------------------------------------------
  TStepMethod                              = procedure of object;
  TStepMethod<T>                           = procedure(const A: T) of object;
  TStepMethod<T1, T2>                      = procedure(const A: T1; const B: T2) of object;
  TStepMethod<T1, T2, T3>                  = procedure(const A: T1; const B: T2; const C: T3) of object;
  TStepMethod<T1, T2, T3, T4>             = procedure(const A: T1; const B: T2; const C: T3; const D: T4) of object;

  TStepOutcome = (soNotRun, soPassed, soFailed, soSkipped);

  // -----------------------------------------------------------------------
  //  TNarrativeLine
  // -----------------------------------------------------------------------
  TNarrativeLine = record
    Label_ : string;
    Text   : string;
  end;

  // -----------------------------------------------------------------------
  //  TBDDStep
  //  Stores a TMethod + TValue array for invocation, and a pre-computed
  //  description string.  Invocation uses TRttiMethod.Invoke so that
  //  parameters are dispatched correctly regardless of count or type.
  //  Falls back to a direct TMethod cast when RTTI cannot find the method
  //  (e.g. private methods without the RTTI directive), ensuring the step
  //  always executes even when the name resolves to "(unnamed step)".
  //  For anonymous methods (TProc path), FProc is set and FMethod is nil.
  // -----------------------------------------------------------------------
  TBDDStep = class
  private
    FDescription : string;
    FMethod      : TMethod;
    FParams      : TArray<TValue>;
    FProc        : TProc;
    FKind        : string;
    FOutcome     : TStepOutcome;
    FErrorMessage: string;
  public
    // Primary path: TMethod + optional TValue parameters
    constructor CreateFromMethod(const AMethod     : TMethod;
                                 const ADescription: string;
                                 const AParams     : TArray<TValue>); overload;

    // Secondary path: anonymous method + mandatory label
    constructor CreateFromProc(const AProc        : TProc;
                               const ADescription : string);

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
    function  MakeStep(AMethod: TStepMethod): TBDDStep; overload;
    function  MakeStep(const AMethod: TMethod;
                       const AParams: TArray<TValue>): TBDDStep; overload;
  public
    constructor Create(AStory: TBDDStory; const ATitle: string);
    destructor  Destroy; override;

    // --- Zero-parameter TStepMethod overloads ---
    function Given  (AMethod: TStepMethod): TBDDScenario; overload;
    function When   (AMethod: TStepMethod): TBDDScenario; overload;
    function Then_  (AMethod: TStepMethod): TBDDScenario; overload;
    function AndAlso(AMethod: TStepMethod): TBDDScenario; overload;

    // --- One-parameter generic overloads ---
    function Given  <T>(AMethod: TStepMethod<T>; const A: T): TBDDScenario; overload;
    function When   <T>(AMethod: TStepMethod<T>; const A: T): TBDDScenario; overload;
    function Then_  <T>(AMethod: TStepMethod<T>; const A: T): TBDDScenario; overload;
    function AndAlso<T>(AMethod: TStepMethod<T>; const A: T): TBDDScenario; overload;

    // --- Two-parameter generic overloads ---
    function Given  <T1,T2>(AMethod: TStepMethod<T1,T2>; const A: T1; const B: T2): TBDDScenario; overload;
    function When   <T1,T2>(AMethod: TStepMethod<T1,T2>; const A: T1; const B: T2): TBDDScenario; overload;
    function Then_  <T1,T2>(AMethod: TStepMethod<T1,T2>; const A: T1; const B: T2): TBDDScenario; overload;
    function AndAlso<T1,T2>(AMethod: TStepMethod<T1,T2>; const A: T1; const B: T2): TBDDScenario; overload;

    // --- Three-parameter generic overloads ---
    function Given  <T1,T2,T3>(AMethod: TStepMethod<T1,T2,T3>; const A: T1; const B: T2; const C: T3): TBDDScenario; overload;
    function When   <T1,T2,T3>(AMethod: TStepMethod<T1,T2,T3>; const A: T1; const B: T2; const C: T3): TBDDScenario; overload;
    function Then_  <T1,T2,T3>(AMethod: TStepMethod<T1,T2,T3>; const A: T1; const B: T2; const C: T3): TBDDScenario; overload;
    function AndAlso<T1,T2,T3>(AMethod: TStepMethod<T1,T2,T3>; const A: T1; const B: T2; const C: T3): TBDDScenario; overload;

    // --- Four-parameter generic overloads ---
    function Given  <T1,T2,T3,T4>(AMethod: TStepMethod<T1,T2,T3,T4>; const A: T1; const B: T2; const C: T3; const D: T4): TBDDScenario; overload;
    function When   <T1,T2,T3,T4>(AMethod: TStepMethod<T1,T2,T3,T4>; const A: T1; const B: T2; const C: T3; const D: T4): TBDDScenario; overload;
    function Then_  <T1,T2,T3,T4>(AMethod: TStepMethod<T1,T2,T3,T4>; const A: T1; const B: T2; const C: T3; const D: T4): TBDDScenario; overload;
    function AndAlso<T1,T2,T3,T4>(AMethod: TStepMethod<T1,T2,T3,T4>; const A: T1; const B: T2; const C: T3; const D: T4): TBDDScenario; overload;

    // --- Anonymous method overloads: TProc + mandatory label ---
    function Given  (AProc: TProc; const ALabel: string): TBDDScenario; overload;
    function When   (AProc: TProc; const ALabel: string): TBDDScenario; overload;
    function Then_  (AProc: TProc; const ALabel: string): TBDDScenario; overload;
    function AndAlso(AProc: TProc; const ALabel: string): TBDDScenario; overload;

    // --- Pre-built TBDDStep overloads ---
    function Given  (AStep: TBDDStep): TBDDScenario; overload;
    function When   (AStep: TBDDStep): TBDDScenario; overload;
    function Then_  (AStep: TBDDStep): TBDDScenario; overload;
    function AndAlso(AStep: TBDDStep): TBDDScenario; overload;

    function WithScenario(const ATitle: string): TBDDScenario;
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
    function AsA      (const AText: string): TBDDStory;
    function IWantTo  (const AText: string): TBDDStory;
    function IWant    (const AText: string): TBDDStory;
    function InOrderTo(const AText: string): TBDDStory;
    function SoThat   (const AText: string): TBDDStory;

    // ---- FDD / Action-Outcome-Entity ----------------------------------
    function Action   (const AText: string): TBDDStory;
    function Outcome  (const AText: string): TBDDStory;
    function Entity   (const AText: string): TBDDStory;

    // ---- Escape hatch -------------------------------------------------
    function Narrative(const ALabel, AText: string): TBDDStory;

    // ---- Scenario chain -----------------------------------------------
    function WithScenario(const ATitle: string): TBDDScenario;

    property Title : string read FTitle;
  end;

  // -----------------------------------------------------------------------
  //  TStepFactory
  //  Factory class for building pre-described TBDDStep instances.
  //
  //  Delphi does not permit type parameters on global (free) functions,
  //  so parameterised Step creation is provided here as static class
  //  methods, which Delphi's generics do support.
  //
  //  Zero-parameter and anonymous-method steps are also available here
  //  for consistency, and are additionally available as the free
  //  functions Step() and Step(TProc, string) below.
  //
  //  Usage:
  //    // Zero-parameter
  //    S := TStepFactory.Create(AccountIsInCredit);
  //
  //    // One-parameter
  //    S := TStepFactory.Create<Integer>(AccountIsOpenedWithBalance, 100);
  //
  //    // Two-parameter
  //    S := TStepFactory.Create<Integer,Integer>(AccountStartsWithBalanceAndLimit, 500, 1000);
  //
  //    // Anonymous method
  //    S := TStepFactory.Create(procedure begin FAccount.Deposit(100) end,
  //                             'account starts with 100');
  // -----------------------------------------------------------------------
  TStepFactory = class
  private
    class function ParamSuffix(const AParams: TArray<TValue>): string; static;
  public
    // Zero-parameter
    class function Create(AMethod: TStepMethod): TBDDStep; overload; static;

    // One-parameter
    class function Create<T>(AMethod: TStepMethod<T>;
                             const A: T): TBDDStep; overload; static;

    // Two-parameter
    class function Create<T1,T2>(AMethod: TStepMethod<T1,T2>;
                                 const A: T1;
                                 const B: T2): TBDDStep; overload; static;

    // Three-parameter
    class function Create<T1,T2,T3>(AMethod: TStepMethod<T1,T2,T3>;
                                    const A: T1;
                                    const B: T2;
                                    const C: T3): TBDDStep; overload; static;

    // Four-parameter
    class function Create<T1,T2,T3,T4>(AMethod: TStepMethod<T1,T2,T3,T4>;
                                       const A: T1;
                                       const B: T2;
                                       const C: T3;
                                       const D: T4): TBDDStep; overload; static;

    // Anonymous method — label is mandatory (no RTTI available)
    class function Create(AProc: TProc;
                          const ALabel: string): TBDDStep; overload; static;
  end;

// -----------------------------------------------------------------------
//  Module-level convenience functions
// -----------------------------------------------------------------------

// Story factory
function Story(const ATitle: string): TBDDStory;

// Name-conversion utilities (exposed for unit-testing)
function MethodNameFromRtti(const AMethod: TMethod) : string;
function IdentifierToWords (const AName: string)    : string;
function CamelCaseToWords  (const AName: string)    : string;

implementation

// ==========================================================================
//  Name conversion
// ==========================================================================

function CamelCaseToWords(const AName: string): string;
var
  I            : Integer;
  Len          : Integer;
  Words        : TStringList;
  Token        : string;
  Prev, Curr   : Char;
  Next         : Char;
  TokenIsUpper : Boolean;
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


      CurrUp      := TCharacter.IsUpper(Curr);
      NextUp      := (Next <> #0) and TCharacter.IsUpper(Next);
      AfterNextLo := (AfterNext <> #0) and TCharacter.IsLower(AfterNext);
      PrevDigit   := TCharacter.IsDigit(Prev);
      CurrDigit   := TCharacter.IsDigit(Curr);
      Next := #0;

      // Letter <-> digit boundary
      if CurrDigit <> PrevDigit then
      begin
        Words.Add(Token);
        Token := Curr;
        Continue;
      end;

      // Rule 2: lowercase or digit followed by uppercase — new word begins
      if Curr.IsUpper and (Prev.IsLower or Prev.IsDigit or Prev.IsWhiteSpace) then
      begin
        Words.Add(Token);
        Token := Curr;
        Continue;
      end;

      // Rule 3: acronym boundary — Curr is uppercase, Next is lowercase,
      // and the token accumulated so far is entirely uppercase (length > 1).
      // This means Curr is the first letter of a new word, not part of
      // the acronym.  Split before Curr regardless of acronym length.
      //
      //   "ATMCard":    at 'C', Token='ATM' (all-upper), Next='a' -> split
      //   "HTTPSProxy": at 'P', Token='HTTPS' (all-upper), Next='r' -> split
      //   "NATOForces": at 'F', Token='NATO' (all-upper), Next='o' -> split
      //
      // Note: ATMPIN will not split. In multiple acronym situations use an underscore instead, e.g.:  ATM_PIN
      TokenIsUpper := (Length(Token) > 1) and (Token = UpperCase(Token));
      if Curr.IsUpper and Next.IsLower and TokenIsUpper then
      begin
        Words.Add(Token);
        Token := Curr;
        Continue;
      end;

      Token := Token + Curr;
    end;

    if Token <> '' then
      Words.Add(Token);

    // Reassemble: preserve all-uppercase tokens (acronyms), lowercase rest
    for I := 0 to Words.Count - 1 do
    begin
      Token := Words[I];
      if Result <> '' then Result := Result + ' ';
      if (Length(Token) > 1) and (Token = UpperCase(Token)) then
        Result := Result + Token
      else
        Result := Result + LowerCase(Token);
    end;

  finally
    Words.Free;
  end;
end;

function IdentifierToWords(const AName: string): string;
var
  HasDoubleUnderscore : Boolean;
begin
  if AName = '' then Exit;

  Result := AName;
  HasDoubleUnderscore := Result.Contains('__');
  while HasDoubleUnderscore do
  begin
    Result := StringReplace(Result, '__', '_', [rfReplaceAll]);
    HasDoubleUnderscore := Result.Contains('__');
  end;
  Result := StringReplace(Result, '_', ' ', [rfReplaceAll]);
  Result := CamelCaseToWords(Result);
  Result := StringReplace(Result, '  ', ' ', [rfReplaceAll]);
  Result := Trim(Result);
end;

// ==========================================================================
//  RTTI helpers
// ==========================================================================

function MethodNameFromRtti(const AMethod: TMethod): string;
var
  Ctx      : TRttiContext;
  RType    : TRttiType;
  RMethod  : TRttiMethod;
  Instance : TObject;
begin
  Result := '(unnamed step)';
  if (AMethod.Data = nil) or (AMethod.Code = nil) then Exit;

  Instance := TObject(AMethod.Data);
  Ctx      := TRttiContext.Create;
  RType    := Ctx.GetType(Instance.ClassType);

  while Assigned(RType) do
  begin
    for RMethod in RType.GetDeclaredMethods do
      if RMethod.CodeAddress = AMethod.Code then
      begin
        Result := IdentifierToWords(RMethod.Name);
        Exit;
      end;
    RType := RType.BaseType;
  end;
end;

// Walks RTTI to find and invoke the method with the stored parameters.
// Returns True if the method was found and invoked via RTTI.
// Returns False if the method was not found (fallback to direct cast needed).
function RttiInvoke(const AMethod: TMethod;
                    const AParams: TArray<TValue>): Boolean;
var
  Ctx      : TRttiContext;
  RType    : TRttiType;
  RMethod  : TRttiMethod;
  Instance : TObject;
begin
  Result := False;
  if (AMethod.Data = nil) or (AMethod.Code = nil) then Exit;

  Instance := TObject(AMethod.Data);
  Ctx      := TRttiContext.Create;
  RType    := Ctx.GetType(Instance.ClassType);

  while Assigned(RType) do
  begin
    for RMethod in RType.GetDeclaredMethods do
      if RMethod.CodeAddress = AMethod.Code then
      begin
        RMethod.Invoke(Instance, AParams);
        Result := True;
        Exit;
      end;
    RType := RType.BaseType;
  end;
end;

// ==========================================================================
//  TStepFactory
// ==========================================================================

class function TStepFactory.ParamSuffix(const AParams: TArray<TValue>): string;
var
  I   : Integer;
  Sep : string;
begin
  if Length(AParams) = 0 then
  begin
    Result := '';
    Exit;
  end;
  Result := ' [';
  Sep    := '';
  for I := 0 to High(AParams) do
  begin
    Result := Result + Sep + AParams[I].ToString;
    Sep    := ', ';
  end;
  Result := Result + ']';
end;

class function TStepFactory.Create(AMethod: TStepMethod): TBDDStep;
var
  M: TMethod;
begin
  M      := TMethod(AMethod);
  Result := TBDDStep.CreateFromMethod(M, MethodNameFromRtti(M), nil);
end;

class function TStepFactory.Create<T>(AMethod: TStepMethod<T>;
                                      const A: T): TBDDStep;
var
  M : TMethod;
  P : TArray<TValue>;
begin
  M      := TMethod(AMethod);
  P      := TArray<TValue>.Create(TValue.From<T>(A));
  Result := TBDDStep.CreateFromMethod(M,
               MethodNameFromRtti(M) + TStepFactory.ParamSuffix(P), P);
end;

class function TStepFactory.Create<T1,T2>(AMethod: TStepMethod<T1,T2>;
                                           const A: T1;
                                           const B: T2): TBDDStep;
var
  M : TMethod;
  P : TArray<TValue>;
begin
  M      := TMethod(AMethod);
  P      := TArray<TValue>.Create(TValue.From<T1>(A), TValue.From<T2>(B));
  Result := TBDDStep.CreateFromMethod(M,
               MethodNameFromRtti(M) + TStepFactory.ParamSuffix(P), P);
end;

class function TStepFactory.Create<T1,T2,T3>(AMethod: TStepMethod<T1,T2,T3>;
                                              const A: T1;
                                              const B: T2;
                                              const C: T3): TBDDStep;
var
  M : TMethod;
  P : TArray<TValue>;
begin
  M      := TMethod(AMethod);
  P      := TArray<TValue>.Create(TValue.From<T1>(A),
                                   TValue.From<T2>(B),
                                   TValue.From<T3>(C));
  Result := TBDDStep.CreateFromMethod(M,
               MethodNameFromRtti(M) + TStepFactory.ParamSuffix(P), P);
end;

class function TStepFactory.Create<T1,T2,T3,T4>(AMethod: TStepMethod<T1,T2,T3,T4>;
                                                  const A: T1;
                                                  const B: T2;
                                                  const C: T3;
                                                  const D: T4): TBDDStep;
var
  M : TMethod;
  P : TArray<TValue>;
begin
  M      := TMethod(AMethod);
  P      := TArray<TValue>.Create(TValue.From<T1>(A),
                                   TValue.From<T2>(B),
                                   TValue.From<T3>(C),
                                   TValue.From<T4>(D));
  Result := TBDDStep.CreateFromMethod(M,
               MethodNameFromRtti(M) + TStepFactory.ParamSuffix(P), P);
end;

class function TStepFactory.Create(AProc: TProc;
                                   const ALabel: string): TBDDStep;
begin
  Result := TBDDStep.CreateFromProc(AProc, ALabel);
end;

// ==========================================================================
//  TBDDStep
// ==========================================================================

constructor TBDDStep.CreateFromMethod(const AMethod     : TMethod;
                                      const ADescription: string;
                                      const AParams     : TArray<TValue>);
begin
  inherited Create;
  FMethod       := AMethod;
  FParams       := AParams;
  FProc         := nil;
  FDescription  := ADescription;
  FOutcome      := soNotRun;
  FErrorMessage := '';
  FKind         := '';
end;

constructor TBDDStep.CreateFromProc(const AProc       : TProc;
                                    const ADescription: string);
begin
  inherited Create;
  FMethod.Data  := nil;
  FMethod.Code  := nil;
  FParams       := nil;
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
    if Assigned(FMethod.Code) then
    begin
      // Primary path: invoke via RTTI so parameters are passed correctly.
      // Falls back to a direct TMethod cast (zero-param only) when the
      // method is not visible to RTTI (e.g. private without directive).
      if not RttiInvoke(FMethod, FParams) then
        TStepMethod(FMethod)();
    end
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
//  Module-level convenience functions
// ==========================================================================

function Story(const ATitle: string): TBDDStory;
begin
  Result := TBDDStory.Create(ATitle);
end;

// ==========================================================================
//  TBDDScenario — internal helpers
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

function TBDDScenario.MakeStep(AMethod: TStepMethod): TBDDStep;
var
  M: TMethod;
begin
  M      := TMethod(AMethod);
  Result := TBDDStep.CreateFromMethod(M, MethodNameFromRtti(M), nil);
end;

function TBDDScenario.MakeStep(const AMethod: TMethod;
                               const AParams: TArray<TValue>): TBDDStep;
begin
  Result := TBDDStep.CreateFromMethod(AMethod,
               MethodNameFromRtti(AMethod) + TStepFactory.ParamSuffix(AParams),
               AParams);
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

  if AStep.Outcome = soFailed then
    if (AKind = 'Given')       or (AKind = 'When') or
       (AKind = 'And (Given)') or (AKind = 'And (When)') then
      FHalted := True;
end;

// ==========================================================================
//  TBDDScenario — zero-parameter overloads
// ==========================================================================

function TBDDScenario.Given(AMethod: TStepMethod): TBDDScenario;
begin FLastKind := 'Given'; AddStep('Given', MakeStep(AMethod)); Result := Self; end;

function TBDDScenario.When(AMethod: TStepMethod): TBDDScenario;
begin FLastKind := 'When'; AddStep('When', MakeStep(AMethod)); Result := Self; end;

function TBDDScenario.Then_(AMethod: TStepMethod): TBDDScenario;
begin FLastKind := 'Then'; AddStep('Then', MakeStep(AMethod)); Result := Self; end;

function TBDDScenario.AndAlso(AMethod: TStepMethod): TBDDScenario;
begin AddStep('And (' + FLastKind + ')', MakeStep(AMethod)); Result := Self; end;

// ==========================================================================
//  TBDDScenario — one-parameter generic overloads
// ==========================================================================

function TBDDScenario.Given<T>(AMethod: TStepMethod<T>; const A: T): TBDDScenario;
var M: TMethod; P: TArray<TValue>;
begin
  M := TMethod(AMethod); P := TArray<TValue>.Create(TValue.From<T>(A));
  FLastKind := 'Given'; AddStep('Given', MakeStep(M, P)); Result := Self;
end;

function TBDDScenario.When<T>(AMethod: TStepMethod<T>; const A: T): TBDDScenario;
var M: TMethod; P: TArray<TValue>;
begin
  M := TMethod(AMethod); P := TArray<TValue>.Create(TValue.From<T>(A));
  FLastKind := 'When'; AddStep('When', MakeStep(M, P)); Result := Self;
end;

function TBDDScenario.Then_<T>(AMethod: TStepMethod<T>; const A: T): TBDDScenario;
var M: TMethod; P: TArray<TValue>;
begin
  M := TMethod(AMethod); P := TArray<TValue>.Create(TValue.From<T>(A));
  FLastKind := 'Then'; AddStep('Then', MakeStep(M, P)); Result := Self;
end;

function TBDDScenario.AndAlso<T>(AMethod: TStepMethod<T>; const A: T): TBDDScenario;
var M: TMethod; P: TArray<TValue>;
begin
  M := TMethod(AMethod); P := TArray<TValue>.Create(TValue.From<T>(A));
  AddStep('And (' + FLastKind + ')', MakeStep(M, P)); Result := Self;
end;

// ==========================================================================
//  TBDDScenario — two-parameter generic overloads
// ==========================================================================

function TBDDScenario.Given<T1,T2>(AMethod: TStepMethod<T1,T2>; const A: T1; const B: T2): TBDDScenario;
var M: TMethod; P: TArray<TValue>;
begin
  M := TMethod(AMethod); P := TArray<TValue>.Create(TValue.From<T1>(A), TValue.From<T2>(B));
  FLastKind := 'Given'; AddStep('Given', MakeStep(M, P)); Result := Self;
end;

function TBDDScenario.When<T1,T2>(AMethod: TStepMethod<T1,T2>; const A: T1; const B: T2): TBDDScenario;
var M: TMethod; P: TArray<TValue>;
begin
  M := TMethod(AMethod); P := TArray<TValue>.Create(TValue.From<T1>(A), TValue.From<T2>(B));
  FLastKind := 'When'; AddStep('When', MakeStep(M, P)); Result := Self;
end;

function TBDDScenario.Then_<T1,T2>(AMethod: TStepMethod<T1,T2>; const A: T1; const B: T2): TBDDScenario;
var M: TMethod; P: TArray<TValue>;
begin
  M := TMethod(AMethod); P := TArray<TValue>.Create(TValue.From<T1>(A), TValue.From<T2>(B));
  FLastKind := 'Then'; AddStep('Then', MakeStep(M, P)); Result := Self;
end;

function TBDDScenario.AndAlso<T1,T2>(AMethod: TStepMethod<T1,T2>; const A: T1; const B: T2): TBDDScenario;
var M: TMethod; P: TArray<TValue>;
begin
  M := TMethod(AMethod); P := TArray<TValue>.Create(TValue.From<T1>(A), TValue.From<T2>(B));
  AddStep('And (' + FLastKind + ')', MakeStep(M, P)); Result := Self;
end;

// ==========================================================================
//  TBDDScenario — three-parameter generic overloads
// ==========================================================================

function TBDDScenario.Given<T1,T2,T3>(AMethod: TStepMethod<T1,T2,T3>; const A: T1; const B: T2; const C: T3): TBDDScenario;
var M: TMethod; P: TArray<TValue>;
begin
  M := TMethod(AMethod); P := TArray<TValue>.Create(TValue.From<T1>(A), TValue.From<T2>(B), TValue.From<T3>(C));
  FLastKind := 'Given'; AddStep('Given', MakeStep(M, P)); Result := Self;
end;

function TBDDScenario.When<T1,T2,T3>(AMethod: TStepMethod<T1,T2,T3>; const A: T1; const B: T2; const C: T3): TBDDScenario;
var M: TMethod; P: TArray<TValue>;
begin
  M := TMethod(AMethod); P := TArray<TValue>.Create(TValue.From<T1>(A), TValue.From<T2>(B), TValue.From<T3>(C));
  FLastKind := 'When'; AddStep('When', MakeStep(M, P)); Result := Self;
end;

function TBDDScenario.Then_<T1,T2,T3>(AMethod: TStepMethod<T1,T2,T3>; const A: T1; const B: T2; const C: T3): TBDDScenario;
var M: TMethod; P: TArray<TValue>;
begin
  M := TMethod(AMethod); P := TArray<TValue>.Create(TValue.From<T1>(A), TValue.From<T2>(B), TValue.From<T3>(C));
  FLastKind := 'Then'; AddStep('Then', MakeStep(M, P)); Result := Self;
end;

function TBDDScenario.AndAlso<T1,T2,T3>(AMethod: TStepMethod<T1,T2,T3>; const A: T1; const B: T2; const C: T3): TBDDScenario;
var M: TMethod; P: TArray<TValue>;
begin
  M := TMethod(AMethod); P := TArray<TValue>.Create(TValue.From<T1>(A), TValue.From<T2>(B), TValue.From<T3>(C));
  AddStep('And (' + FLastKind + ')', MakeStep(M, P)); Result := Self;
end;

// ==========================================================================
//  TBDDScenario — four-parameter generic overloads
// ==========================================================================

function TBDDScenario.Given<T1,T2,T3,T4>(AMethod: TStepMethod<T1,T2,T3,T4>; const A: T1; const B: T2; const C: T3; const D: T4): TBDDScenario;
var M: TMethod; P: TArray<TValue>;
begin
  M := TMethod(AMethod); P := TArray<TValue>.Create(TValue.From<T1>(A), TValue.From<T2>(B), TValue.From<T3>(C), TValue.From<T4>(D));
  FLastKind := 'Given'; AddStep('Given', MakeStep(M, P)); Result := Self;
end;

function TBDDScenario.When<T1,T2,T3,T4>(AMethod: TStepMethod<T1,T2,T3,T4>; const A: T1; const B: T2; const C: T3; const D: T4): TBDDScenario;
var M: TMethod; P: TArray<TValue>;
begin
  M := TMethod(AMethod); P := TArray<TValue>.Create(TValue.From<T1>(A), TValue.From<T2>(B), TValue.From<T3>(C), TValue.From<T4>(D));
  FLastKind := 'When'; AddStep('When', MakeStep(M, P)); Result := Self;
end;

function TBDDScenario.Then_<T1,T2,T3,T4>(AMethod: TStepMethod<T1,T2,T3,T4>; const A: T1; const B: T2; const C: T3; const D: T4): TBDDScenario;
var M: TMethod; P: TArray<TValue>;
begin
  M := TMethod(AMethod); P := TArray<TValue>.Create(TValue.From<T1>(A), TValue.From<T2>(B), TValue.From<T3>(C), TValue.From<T4>(D));
  FLastKind := 'Then'; AddStep('Then', MakeStep(M, P)); Result := Self;
end;

function TBDDScenario.AndAlso<T1,T2,T3,T4>(AMethod: TStepMethod<T1,T2,T3,T4>; const A: T1; const B: T2; const C: T3; const D: T4): TBDDScenario;
var M: TMethod; P: TArray<TValue>;
begin
  M := TMethod(AMethod); P := TArray<TValue>.Create(TValue.From<T1>(A), TValue.From<T2>(B), TValue.From<T3>(C), TValue.From<T4>(D));
  AddStep('And (' + FLastKind + ')', MakeStep(M, P)); Result := Self;
end;

// ==========================================================================
//  TBDDScenario — TProc overloads
// ==========================================================================

function TBDDScenario.Given(AProc: TProc; const ALabel: string): TBDDScenario;
begin FLastKind := 'Given'; AddStep('Given', TBDDStep.CreateFromProc(AProc, ALabel)); Result := Self; end;

function TBDDScenario.When(AProc: TProc; const ALabel: string): TBDDScenario;
begin FLastKind := 'When'; AddStep('When', TBDDStep.CreateFromProc(AProc, ALabel)); Result := Self; end;

function TBDDScenario.Then_(AProc: TProc; const ALabel: string): TBDDScenario;
begin FLastKind := 'Then'; AddStep('Then', TBDDStep.CreateFromProc(AProc, ALabel)); Result := Self; end;

function TBDDScenario.AndAlso(AProc: TProc; const ALabel: string): TBDDScenario;
begin AddStep('And (' + FLastKind + ')', TBDDStep.CreateFromProc(AProc, ALabel)); Result := Self; end;

// ==========================================================================
//  TBDDScenario — TBDDStep overloads
// ==========================================================================

function TBDDScenario.Given(AStep: TBDDStep): TBDDScenario;
begin FLastKind := 'Given'; AddStep('Given', AStep); Result := Self; end;

function TBDDScenario.When(AStep: TBDDStep): TBDDScenario;
begin FLastKind := 'When'; AddStep('When', AStep); Result := Self; end;

function TBDDScenario.Then_(AStep: TBDDStep): TBDDScenario;
begin FLastKind := 'Then'; AddStep('Then', AStep); Result := Self; end;

function TBDDScenario.AndAlso(AStep: TBDDStep): TBDDScenario;
begin AddStep('And (' + FLastKind + ')', AStep); Result := Self; end;

// ==========================================================================
//  TBDDScenario — chain and execute
// ==========================================================================

function TBDDScenario.WithScenario(const ATitle: string): TBDDScenario;
begin
  Result := FStory.WithScenario(ATitle);
end;

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
          FailMsgs.Add('[' + Scenario.Title + '] ' +
                       S.Kind + ' ' + S.Description + ': ' + S.ErrorMessage);
        end;
      end;
    end;

    if not AllPassed then
      Assert.Fail('StoryOP scenario failures:' + sLineBreak + FailMsgs.Text);

  finally
    FailMsgs.Free;
    FStory.Free;
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
var Idx: Integer;
begin
  Idx := Length(FNarrative);
  SetLength(FNarrative, Idx + 1);
  FNarrative[Idx].Label_ := ALabel;
  FNarrative[Idx].Text   := AText;
end;

function TBDDStory.AsA      (const AText: string): TBDDStory; begin AddNarrative('As a',       AText); Result := Self; end;
function TBDDStory.IWantTo  (const AText: string): TBDDStory; begin AddNarrative('I want to',  AText); Result := Self; end;
function TBDDStory.IWant    (const AText: string): TBDDStory; begin AddNarrative('I want',     AText); Result := Self; end;
function TBDDStory.InOrderTo(const AText: string): TBDDStory; begin AddNarrative('In order to',AText); Result := Self; end;
function TBDDStory.SoThat   (const AText: string): TBDDStory; begin AddNarrative('So that',    AText); Result := Self; end;
function TBDDStory.Action   (const AText: string): TBDDStory; begin AddNarrative('Action',     AText); Result := Self; end;
function TBDDStory.Outcome  (const AText: string): TBDDStory; begin AddNarrative('Outcome',    AText); Result := Self; end;
function TBDDStory.Entity   (const AText: string): TBDDStory; begin AddNarrative('Entity',     AText); Result := Self; end;
function TBDDStory.Narrative(const ALabel, AText: string): TBDDStory; begin AddNarrative(ALabel, AText); Result := Self; end;

function TBDDStory.WithScenario(const ATitle: string): TBDDScenario;
var Scenario: TBDDScenario;
begin
  Scenario := TBDDScenario.Create(Self, ATitle);
  FScenarios.Add(Scenario);
  Result := Scenario;
end;

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
        while Length(Line) < COL_WIDTH do Line := Line + ' ';
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
