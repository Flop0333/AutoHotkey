; ============================================================================
; Git Repository - The checkout's branch, sync state, and branch switching
; ============================================================================
;
; [PURPOSE]
;   The Control Deck title bar shows the checked-out branch and how far it is
;   ahead of or behind its upstream, switches branches, and syncs. Parsing is
;   kept apart from running git so it can be tested without a repository.
;
; [SAFETY]
;   - Git runs hidden, in the repository, and writes to a temporary file:
;     WScript.Shell.Exec would read a pipe but always opens a console window.
;   - A branch name from the page is only used when it is one git itself listed,
;     and never when it could be read as an option.
;   - A stash message is handed to git through an environment variable, so no
;     text from the page is ever parsed by the shell as a command.
;   - Discarding changes keeps ignored files: secrets, profiles, and logs are
;     git-ignored and must survive a discard.
; ============================================================================

class GitRepository {
	static STASH_MESSAGE_VARIABLE := "CONTROL_DECK_STASH_MESSAGE"

	; directory is the repository root.
	__New(directory) {
		this.directory := directory
	}

	Status() {
		result := this.Run("status -sb --porcelain=v1")
		if result.exitCode
			throw Error(GitRepository.FirstLine(result.output, "git status failed"))
		status := GitRepository.ParseStatus(result.output)
		status["remote"] := ""
		if (status["branch"] != "" && !status["detached"] && status["upstream"] = "")
			this.AddUnpublishedCommits(status)
		return status
	}

	; A branch that was never pushed has no upstream to count against, so the
	; commits no remote branch contains are what pushing it would publish.
	AddUnpublishedCommits(status) {
		remotes := this.Run("remote")
		remote := remotes.exitCode ? "" : GitRepository.ChooseRemote(remotes.output)
		if (remote = "")
			return
		result := this.Run("rev-list --count HEAD --not --remotes")
		if result.exitCode
			return
		status["remote"] := remote
		status["ahead"] := GitRepository.ParseCount(result.output)
	}

	; Local branches, then remote branches that have no local branch yet: git
	; switch creates the local one and tracks the remote.
	Branches() {
		result := this.Run('for-each-ref --format="%(refname)" refs/heads refs/remotes')
		if result.exitCode
			throw Error(GitRepository.FirstLine(result.output, "Could not list the branches"))
		return GitRepository.ParseBranches(result.output)
	}

	; Refreshes the remote branches and the ahead/behind counts. Never prompts:
	; a fetch that needs credentials fails instead of waiting on a hidden prompt.
	Fetch() {
		result := this.Run("fetch --prune --quiet", Map("GIT_TERMINAL_PROMPT", "0"))
		if result.exitCode
			throw Error(GitRepository.FirstLine(result.output, "git fetch failed"))
	}

	; mode is "" for a clean tree, "stash" or "discard" when there are changes.
	Switch(branch, mode := "", stashMessage := "") {
		branches := this.Branches()
		if !GitRepository.IsListedBranch(branch, branches)
			throw Error("Unknown branch: " branch)
		if (branch = this.Status()["branch"])
			throw Error("Already on " branch)

		switch mode {
			case "stash": this.Stash(stashMessage)
			case "discard": this.Discard()
			case "":
			default: throw Error("Unknown way to handle changes: " mode)
		}

		result := this.Run("switch " branch)
		if result.exitCode
			throw Error(GitRepository.FirstLine(result.output, "Could not switch to " branch))
	}

	Stash(message) {
		message := GitRepository.CleanStashMessage(message)
		arguments := "stash push --include-untracked"
		environment := Map()
		if (message != "") {
			arguments .= ' --message "%' GitRepository.STASH_MESSAGE_VARIABLE '%"'
			environment[GitRepository.STASH_MESSAGE_VARIABLE] := message
		}
		result := this.Run(arguments, environment)
		if result.exitCode
			throw Error(GitRepository.FirstLine(result.output, "Could not stash the changes"))
	}

	; Tracked changes are reset and untracked files removed; ignored files stay.
	Discard() {
		result := this.Run("reset --hard --quiet")
		if result.exitCode
			throw Error(GitRepository.FirstLine(result.output, "Could not discard the changes"))
		result := this.Run("clean -fd --quiet")
		if result.exitCode
			throw Error(GitRepository.FirstLine(result.output, "Could not remove untracked files"))
	}

	; Pulls what is behind, then pushes what is ahead. The pull only
	; fast-forwards: a branch that has diverged is left for a person to merge
	; rather than half-merged by a hidden process.
	; A branch without an upstream is published instead: pushed to the remote
	; and set to track it, so later syncs pull and push as usual.
	Sync() {
		status := this.Status()
		if (status["upstream"] = "") {
			if (status["remote"] = "" || !status["ahead"] || !GitRepository.IsSafeBranchName(status["branch"]))
				throw Error(status["branch"] " has no upstream branch to sync with")
			result := this.Run("push --quiet --set-upstream " status["remote"] " " status["branch"], Map("GIT_TERMINAL_PROMPT", "0"))
			if result.exitCode
				throw Error(GitRepository.FirstLine(result.output, "Could not publish " status["branch"]))
			return Map("pulled", 0, "pushed", status["ahead"])
		}
		pulled := 0, pushed := 0
		if status["behind"] {
			result := this.Run("pull --ff-only --quiet", Map("GIT_TERMINAL_PROMPT", "0"))
			if result.exitCode
				throw Error(GitRepository.FirstLine(result.output, "Could not pull " status["upstream"]))
			pulled := status["behind"]
		}
		if status["ahead"] {
			result := this.Run("push --quiet", Map("GIT_TERMINAL_PROMPT", "0"))
			if result.exitCode
				throw Error(GitRepository.FirstLine(result.output, "Could not push to " status["upstream"]))
			pushed := status["ahead"]
		}
		return Map("pulled", pulled, "pushed", pushed)
	}

	; Output and errors land in one file; the exit code tells them apart.
	Run(arguments, environment := Map()) {
		outputFile := A_Temp "\ahk-control-deck-git-" DllCall("GetCurrentProcessId", "UInt") "-" A_TickCount ".txt"
		previous := Map()
		for name, value in environment {
			previous[name] := EnvGet(name)
			EnvSet(name, value)
		}
		try {
			exitCode := RunWait(A_ComSpec ' /C git ' arguments ' > "' outputFile '" 2>&1', this.directory, "Hide")
			output := FileExist(outputFile) ? FileRead(outputFile, "UTF-8") : ""
		} finally {
			; An empty value was an unset variable, and is removed again.
			for name, value in previous
				value = "" ? EnvSet(name) : EnvSet(name, value)
			try FileDelete(outputFile)
		}
		return { exitCode: exitCode, output: output }
	}

	; --- Parsing ------------------------------------------------------------

	; The first line of `git status -sb` names the branch, its upstream, and the
	; counts: "## main...origin/main [ahead 1, behind 2]". Every further line is
	; one changed or untracked path.
	static ParseStatus(output) {
		lines := StrSplit(RTrim(output, "`r`n"), "`n", "`r")
		status := Map("branch", "", "upstream", "", "ahead", 0, "behind", 0, "changes", 0, "detached", 0)
		if !lines.Length
			return status

		header := lines[1]
		if RegExMatch(header, "^## (?:No commits yet on |Initial commit on )(\S+)", &match) {
			status["branch"] := match[1]
		} else if RegExMatch(header, "^## HEAD \(no branch\)") {
			status["branch"] := "HEAD"
			status["detached"] := 1
		} else if RegExMatch(header, "^## (\S+?)(?:\.\.\.(\S+))?(?: \[(.*)\])?$", &match) {
			status["branch"] := match[1]
			status["upstream"] := match[2]
			; "[gone]" means the upstream was deleted: there is nothing to sync with.
			if (match[3] = "gone")
				status["upstream"] := ""
			if RegExMatch(match[3], "ahead (\d+)", &count)
				status["ahead"] := Integer(count[1])
			if RegExMatch(match[3], "behind (\d+)", &count)
				status["behind"] := Integer(count[1])
		}

		loop lines.Length - 1
			if (Trim(lines[A_Index + 1]) != "")
				status["changes"] += 1
		return status
	}

	; for-each-ref prints full ref names, so a local branch and a remote one can
	; never be confused. A remote's HEAD is an alias, not a branch.
	static ParseBranches(output) {
		localBranches := [], remoteBranches := [], listed := Map()
		remoteRefs := []
		for line in StrSplit(output, "`n", "`r") {
			line := Trim(line)
			if RegExMatch(line, "^refs/heads/(.+)$", &match) {
				localBranches.Push(match[1])
				listed[match[1]] := true
			} else if RegExMatch(line, "^refs/remotes/[^/]+/(.+)$", &match) {
				if (match[1] != "HEAD")
					remoteRefs.Push(match[1])
			}
		}
		for name in remoteRefs
			if !listed.Has(name) {
				remoteBranches.Push(name)
				listed[name] := true
			}
		return Map("local", GitRepository.MainFirst(localBranches), "remote", GitRepository.MainFirst(remoteBranches))
	}

	; main leads the list; the rest keep git's alphabetical order.
	static MainFirst(names) {
		ordered := []
		for name in names
			if (name == "main")
				ordered.Push(name)
		for name in names
			if (name !== "main")
				ordered.Push(name)
		return ordered
	}

	; origin when there is one, otherwise the first remote git lists.
	static ChooseRemote(output) {
		remotes := []
		for line in StrSplit(output, "`n", "`r") {
			line := Trim(line)
			if GitRepository.IsSafeBranchName(line)
				remotes.Push(line)
		}
		for remote in remotes
			if (remote == "origin")
				return remote
		return remotes.Length ? remotes[1] : ""
	}

	static ParseCount(output) => RegExMatch(String(output), "^\s*(\d+)", &match) ? Integer(match[1]) : 0

	static IsListedBranch(branch, branches) {
		if !GitRepository.IsSafeBranchName(branch)
			return false
		for group in ["local", "remote"]
			for name in branches[group]
				if (name == branch)
					return true
		return false
	}

	; Characters a branch can legally contain that the shell or git would read
	; as something else are refused outright, whatever git listed.
	static IsSafeBranchName(branch) {
		return branch is String
			&& RegExMatch(branch, "^[A-Za-z0-9_][A-Za-z0-9_./+-]*$")
			&& !InStr(branch, "..")
	}

	; One line, and nothing that would end the quoted argument early: no quote,
	; and no trailing backslash, which would escape the closing quote.
	static CleanStashMessage(message) {
		message := RegExReplace(String(message), "[\r\n\t]+", " ")
		message := StrReplace(message, '"', "'")
		return RTrim(Trim(message), "\ ")
	}

	; git's own error line when there is one: a rejected push starts its output
	; with the remote's address, which explains nothing.
	static FirstLine(output, fallback) {
		if RegExMatch(output, "m)^(?:fatal|error): *(.+)$", &match)
			return Trim(match[1], " `r")
		for line in StrSplit(output, "`n", "`r") {
			line := Trim(line)
			if (line != "")
				return RegExReplace(line, "^(fatal|error): ", "")
		}
		return fallback
	}
}
