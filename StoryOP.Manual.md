# StoryOP — Story for Object Pascal

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
7. [Fluent API Reference](#fluent-api-reference)
8. [Step Overloads](#step-overloads)
9. [Pre-built Step Variables](#pre-built-step-variables)
10. [Multi-Scenario Stories](#multi-scenario-stories)
11. [State Management Between Scenarios](#state-management-between-scenarios)
12. [Failure Behaviour](#failure-behaviour)
13. [Parameterised Scenarios with TestCase](#parameterised-scenarios-with-testcase)
14. [Narrative Report Output](#narrative-report-output)
15. [TestInsight and DUnitX Runner Integration](#testinsight-and-dunitx-runner-integration)
16. [Memory Management](#memory-management)
17. [Known Limits and Nuances](#known-limits-and-nuances)
18. [Compatibility](#compatibility)

---

## Overview

StoryOP wraps DUnitX with a story-driven DSL inspired by StoryQ. It
is not a replacement for DUnitX — it is a thin layer on top of it.
Your test fixtures are still ordinary `[TestFixture]` classes, your
test methods are still ordinary `[Test]` methods, and all DUnitX
tooling (TestInsight, console and GUI runners, etc.) works without
modification.

The DSL adds:

- A fluent story/scenario/step chain that produces a readable
  plain-text narrative report alongside the normal DUnitX output
- Automatic step description derivation from method names via RTTI,
  supporting both CamelCase and underscore naming conventions
- Multiple narrative header styles that can be freely mixed, or bypassed using a simple string
- Halt-on-failure behaviour that marks subsequent steps as SKIPPED
  when a test step fails

---

## Files

| File                            | Purpose                                   |
| ------------------------------- | ----------------------------------------- |
| `StoryOP.pas`                   | The entire framework — one unit           |
| `StoryOP.BankAccount.Tests.pas` | Working example covering all DSL features |
| `StoryOP.Tests.dpr`             | Test runner program                       |
| `StoryOP.Tests.dproj`           | Delphi 12 Athens project file             |

---

## Getting Started

1. Open the StoryOP project in the Delphi IDE.
2. Ensure DUnitX is on your library path
   (typically `$(BDS)\source\DUnitX` — already in the `.dproj`
   search path).
3. Build and run.

To use StoryOP in your own project:

1. Add `StoryOP.pas` to your test project, or add it's location to the search path.
2. Add `StoryOP` to the `uses` clause of your test unit.
3. Declare step procedures on your fixture class (see
   [RTTI and Method Visibility](#rtti-and-method-visibility) below).
4. Compose stories inside ordinary `[Test]` methods using the
   fluent chain, ending every chain with `.Execute`.

---

## RTTI and Method Visibility

StoryOP derives step descriptions from your procedure names at
runtime using Delphi's RTTI system. 

This mechanism works correctly and reliably, but it has one
critical constraint: **Delphi only generates RTTI metadata for
methods that are `public` or `published` by default.**

### What this means in practice

Step procedures declared as `private` or `protected` will not
appear in the RTTI method table. When StoryOP cannot find a
matching method, it falls back to the description `(unnamed step)`
in the narrative report. The test will still run correctly —
only the narrative text is affected.

### The recommended solution

Declare all step procedures as `public`. For test fixture classes
this carries no practical risk — test code does not have the same
encapsulation concerns as production domain objects, and no
production system will accidentally depend on a test step procedure.

```pascal
[TestFixture]
TMyTests = class
public                          // <-- step procedures here
  procedure AccountIsInCredit;
  procedure CustomerRequestsAWithdrawalOf20;
  procedure AccountBalanceShouldBe80;

  [Setup]    procedure Setup;
  [TearDown] procedure TearDown;

  [Test]     procedure Test_WithdrawalFromAccountInCredit;
end;
```

### If you prefer private or protected steps

Add the following compiler directive to the top of your test unit,
immediately after the `interface` keyword or before the type
declaration:

```pascal
{$RTTI EXPLICIT METHODS([vcPrivate, vcProtected, vcPublic, vcPublished])}
```

This instructs the compiler to generate full RTTI metadata for all
method visibilities in that unit. It has no effect on other units
and no runtime cost beyond the additional metadata.

The example test unit `StoryOP.BankAccount.Tests.pas` includes this
directive so you can see where to place it.

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
| `Account_IsInCredit`       | `account is in credit`        |

Both conventions can be freely mixed within the same scenario.

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

Each has three overloads — see [Step Overloads](#step-overloads).

| Method                 | Notes                                               |
| ---------------------- | --------------------------------------------------- |
| `.Given(step)`         | Precondition                                        |
| `.When(step)`          | Action                                              |
| `.Then_(step)`         | Outcome (`Then` is a Delphi reserved word)          |
| `.AndAlso(step)`       | Continuation; inherits G/W/T context for halt logic |
| `.WithScenario(title)` | Adds a sibling scenario to the same story           |
| `.Execute`             | Runs steps, writes report, frees story              |

**Always end every chain with `.Execute`.**

---

## Step Overloads

Every step method (`Given`, `When`, `Then_`, `AndAlso`) accepts
one of three forms.

### 1. TStepMethod — primary path (recommended)

Pass a method reference directly by name. The description is
derived automatically from the method name via RTTI.

```pascal
.Given(AccountIsInCredit)
.When(CustomerRequestsAWithdrawalOf20)
.Then_(AccountBalanceShouldBe80)
```

Requirements:

- The procedure must be a method of the fixture class
  (`procedure of object`)
- The method must be `public` or `published`, or the
  `{$RTTI EXPLICIT METHODS(...)}` directive must be present
  (see [RTTI and Method Visibility](#rtti-and-method-visibility))

### 2. TProc — anonymous method path

Pass an inline anonymous method with a mandatory label string.
RTTI is bypassed; the label is used directly as the description.

```pascal
.Given(procedure begin FAccount.Deposit(100) end,
       'account starts with a balance of 100')

.When(procedure begin FAccount.Withdraw(20) end,
      'a withdrawal of 20 is requested')

.Then_(procedure
       begin
         Assert.AreEqual(80, FAccount.Balance, 'Expected 80');
       end,
       'the balance should be 80')
```

The label parameter is **not optional** for anonymous methods, as there is no method name for RTTI to find.

Anonymous methods capture variables from their enclosing scope,
making them useful for parameterised scenarios (see
[Parameterised Scenarios](#parameterised-scenarios-with-testcase)).

### 3. TBDDStep — pre-built step

Build a step explicitly using the `Step()` factory. The description
is captured once at construction and stored permanently, making it
safe to assign to a variable and reuse.

```pascal
// TStepMethod factory — RTTI runs here, name stored permanently
var S: TBDDStep;
S := Step(AccountIsInCredit);

// TProc factory — label required
var S: TBDDStep;
S := Step(procedure begin ... end, 'my description');

// Use in chain — description already stored, no RTTI needed here
.Given(S)
```

See [Pre-built Step Variables](#pre-built-step-variables).

---

## Pre-built Step Variables

The `Step()` factory captures the description at the point of
construction. This is the correct pattern when you want to assign
a step to a variable before using it — passing a method reference
directly to a variable without using `Step()` would lose the name.

```pascal
var
  GivenInCredit : TBDDStep;
  WhenWithdraw  : TBDDStep;
  ThenBalance80 : TBDDStep;
begin
  GivenInCredit := Step(AccountIsInCredit);           // name captured here
  WhenWithdraw  := Step(CustomerRequestsAWithdrawalOf20);
  ThenBalance80 := Step(AccountBalanceShouldBe80);

  Story('Account Holder Withdraws Cash')
    .WithScenario('Using pre-built step variables')
      .Given(GivenInCredit)                           // description already stored
      .When(WhenWithdraw)
      .Then_(ThenBalance80)
    .Execute;
  // Do NOT free GivenInCredit, WhenWithdraw, or ThenBalance80 —
  // Execute frees all steps as part of freeing the story.
end;
```

---

## Multi-Scenario Stories

Multiple scenarios can be composed in a single fluent chain.
Call `.Execute` once on the last scenario in the chain.

```pascal
Story('Account Holder Withdraws Cash')
  .AsA('account holder')
  .IWant('to withdraw cash from the ATM')
  .SoThat('I have spending money')

  .WithScenario('Account in credit, no overdraft limit')
    .Given(AccountIsInCredit)
    .When(CustomerRequestsAWithdrawalOf20)
    .Then_(AccountBalanceShouldBe80)

  .WithScenario('Account has insufficient funds')
    .Given(ResetAccount)               // see State Management below
    .AndAlso(AccountHasABalanceOf10)
    .When(CustomerRequestsAWithdrawalOf20)
    .Then_(WithdrawalShouldBeDeclined)

  .Execute;
```

The narrative report will include all scenarios under the single
story header. DUnitX records the enclosing `[Test]` method as one
test — pass or fail.

---

## State Management Between Scenarios

DUnitX calls `[Setup]` and `[TearDown]` around each `[Test]`
method, but within a single `Execute` call all scenarios share the
same fixture instance. If the first scenario modifies state (e.g.
deposits money into an account), that state carries over into the
second scenario unless you explicitly reset it.

The recommended pattern is to include a reset step as the first
`Given` of any scenario that requires a clean state:

```pascal
procedure TMyTests.ResetAccount;
begin
  FreeAndNil(FAccount);
  FAccount := TBankAccount.Create;
end;

// In the scenario chain:
.WithScenario('Account has insufficient funds')
  .Given(ResetAccount)             // clean slate
  .AndAlso(AccountHasABalanceOf10)
  ...
```

Alternatively, split scenarios that require independent state into
separate `[Test]` methods, each of which gets its own `[Setup]`
call automatically.

---

## Failure Behaviour

### Given and When failures — halt and skip

If a `Given` or `When` step (including `AndAlso` continuations of
either) raises an exception, the scenario is halted immediately.
All remaining steps in that scenario are marked `[SKIPPED]` in the
report and are not executed.

### Then failures — record and continue

If a `Then` step raises an exception, the failure is recorded but
the scenario continues. All subsequent `Then` steps still run.

### End-of-Execute failure aggregation

After all scenarios have run, if any steps failed, `Execute` calls
`Assert.Fail` with a summary of all failures. DUnitX records the
enclosing `[Test]` method as failed with the combined message.

### Verifying failure behaviour in tests

To write a test that asserts a scenario correctly fails, wrap the
`Execute` call in `Assert.WillRaise`:

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

StoryOP is compatible with DUnitX `[TestCase]` attributes.
DUnitX calls the test method once per `[TestCase]`, each time
passing different parameters. Each invocation builds and executes
its own independent story object graph.

Because `[TestCase]` parameters arrive as method arguments, they
cannot be passed to `TStepMethod` procedures (which take no
parameters). Use anonymous method captures instead, and supply
explicit label strings derived from the parameter values:

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

Always derive the scenario title dynamically from the parameters
so that the narrative report is meaningful for each invocation.

TestInsight displays parameterised cases as separate rows using
the string supplied in the `[TestCase]` attribute.

---

## Narrative Report Output

The report is emitted via `TDUnitX.CurrentRunner.Log` at
`TLogLevel.Information`, which means it appears in all registered
DUnitX loggers — console, NUnit XML, and TestInsight.

Example output:

```
Story: Account Holder Withdraws Cash
  As a account holder
  I want to withdraw cash from the ATM
  So that I have spending money

  Scenario: Account in credit, no overdraft limit
    Given account is in credit                           [PASSED]
    When  customer requests a withdrawal of 20           [PASSED]
    Then  account balance should be 80                   [PASSED]

  Scenario: Account has insufficient funds
    Given reset account                                  [PASSED]
    And (Given) account has a balance of 10              [PASSED]
    When  customer requests a withdrawal of 20           [PASSED]
    Then  withdrawal should be declined                  [PASSED]
```

Step outcome markers:

| Marker      | Meaning                                                  |
| ----------- | -------------------------------------------------------- |
| `[PASSED]`  | Step executed without raising an exception               |
| `[FAILED]`  | Step raised an exception; message shown on next line     |
| `[SKIPPED]` | Step not executed due to a prior Given/When failure      |
| `[NOT RUN]` | Step was never attempted (should not appear in practice) |

---

## TestInsight and DUnitX Runner Integration

StoryOP integrates transparently with all DUnitX tooling because
it is a pure wrapper — your test methods are still ordinary
`[Test]` methods on `[TestFixture]` classes.

**TestInsight** discovers and runs StoryOP tests without any
configuration. The narrative report is emitted to the TestInsight
log output. Because TestInsight truncates long log output in its
tooltip display, the narrative is best viewed in the full log panel
rather than the inline tooltip.

**Console runner** — narrative output appears interleaved with the
standard DUnitX pass/fail output. If verbose output is not
appearing, ensure your DPR passes `True` to
`TDUnitXConsoleLogger.Create` to enable detailed logging.

**NUnit XML output** — narrative lines are included as information
log entries in the XML file, visible in CI pipeline log viewers.

**Failure reporting** — because StoryOP aggregates all step
failures into a single `Assert.Fail` call at the end of `Execute`,
DUnitX and TestInsight record each BDD test method as one test
with one combined failure message, rather than individual failures
per step. This is intentional — a scenario is one logical test.

---

## Memory Management

StoryOP manages all of its own objects. You must not free any
StoryOP objects manually.

- `Story()` creates a `TBDDStory` which owns all `TBDDScenario`
  objects added via `.WithScenario()`
- Each `TBDDScenario` owns the `TBDDStep` objects added to it
- `Execute` frees the entire object graph by calling `FStory.Free`
  after the report is written and any failure is raised

This means:

- Do not call `Free` on any `TBDDStory`, `TBDDScenario`, or
  `TBDDStep` object
- Pre-built `TBDDStep` variables created via `Step()` are also
  freed by `Execute` once they have been added to a scenario —
  do not free them manually after passing them to a step method
- If `Execute` is never called (e.g. due to an exception during
  chain construction), the story object will leak — always ensure
  `Execute` is reached

---

## Known Limits and Nuances

### `Then` is a Delphi reserved word

The outcome step method is named `Then_` (with a trailing
underscore) because `Then` is a reserved word in Delphi. This is
the one unavoidable departure from a pure StoryQ-style API.

### Step procedures must be `procedure of object`

Steps must be methods of a class — plain procedures and class
methods (static methods) will not work with the `TStepMethod`
overload because they do not produce a valid `TMethod` record.
Use the `TProc` overload with an explicit label for these cases.

### Method visibility and RTTI

As described in [RTTI and Method Visibility](#rtti-and-method-visibility):
step procedures must be `public` or `published` for automatic name
derivation to work, unless the `{$RTTI EXPLICIT METHODS(...)}` 
directive is present in the test unit. Methods that cannot be found
via RTTI produce `(unnamed step)` in the narrative report but still
execute correctly.

### Inherited step procedures

`GetDeclaredMethods` is called on each type in the inheritance
chain, so step procedures declared on a base fixture class are
found correctly, provided they meet the visibility requirement
above.

### Overloaded step procedures

If two methods share the same name but differ in signature, the
code-address match will still identify the correct overload.
However, both will produce identical narrative text (derived from
the shared name), which may be confusing. Prefer distinct names
for step procedures.

### Inlined methods

The Delphi compiler may inline very small methods when
optimisation is enabled. An inlined method may not have a stable
`CodeAddress` and will not be found by the RTTI lookup, producing
`(unnamed step)`. Add `[NoInline]` to any step procedure that
exhibits this behaviour, or disable inlining for the test project.
In practice this is rarely an issue for step procedures, which
tend to be more than a few instructions.

### Multi-scenario state leakage

As described in [State Management Between Scenarios](#state-management-between-scenarios),
DUnitX only calls `[Setup]` and `[TearDown]` between `[Test]`
methods, not between scenarios within a single `Execute` call.
Always account for shared state when composing multi-scenario
stories.

### `[TestCase]` and method names

`[TestCase]` parameterised tests must use the anonymous method
(`TProc`) overload for steps that depend on parameter values,
since `TStepMethod` procedures cannot accept parameters. This
means explicit label strings are required for those steps, as
described in [Parameterised Scenarios](#parameterised-scenarios-with-testcase).

### Execute must always be the last call

`Execute` writes the report, raises any accumulated failures, and
frees the entire object graph. If you forget to call `Execute`,
no report is written, no failures are raised, the test appears
to pass silently, and the story object leaks. Always end every
fluent chain with `.Execute`.

---

## Compatibility

| Requirement    | Detail                                                                           |
| -------------- | -------------------------------------------------------------------------------- |
| Delphi version | 2009+ (`Rtti` unit, `procedure of object`, anonymous methods required)           |
| DUnitX version | Any (uses only `Assert`, `TDUnitX.CurrentRunner.Log`, `ETestFailure`)            |
| Platforms      | Any platform supported by DUnitX (Win32, Win64, etc.)                            |
| FPC / Lazarus  | `{$MODE DELPHI}` guard included; RTTI behaviour under FPC may require adjustment |

---

## Licence

MIT — use freely in commercial and open-source projects.
