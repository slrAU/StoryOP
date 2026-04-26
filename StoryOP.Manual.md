# StoryOP — Story Object Pascal

A StoryQ-inspired BDD wrapper for DUnitX.
Provides a fluent `Story > Scenario > Given / When / Then` DSL with
plain-text narrative reporting, designed to support multiple story
definition styles without enforcing any single development methodology.

---

## Contents

1. [Overview](#overview)
2. [Files](#files)
3. [Getting Started](#getting-started)
4. [RTTI and Method Visibility — Read This First](#rtti-and-method-visibility)
5. [Narrative Patterns](#narrative-patterns)
6. [Step Naming Conventions](#step-naming-conventions)
7. [Step Method Types — TStepMethod Family](#step-method-types)
8. [Fluent API Reference](#fluent-api-reference)
9. [Step Overloads](#step-overloads)
10. [TStepFactory — Pre-built Step Variables](#tstepfactory)
11. [Parameterised Steps — Generics](#parameterised-steps)
12. [Multi-Scenario Stories](#multi-scenario-stories)
13. [State Management Between Scenarios](#state-management-between-scenarios)
14. [Failure Behaviour](#failure-behaviour)
15. [Parameterised Scenarios with TestCase](#parameterised-scenarios-with-testcase)
16. [Narrative Report Output](#narrative-report-output)
17. [TestInsight and DUnitX Runner Integration](#testinsight-and-dunitx-runner-integration)
18. [Memory Management](#memory-management)
19. [Known Limits and Nuances](#known-limits-and-nuances)
20. [Compatibility](#compatibility)

---

## Overview

StoryOP wraps DUnitX with a story-driven DSL inspired by StoryQ. It
is not a replacement for DUnitX — it is a thin layer on top of it.
Your test fixtures are still ordinary `[TestFixture]` classes, your
test methods are still ordinary `[Test]` methods, and all DUnitX
tooling (TestInsight, console runner, XML logger) works without
modification.

The DSL adds:

- A fluent story/scenario/step chain producing a readable plain-text
  narrative report alongside normal DUnitX output
- Automatic step description derivation from method names via RTTI,
  supporting CamelCase, underscore, and mixed naming conventions
- Generic step method types supporting zero to four typed parameters,
  with parameter values automatically appended to the narrative
- Multiple narrative header styles (BDD, FDD, declarative, plain
  string) that can be freely mixed in any order
- Halt-on-failure behaviour that marks subsequent steps SKIPPED when
  a Given or When step fails

---

## Files

| File                            | Purpose                                                     |
| ------------------------------- | ----------------------------------------------------------- |
| `StoryOP.pas`                   | The entire framework — one unit                             |
| `StoryOP.Tests.pas`             | Comprehensive self-test suite (tests StoryOP using StoryOP) |
| `StoryOP.BankAccount.Tests.pas` | Domain example covering all DSL features                    |
| `StoryOP.Tests.dpr`             | Console test runner program                                 |
| `StoryOP.Tests.dproj`           | Delphi 12 Athens project file                               |
| `StoryOP.groupproj`             | Project group — open this in the IDE                        |

---

## Getting Started

1. Open `StoryOP.groupproj` in Delphi 12 Athens.
2. Ensure DUnitX is on your library path
   (`$(BDS)\source\DUnitX` — already in the `.dproj` search path).
3. Build and run — the console shows the BDD narrative report
   followed by the standard DUnitX pass/fail summary.

To use StoryOP in your own project:

1. Add `StoryOP.pas` to your project.
2. Add `StoryOP` to the `uses` clause of your test unit.
3. Declare step procedures as `public` methods of your fixture class.
4. Compose stories inside ordinary `[Test]` methods using the
   fluent chain, ending every chain with `.Execute`.

---

## RTTI and Method Visibility

StoryOP derives step descriptions from your procedure names at
runtime using RTTI. It obtains a `TMethod` record from the step
procedure reference, then walks the RTTI method table of your fixture
class to find the method whose `CodeAddress` matches `TMethod.Code`.

This works correctly and reliably, but with one critical constraint:
**Delphi only generates RTTI metadata for methods that are `public`
or `published` by default.**

### What this means in practice

Step procedures declared as `private` or `protected` will not appear
in the RTTI method table. StoryOP falls back to `(unnamed step)` in
the narrative report. The test still runs correctly — only the
narrative text is affected.

### The recommended solution

Declare all step procedures as `public`. Test fixture classes do not
have the same encapsulation concerns as production domain objects,
and no production system will accidentally depend on a step procedure.

```pascal
[TestFixture]
TMyTests = class
public
  procedure AccountIsInCredit;
  procedure CustomerRequestsAWithdrawalOf20;
  procedure AccountBalanceShouldBe80;

  [Setup]    procedure Setup;
  [TearDown] procedure TearDown;
  [Test]     procedure Test_Withdrawal;
end;
```

### If you prefer private or protected steps

Add the following directive to the top of your test unit:

```pascal
{$RTTI EXPLICIT METHODS([vcPrivate, vcProtected, vcPublic, vcPublished])}
```

This instructs the compiler to generate full RTTI metadata for all
method visibilities in that unit only.

### Summary

| Visibility  | Works without directive | Works with directive |
| ----------- | ----------------------- | -------------------- |
| `private`   | No — `(unnamed step)`   | Yes                  |
| `protected` | No — `(unnamed step)`   | Yes                  |
| `public`    | **Yes**                 | Yes                  |
| `published` | **Yes**                 | Yes                  |

---

## Narrative Patterns

All narrative methods append an ordered `(label, text)` pair to the
story header. They may be called in any order, any number of times,
and freely mixed. The report prints them exactly as supplied.

### BDD canonical — Role / Behaviour / Benefit

```pascal
Story('Account Holder Withdraws Cash')
  .AsA('account holder')
  .IWant('to withdraw cash from the ATM')
  .SoThat('I have spending money when I need it')
```

### Classic BDD — In Order To / As A / I Want To

```pascal
Story('Account Holder Withdraws Cash')
  .InOrderTo('have spending money')
  .AsA('account holder')
  .IWantTo('withdraw cash from the ATM')
```

### FDD — Action / Outcome / Entity

```pascal
Story('Withdraw Cash From Account')
  .Action('withdraw a sum of money from the ATM')
  .Outcome('the account balance is reduced by the withdrawal amount')
  .Entity('bank account')
```

### Declarative / mixed

```pascal
Story('Account Holder Withdraws Cash')
  .AsA('account holder')
  .Action('withdraw cash from the ATM')
  .Outcome('my account balance is reduced accordingly')
```

### Plain string only

```pascal
Story('As an account holder I want to withdraw cash from the ATM')
```

### Custom labels — escape hatch

```pascal
Story('Account Holder Withdraws Cash')
  .Narrative('Given that', 'I am a registered account holder')
  .Narrative('I expect that', 'my withdrawal is processed correctly')
```

---

## Step Naming Conventions

Step procedures may use CamelCase, underscores, or a mixture.
All are converted to lowercase space-separated narrative text.
All-uppercase tokens are treated as acronyms and preserved.

| Procedure name             | Narrative text                |
| -------------------------- | ----------------------------- |
| `AccountIsInCredit`        | `account is in credit`        |
| `Account_is_in_credit`     | `account is in credit`        |
| `CustomerWithdrawsFromATM` | `customer withdraws from ATM` |
| `RequestWithdrawalOf20`    | `request withdrawal of 20`    |
| `ATMWithdrawal`            | `ATM withdrawal`              |
| `Account_IsInCredit`       | `account is in credit`        |

Both conventions can be freely mixed within the same scenario.

---

## Step Method Types

StoryOP defines a family of `TStepMethod` types using generic
specialisation. Different type-parameter counts produce distinct
types, just as method overloads are distinct — no numeric suffixes
are needed.

```pascal
TStepMethod                          // procedure of object — no parameters
TStepMethod<T>                       // one typed parameter
TStepMethod<T1, T2>                  // two typed parameters
TStepMethod<T1, T2, T3>              // three typed parameters
TStepMethod<T1, T2, T3, T4>         // four typed parameters
```

Step procedures must match one of these signatures:

```pascal
// Zero parameters
procedure AccountIsInCredit;

// One parameter
procedure CustomerWithdraws(const AAmount: Integer);

// Two parameters
procedure AccountStartsWithBalanceAndLimit(const ABalance: Integer;
                                           const ALimit: Integer);

// Three parameters
procedure SetNameAgeScore(const AName: string;
                          const AAge: Integer;
                          const AScore: Double);

// Four parameters
procedure TransferAndVerify(const AFrom: Integer; const ATo: Integer;
                            const AAmount: Integer; const AExpected: Integer);
```

---

## Fluent API Reference

### Story factory

```pascal
function Story(const ATitle: string): TBDDStory;
```

### TBDDStory narrative methods

All return `TBDDStory` for chaining.

| Method                    | Label in report | Pattern |
| ------------------------- | --------------- | ------- |
| `.AsA(text)`              | `As a`          | BDD     |
| `.IWant(text)`            | `I want`        | BDD     |
| `.IWantTo(text)`          | `I want to`     | BDD     |
| `.InOrderTo(text)`        | `In order to`   | BDD     |
| `.SoThat(text)`           | `So that`       | BDD     |
| `.Action(text)`           | `Action`        | FDD     |
| `.Outcome(text)`          | `Outcome`       | FDD     |
| `.Entity(text)`           | `Entity`        | FDD     |
| `.Narrative(label, text)` | *(your label)*  | Any     |

### TBDDStory scenario method

```pascal
function WithScenario(const ATitle: string): TBDDScenario;
```

### TBDDScenario step methods

Each has multiple overloads — see [Step Overloads](#step-overloads).

| Method                 | Notes                                               |
| ---------------------- | --------------------------------------------------- |
| `.Given(...)`          | Precondition                                        |
| `.When(...)`           | Action                                              |
| `.Then_(...)`          | Outcome (`Then` is a Delphi reserved word)          |
| `.AndAlso(...)`        | Continuation; inherits G/W/T context for halt logic |
| `.WithScenario(title)` | Adds a sibling scenario to the same story           |
| `.Execute`             | Runs steps, writes report, frees story              |

**Always end every chain with `.Execute`.**

---

## Step Overloads

Every step method accepts one of four forms.

### 1. Zero-parameter TStepMethod (primary path)

```pascal
.Given(AccountIsInCredit)
.When(CustomerRequestsAWithdrawalOf20)
.Then_(AccountBalanceShouldBe80)
```

### 2. Parameterised TStepMethod (generic path)

Specify the type parameters explicitly in angle brackets:

```pascal
.Given<Integer>(AccountIsOpenedWithBalance, 100)
.When<Integer>(CustomerWithdraws, 20)
.Then_<Integer>(BalanceShouldBe, 80)

.Given<Integer,Integer>(AccountStartsWithBalanceAndLimit, 500, 1000)

.Given<string,Integer,Double>(SetNameAgeScore, 'Alice', 25, 90.0)

.Given<Integer,Integer,Integer,Integer>(TransferAndVerify, 200, 50, 75, 125)
```

Parameter values are appended to the step description automatically:

```
Given account is opened with balance [100]
When  customer withdraws [20]
Then  balance should be [80]
```

### 3. Anonymous method (TProc) — label required

Use for inline anonymous methods. The label is mandatory since there
is no method name for RTTI to find.

```pascal
.Given(procedure begin FAccount.Deposit(100) end,
       'account starts with a balance of 100')

.Then_(procedure
       begin
         Assert.AreEqual(80, FAccount.Balance, 'Expected 80');
       end,
       'the balance should be 80')
```

### 4. Pre-built TBDDStep

See [TStepFactory](#tstepfactory).

```pascal
var S: TBDDStep;
S := TStepFactory.Create<Integer>(BalanceShouldBe, 80);
...
.Then_(S)
```

---

## TStepFactory

`TStepFactory` is a static class that builds self-describing
`TBDDStep` instances. The description is captured once at
construction via RTTI and stored permanently on the step object,
making it safe to assign to a variable and use later.

### Why TStepFactory instead of a free function?

Delphi does not permit type parameters on global (free) functions.
Generic factory methods must be on a class. `TStepFactory` provides
this as static class methods. Zero-parameter and anonymous-method
steps are also available as the free functions `Step()` for
convenience.

### TStepFactory.Create overloads

```pascal
// Zero-parameter — also available as Step(AMethod)
S := TStepFactory.Create(AccountIsInCredit);

// One-parameter
S := TStepFactory.Create<Integer>(BalanceShouldBe, 80);
S := TStepFactory.Create<string>(AccountHolderIsNamed, 'Alice');

// Two-parameter
S := TStepFactory.Create<Integer,Integer>(AccountStartsWithBalanceAndLimit, 500, 1000);

// Three-parameter
S := TStepFactory.Create<string,Integer,Double>(SetNameAgeScore, 'Alice', 25, 90.0);

// Four-parameter
S := TStepFactory.Create<Integer,Integer,Integer,Integer>(TransferAndVerify, 200, 50, 75, 125);

// Anonymous method — also available as Step(AProc, ALabel)
S := TStepFactory.Create(procedure begin ... end, 'my description');
```

### Usage pattern for pre-built steps

```pascal
var
  GivenStep : TBDDStep;
  WhenStep  : TBDDStep;
  ThenStep  : TBDDStep;
begin
  GivenStep := TStepFactory.Create<Integer>(AccountIsOpenedWithBalance, 100);
  WhenStep  := TStepFactory.Create<Integer>(CustomerWithdraws, 20);
  ThenStep  := TStepFactory.Create<Integer>(BalanceShouldBe, 80);

  Story('Account Holder Withdraws Cash')
    .WithScenario('Using pre-built step variables')
      .Given(GivenStep)
      .When(WhenStep)
      .Then_(ThenStep)
    .Execute;
  // Do NOT free GivenStep, WhenStep, or ThenStep —
  // Execute frees all steps as part of freeing the story.
end;
```

### Module-level Step() convenience functions

Two zero-type-parameter overloads are available as free functions:

```pascal
// Zero-parameter method reference
S := Step(AccountIsInCredit);

// Anonymous method with label
S := Step(procedure begin ... end, 'my description');
```

---

## Parameterised Steps — Generics

### Declaring parameterised step procedures

```pascal
[TestFixture]
TMyTests = class
public
  // One parameter
  procedure AccountIsOpenedWithBalance(const ABalance: Integer);

  // Two parameters
  procedure TransferAmount(const AFrom: Integer; const ATo: Integer);

  // Three parameters
  procedure SetCredentials(const AUser: string;
                           const APin: Integer;
                           const AExpiry: string);

  // Four parameters
  procedure ConfigureAccount(const AName: string;
                             const ABalance: Integer;
                             const ALimit: Integer;
                             const AActive: Boolean);
end;
```

### Calling parameterised steps in a chain

```pascal
Story('Account Holder Withdraws Cash')
  .WithScenario('Parameterised withdrawal')
    .Given<Integer>(AccountIsOpenedWithBalance, 100)
    .When<Integer>(CustomerWithdraws, 20)
    .Then_<Integer>(BalanceShouldBe, 80)
  .Execute;
```

### Parameter representation in narrative

Parameter values are appended to the method name in square brackets,
using `TValue.ToString` for rendering:

| Type     | Value         | Rendered as                 |
| -------- | ------------- | --------------------------- |
| Integer  | `42`          | `[42]`                      |
| string   | `'Alice'`     | `[Alice]`                   |
| Boolean  | `True`        | `[True]`                    |
| Double   | `3.14`        | `[3.14]` (platform default) |
| Multiple | `20, 'Alice'` | `[20, Alice]`               |

### Type support

Any type that `TValue` can represent is supported as a step parameter,
including integers, strings, booleans, floating-point types,
enumerations, and records. Objects can be passed but render as the
class name in the narrative.

---

## Multi-Scenario Stories

Multiple scenarios can be composed in a single fluent chain. Call
`.Execute` once on the last scenario.

```pascal
Story('Account Holder Withdraws Cash')
  .AsA('account holder')
  .IWant('to withdraw cash from the ATM')
  .SoThat('I have spending money')

  .WithScenario('Account in credit, no overdraft limit')
    .Given<Integer>(AccountIsOpenedWithBalance, 100)
    .When<Integer>(CustomerWithdraws, 20)
    .Then_<Integer>(BalanceShouldBe, 80)

  .WithScenario('Account has insufficient funds')
    .Given(ResetAccount)
    .AndAlso<Integer>(AccountIsOpenedWithBalance, 10)
    .When<Integer>(CustomerWithdraws, 20)
    .Then_(WithdrawalShouldBeDeclined)

  .Execute;
```

The narrative report includes all scenarios under the single story
header. DUnitX records the enclosing `[Test]` method as one test.

---

## State Management Between Scenarios

**Important for multi-scenario stories.**

DUnitX calls `[Setup]` and `[TearDown]` around each `[Test]` method,
but within a single `Execute` call all scenarios share the same
fixture instance. State from the first scenario carries into the
second unless explicitly reset.

The recommended pattern is a reset step as the first `Given` of any
scenario that requires clean state:

```pascal
procedure TMyTests.ResetAccount;
begin
  FreeAndNil(FAccount);
  FAccount := TBankAccount.Create;
end;

// In the chain:
.WithScenario('Second scenario')
  .Given(ResetAccount)
  .AndAlso<Integer>(AccountIsOpenedWithBalance, 10)
  ...
```

Alternatively, split scenarios requiring independent state into
separate `[Test]` methods, each getting its own `[Setup]` call.

---

## Failure Behaviour

### Given and When failures — halt and skip

If a `Given` or `When` step (including `AndAlso` continuations of
either) raises an exception, the scenario halts immediately. All
remaining steps in that scenario are marked `[SKIPPED]`.

### Then failures — record and continue

If a `Then` step raises an exception, the failure is recorded but
the scenario continues. All subsequent `Then` steps still run.
This includes `AndAlso` continuations of `Then`.

### Halt behaviour summary

| Failing step kind | Effect on remaining steps                   |
| ----------------- | ------------------------------------------- |
| `Given`           | All subsequent → **SKIPPED**                |
| `When`            | All subsequent → **SKIPPED**                |
| `And (Given)`     | All subsequent → **SKIPPED**                |
| `And (When)`      | All subsequent → **SKIPPED**                |
| `Then`            | Failure recorded; remaining steps still run |
| `And (Then)`      | Failure recorded; remaining steps still run |

### End-of-Execute failure aggregation

After all scenarios complete, if any steps failed, `Execute` calls
`Assert.Fail` with a combined message. DUnitX records the enclosing
`[Test]` as failed.

### Verifying failure behaviour in tests

```pascal
Assert.WillRaise(
  procedure
  begin
    Story('...')
      .WithScenario('...')
        .Given(AStepThatWillFail)
        .Then_(AStepThatShouldBeSkipped)
      .Execute;
  end,
  ETestFailure,
  'Expected Execute to raise ETestFailure'
);
```

---

## Parameterised Scenarios with TestCase

StoryOP is compatible with DUnitX `[TestCase]` attributes. Because
`[TestCase]` parameters arrive as method arguments, use the anonymous
method (`TProc`) overload with explicit labels:

```pascal
[Test]
[TestCase('Withdraw 20 from 100, expect 80', '100,20,80')]
[TestCase('Withdraw 10 from 50, expect 40',  '50,10,40')]
procedure Test_Withdrawal(AStart, AAmount, AExpected: Integer);
begin
  Story('Account Holder Withdraws Cash')
    .WithScenario(Format('Withdraw %d from %d, expect %d',
                         [AAmount, AStart, AExpected]))

      .Given(procedure begin FAccount.Deposit(AStart) end,
             Format('account balance is %d', [AStart]))

      .When(procedure begin FAccount.Withdraw(AAmount) end,
            Format('customer withdraws %d', [AAmount]))

      .Then_(procedure
             begin
               Assert.AreEqual(AExpected, FAccount.Balance);
             end,
             Format('balance should be %d', [AExpected]))

    .Execute;
end;
```

Always derive the scenario title from the parameters so the narrative
is meaningful for each invocation. TestInsight displays parameterised
cases as separate rows using the `[TestCase]` string.

---

## Narrative Report Output

Emitted via `TDUnitX.CurrentRunner.Log` at `TLogLevel.Information`,
appearing in all registered DUnitX loggers.

```
Story: Account Holder Withdraws Cash
  As a account holder
  I want to withdraw cash from the ATM
  So that I have spending money

  Scenario: Parameterised withdrawal
    Given account is opened with balance [100]      [PASSED]
    When  customer withdraws [20]                   [PASSED]
    Then  balance should be [80]                    [PASSED]

  Scenario: Account has insufficient funds
    Given reset account                             [PASSED]
    And (Given) account is opened with balance [10] [PASSED]
    When  customer withdraws [20]                   [PASSED]
    Then  withdrawal should be declined             [PASSED]
```

Step outcome markers:

| Marker      | Meaning                                                  |
| ----------- | -------------------------------------------------------- |
| `[PASSED]`  | Step executed without raising an exception               |
| `[FAILED]`  | Step raised an exception; error shown on next line       |
| `[SKIPPED]` | Step not executed due to a prior Given/When failure      |
| `[NOT RUN]` | Step was never attempted (should not appear in practice) |

---

## TestInsight and DUnitX Runner Integration

StoryOP integrates transparently with all DUnitX tooling because
your test methods are still ordinary `[Test]` methods on
`[TestFixture]` classes.

**TestInsight** discovers and runs StoryOP tests without configuration.
Narrative output appears in the TestInsight log. Because TestInsight
truncates long log output in tooltips, view the narrative in the full
log panel rather than the inline tooltip.

**Console runner** — narrative output appears interleaved with DUnitX
pass/fail output. Pass `True` to `TDUnitXConsoleLogger.Create` to
enable detailed logging.

**NUnit XML** — narrative lines appear as information log entries in
the XML file, visible in CI pipeline log viewers.

**Failure reporting** — StoryOP aggregates all step failures into a
single `Assert.Fail` call at the end of `Execute`. DUnitX and
TestInsight record the BDD test method as one test with one combined
failure message.

---

## Memory Management

StoryOP manages all of its own objects. Do not free any StoryOP
objects manually.

- `Story()` creates a `TBDDStory` which owns all `TBDDScenario` objects
- Each `TBDDScenario` owns the `TBDDStep` objects added to it
- `Execute` frees the entire graph via `FStory.Free`
- Pre-built `TBDDStep` variables created via `TStepFactory.Create`
  are also freed by `Execute` once passed to a scenario — do not
  free them manually after passing them to a step method
- If `Execute` is never called, the story object will leak

---

## Known Limits and Nuances

### `Then_` naming

The outcome step method is named `Then_` because `Then` is a reserved
word in Delphi. This is the one unavoidable departure from pure
StoryQ-style naming.

### Generic free functions not supported by Delphi

Delphi does not permit type parameters on global (free) functions.
The parameterised `Step<T>()` factory is therefore provided as
`TStepFactory.Create<T>()`. The zero-parameter `Step()` free function
remains available as a convenience alias.

### Step procedures must be `procedure of object`

Steps must be instance methods of a class. Plain procedures and
class (static) methods do not produce a valid `TMethod` record and
cannot be used with the `TStepMethod` overloads. Use the `TProc`
overload with an explicit label for these cases.

### Method visibility and RTTI

Step procedures must be `public` or `published` for automatic name
derivation. Methods invisible to RTTI produce `(unnamed step)` in
the narrative but still execute correctly. See
[RTTI and Method Visibility](#rtti-and-method-visibility).

### Inherited step procedures

`GetDeclaredMethods` is called on each type in the inheritance chain,
so step procedures on a base fixture class are found correctly,
provided they meet the visibility requirement.

### Overloaded step procedures

If two methods share the same name but differ in signature, code-
address matching identifies the correct overload. However, both will
produce identical narrative text. Prefer distinct names.

### Inlined methods

The compiler may inline very small methods when optimisation is
enabled. An inlined method may not have a stable `CodeAddress` and
will produce `(unnamed step)`. Add `[NoInline]` to affected step
procedures, or disable inlining for the test project.

### Multi-scenario state leakage

DUnitX only calls `[Setup]` and `[TearDown]` between `[Test]`
methods, not between scenarios within a single `Execute` call.
See [State Management Between Scenarios](#state-management-between-scenarios).

### `[TestCase]` and parameterised steps

`[TestCase]` parameters must use the anonymous `TProc` overload since
`TStepMethod` procedures cannot accept parameters. Explicit labels
are required for those steps. See
[Parameterised Scenarios with TestCase](#parameterised-scenarios-with-testcase).

### `TValue.ToString` rendering

Parameter values in the narrative are rendered using `TValue.ToString`.
For primitive types (Integer, string, Boolean, Double, enumeration)
this produces clean readable output. For records and objects it
produces the type name. Custom rendering is not currently supported.

### Execute must always be the last call

`Execute` writes the report, raises failures, and frees the object
graph. Forgetting `.Execute` means no report is written, no failures
are raised, the test passes silently, and the story leaks. Always
end every fluent chain with `.Execute`.

---

## Compatibility

| Requirement    | Detail                                                                           |
| -------------- | -------------------------------------------------------------------------------- |
| Delphi version | 2009+ (`Rtti` unit, generics, anonymous methods required)                        |
| DUnitX version | Any (uses only `Assert`, `TDUnitX.CurrentRunner.Log`, `ETestFailure`)            |
| Platforms      | Any platform supported by DUnitX (Win32, Win64, etc.)                            |
| FPC / Lazarus  | `{$MODE DELPHI}` guard included; RTTI behaviour under FPC may require adjustment |

---

## Licence

MIT — use freely in commercial and open-source projects.
