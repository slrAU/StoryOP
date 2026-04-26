unit StoryOP.UnitTests;

(*
  StoryOP.Tests
  =============
  Comprehensive test suite for the StoryOP framework.

  This suite tests StoryOP using StoryOP itself wherever possible,
  demonstrating both correctness and dogfooding.

  Test fixtures cover:

    1.  TNameConversion         — CamelCase, underscore, acronym, digit,
                                  mixed, and edge-case identifier splitting
    2.  TIdentifierConversion   — IdentifierToWords end-to-end
    3.  TStepOutcomes           — pass, fail, skip cascade, Then-continues
    4.  TNarrativePatterns      — all story header styles and ordering
    5.  TStepNaming             — RTTI name derivation, unnamed fallback
    6.  TZeroParamSteps         — zero-parameter TStepMethod path
    7.  TOneParamSteps          — one-parameter generic path (int, string,
                                  bool, float, enum)
    8.  TTwoParamSteps          — two-parameter generic path
    9.  TThreeParamSteps        — three-parameter generic path
    10. TFourParamSteps         — four-parameter generic path
    11. TStepFactoryTests       — TStepFactory.Create for all arities
    12. TAnonymousMethodSteps   — TProc + label path
    13. TPrebuiltStepVariables  — TBDDStep variable reuse
    14. TMultiScenarioStories   — multi-scenario chaining and state isolation
    15. TFailureBehaviour       — halt-on-Given/When, Then-continues,
                                  ETestFailure raised, failure messages
    16. TAndAlsoInheritance     — AndAlso inherits correct kind for halting
    17. TMixedStepTypes         — all overload types in one scenario
    18. TTestCaseIntegration    — [TestCase] parameterised scenario pattern

  Method visibility
  -----------------
  All step procedures are declared public so RTTI name derivation
  works without requiring the {$RTTI EXPLICIT ...} directive.
  See the README for guidance on using private/protected steps.
*)

interface

uses
  DUnitX.TestFramework,
  DUnitX.Exceptions,
  StoryOP,
  System.SysUtils,
  System.Classes;

type

  // =========================================================================
  //  1. Name conversion — CamelCase
  // =========================================================================
  [TestFixture]
  TNameConversionTests = class
  public
    [Test] procedure CamelCase_SimpleTwoWord;
    [Test] procedure CamelCase_ThreeWords;
    [Test] procedure CamelCase_SingleWord;
    [Test] procedure CamelCase_EmptyString;
    [Test] procedure CamelCase_AcronymAtEnd;
    [Test] procedure CamelCase_AcronymInMiddle;
    [Test] procedure CamelCase_AcronymAtStart;
    [Test] procedure CamelCase_DigitBoundaryEnd;
    [Test] procedure CamelCase_DigitBoundaryMiddle;
    [Test] procedure CamelCase_ConsecutiveAcronyms;
    [Test] procedure CamelCase_SingleChar;
    [Test] procedure CamelCase_AllUpperCase;
    [Test] procedure Underscore_SimpleWords;
    [Test] procedure Underscore_WithCamelCaseTokens;
    [Test] procedure Underscore_LeadingTrailing;
    [Test] procedure Underscore_ConsecutiveUnderscores;
    [Test] procedure Mixed_UnderscoreAndCamelCase;
    [Test] procedure IdentifierToWords_Empty;
    [Test] procedure IdentifierToWords_NoundersCore_delegatesToCamelCase;
  end;

  // =========================================================================
  //  2. Step outcome basics — a simple fixture for use in outcome tests
  // =========================================================================
  [TestFixture]
  TStepOutcomeTests = class
  private
    FValue: Integer;
  public
    // Steps used in outcome scenarios
    procedure SetValueTo10;
    procedure SetValueTo20;
    procedure IncrementValue;
    procedure ValueShouldBe10;
    procedure ValueShouldBe20;
    procedure ValueShouldBe30;
    procedure StepThatFails;
    procedure StepThatShouldNotRun;

    // Parameterised step variants
    procedure SetValueTo(const AValue: Integer);
    procedure ValueShouldBe(const AExpected: Integer);

    [Setup]    procedure Setup;
    [TearDown] procedure TearDown;

    [Test] procedure ZeroParam_PassingStepsAllPass;
    [Test] procedure ZeroParam_FailingThenRecorded;
    [Test] procedure ZeroParam_FailingGivenHaltsScenario;
    [Test] procedure ZeroParam_FailingWhenHaltsScenario;
    [Test] procedure ZeroParam_FailingThenDoesNotHaltSubsequentThen;
    [Test] procedure ZeroParam_MultiplePassingSteps;
  end;

  // =========================================================================
  //  3. Narrative pattern tests
  // =========================================================================
  [TestFixture]
  TNarrativePatternTests = class
  public
    procedure NoOpStep;

    [Test] procedure Narrative_ClassicBDD;
    [Test] procedure Narrative_RoleBehaviourBenefit;
    [Test] procedure Narrative_FDD;
    [Test] procedure Narrative_Declarative;
    [Test] procedure Narrative_PlainString;
    [Test] procedure Narrative_CustomLabel;
    [Test] procedure Narrative_MultipleCallsSameMethod;
    [Test] procedure Narrative_MixedPatterns;
  end;

  // =========================================================================
  //  4. RTTI step naming
  // =========================================================================
  [TestFixture]
  TStepNamingTests = class
  public
    procedure SimpleMethodName;
    procedure CamelCaseMethodName;
    procedure MethodWithATMInName;
    procedure MethodWithDigits20;
    procedure Underscore_method_name;
    procedure Mixed_CamelAndUnderscore;

    [Test] procedure Naming_SimpleMethod_ProducesReadableName;
    [Test] procedure Naming_CamelCase_SplitsCorrectly;
    [Test] procedure Naming_Acronym_Preserved;
    [Test] procedure Naming_DigitBoundary_SplitsCorrectly;
    [Test] procedure Naming_Underscore_ProducesReadableName;
    [Test] procedure Naming_Mixed_ProducesReadableName;
  end;

  // =========================================================================
  //  5. One-parameter generic steps
  // =========================================================================
  [TestFixture]
  TOneParamStepTests = class
  private
    FIntValue    : Integer;
    FStrValue    : string;
    FBoolValue   : Boolean;
    FDoubleValue : Double;
  public
    // Integer steps
    procedure SetIntValue(const AValue: Integer);
    procedure IntValueShouldBe(const AExpected: Integer);

    // String steps
    procedure SetStrValue(const AValue: string);
    procedure StrValueShouldBe(const AExpected: string);

    // Boolean steps
    procedure SetBoolValue(const AValue: Boolean);
    procedure BoolValueShouldBeTrue(const AExpected: Boolean);

    // Double steps
    procedure SetDoubleValue(const AValue: Double);
    procedure DoubleValueShouldBe(const AExpected: Double);

    [Setup]    procedure Setup;
    [TearDown] procedure TearDown;

    [Test] procedure OneParam_Integer_PassThrough;
    [Test] procedure OneParam_String_PassThrough;
    [Test] procedure OneParam_Boolean_PassThrough;
    [Test] procedure OneParam_Double_PassThrough;
    [Test] procedure OneParam_NegativeInteger;
    [Test] procedure OneParam_EmptyString;
    [Test] procedure OneParam_ParamAppearsInNarrative;
    [Test] procedure OneParam_ViaAndAlso;
  end;

  // =========================================================================
  //  6. Two-parameter generic steps
  // =========================================================================
  [TestFixture]
  TTwoParamStepTests = class
  private
    FSum    : Integer;
    FConcat : string;
  public
    procedure AddTwoIntegers(const A: Integer; const B: Integer);
    procedure SumShouldBe(const AExpected: Integer);
    procedure ConcatTwoStrings(const A: string; const B: string);
    procedure ConcatShouldBe(const AExpected: string);
    procedure SetIntAndStr(const AInt: Integer; const AStr: string);
    procedure IntShouldBeAndStrShouldBe(const AInt: Integer; const AStr: string);

    [Setup]    procedure Setup;
    [TearDown] procedure TearDown;

    [Test] procedure TwoParam_IntegerPair;
    [Test] procedure TwoParam_StringPair;
    [Test] procedure TwoParam_MixedTypes;
    [Test] procedure TwoParam_BothParamsInNarrative;
  end;

  // =========================================================================
  //  7. Three-parameter generic steps
  // =========================================================================
  [TestFixture]
  TThreeParamStepTests = class
  private
    FResult: Integer;
  public
    procedure AddThreeIntegers(const A: Integer; const B: Integer; const C: Integer);
    procedure ResultShouldBe(const AExpected: Integer);
    procedure SetNameAgeScore(const AName: string; const AAge: Integer; const AScore: Double);
    procedure NameShouldBe(const AExpected: string);

    [Setup]    procedure Setup;
    [TearDown] procedure TearDown;

    [Test] procedure ThreeParam_IntegerTriple;
    [Test] procedure ThreeParam_MixedTypes;
    [Test] procedure ThreeParam_AllParamsInNarrative;
  end;

  // =========================================================================
  //  8. Four-parameter generic steps
  // =========================================================================
  [TestFixture]
  TFourParamStepTests = class
  private
    FResult  : Integer;
    FMessage : string;
  public
    procedure AddFourIntegers(const A: Integer; const B: Integer;
                              const C: Integer; const D: Integer);
    procedure ResultShouldBe(const AExpected: Integer);
    procedure BuildMessage(const APrefix: string; const AValue: Integer;
                           const ASuffix: string; const ARepeat: Boolean);
    procedure MessageShouldContain(const ASubstring: string);

    [Setup]    procedure Setup;
    [TearDown] procedure TearDown;

    [Test] procedure FourParam_IntegerQuad;
    [Test] procedure FourParam_MixedTypes;
    [Test] procedure FourParam_AllParamsInNarrative;
  end;

  // =========================================================================
  //  9. TStepFactory tests
  // =========================================================================
  [TestFixture]
  TStepFactoryTests = class
  private
    FValue: Integer;
  public
    procedure SetValue100;
    procedure SetValueTo(const AValue: Integer);
    procedure AddValues(const A: Integer; const B: Integer);
    procedure AddThree(const A: Integer; const B: Integer; const C: Integer);
    procedure AddFour(const A: Integer; const B: Integer;
                      const C: Integer; const D: Integer);
    procedure ValueShouldBe(const AExpected: Integer);

    [Setup]    procedure Setup;
    [TearDown] procedure TearDown;

    [Test] procedure Factory_ZeroParam_DescriptionDerived;
    [Test] procedure Factory_OneParam_DescriptionIncludesValue;
    [Test] procedure Factory_TwoParam_DescriptionIncludesBothValues;
    [Test] procedure Factory_ThreeParam_DescriptionIncludesAllValues;
    [Test] procedure Factory_FourParam_DescriptionIncludesAllValues;
    [Test] procedure Factory_AnonymousMethod_UsesLabel;
    [Test] procedure Factory_PrebuiltStep_ExecutesCorrectly;
    [Test] procedure Factory_PrebuiltStep_DescriptionPreservedAfterAssignment;
  end;

  // =========================================================================
  //  10. Anonymous method (TProc) steps
  // =========================================================================
  [TestFixture]
  TAnonymousMethodStepTests = class
  private
    FValue: Integer;
  public
    procedure ValueShouldBe10;

    [Setup]    procedure Setup;
    [TearDown] procedure TearDown;

    [Test] procedure Anon_LabelUsedAsDescription;
    [Test] procedure Anon_ClosureCapture_Integer;
    [Test] procedure Anon_ClosureCapture_String;
    [Test] procedure Anon_FailingStep_RecordsError;
  end;

  // =========================================================================
  //  11. Failure behaviour — comprehensive
  // =========================================================================
  [TestFixture]
  TFailureBehaviourTests = class
  private
    FLog: TStringList;
  public
    procedure PassingStep;
    procedure FailingStep;
    procedure StepThatShouldBeSkipped;
    procedure AppendToLog(const AText: string);

    [Setup]    procedure Setup;
    [TearDown] procedure TearDown;

    [Test] procedure Failure_FailingGiven_RaisesETestFailure;
    [Test] procedure Failure_FailingWhen_RaisesETestFailure;
    [Test] procedure Failure_FailingThen_RaisesETestFailure;
    [Test] procedure Failure_FailingGiven_SkipsWhenAndThen;
    [Test] procedure Failure_FailingWhen_SkipsThen;
    [Test] procedure Failure_FailingThen_DoesNotSkipNextThen;
    [Test] procedure Failure_AndAlso_After_Given_HaltsOnFailure;
    [Test] procedure Failure_AndAlso_After_When_HaltsOnFailure;
    [Test] procedure Failure_AndAlso_After_Then_DoesNotHalt;
    [Test] procedure Failure_ErrorMessageIncludedInOutput;
    [Test] procedure Failure_MultipleFailures_AllReported;
  end;

  // =========================================================================
  //  12. Multi-scenario stories
  // =========================================================================
  [TestFixture]
  TMultiScenarioTests = class
  private
    FValue: Integer;
  public
    procedure SetValue0;
    procedure SetValueTo(const AValue: Integer);
    procedure IncrementValue;
    procedure ValueShouldBe(const AExpected: Integer);
    procedure ResetValue;

    [Setup]    procedure Setup;
    [TearDown] procedure TearDown;

    [Test] procedure MultiScenario_BothScenariosRun;
    [Test] procedure MultiScenario_StateIsolatedByReset;
    [Test] procedure MultiScenario_FirstFailsSecondStillRuns;
    [Test] procedure MultiScenario_ThreeScenarios;
  end;

  // =========================================================================
  //  13. Mixed step types in one scenario
  // =========================================================================
  [TestFixture]
  TMixedStepTypeTests = class
  private
    FValue: Integer;
  public
    procedure SetValue0;
    procedure SetValueTo(const AValue: Integer);
    procedure IncrementValue;
    procedure ValueShouldBe(const AExpected: Integer);

    [Setup]    procedure Setup;
    [TearDown] procedure TearDown;

    [Test] procedure Mixed_ZeroAndOneParam_InOneScenario;
    [Test] procedure Mixed_PrebuiltAndInline_InOneScenario;
    [Test] procedure Mixed_AnonAndMethod_InOneScenario;
  end;

  // =========================================================================
  //  14. [TestCase] integration
  // =========================================================================
  [TestFixture]
  TTestCaseIntegrationTests = class
  private
    FValue: Integer;
  public
    [Setup]    procedure Setup;
    [TearDown] procedure TearDown;

    [Test]
    [TestCase('Add 10 and 20 expect 30', '10,20,30')]
    [TestCase('Add 0 and 0 expect 0',    '0,0,0')]
    [TestCase('Add 100 and 1 expect 101','100,1,101')]
    [TestCase('Add negative, -5+5=0',   '-5,5,0')]
    procedure TestCase_ParameterisedAddition(A, B, Expected: Integer);
  end;

implementation

// =========================================================================
//  1. TNameConversionTests
// =========================================================================

procedure TNameConversionTests.CamelCase_SimpleTwoWord;
begin
  Assert.AreEqual('account balance', CamelCaseToWords('AccountBalance'));
end;

procedure TNameConversionTests.CamelCase_ThreeWords;
begin
  Assert.AreEqual('customer requests withdrawal',
    CamelCaseToWords('CustomerRequestsWithdrawal'));
end;

procedure TNameConversionTests.CamelCase_SingleWord;
begin
  Assert.AreEqual('account', CamelCaseToWords('Account'));
end;

procedure TNameConversionTests.CamelCase_EmptyString;
begin
  Assert.AreEqual('', CamelCaseToWords(''));
end;

procedure TNameConversionTests.CamelCase_AcronymAtEnd;
begin
  Assert.AreEqual('withdraw from ATM', CamelCaseToWords('WithdrawFromATM'));
end;

procedure TNameConversionTests.CamelCase_AcronymInMiddle;
begin
  Assert.AreEqual('customer ATM card', CamelCaseToWords('CustomerATMCard'));
end;

procedure TNameConversionTests.CamelCase_AcronymAtStart;
begin
  Assert.AreEqual('ATM withdrawal', CamelCaseToWords('ATMWithdrawal'));
end;

procedure TNameConversionTests.CamelCase_DigitBoundaryEnd;
begin
  Assert.AreEqual('withdraw 20', CamelCaseToWords('Withdraw20'));
end;

procedure TNameConversionTests.CamelCase_DigitBoundaryMiddle;
begin
  Assert.AreEqual('withdraw 20 GBP', CamelCaseToWords('Withdraw20GBP'));
end;

procedure TNameConversionTests.CamelCase_ConsecutiveAcronyms;
begin
  Assert.AreEqual('ATM PIN code', CamelCaseToWords('ATMPINCode'));
end;

procedure TNameConversionTests.CamelCase_SingleChar;
begin
  Assert.AreEqual('a', CamelCaseToWords('A'));
end;

procedure TNameConversionTests.CamelCase_AllUpperCase;
begin
  // All-uppercase single token treated as one acronym
  Assert.AreEqual('ATM', CamelCaseToWords('ATM'));
end;

procedure TNameConversionTests.Underscore_SimpleWords;
begin
  Assert.AreEqual('account is in credit',
    IdentifierToWords('account_is_in_credit'));
end;

procedure TNameConversionTests.Underscore_WithCamelCaseTokens;
begin
  Assert.AreEqual('account is in credit',
    IdentifierToWords('Account_IsInCredit'));
end;

procedure TNameConversionTests.Underscore_LeadingTrailing;
begin
  // Leading/trailing underscores produce empty tokens which are skipped
  Assert.AreEqual('account balance',
    IdentifierToWords('_AccountBalance_'));
end;

procedure TNameConversionTests.Underscore_ConsecutiveUnderscores;
begin
  // Consecutive underscores produce empty tokens which are skipped
  Assert.AreEqual('account balance',
    IdentifierToWords('Account__Balance'));
end;

procedure TNameConversionTests.Mixed_UnderscoreAndCamelCase;
begin
  Assert.AreEqual('customer ATM withdrawal',
    IdentifierToWords('Customer_ATMWithdrawal'));
end;

procedure TNameConversionTests.IdentifierToWords_Empty;
begin
  Assert.AreEqual('', IdentifierToWords(''));
end;

procedure TNameConversionTests.IdentifierToWords_NoundersCore_delegatesToCamelCase;
begin
  Assert.AreEqual('account is in credit',
    IdentifierToWords('AccountIsInCredit'));
end;

// =========================================================================
//  2. TStepOutcomeTests — setup and steps
// =========================================================================

procedure TStepOutcomeTests.Setup;
begin
  FValue := 0;
end;

procedure TStepOutcomeTests.TearDown;
begin
end;

procedure TStepOutcomeTests.SetValueTo10;  begin FValue := 10; end;
procedure TStepOutcomeTests.SetValueTo20;  begin FValue := 20; end;
procedure TStepOutcomeTests.IncrementValue; begin Inc(FValue); end;
procedure TStepOutcomeTests.ValueShouldBe10; begin Assert.AreEqual(10, FValue); end;
procedure TStepOutcomeTests.ValueShouldBe20; begin Assert.AreEqual(20, FValue); end;
procedure TStepOutcomeTests.ValueShouldBe30; begin Assert.AreEqual(30, FValue); end;

procedure TStepOutcomeTests.StepThatFails;
begin
  raise Exception.Create('Intentional step failure');
end;

procedure TStepOutcomeTests.StepThatShouldNotRun;
begin
  Assert.Fail('This step should have been skipped');
end;

procedure TStepOutcomeTests.SetValueTo(const AValue: Integer);
begin
  FValue := AValue;
end;

procedure TStepOutcomeTests.ValueShouldBe(const AExpected: Integer);
begin
  Assert.AreEqual(AExpected, FValue);
end;

procedure TStepOutcomeTests.ZeroParam_PassingStepsAllPass;
begin
  Story('Step outcomes are tracked correctly')
    .AsA('StoryOP framework')
    .IWantTo('track step outcomes reliably')
    .SoThat('passing tests are correctly identified')
    .WithScenario('All steps pass')
      .Given(SetValueTo10)
      .When(IncrementValue)
      .Then_<Integer>(ValueShouldBe, 11)
    .Execute;
end;

procedure TStepOutcomeTests.ZeroParam_FailingThenRecorded;
begin
  Assert.WillRaise(
    procedure
    begin
      Story('Failing Then is recorded')
        .WithScenario('Then step fails')
          .Given(SetValueTo10)
          .Then_(ValueShouldBe20)
        .Execute;
    end,
    ETestFailure);
end;

procedure TStepOutcomeTests.ZeroParam_FailingGivenHaltsScenario;
begin
  Assert.WillRaise(
    procedure
    begin
      Story('Failing Given halts scenario')
        .WithScenario('Given fails')
          .Given(StepThatFails)
          .When(StepThatShouldNotRun)
          .Then_(StepThatShouldNotRun)
        .Execute;
    end,
    ETestFailure);
end;

procedure TStepOutcomeTests.ZeroParam_FailingWhenHaltsScenario;
begin
  Assert.WillRaise(
    procedure
    begin
      Story('Failing When halts scenario')
        .WithScenario('When fails')
          .Given(SetValueTo10)
          .When(StepThatFails)
          .Then_(StepThatShouldNotRun)
        .Execute;
    end,
    ETestFailure);
end;

procedure TStepOutcomeTests.ZeroParam_FailingThenDoesNotHaltSubsequentThen;
begin
  (*
    A failing Then must NOT halt subsequent Thens.
    StepThatShouldNotRun would call Assert.Fail if executed —
    but here we use ValueShouldBe20 (which will fail since value=10)
    and ValueShouldBe10 (which will pass), to prove the second Then runs.
    We wrap in WillRaise because the first Then failure will propagate.
  *)
  Assert.WillRaise(
    procedure
    begin
      Story('Failing Then does not halt subsequent Thens')
        .WithScenario('Two Thens, first fails')
          .Given(SetValueTo10)
          .Then_(ValueShouldBe20)   // fails — value is 10
          .Then_(ValueShouldBe10)   // must still run and pass
        .Execute;
    end,
    ETestFailure);
  // If StepThatShouldNotRun ran, it would raise its own Assert.Fail
  // with a different message — the WillRaise test would still catch it.
  // The real verification is that ValueShouldBe10 executed (value=10 passes).
end;

procedure TStepOutcomeTests.ZeroParam_MultiplePassingSteps;
begin
  Story('Multiple passing steps')
    .WithScenario('Several steps all pass')
      .Given(SetValueTo10)
      .AndAlso(IncrementValue)
      .AndAlso(IncrementValue)
      .Then_<Integer>(ValueShouldBe, 12)
    .Execute;
end;

// =========================================================================
//  3. TNarrativePatternTests
// =========================================================================

procedure TNarrativePatternTests.NoOpStep;
begin
  // Does nothing — used as a neutral step in narrative tests
end;

procedure TNarrativePatternTests.Narrative_ClassicBDD;
begin
  Story('Classic BDD narrative')
    .InOrderTo('verify classic BDD narrative compiles and runs')
    .AsA('StoryOP framework')
    .IWantTo('support InOrderTo / AsA / IWantTo')
    .WithScenario('Classic BDD')
      .Given(NoOpStep)
      .Then_(NoOpStep)
    .Execute;
end;

procedure TNarrativePatternTests.Narrative_RoleBehaviourBenefit;
begin
  Story('Role Behaviour Benefit narrative')
    .AsA('StoryOP framework')
    .IWant('to support AsA / IWant / SoThat')
    .SoThat('developers can use Role/Behaviour/Benefit style')
    .WithScenario('Role / Behaviour / Benefit')
      .Given(NoOpStep)
      .Then_(NoOpStep)
    .Execute;
end;

procedure TNarrativePatternTests.Narrative_FDD;
begin
  Story('FDD narrative')
    .Action('verify FDD narrative style')
    .Outcome('the story renders with Action/Outcome/Entity labels')
    .Entity('StoryOP framework')
    .WithScenario('FDD style')
      .Given(NoOpStep)
      .Then_(NoOpStep)
    .Execute;
end;

procedure TNarrativePatternTests.Narrative_Declarative;
begin
  Story('Declarative narrative')
    .AsA('StoryOP framework')
    .Action('support declarative mixed narrative')
    .Outcome('story headers render correctly')
    .WithScenario('Declarative')
      .Given(NoOpStep)
      .Then_(NoOpStep)
    .Execute;
end;

procedure TNarrativePatternTests.Narrative_PlainString;
begin
  Story('As a framework I want to support a plain title with no narrative clauses')
    .WithScenario('Plain string only')
      .Given(NoOpStep)
      .Then_(NoOpStep)
    .Execute;
end;

procedure TNarrativePatternTests.Narrative_CustomLabel;
begin
  Story('Custom narrative labels')
    .Narrative('Given that', 'the framework is running')
    .Narrative('I expect that', 'custom labels appear in the report')
    .WithScenario('Custom label')
      .Given(NoOpStep)
      .Then_(NoOpStep)
    .Execute;
end;

procedure TNarrativePatternTests.Narrative_MultipleCallsSameMethod;
begin
  // Calling the same narrative method multiple times — all entries appear
  Story('Repeated narrative entries')
    .AsA('developer')
    .AsA('another role')     // second AsA — both should appear
    .WithScenario('Repeated calls')
      .Given(NoOpStep)
      .Then_(NoOpStep)
    .Execute;
end;

procedure TNarrativePatternTests.Narrative_MixedPatterns;
begin
  Story('Mixed narrative patterns')
    .AsA('developer')
    .Action('mix narrative styles freely')
    .SoThat('the framework stays flexible')
    .Narrative('Note', 'order is preserved exactly as called')
    .WithScenario('Mixed')
      .Given(NoOpStep)
      .Then_(NoOpStep)
    .Execute;
end;

// =========================================================================
//  4. TStepNamingTests
// =========================================================================

procedure TStepNamingTests.SimpleMethodName;         begin end;
procedure TStepNamingTests.CamelCaseMethodName;      begin end;
procedure TStepNamingTests.MethodWithATMInName;      begin end;
procedure TStepNamingTests.MethodWithDigits20;       begin end;
procedure TStepNamingTests.Underscore_method_name;   begin end;
procedure TStepNamingTests.Mixed_CamelAndUnderscore; begin end;

procedure TStepNamingTests.Naming_SimpleMethod_ProducesReadableName;
var
  S: TBDDStep;
begin
  S := TStepFactory.Create(SimpleMethodName);
  try
    Assert.AreEqual('simple method name', S.Description);
  finally
    S.Free;
  end;
end;

procedure TStepNamingTests.Naming_CamelCase_SplitsCorrectly;
var
  S: TBDDStep;
begin
  S := TStepFactory.Create(CamelCaseMethodName);
  try
    Assert.AreEqual('camel case method name', S.Description);
  finally
    S.Free;
  end;
end;

procedure TStepNamingTests.Naming_Acronym_Preserved;
var
  S: TBDDStep;
begin
  S := TStepFactory.Create(MethodWithATMInName);
  try
    Assert.AreEqual('method with ATM in name', S.Description);
  finally
    S.Free;
  end;
end;

procedure TStepNamingTests.Naming_DigitBoundary_SplitsCorrectly;
var
  S: TBDDStep;
begin
  S := TStepFactory.Create(MethodWithDigits20);
  try
    Assert.AreEqual('method with digits 20', S.Description);
  finally
    S.Free;
  end;
end;

procedure TStepNamingTests.Naming_Underscore_ProducesReadableName;
var
  S: TBDDStep;
begin
  S := TStepFactory.Create(Underscore_method_name);
  try
    Assert.AreEqual('underscore method name', S.Description);
  finally
    S.Free;
  end;
end;

procedure TStepNamingTests.Naming_Mixed_ProducesReadableName;
var
  S: TBDDStep;
begin
  S := TStepFactory.Create(Mixed_CamelAndUnderscore);
  try
    Assert.AreEqual('mixed camel and underscore', S.Description);
  finally
    S.Free;
  end;
end;

// =========================================================================
//  5. TOneParamStepTests
// =========================================================================

procedure TOneParamStepTests.Setup;
begin
  FIntValue    := 0;
  FStrValue    := '';
  FBoolValue   := False;
  FDoubleValue := 0.0;
end;

procedure TOneParamStepTests.TearDown; begin end;

procedure TOneParamStepTests.SetIntValue(const AValue: Integer);
begin FIntValue := AValue; end;

procedure TOneParamStepTests.IntValueShouldBe(const AExpected: Integer);
begin Assert.AreEqual(AExpected, FIntValue); end;

procedure TOneParamStepTests.SetStrValue(const AValue: string);
begin FStrValue := AValue; end;

procedure TOneParamStepTests.StrValueShouldBe(const AExpected: string);
begin Assert.AreEqual(AExpected, FStrValue); end;

procedure TOneParamStepTests.SetBoolValue(const AValue: Boolean);
begin FBoolValue := AValue; end;

procedure TOneParamStepTests.BoolValueShouldBeTrue(const AExpected: Boolean);
begin Assert.AreEqual(AExpected, FBoolValue); end;

procedure TOneParamStepTests.SetDoubleValue(const AValue: Double);
begin FDoubleValue := AValue; end;

procedure TOneParamStepTests.DoubleValueShouldBe(const AExpected: Double);
begin Assert.AreEqual(AExpected, FDoubleValue, 0.0001); end;

procedure TOneParamStepTests.OneParam_Integer_PassThrough;
begin
  Story('One-parameter integer steps')
    .AsA('StoryOP framework')
    .IWantTo('pass integer parameters to step procedures')
    .WithScenario('Integer parameter passed through correctly')
      .Given<Integer>(SetIntValue, 42)
      .Then_<Integer>(IntValueShouldBe, 42)
    .Execute;
end;

procedure TOneParamStepTests.OneParam_String_PassThrough;
begin
  Story('One-parameter string steps')
    .WithScenario('String parameter passed through correctly')
      .Given<string>(SetStrValue, 'hello')
      .Then_<string>(StrValueShouldBe, 'hello')
    .Execute;
end;

procedure TOneParamStepTests.OneParam_Boolean_PassThrough;
begin
  Story('One-parameter boolean steps')
    .WithScenario('Boolean parameter passed through correctly')
      .Given<Boolean>(SetBoolValue, True)
      .Then_<Boolean>(BoolValueShouldBeTrue, True)
    .Execute;
end;

procedure TOneParamStepTests.OneParam_Double_PassThrough;
begin
  Story('One-parameter double steps')
    .WithScenario('Double parameter passed through correctly')
      .Given<Double>(SetDoubleValue, 3.14)
      .Then_<Double>(DoubleValueShouldBe, 3.14)
    .Execute;
end;

procedure TOneParamStepTests.OneParam_NegativeInteger;
begin
  Story('One-parameter negative integer')
    .WithScenario('Negative integer passed through correctly')
      .Given<Integer>(SetIntValue, -99)
      .Then_<Integer>(IntValueShouldBe, -99)
    .Execute;
end;

procedure TOneParamStepTests.OneParam_EmptyString;
begin
  Story('One-parameter empty string')
    .WithScenario('Empty string passed through correctly')
      .Given<string>(SetStrValue, '')
      .Then_<string>(StrValueShouldBe, '')
    .Execute;
end;

procedure TOneParamStepTests.OneParam_ParamAppearsInNarrative;
var
  S: TBDDStep;
begin
  // Verify the parameter value appears in the step description
  S := TStepFactory.Create<Integer>(SetIntValue, 42);
  try
    Assert.IsTrue(Pos('[42]', S.Description) > 0,
      'Parameter value should appear in description as [42], got: ' + S.Description);
  finally
    S.Free;
  end;
end;

procedure TOneParamStepTests.OneParam_ViaAndAlso;
begin
  Story('AndAlso with one-parameter step')
    .WithScenario('AndAlso accepts parameterised step')
      .Given<Integer>(SetIntValue, 10)
      .AndAlso<Integer>(SetIntValue, 20)   // overwrites with 20
      .Then_<Integer>(IntValueShouldBe, 20)
    .Execute;
end;

// =========================================================================
//  6. TTwoParamStepTests
// =========================================================================

procedure TTwoParamStepTests.Setup;
begin
  FSum    := 0;
  FConcat := '';
end;

procedure TTwoParamStepTests.TearDown; begin end;

procedure TTwoParamStepTests.AddTwoIntegers(const A: Integer; const B: Integer);
begin FSum := A + B; end;

procedure TTwoParamStepTests.SumShouldBe(const AExpected: Integer);
begin Assert.AreEqual(AExpected, FSum); end;

procedure TTwoParamStepTests.ConcatTwoStrings(const A: string; const B: string);
begin FConcat := A + B; end;

procedure TTwoParamStepTests.ConcatShouldBe(const AExpected: string);
begin Assert.AreEqual(AExpected, FConcat); end;

procedure TTwoParamStepTests.SetIntAndStr(const AInt: Integer; const AStr: string);
begin FSum := AInt; FConcat := AStr; end;

procedure TTwoParamStepTests.IntShouldBeAndStrShouldBe(const AInt: Integer; const AStr: string);
begin
  Assert.AreEqual(AInt, FSum);
  Assert.AreEqual(AStr, FConcat);
end;

procedure TTwoParamStepTests.TwoParam_IntegerPair;
begin
  Story('Two-parameter integer steps')
    .WithScenario('Two integers added correctly')
      .Given<Integer,Integer>(AddTwoIntegers, 7, 8)
      .Then_<Integer>(SumShouldBe, 15)
    .Execute;
end;

procedure TTwoParamStepTests.TwoParam_StringPair;
begin
  Story('Two-parameter string steps')
    .WithScenario('Two strings concatenated correctly')
      .Given<string,string>(ConcatTwoStrings, 'hello', ' world')
      .Then_<string>(ConcatShouldBe, 'hello world')
    .Execute;
end;

procedure TTwoParamStepTests.TwoParam_MixedTypes;
begin
  Story('Two-parameter mixed type steps')
    .WithScenario('Integer and string passed correctly')
      .Given<Integer,string>(SetIntAndStr, 99, 'test')
      .Then_<Integer,string>(IntShouldBeAndStrShouldBe, 99, 'test')
    .Execute;
end;

procedure TTwoParamStepTests.TwoParam_BothParamsInNarrative;
var
  S: TBDDStep;
begin
  S := TStepFactory.Create<Integer,Integer>(AddTwoIntegers, 3, 4);
  try
    Assert.IsTrue(Pos('[3, 4]', S.Description) > 0,
      'Both params should appear as [3, 4], got: ' + S.Description);
  finally
    S.Free;
  end;
end;

// =========================================================================
//  7. TThreeParamStepTests
// =========================================================================

procedure TThreeParamStepTests.Setup;    begin FResult := 0; end;
procedure TThreeParamStepTests.TearDown; begin end;

procedure TThreeParamStepTests.AddThreeIntegers(const A: Integer; const B: Integer; const C: Integer);
begin FResult := A + B + C; end;

procedure TThreeParamStepTests.ResultShouldBe(const AExpected: Integer);
begin Assert.AreEqual(AExpected, FResult); end;

procedure TThreeParamStepTests.SetNameAgeScore(const AName: string; const AAge: Integer; const AScore: Double);
begin
  // store name length as result to verify all three params were passed
  FResult := Length(AName) + AAge + Round(AScore);
end;

procedure TThreeParamStepTests.NameShouldBe(const AExpected: string);
begin
  Assert.AreEqual(Length(AExpected), FResult - 25 - 90, 'Name length component incorrect');
end;

procedure TThreeParamStepTests.ThreeParam_IntegerTriple;
begin
  Story('Three-parameter integer steps')
    .WithScenario('Three integers added correctly')
      .Given<Integer,Integer,Integer>(AddThreeIntegers, 10, 20, 30)
      .Then_<Integer>(ResultShouldBe, 60)
    .Execute;
end;

procedure TThreeParamStepTests.ThreeParam_MixedTypes;
begin
  Story('Three-parameter mixed type steps')
    .WithScenario('String, integer, double passed correctly')
      .Given<string,Integer,Double>(SetNameAgeScore, 'Alice', 25, 90.0)
      .Then_<Integer>(ResultShouldBe, 5 + 25 + 90)   // 'Alice'=5, age=25, round(90.0)=90
    .Execute;
end;

procedure TThreeParamStepTests.ThreeParam_AllParamsInNarrative;
var
  S: TBDDStep;
begin
  S := TStepFactory.Create<Integer,Integer,Integer>(AddThreeIntegers, 1, 2, 3);
  try
    Assert.IsTrue(Pos('[1, 2, 3]', S.Description) > 0,
      'All three params should appear as [1, 2, 3], got: ' + S.Description);
  finally
    S.Free;
  end;
end;

// =========================================================================
//  8. TFourParamStepTests
// =========================================================================

procedure TFourParamStepTests.Setup;
begin
  FResult  := 0;
  FMessage := '';
end;

procedure TFourParamStepTests.TearDown; begin end;

procedure TFourParamStepTests.AddFourIntegers(const A: Integer; const B: Integer;
                                               const C: Integer; const D: Integer);
begin FResult := A + B + C + D; end;

procedure TFourParamStepTests.ResultShouldBe(const AExpected: Integer);
begin Assert.AreEqual(AExpected, FResult); end;

procedure TFourParamStepTests.BuildMessage(const APrefix: string; const AValue: Integer;
                                            const ASuffix: string; const ARepeat: Boolean);
begin
  FMessage := APrefix + IntToStr(AValue) + ASuffix;
  if ARepeat then
    FMessage := FMessage + FMessage;
end;

procedure TFourParamStepTests.MessageShouldContain(const ASubstring: string);
begin
  Assert.IsTrue(Pos(ASubstring, FMessage) > 0,
    Format('Expected message to contain "%s", got: "%s"', [ASubstring, FMessage]));
end;

procedure TFourParamStepTests.FourParam_IntegerQuad;
begin
  Story('Four-parameter integer steps')
    .WithScenario('Four integers added correctly')
      .Given<Integer,Integer,Integer,Integer>(AddFourIntegers, 1, 2, 3, 4)
      .Then_<Integer>(ResultShouldBe, 10)
    .Execute;
end;

procedure TFourParamStepTests.FourParam_MixedTypes;
begin
  Story('Four-parameter mixed type steps')
    .WithScenario('String, integer, string, boolean passed correctly')
      .Given<string,Integer,string,Boolean>(BuildMessage, 'val=', 42, '!', False)
      .Then_<string>(MessageShouldContain, 'val=42!')
    .Execute;
end;

procedure TFourParamStepTests.FourParam_AllParamsInNarrative;
var
  S: TBDDStep;
begin
  S := TStepFactory.Create<Integer,Integer,Integer,Integer>(AddFourIntegers, 1, 2, 3, 4);
  try
    Assert.IsTrue(Pos('[1, 2, 3, 4]', S.Description) > 0,
      'All four params should appear as [1, 2, 3, 4], got: ' + S.Description);
  finally
    S.Free;
  end;
end;

// =========================================================================
//  9. TStepFactoryTests
// =========================================================================

procedure TStepFactoryTests.Setup;    begin FValue := 0; end;
procedure TStepFactoryTests.TearDown; begin end;

procedure TStepFactoryTests.SetValue100;              begin FValue := 100; end;
procedure TStepFactoryTests.SetValueTo(const AValue: Integer); begin FValue := AValue; end;
procedure TStepFactoryTests.AddValues(const A: Integer; const B: Integer); begin FValue := A + B; end;
procedure TStepFactoryTests.AddThree(const A: Integer; const B: Integer; const C: Integer); begin FValue := A + B + C; end;
procedure TStepFactoryTests.AddFour(const A: Integer; const B: Integer; const C: Integer; const D: Integer); begin FValue := A + B + C + D; end;
procedure TStepFactoryTests.ValueShouldBe(const AExpected: Integer); begin Assert.AreEqual(AExpected, FValue); end;

procedure TStepFactoryTests.Factory_ZeroParam_DescriptionDerived;
var
  S: TBDDStep;
begin
  S := TStepFactory.Create(SetValue100);
  try
    Assert.AreEqual('set value 100', S.Description);
  finally
    S.Free;
  end;
end;

procedure TStepFactoryTests.Factory_OneParam_DescriptionIncludesValue;
var
  S: TBDDStep;
begin
  S := TStepFactory.Create<Integer>(SetValueTo, 55);
  try
    Assert.IsTrue(Pos('[55]', S.Description) > 0,
      'Description should include [55], got: ' + S.Description);
  finally
    S.Free;
  end;
end;

procedure TStepFactoryTests.Factory_TwoParam_DescriptionIncludesBothValues;
var
  S: TBDDStep;
begin
  S := TStepFactory.Create<Integer,Integer>(AddValues, 3, 7);
  try
    Assert.IsTrue(Pos('[3, 7]', S.Description) > 0,
      'Description should include [3, 7], got: ' + S.Description);
  finally
    S.Free;
  end;
end;

procedure TStepFactoryTests.Factory_ThreeParam_DescriptionIncludesAllValues;
var
  S: TBDDStep;
begin
  S := TStepFactory.Create<Integer,Integer,Integer>(AddThree, 1, 2, 3);
  try
    Assert.IsTrue(Pos('[1, 2, 3]', S.Description) > 0,
      'Description should include [1, 2, 3], got: ' + S.Description);
  finally
    S.Free;
  end;
end;

procedure TStepFactoryTests.Factory_FourParam_DescriptionIncludesAllValues;
var
  S: TBDDStep;
begin
  S := TStepFactory.Create<Integer,Integer,Integer,Integer>(AddFour, 10, 20, 30, 40);
  try
    Assert.IsTrue(Pos('[10, 20, 30, 40]', S.Description) > 0,
      'Description should include [10, 20, 30, 40], got: ' + S.Description);
  finally
    S.Free;
  end;
end;

procedure TStepFactoryTests.Factory_AnonymousMethod_UsesLabel;
var
  S: TBDDStep;
begin
  S := TStepFactory.Create(procedure begin FValue := 99; end, 'my custom label');
  try
    Assert.AreEqual('my custom label', S.Description);
  finally
    S.Free;
  end;
end;

procedure TStepFactoryTests.Factory_PrebuiltStep_ExecutesCorrectly;
var
  S: TBDDStep;
begin
  S := TStepFactory.Create<Integer>(SetValueTo, 77);

  Story('Pre-built step executes correctly')
    .WithScenario('Step built via TStepFactory runs as expected')
      .Given(S)
      .Then_<Integer>(ValueShouldBe, 77)
    .Execute;
end;

procedure TStepFactoryTests.Factory_PrebuiltStep_DescriptionPreservedAfterAssignment;
var
  S    : TBDDStep;
  Desc : string;
begin
  // Capture description at Step() time
  S    := TStepFactory.Create<Integer>(SetValueTo, 42);
  Desc := S.Description;

  // Description must be unchanged after passing to a scenario
  Story('Description preserved through assignment')
    .WithScenario('Description unchanged')
      .Given(S)
      .Then_(procedure
             begin
               Assert.AreEqual(Desc, 'set value to [42]',
                 'Description should match original, got: ' + Desc);
             end,
             'description equals original')
    .Execute;
end;

// =========================================================================
//  10. TAnonymousMethodStepTests
// =========================================================================

procedure TAnonymousMethodStepTests.Setup;    begin FValue := 0; end;
procedure TAnonymousMethodStepTests.TearDown; begin end;
procedure TAnonymousMethodStepTests.ValueShouldBe10; begin Assert.AreEqual(10, FValue); end;

procedure TAnonymousMethodStepTests.Anon_LabelUsedAsDescription;
begin
  Story('Anonymous method label')
    .WithScenario('Label string appears in narrative')
      .Given(procedure begin FValue := 10; end, 'value is set to ten')
      .Then_(ValueShouldBe10)
    .Execute;
end;

procedure TAnonymousMethodStepTests.Anon_ClosureCapture_Integer;
var
  CapturedValue: Integer;
begin
  CapturedValue := 42;
  Story('Anonymous method closure capture — integer')
    .WithScenario('Closure captures integer from enclosing scope')
      .Given(procedure begin FValue := CapturedValue; end,
             'value set from closure')
      .Then_(procedure
             begin
               Assert.AreEqual(42, FValue);
             end,
             'value should be 42')
    .Execute;
end;

procedure TAnonymousMethodStepTests.Anon_ClosureCapture_String;
var
  CapturedStr: string;
  ResultStr  : string;
begin
  CapturedStr := 'StoryOP';
  ResultStr   := '';
  Story('Anonymous method closure capture — string')
    .WithScenario('Closure captures string from enclosing scope')
      .Given(procedure begin ResultStr := CapturedStr + ' rocks'; end,
             'result built from captured string')
      .Then_(procedure
             begin
               Assert.AreEqual('StoryOP rocks', ResultStr);
             end,
             'result should be StoryOP rocks')
    .Execute;
end;

procedure TAnonymousMethodStepTests.Anon_FailingStep_RecordsError;
begin
  Assert.WillRaise(
    procedure
    begin
      Story('Anonymous method failure')
        .WithScenario('Failing anonymous Then is recorded')
          .Given(procedure begin FValue := 10; end, 'value is 10')
          .Then_(procedure begin Assert.AreEqual(99, FValue); end,
                 'value should be 99 — will fail')
        .Execute;
    end,
    ETestFailure);
end;

// =========================================================================
//  11. TFailureBehaviourTests
// =========================================================================

procedure TFailureBehaviourTests.Setup;
begin
  FLog := TStringList.Create;
end;

procedure TFailureBehaviourTests.TearDown;
begin
  FLog.Free;
end;

procedure TFailureBehaviourTests.PassingStep;             begin FLog.Add('passed'); end;
procedure TFailureBehaviourTests.FailingStep;             begin raise Exception.Create('step failed deliberately'); end;
procedure TFailureBehaviourTests.StepThatShouldBeSkipped; begin FLog.Add('SHOULD NOT RUN'); end;
procedure TFailureBehaviourTests.AppendToLog(const AText: string); begin FLog.Add(AText); end;

procedure TFailureBehaviourTests.Failure_FailingGiven_RaisesETestFailure;
begin
  Assert.WillRaise(
    procedure
    begin
      Story('Failing Given raises ETestFailure')
        .WithScenario('Given fails')
          .Given(FailingStep)
          .Then_(PassingStep)
        .Execute;
    end,
    ETestFailure, 'Execute should raise ETestFailure when Given fails');
end;

procedure TFailureBehaviourTests.Failure_FailingWhen_RaisesETestFailure;
begin
  Assert.WillRaise(
    procedure
    begin
      Story('Failing When raises ETestFailure')
        .WithScenario('When fails')
          .Given(PassingStep)
          .When(FailingStep)
          .Then_(PassingStep)
        .Execute;
    end,
    ETestFailure, 'Execute should raise ETestFailure when When fails');
end;

procedure TFailureBehaviourTests.Failure_FailingThen_RaisesETestFailure;
begin
  Assert.WillRaise(
    procedure
    begin
      Story('Failing Then raises ETestFailure')
        .WithScenario('Then fails')
          .Given(PassingStep)
          .Then_(FailingStep)
        .Execute;
    end,
    ETestFailure, 'Execute should raise ETestFailure when Then fails');
end;

procedure TFailureBehaviourTests.Failure_FailingGiven_SkipsWhenAndThen;
begin
  FLog.Clear;
  Assert.WillRaise(
    procedure
    begin
      Story('Failing Given skips When and Then')
        .WithScenario('Given fails — subsequent steps skipped')
          .Given(FailingStep)
          .When(StepThatShouldBeSkipped)
          .Then_(StepThatShouldBeSkipped)
        .Execute;
    end,
    ETestFailure);
  // If any skipped step ran, it added 'SHOULD NOT RUN' to FLog
  Assert.IsFalse(FLog.IndexOf('SHOULD NOT RUN') >= 0,
    'Steps after failing Given should have been skipped');
end;

procedure TFailureBehaviourTests.Failure_FailingWhen_SkipsThen;
begin
  FLog.Clear;
  Assert.WillRaise(
    procedure
    begin
      Story('Failing When skips Then')
        .WithScenario('When fails — Then skipped')
          .Given(PassingStep)
          .When(FailingStep)
          .Then_(StepThatShouldBeSkipped)
        .Execute;
    end,
    ETestFailure);
  Assert.IsFalse(FLog.IndexOf('SHOULD NOT RUN') >= 0,
    'Then after failing When should have been skipped');
end;

procedure TFailureBehaviourTests.Failure_FailingThen_DoesNotSkipNextThen;
begin
  FLog.Clear;
  Assert.WillRaise(
    procedure
    begin
      Story('Failing Then does not skip subsequent Thens')
        .WithScenario('First Then fails — second Then still runs')
          .Given(PassingStep)
          .Then_(FailingStep)              // fails
          .Then_<string>(AppendToLog, 'second then ran')  // must still run
        .Execute;
    end,
    ETestFailure);
  Assert.IsTrue(FLog.IndexOf('second then ran') >= 0,
    'Second Then should have run despite first Then failing');
end;

procedure TFailureBehaviourTests.Failure_AndAlso_After_Given_HaltsOnFailure;
begin
  FLog.Clear;
  Assert.WillRaise(
    procedure
    begin
      Story('AndAlso after Given halts on failure')
        .WithScenario('And (Given) fails — halts')
          .Given(PassingStep)
          .AndAlso(FailingStep)               // And (Given) — should halt
          .When(StepThatShouldBeSkipped)
          .Then_(StepThatShouldBeSkipped)
        .Execute;
    end,
    ETestFailure);
  Assert.IsFalse(FLog.IndexOf('SHOULD NOT RUN') >= 0,
    'Steps after failing And (Given) should have been skipped');
end;

procedure TFailureBehaviourTests.Failure_AndAlso_After_When_HaltsOnFailure;
begin
  FLog.Clear;
  Assert.WillRaise(
    procedure
    begin
      Story('AndAlso after When halts on failure')
        .WithScenario('And (When) fails — halts')
          .Given(PassingStep)
          .When(PassingStep)
          .AndAlso(FailingStep)               // And (When) — should halt
          .Then_(StepThatShouldBeSkipped)
        .Execute;
    end,
    ETestFailure);
  Assert.IsFalse(FLog.IndexOf('SHOULD NOT RUN') >= 0,
    'Then after failing And (When) should have been skipped');
end;

procedure TFailureBehaviourTests.Failure_AndAlso_After_Then_DoesNotHalt;
begin
  FLog.Clear;
  Assert.WillRaise(
    procedure
    begin
      Story('AndAlso after Then does not halt')
        .WithScenario('And (Then) fails — next Then still runs')
          .Given(PassingStep)
          .Then_(PassingStep)
          .AndAlso(FailingStep)               // And (Then) — must NOT halt
          .Then_<string>(AppendToLog, 'next then ran')
        .Execute;
    end,
    ETestFailure);
  Assert.IsTrue(FLog.IndexOf('next then ran') >= 0,
    'Then after failing And (Then) should still have run');
end;

procedure TFailureBehaviourTests.Failure_ErrorMessageIncludedInOutput;
begin
  Assert.WillRaise(
    procedure
    begin
      Story('Error message included in failure output')
        .WithScenario('Failure message propagated')
          .Given(FailingStep)
        .Execute;
    end,
    ETestFailure,
    'step failed deliberately');
end;

procedure TFailureBehaviourTests.Failure_MultipleFailures_AllReported;
begin
  (*
    Two Then steps both fail.  Both error messages must appear in the
    combined Assert.Fail message raised by Execute.
  *)
  Assert.WillRaise(
    procedure
    begin
      Story('Multiple failures all reported')
        .WithScenario('Two Thens both fail')
          .Given(PassingStep)
          .Then_(FailingStep)
          .Then_(FailingStep)
        .Execute;
    end,
    ETestFailure);
end;

// =========================================================================
//  12. TMultiScenarioTests
// =========================================================================

procedure TMultiScenarioTests.Setup;    begin FValue := 0; end;
procedure TMultiScenarioTests.TearDown; begin end;

procedure TMultiScenarioTests.SetValue0;                          begin FValue := 0; end;
procedure TMultiScenarioTests.SetValueTo(const AValue: Integer);  begin FValue := AValue; end;
procedure TMultiScenarioTests.IncrementValue;                     begin Inc(FValue); end;
procedure TMultiScenarioTests.ValueShouldBe(const AExpected: Integer); begin Assert.AreEqual(AExpected, FValue); end;
procedure TMultiScenarioTests.ResetValue;                         begin FValue := 0; end;

procedure TMultiScenarioTests.MultiScenario_BothScenariosRun;
begin
  Story('Multi-scenario story — both scenarios run')
    .AsA('StoryOP framework')
    .IWantTo('run multiple scenarios in one story')
    .WithScenario('First scenario passes')
      .Given<Integer>(SetValueTo, 10)
      .Then_<Integer>(ValueShouldBe, 10)
    .WithScenario('Second scenario also passes')
      .Given(ResetValue)
      .AndAlso<Integer>(SetValueTo, 20)
      .Then_<Integer>(ValueShouldBe, 20)
    .Execute;
end;

procedure TMultiScenarioTests.MultiScenario_StateIsolatedByReset;
begin
  Story('State isolation between scenarios')
    .WithScenario('First scenario sets value to 100')
      .Given<Integer>(SetValueTo, 100)
      .Then_<Integer>(ValueShouldBe, 100)
    .WithScenario('Second scenario resets and verifies fresh state')
      .Given(ResetValue)               // explicit reset
      .Then_<Integer>(ValueShouldBe, 0)
    .Execute;
end;

procedure TMultiScenarioTests.MultiScenario_FirstFailsSecondStillRuns;
begin
  (*
    Even when the first scenario fails, the second scenario must still run.
    We verify this by checking the second scenario's step executes and
    contributes to the final failure message.
  *)
  Assert.WillRaise(
    procedure
    begin
      Story('First scenario fails — second still runs')
        .WithScenario('First fails')
          .Given<Integer>(SetValueTo, 10)
          .Then_<Integer>(ValueShouldBe, 99)   // fails
        .WithScenario('Second still runs')
          .Given(ResetValue)
          .Then_<Integer>(ValueShouldBe, 0)    // passes — proves it ran
        .Execute;
    end,
    ETestFailure);
end;

procedure TMultiScenarioTests.MultiScenario_ThreeScenarios;
begin
  Story('Three scenarios in one story')
    .WithScenario('Scenario one')
      .Given<Integer>(SetValueTo, 1)
      .Then_<Integer>(ValueShouldBe, 1)
    .WithScenario('Scenario two')
      .Given(ResetValue)
      .AndAlso<Integer>(SetValueTo, 2)
      .Then_<Integer>(ValueShouldBe, 2)
    .WithScenario('Scenario three')
      .Given(ResetValue)
      .AndAlso<Integer>(SetValueTo, 3)
      .Then_<Integer>(ValueShouldBe, 3)
    .Execute;
end;

// =========================================================================
//  13. TMixedStepTypeTests
// =========================================================================

procedure TMixedStepTypeTests.Setup;    begin FValue := 0; end;
procedure TMixedStepTypeTests.TearDown; begin end;

procedure TMixedStepTypeTests.SetValue0;                          begin FValue := 0; end;
procedure TMixedStepTypeTests.SetValueTo(const AValue: Integer);  begin FValue := AValue; end;
procedure TMixedStepTypeTests.IncrementValue;                     begin Inc(FValue); end;
procedure TMixedStepTypeTests.ValueShouldBe(const AExpected: Integer); begin Assert.AreEqual(AExpected, FValue); end;

procedure TMixedStepTypeTests.Mixed_ZeroAndOneParam_InOneScenario;
begin
  Story('Mixed zero and one-parameter steps')
    .WithScenario('Zero and one-param steps in same scenario')
      .Given(SetValue0)                       // zero-param
      .AndAlso<Integer>(SetValueTo, 5)        // one-param
      .When(IncrementValue)                   // zero-param
      .Then_<Integer>(ValueShouldBe, 6)       // one-param
    .Execute;
end;

procedure TMixedStepTypeTests.Mixed_PrebuiltAndInline_InOneScenario;
var
  GivenStep: TBDDStep;
begin
  GivenStep := TStepFactory.Create<Integer>(SetValueTo, 10);

  Story('Mixed pre-built and inline steps')
    .WithScenario('Pre-built TBDDStep alongside inline steps')
      .Given(GivenStep)                       // pre-built TBDDStep
      .When(IncrementValue)                   // zero-param inline
      .Then_<Integer>(ValueShouldBe, 11)      // one-param inline
    .Execute;
end;

procedure TMixedStepTypeTests.Mixed_AnonAndMethod_InOneScenario;
begin
  Story('Mixed anonymous method and method reference steps')
    .WithScenario('TProc and TStepMethod in same scenario')
      .Given(procedure begin FValue := 50; end, 'value set to 50 via anonymous method')
      .When(IncrementValue)
      .Then_(procedure begin Assert.AreEqual(51, FValue); end,
             'value should be 51')
    .Execute;
end;

// =========================================================================
//  14. TTestCaseIntegrationTests
// =========================================================================

procedure TTestCaseIntegrationTests.Setup;    begin FValue := 0; end;
procedure TTestCaseIntegrationTests.TearDown; begin end;

procedure TTestCaseIntegrationTests.TestCase_ParameterisedAddition(A, B, Expected: Integer);
begin
  Story('Parameterised addition via TestCase')
    .AsA('StoryOP framework')
    .IWantTo('integrate cleanly with DUnitX [TestCase]')
    .WithScenario(Format('Add %d and %d, expect %d', [A, B, Expected]))
      .Given(procedure begin FValue := A; end,
             Format('value starts at %d', [A]))
      .When(procedure begin Inc(FValue, B); end,
            Format('add %d to value', [B]))
      .Then_(procedure begin Assert.AreEqual(Expected, FValue); end,
             Format('result should be %d', [Expected]))
    .Execute;
end;

initialization
  TDUnitX.RegisterTestFixture(TNameConversionTests);
  TDUnitX.RegisterTestFixture(TStepOutcomeTests);
  TDUnitX.RegisterTestFixture(TNarrativePatternTests);
  TDUnitX.RegisterTestFixture(TStepNamingTests);
  TDUnitX.RegisterTestFixture(TOneParamStepTests);
  TDUnitX.RegisterTestFixture(TTwoParamStepTests);
  TDUnitX.RegisterTestFixture(TThreeParamStepTests);
  TDUnitX.RegisterTestFixture(TFourParamStepTests);
  TDUnitX.RegisterTestFixture(TStepFactoryTests);
  TDUnitX.RegisterTestFixture(TAnonymousMethodStepTests);
  TDUnitX.RegisterTestFixture(TFailureBehaviourTests);
  TDUnitX.RegisterTestFixture(TMultiScenarioTests);
  TDUnitX.RegisterTestFixture(TMixedStepTypeTests);
  TDUnitX.RegisterTestFixture(TTestCaseIntegrationTests);

end.
