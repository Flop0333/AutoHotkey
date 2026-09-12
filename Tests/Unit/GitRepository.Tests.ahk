#Requires AutoHotkey v2
#Include ..\Support\Assert.ahk
#Include ..\..\Dashboards\Control Deck\Git Repository.ahk

; The Control Deck title bar reads the branch and its sync state from git's
; output, and switches only to a branch git listed. None of this needs a
; repository: it is all parsing and checking.

Test_Status_ReadsBranchUpstreamAndCounts() {
    status := GitRepository.ParseStatus("## main...origin/main [ahead 1, behind 2]`n M README.md`n?? new.txt`n")
    Assert.Equal("main", status["branch"])
    Assert.Equal("origin/main", status["upstream"])
    Assert.Equal(1, status["ahead"])
    Assert.Equal(2, status["behind"])
    Assert.Equal(2, status["changes"])
}

Test_Status_ReadsABranchNameWithDotsAndSlashes() {
    status := GitRepository.ParseStatus("## feature/v2.1-fix...origin/feature/v2.1-fix [behind 3]`r`n")
    Assert.Equal("feature/v2.1-fix", status["branch"])
    Assert.Equal("origin/feature/v2.1-fix", status["upstream"])
    Assert.Equal(0, status["ahead"])
    Assert.Equal(3, status["behind"])
    Assert.Equal(0, status["changes"])
}

Test_Status_ReadsABranchWithoutUpstream() {
    status := GitRepository.ParseStatus("## feature/local-only`n")
    Assert.Equal("feature/local-only", status["branch"])
    Assert.Equal("", status["upstream"])
}

Test_Status_TreatsAGoneUpstreamAsNone() {
    status := GitRepository.ParseStatus("## old...origin/old [gone]`n")
    Assert.Equal("old", status["branch"])
    Assert.Equal("", status["upstream"])
}

Test_Status_ReadsADetachedHead() {
    status := GitRepository.ParseStatus("## HEAD (no branch)`n")
    Assert.Equal("HEAD", status["branch"])
    Assert.Equal(1, status["detached"])
}

Test_Status_ReadsARepositoryWithoutCommits() {
    Assert.Equal("main", GitRepository.ParseStatus("## No commits yet on main`n")["branch"])
}

Test_Status_ReportsNoBranchForNoOutput() {
    Assert.Equal("", GitRepository.ParseStatus("")["branch"])
}

Test_Branches_ListsLocalThenRemoteOnlyBranches() {
    output := "refs/heads/feature/a`nrefs/heads/main`nrefs/remotes/origin/HEAD`nrefs/remotes/origin/feature/b`nrefs/remotes/origin/main`n"
    branches := GitRepository.ParseBranches(output)
    Assert.Equal(2, branches["local"].Length)
    Assert.Equal("main", branches["local"][1])
    Assert.Equal("feature/a", branches["local"][2])
    Assert.Equal(1, branches["remote"].Length)
    Assert.Equal("feature/b", branches["remote"][1])
}

Test_Branches_PutMainFirst() {
    output := "refs/heads/codex/x`nrefs/heads/feature/a`nrefs/heads/main`nrefs/heads/zeta`nrefs/remotes/origin/alpha`nrefs/remotes/origin/main`n"
    branches := GitRepository.ParseBranches(output)
    Assert.Equal("main", branches["local"][1])
    Assert.Equal("codex/x", branches["local"][2])
    Assert.Equal("zeta", branches["local"][4])
    ; A remote main has a local branch, so it is not listed again.
    Assert.Equal(1, branches["remote"].Length)
    Assert.Equal("main", GitRepository.MainFirst(["alpha", "main"])[1])
}

Test_Remote_PrefersOrigin() {
    Assert.Equal("origin", GitRepository.ChooseRemote("fork`norigin`n"))
    Assert.Equal("fork", GitRepository.ChooseRemote("fork`r`n"))
    Assert.Equal("", GitRepository.ChooseRemote(""))
}

Test_Count_ReadsRevListOutput() {
    Assert.Equal(3, GitRepository.ParseCount("3`n"))
    Assert.Equal(0, GitRepository.ParseCount(""))
}

Test_Branches_ListsARemoteBranchOnceAcrossRemotes() {
    branches := GitRepository.ParseBranches("refs/remotes/origin/topic`nrefs/remotes/upstream/topic`n")
    Assert.Equal(1, branches["remote"].Length)
}

Test_ListedBranch_AcceptsOnlyWhatGitListed() {
    branches := Map("local", ["main"], "remote", ["feature/b"])
    Assert.True(GitRepository.IsListedBranch("main", branches))
    Assert.True(GitRepository.IsListedBranch("feature/b", branches))
    Assert.False(GitRepository.IsListedBranch("other", branches))
    Assert.False(GitRepository.IsListedBranch("MAIN", branches))
}

Test_SafeBranchName_RefusesOptionsAndShellCharacters() {
    Assert.True(GitRepository.IsSafeBranchName("codex/ticket-92_license.v2"))
    Assert.False(GitRepository.IsSafeBranchName("--force"))
    Assert.False(GitRepository.IsSafeBranchName("main & calc"))
    Assert.False(GitRepository.IsSafeBranchName("a..b"))
    Assert.False(GitRepository.IsSafeBranchName(""))
    Assert.False(GitRepository.IsSafeBranchName(42))
}

Test_StashMessage_StaysOneQuotedArgument() {
    Assert.Equal("fix 'the' thing", GitRepository.CleanStashMessage('fix "the"`r`nthing'))
    Assert.Equal("path C:\temp", GitRepository.CleanStashMessage("path C:\temp\\ "))
    Assert.Equal("", GitRepository.CleanStashMessage("   "))
}

Test_FirstLine_DropsGitsSeverityPrefix() {
    Assert.Equal("not a git repository", GitRepository.FirstLine("`nfatal: not a git repository`nmore", "fallback"))
    Assert.Equal("fallback", GitRepository.FirstLine("", "fallback"))
    Assert.Equal("failed to push some refs", GitRepository.FirstLine("To https://example.invalid/repo.git`n ! [rejected] main -> main`nerror: failed to push some refs`n", "fallback"))
}

TestKit.Run("Status reads the branch, upstream, counts, and changes", Test_Status_ReadsBranchUpstreamAndCounts)
TestKit.Run("Status reads a branch name with dots and slashes", Test_Status_ReadsABranchNameWithDotsAndSlashes)
TestKit.Run("Status reads a branch without an upstream", Test_Status_ReadsABranchWithoutUpstream)
TestKit.Run("A gone upstream leaves nothing to sync with", Test_Status_TreatsAGoneUpstreamAsNone)
TestKit.Run("Status reads a detached HEAD", Test_Status_ReadsADetachedHead)
TestKit.Run("Status reads a repository without commits", Test_Status_ReadsARepositoryWithoutCommits)
TestKit.Run("No output reports no branch", Test_Status_ReportsNoBranchForNoOutput)
TestKit.Run("Branches list local ones, then remote ones without a local branch", Test_Branches_ListsLocalThenRemoteOnlyBranches)
TestKit.Run("A branch on two remotes is listed once", Test_Branches_ListsARemoteBranchOnceAcrossRemotes)
TestKit.Run("main leads the branch list", Test_Branches_PutMainFirst)
TestKit.Run("origin is the remote a new branch is published to", Test_Remote_PrefersOrigin)
TestKit.Run("A rev-list count is read as a number", Test_Count_ReadsRevListOutput)
TestKit.Run("Only a branch git listed is accepted", Test_ListedBranch_AcceptsOnlyWhatGitListed)
TestKit.Run("Branch names that read as options or shell syntax are refused", Test_SafeBranchName_RefusesOptionsAndShellCharacters)
TestKit.Run("A stash message stays one quoted argument", Test_StashMessage_StaysOneQuotedArgument)
TestKit.Run("Git errors are reported without their severity prefix", Test_FirstLine_DropsGitsSeverityPrefix)

TestKit.Report()
