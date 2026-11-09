#Requires AutoHotkey v2
#Include ..\Support\Assert.ahk
#Include ..\..\Lib\Apps\Parsec.ahk

Test_ConnectAndDisconnect() {
    sessions := ParsecSessions()
    Assert.True(sessions.Apply("[I 2026-01-01 10:00:00] Guest#111 connected.`r`n"))
    Assert.True(sessions.IsConnected)
    Assert.True(sessions.Apply("[I 2026-01-01 10:05:00] Guest#111 disconnected.`r`n"))
    Assert.False(sessions.IsConnected)
}

Test_StaysConnectedUntilLastGuestLeaves() {
    sessions := ParsecSessions()
    sessions.Apply("[I 2026-01-01 10:00:00] Guest A#111 connected.`n[I 2026-01-01 10:00:05] Other#222 connected.`n")
    Assert.Equal(2, sessions.Count)
    Assert.False(sessions.Apply("[I 2026-01-01 10:01:00] Guest A#111 disconnected.`n"))
    Assert.True(sessions.IsConnected)
    Assert.True(sessions.Apply("[I 2026-01-01 10:02:00] Other#222 disconnected.`n"))
    Assert.False(sessions.IsConnected)
}

Test_IgnoresUnrelatedLines() {
    sessions := ParsecSessions()
    sessions.Apply("[D 2026-01-01 10:00:00] IPC AS Client Connected.`n"
        . "[I 2026-01-01 10:00:01] Virtual tablet removed due to client disconnect`n"
        . "[I 2026-01-01 10:00:02] Guest#111 disconnected.`n")
    Assert.False(sessions.IsConnected)
}

Test_ReconnectCountsOnce() {
    sessions := ParsecSessions()
    sessions.Apply("[I 2026-01-01 10:00:00] Guest#111 connected.`n[I 2026-01-01 10:00:09] Guest#111 connected.`n")
    Assert.Equal(1, sessions.Count)
}

TestKit.Run("Parsec connect then disconnect", Test_ConnectAndDisconnect)
TestKit.Run("Parsec stays connected until the last guest leaves", Test_StaysConnectedUntilLastGuestLeaves)
TestKit.Run("Parsec ignores unrelated log lines", Test_IgnoresUnrelatedLines)
TestKit.Run("Parsec reconnect of the same guest counts once", Test_ReconnectCountsOnce)
TestKit.Report()
