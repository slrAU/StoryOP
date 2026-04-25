unit StoryOP.BankAccount.Tests;

(*
  StoryOP Example - Bank Account Withdrawal
  ==========================================
  Demonstrates all StoryOP DSL features:

    - CamelCase step naming  (primary, idiomatic Delphi style)
    - Underscore step naming (also supported)
    - Multiple narrative patterns (BDD, FDD, declarative, mixed)
    - Pre-built TBDDStep variables (description survives assignment)
    - Inline anonymous methods with explicit labels
    - Multi-scenario stories
    - Halt-on-failure cascade

  Step procedures are plain "procedure of object" methods declared on
  the fixture class.  Pass them directly by name — no wrapping needed:

      .Given(AccountIsInCredit)
      .When(CustomerRequestsAWithdrawalOf20)
      .Then_(AccountBalanceShouldBe80)
*)

interface

{$RTTI EXPLICIT METHODS([vcProtected, vcPublic, vcPublished])}
//{$RTTI EXPLICIT METHODS([vcPrivate, vcProtected, vcPublic, vcPublished])
//                FIELDS([vcPrivate, vcProtected, vcPublic, vcPublished])
//                PROPERTIES([vcPublic, vcPublished])}

uses
  DUnitX.TestFramework,
  DUnitX.Exceptions,
  StoryOP;

type

  // -----------------------------------------------------------------------
  //  Minimal domain object
  // -----------------------------------------------------------------------
  TBankAccount = class
  private
    FBalance           : Integer;
    FWithdrawalDeclined: Boolean;
  public
    procedure Deposit (AAmount: Integer);
    procedure Withdraw(AAmount: Integer);
    property Balance            : Integer read FBalance;
    property WithdrawalDeclined : Boolean read FWithdrawalDeclined;
  end;

  // -----------------------------------------------------------------------
  //  Test fixture
  // -----------------------------------------------------------------------
  [TestFixture]
  TBankAccountTests = class
  private
    FAccount: TBankAccount;

    // Resets the account to a clean state between scenarios within a
    // single multi-scenario Execute call.  Call as an AndAlso step or
    // as the first Given of each scenario when state must be isolated.
    procedure ResetAccount;

    // ------------------------------------------------------------------
    //  Step procedures — CamelCase (primary, idiomatic Delphi style)
    //  Framework splits on case transitions:
    //    AccountIsInCredit  ->  "account is in credit"
    // ------------------------------------------------------------------

  protected
    // Givens
    procedure AccountIsInCredit;
    procedure AccountHasABalanceOf10;

    // Whens
    procedure CustomerRequestsAWithdrawalOf20;

    // Thens
    procedure AccountBalanceShouldBe80;
    procedure WithdrawalShouldBeDeclined;

    // Used to demonstrate halt/skip behaviour
    procedure BalanceShouldBe500;

    // ------------------------------------------------------------------
    //  Step procedure — underscore style (also supported)
    // ------------------------------------------------------------------
    procedure Account_has_been_opened_today;

  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    // ------------------------------------------------------------------
    //  Test methods
    // ------------------------------------------------------------------

    [Test]
    { Classic BDD narrative — InOrderTo / AsA / IWantTo }
    procedure Test_ClassicBDDNarrative;

    [Test]
    { Role/Behaviour/Benefit narrative — AsA / IWant / SoThat }
    procedure Test_RoleBehaviourBenefitNarrative;

    [Test]
    { FDD narrative — Action / Outcome / Entity }
    procedure Test_FDDNarrative;

    [Test]
    { Declarative / mixed narrative }
    procedure Test_DeclarativeMixedNarrative;

    [Test]
    { Plain story string — no narrative clauses }
    procedure Test_PlainStoryString;

    [Test]
    { Insufficient funds path }
    procedure Test_WithdrawalDeclinedWhenInsufficientFunds;

    [Test]
    { Multi-scenario story in a single chain }
    procedure Test_AllWithdrawalScenarios;

    [Test]
    { Pre-built TBDDStep variables — description captured at Step() call }
    procedure Test_UsingPrebuiltStepVariables;

    [Test]
    { Inline anonymous method with explicit label }
    procedure Test_InlineAnonymousMethodWithLabel;

    [Test]
    { Mixed naming conventions in one scenario }
    procedure Test_MixedNamingConventions;

    [Test]
    { Escape hatch: Narrative() for a custom label }
    procedure Test_CustomNarrativeLabel;

    [Test]
    { Demonstrates halt-on-failure — intentionally fails }
    procedure Test_FailingGivenSkipsSubsequentSteps;
  end;

implementation

uses
  System.SysUtils;

// -----------------------------------------------------------------------
//  TBankAccount
// -----------------------------------------------------------------------

procedure TBankAccount.Deposit(AAmount: Integer);
begin
  Inc(FBalance, AAmount);
end;

procedure TBankAccount.Withdraw(AAmount: Integer);
begin
  if AAmount > FBalance then
    FWithdrawalDeclined := True
  else
  begin
    Dec(FBalance, AAmount);
    FWithdrawalDeclined := False;
  end;
end;

// -----------------------------------------------------------------------
//  Setup / TearDown
// -----------------------------------------------------------------------

procedure TBankAccountTests.Setup;
begin
  FAccount := TBankAccount.Create;
end;

procedure TBankAccountTests.TearDown;
begin
  FAccount.Free;
end;

// -----------------------------------------------------------------------
//  Setup / helper steps
// -----------------------------------------------------------------------

procedure TBankAccountTests.ResetAccount;
begin
  FreeAndNil(FAccount);
  FAccount := TBankAccount.Create;
end;

// -----------------------------------------------------------------------
//  Step implementations — CamelCase
// -----------------------------------------------------------------------

procedure TBankAccountTests.AccountIsInCredit;
begin
//  FAccount.Deposit(100);
end;

procedure TBankAccountTests.AccountHasABalanceOf10;
begin
  FAccount.Deposit(10);
end;

procedure TBankAccountTests.CustomerRequestsAWithdrawalOf20;
begin
  FAccount.Withdraw(20);
end;

procedure TBankAccountTests.AccountBalanceShouldBe80;
begin
  Assert.AreEqual(80, FAccount.Balance,
    'Expected balance of 80 after withdrawing 20 from 100');
end;

procedure TBankAccountTests.WithdrawalShouldBeDeclined;
begin
  Assert.IsTrue(FAccount.WithdrawalDeclined,
    'Expected the withdrawal to be declined');
end;

procedure TBankAccountTests.BalanceShouldBe500;
begin
  Assert.AreEqual(500, FAccount.Balance, 'Deliberately wrong assertion');
end;

// -----------------------------------------------------------------------
//  Step implementations — underscore style
// -----------------------------------------------------------------------

procedure TBankAccountTests.Account_has_been_opened_today;
begin
  // Precondition satisfied by Setup — nothing extra needed
end;

// -----------------------------------------------------------------------
//  Test methods
// -----------------------------------------------------------------------

procedure TBankAccountTests.Test_ClassicBDDNarrative;
begin
  Story('Account Holder Withdraws Cash')
    .InOrderTo('have spending money')
    .AsA('account holder')
    .IWantTo('withdraw cash from the ATM')
    .WithScenario('Account in credit, no overdraft limit')
      .Given(AccountIsInCredit)
      .When(CustomerRequestsAWithdrawalOf20)
      .Then_(AccountBalanceShouldBe80)
    .Execute;
end;

procedure TBankAccountTests.Test_RoleBehaviourBenefitNarrative;
begin
  Story('Account Holder Withdraws Cash')
    .AsA('account holder')
    .IWant('to withdraw cash from the ATM')
    .SoThat('I have spending money when I need it')
    .WithScenario('Account in credit, no overdraft limit')
      .Given(AccountIsInCredit)
      .When(CustomerRequestsAWithdrawalOf20)
      .Then_(AccountBalanceShouldBe80)
    .Execute;
end;

procedure TBankAccountTests.Test_FDDNarrative;
begin
  Story('Withdraw Cash From Account')
    .Action('withdraw a sum of money from the ATM')
    .Outcome('the account balance is reduced by the withdrawal amount')
    .Entity('bank account')
    .WithScenario('Account in credit, no overdraft limit')
      .Given(AccountIsInCredit)
      .When(CustomerRequestsAWithdrawalOf20)
      .Then_(AccountBalanceShouldBe80)
    .Execute;
end;

procedure TBankAccountTests.Test_DeclarativeMixedNarrative;
begin
  Story('Account Holder Withdraws Cash')
    .AsA('account holder')
    .Action('withdraw cash from the ATM')
    .Outcome('my account balance is reduced accordingly')
    .WithScenario('Account in credit, no overdraft limit')
      .Given(AccountIsInCredit)
      .When(CustomerRequestsAWithdrawalOf20)
      .Then_(AccountBalanceShouldBe80)
    .Execute;
end;

procedure TBankAccountTests.Test_PlainStoryString;
begin
  Story('As an account holder I want to withdraw cash from the ATM')
    .WithScenario('Account in credit, no overdraft limit')
      .Given(AccountIsInCredit)
      .When(CustomerRequestsAWithdrawalOf20)
      .Then_(AccountBalanceShouldBe80)
    .Execute;
end;

procedure TBankAccountTests.Test_WithdrawalDeclinedWhenInsufficientFunds;
begin
  Story('Account Holder Withdraws Cash')
    .AsA('account holder')
    .IWant('to be protected from overdrawing my account')
    .SoThat('I do not incur unexpected fees')
    .WithScenario('Account has insufficient funds')
      .Given(AccountHasABalanceOf10)
      .When(CustomerRequestsAWithdrawalOf20)
      .Then_(WithdrawalShouldBeDeclined)
    .Execute;
end;

procedure TBankAccountTests.Test_AllWithdrawalScenarios;
{
  Two scenarios share one story and one Execute call.
  ResetAccount is used as the first Given of the second scenario so
  that it starts from a clean state, independent of the first scenario.
}
begin
  Story('Account Holder Withdraws Cash')
    .AsA('account holder')
    .IWant('to withdraw cash from the ATM')
    .SoThat('I have spending money')

    .WithScenario('Account in credit, no overdraft limit')
      .Given(AccountIsInCredit)
      .When(CustomerRequestsAWithdrawalOf20)
      .Then_(AccountBalanceShouldBe80)

    .WithScenario('Account has insufficient funds')
      .Given(ResetAccount)               // isolate from previous scenario
      .AndAlso(AccountHasABalanceOf10)
      .When(CustomerRequestsAWithdrawalOf20)
      .Then_(WithdrawalShouldBeDeclined)

    .Execute;
end;

procedure TBankAccountTests.Test_UsingPrebuiltStepVariables;
{
  TBDDStep variables capture their description at Step() construction.
  The name is correct regardless of how the variable is later used.
  Execute frees all steps — do not Free them manually.
}
var
  GivenInCredit : TBDDStep;
  WhenWithdraw  : TBDDStep;
  ThenBalance80 : TBDDStep;
begin
  GivenInCredit := Step(AccountIsInCredit);
  WhenWithdraw  := Step(CustomerRequestsAWithdrawalOf20);
  ThenBalance80 := Step(AccountBalanceShouldBe80);

  Story('Account Holder Withdraws Cash')
    .AsA('account holder')
    .IWantTo('withdraw cash from the ATM')
    .WithScenario('Using pre-built step variables')
      .Given(GivenInCredit)
      .When(WhenWithdraw)
      .Then_(ThenBalance80)
    .Execute;
end;

procedure TBankAccountTests.Test_InlineAnonymousMethodWithLabel;
{
  Inline anonymous methods have no method name for RTTI to find,
  so an explicit label string is required as the second argument.
}
begin
  Story('Account Holder Withdraws Cash')
    .AsA('account holder')
    .IWantTo('withdraw cash from the ATM')
    .WithScenario('Using inline anonymous methods')

      .Given(procedure begin FAccount.Deposit(100) end,
             'account starts with a balance of 100')

      .When(procedure begin FAccount.Withdraw(20) end,
            'a withdrawal of 20 is requested')

      .Then_(procedure
             begin
               Assert.AreEqual(80, FAccount.Balance, 'Expected balance of 80');
             end,
             'the balance should be 80')

    .Execute;
end;

procedure TBankAccountTests.Test_MixedNamingConventions;
{
  CamelCase and underscore steps can be freely mixed.
  Both resolve to readable narrative text.
}
begin
  Story('Account Holder Withdraws Cash')
    .AsA('account holder')
    .IWantTo('withdraw cash from the ATM')
    .WithScenario('Mixed naming conventions')
      .Given(Account_has_been_opened_today)      // underscore style
      .AndAlso(AccountIsInCredit)                // CamelCase style
      .When(CustomerRequestsAWithdrawalOf20)     // CamelCase style
      .Then_(AccountBalanceShouldBe80)           // CamelCase style
    .Execute;
end;

procedure TBankAccountTests.Test_CustomNarrativeLabel;
{
  Narrative() is an escape hatch for any label not covered by the
  built-in narrative methods.
}
begin
  Story('Account Holder Withdraws Cash')
    .Narrative('Given that', 'I am a registered account holder')
    .Narrative('I expect that', 'my withdrawal request is processed correctly')
    .WithScenario('Custom narrative labels')
      .Given(AccountIsInCredit)
      .When(CustomerRequestsAWithdrawalOf20)
      .Then_(AccountBalanceShouldBe80)
    .Execute;
end;

procedure TBankAccountTests.Test_FailingGivenSkipsSubsequentSteps;
{
  Verifies halt-on-failure behaviour: a failing Given must cause all
  subsequent steps to be marked SKIPPED rather than executed.

  The story is wrapped in Assert.WillRaise so DUnitX records this as
  a passing test — we are asserting that Execute raises ETestFailure,
  which is exactly what a failing Given propagates through Assert.Fail.
}
begin
  Assert.WillRaise(
    procedure
    begin
      Story('Demonstrating halt-on-failure')
        .WithScenario('A failing Given skips all subsequent steps')
          .Given(procedure
                 begin
                   raise Exception.Create('Simulated precondition failure');
                 end,
                 'a precondition that cannot be met')
          .When(CustomerRequestsAWithdrawalOf20)   // must be SKIPPED
          .Then_(AccountBalanceShouldBe80)          // must be SKIPPED
        .Execute;
    end,
    ETestFailure,
    'Execute should have raised ETestFailure due to the failing Given'
  );
end;

initialization
  TDUnitX.RegisterTestFixture(TBankAccountTests);

end.
