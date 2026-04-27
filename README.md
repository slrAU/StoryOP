# StoryOP

![License](https://img.shields.io/badge/license-MIT-green.svg)
![GitHub release](https://img.shields.io/github/v/release/slrAU/StoryOP)
![Downloads](https://img.shields.io/github/downloads/slrAU/StoryOP/total)
![Issues](https://img.shields.io/github/issues/slrAU/StoryOP)
![Discussions](https://img.shields.io/github/discussions/slrAU/StoryOP)
![Stars](https://img.shields.io/github/stars/slrAU/StoryOP)

## TL;DR

Presently, the requirements for usage are Delphi XE4 or greater and should support any version of DUnitX.

Comprehensive documentation can be found in the StoryOP.Manual.md file. I may get around to throwing it into the project wiki at some point.

For folks who are already familiar with StoryQ and just want to jump right in,

1. Add `StoryOP.pas` to your test project, or add it's location to the search path.

2. Add `StoryOP` to the `uses` clause of your test unit.

3. Declare public step procedures on your fixture class.  
   See the RTTI and Method Visibility section of the manual if you really can't live without enforcing encapsulation on an unsuspecting test or two.

4. Compose stories inside ordinary `[Test]` methods using the
   fluent chain, ending every chain with `.Execute`.

5. See the use-case examples in `StoryOP.BankAccount.Tests.pas` unit if you want to see how this all works... but seriously, flick through the manual if you want to know more, or send me a message via the discussions.

## What this is?

A Behaviour-Driven Development framework for Delphi. This project is based on what I remember about a similar framework for .Net called StoryQ, with a fluent syntax, expressive human-readable test output, an easy single file wrapper for DUnitX that works with TestInsight or your preferred test runner, and designed to capture behaviour/features/user-stories directly in source code if needed.

The original StoryQ was created by Rob Fonseca-Ensor, and the project used to exist at http://storyq.codeplex.com/ . Unfortunately, the Internet being what it is and with the project being an old one that wasn't being actively maintained in recent years, the CodePlex website no longer exists and you can't find the original source code. Although I understand the project was [cloned to GitHub](https://github.com/wforney/storyq) about a decade before this StoryOP project was created.

## Why should StoryOP interest you?

Here are my top 5 reasons to take an interest in StoryOP (your reasons may vary):

1. It's Delphi Native, and with a little imagination, it could be packaged into a drop-in library and used in other development toolchains with minimal configuration.

2. It provides a Fluent, expressive, human-readable DSL for unit testing, while also enabling Behaviour/Feature/Story capture directly in source code, and producing human-readable test output.

3. It integrates seamlessly with the tools that Delphi developers already use, such as DUnitX and TestInsight, and doesn't require integration into the IDE while not getting in the way of Delphi's Code Insight.

4. It's Agile, meaning that it aligns well with BDD as a starting point, yet also empowers you to adopt your own preferred syntactic pattern for story presentation that better suits your preferred development methodology.

5. It's under active development, well-documented, and fulfils a long-standing gap in the Delphi testing ecosystem.
- **Bonus reason:** It's Free, MIT-licensed, and unrestricted in usage or features.

## Why was this project started?

Although there are a couple of BDD frameworks already available for Delphi, I've found them to be a little... unwieldy... which, to be fair, may have originally been a knee-jerk wish that they were more StoryQ-like.  

All of the other BDD testing frameworks that I found with Delphi support seem to be built to emulate Cucumber or Gherkin. Personally, I despise spending time trying to force a tool to submit to my desire for it to be something easier when that time could be better spent getting on with my project. Oft-times I have found that frameworks have been poorly documented, lacking relevant examples, and relying on a deep knowledge of the source code, when all I've wanted is a handful of functions to do something simple and well. When I decided recently to resume software development after a lengthy hiatus, I found it really demotivating that nothing I wanted to do with my chosen toolchain seemed to be a good fit for the methodology... or vice versa. I wanted to avoid installation and setup of yet another external tool when I would prefer to simply drop a single file onto my computer somewhere and add it to the project's search path.  

I also can't help thinking that the design of the other tools is partially based on the quirks of the languages they have been programmed with, and that shoehorning them into a different language requires syntactic tricks and loopholes to get something non-native to work.  In my view, this is a messy approach, unpleasant to work with, non-intuitive, and generally slows the development process down.

I also see fluent syntax as a programmer's guilty pleasure. Sure, there are plenty of solid software engineering arguments that suggest avoiding fluent chains like the plague. On the other hand, a well-designed fluent API applied as a discrete DSL to a linear set of process steps can also be expressive, readable, and incredibly elegant, so long as the code avoids the risk of side-effects, encourages keeping the chains short and linear, distinctly stepped both in function and return types, and expresses a narrow and well-defined domain. This is a style that lends itself well to BDD scenarios and user story definitions.

So, I guess it was partly out of frustration, but also largely because I thought it would be an interesting project to sink my teeth into, that prompted me to throw this project together. It gave me something to get myself back onto the horse with, solved a problem I was having with my desire to test my code well, and with a genuine desire that others could find it useful too.
