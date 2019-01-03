# SlnTools.fs

A collection of tools for manipulating solution files. 

## Motivation

Let's face it, in the context of dotnet SDK and the new project system, 
solution files are more of an obstacle than a genuinely useful component.
For instance, running `dotnet test` at the solution level will result in warnings 
(or even errors if you're running an older version of the SDK!).
In the context of repos that contain a large number of interdependent projects,
it is common to maintain redundant numbers of solution files that contain
different subsets of projects (e.g. maintaining an `all.sln` at the root of the repo).
All this tends to be intractable as number of projects (and team members!) increases.

## SlnTools

`SlnTools.fs` provides a solution (pun intended!) to this problem,
when building dotnet SDK projects using FAKE. 
It effectively provides solution files treated as ephemeral containers for project sets.
For instance, assuming I wanted to recursively build all projects within a folder:
```fsharp
#load "SlnTools.fs"
open Fake

// creates a random solution file in the /tmp folder
// using a collection of project file paths
let slnFile = !! "baseDir/**/*.??proj" |> SlnTools.createTempSolutionFile

DotNetCli.Build(fun p -> { p with Project = slnFile })
```
This results in significantly faster build times, 
particularly if the repository contains a large number solution files with overlapping dependencies.

To run tests, we can do
```fsharp
let testSlnFile = !! "baseDir/tests/**/*.??proj" |> SlnTools.createTempSolutionFile

DotNetCli.Test(fun p -> { p with Project = testSlnFile })
```
To run `dotnet pack`, we can do
```fsharp
let packSlnFile = !! "baseDir/src/**/*.??proj" |> SlnTools.createTempSolutionFile

DotNetCli.Pack(fun p -> { p with Project = packSlnFile })
```

## Using it in your build scripts

Can be referenced using paket's [github facility](https://fsprojects.github.io/Paket/github-dependencies.html). In your `paket.dependencies`:
```
github eiriktsarpalis/snippets SlnTools/SlnTools.fs
```
