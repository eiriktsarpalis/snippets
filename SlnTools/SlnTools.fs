[<RequireQualifiedAccess>]
module SlnTools

// Simple tool for generating Solution files out of a list of projects.

open System
open System.IO
open System.Text.RegularExpressions

let private fsharpProjectTypeGuid = Guid.Parse "6EC3EE1D-3C4E-46DD-8F32-0CC8E7565705"

type Project =
    {
        ProjectTypeGuid : Guid
        ProjectGuid : Guid
        ProjectName : string
        ProjectFile : string
    }
with
    /// Reads and parses the contents of a solution file,
    /// returning an array of project definitions
    static member FromSolutionFile (sln : string) =
        let contents = File.ReadAllText sln
        let projectRegex = "Project\(\"\{(.+)\}\"\) = \"(.+)\", \"(.+\...proj)\", \"\{(.+)\}"
        let matches = Regex.Matches(contents, projectRegex)
        let parse (m : Match) =
            {
                ProjectTypeGuid = Guid.Parse m.Groups.[1].Value
                ProjectName = m.Groups.[2].Value
                ProjectFile =
                    let dirName = Path.GetDirectoryName sln 
                    let forwardSlashes = m.Groups.[3].Value.Replace('\\','/')
                    Path.Combine(dirName, forwardSlashes) |> Path.GetFullPath

                ProjectGuid = Guid.Parse m.Groups.[4].Value
            }

        try matches |> Seq.cast<Match> |> Seq.map parse |> Seq.toArray
        with e -> failwithf "failed to parse sln %s error: %O" sln e

    /// Generates a placeholder project definition from a project file path
    static member FromProjectFile(projFile : string) =
        {
            ProjectTypeGuid = fsharpProjectTypeGuid 
            ProjectGuid = Guid.NewGuid()
            ProjectName = Path.GetFileNameWithoutExtension projFile
            ProjectFile = projFile
        }

/// Formats the contents of a solution file using a list of projects
let formatSolutionFile (projects : seq<Project>) = 
    let projects = Seq.toArray projects
    seq {
        let fmtGuid (g:Guid) = g.ToString().ToUpper()

        yield ""
        yield "Microsoft Visual Studio Solution File, Format Version 12.00"
        yield "# Visual Studio 15"
        yield "VisualStudioVersion = 15.0.27428.2002"
        yield "MinimumVisualStudioVersion = 10.0.40219.1"

        for proj in projects do
            yield sprintf """Project("{%s}") = "%s", "%s", "{%s}" """ 
                        (fmtGuid proj.ProjectTypeGuid) 
                        proj.ProjectName 
                        proj.ProjectFile
                        (fmtGuid proj.ProjectGuid)

            yield "EndProject"

        yield "Global"

        yield "\tGlobalSection(SolutionConfigurationPlatforms) = preSolution"
        yield "\t\tDebug|Any CPU = Debug|Any CPU"
        yield "\t\tRelease|Any CPU = Release|Any CPU"
        yield "\tEndGlobalSection"

        yield "\tGlobalSection(ProjectConfigurationPlatforms) = postSolution"
        for proj in projects do 
            let fmt config platform cfg = 
                sprintf "\t\t{%s}.%s|%s.%s = %s|%s"
                    (fmtGuid proj.ProjectGuid) config platform cfg config platform

            yield fmt "Debug" "Any CPU" "ActiveCfg"
            yield fmt "Debug" "Any CPU" "Build.0"
            yield fmt "Release" "Any CPU" "ActiveCfg"
            yield fmt "Release" "Any CPU" "Build.0"

        yield "\tEndGlobalSection"
        yield "EndGlobal"

    } |> String.concat Environment.NewLine

/// Creates a minimal solution file containing all projects in the list
let createSolutionFile (targetSln : string) (projects : seq<string>) =
    let contents = projects |> Seq.map Project.FromProjectFile |> formatSolutionFile
    File.WriteAllText(targetSln, contents)

/// Creates a temporary, randomly named solution file containing all
/// projects in the input sequence. 
let createTempSolutionFile (projects : seq<string>) : string =
    let tempSln =
        let tmpDir = Path.GetTempPath()
        let tmpFileName = Path.GetRandomFileName()
        Path.Combine(tmpDir, Path.ChangeExtension(tmpFileName, "sln"))

    createSolutionFile tempSln projects
    tempSln

/// Validates that projects in solution file exist and have consistent structure
let validateSolution (sln : string) =
    let projects = Project.FromSolutionFile sln
    let validateProject (project : Project) =
        if not <| File.Exists project.ProjectFile then
            failwithf "project file %A in solution file %A could not be found" project.ProjectFile sln

        let projName = Path.GetFileNameWithoutExtension project.ProjectFile

        if projName <> project.ProjectName then
            failwithf "project %A in solution file %A has name %A. It should match the project file name."
                (Path.GetFileName project.ProjectFile) sln project.ProjectName

    for proj in projects do validateProject proj
