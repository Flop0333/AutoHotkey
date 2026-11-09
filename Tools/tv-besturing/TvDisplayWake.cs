using System;
using System.ComponentModel;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Windows.Forms;

namespace TvBesturing
{
    public sealed class DisplayWake : NativeWindow, IDisposable
    {
        private const int PowerBroadcast = 0x0218;
        private const int PowerSettingChange = 0x8013;
        private const int SessionInfoEx = 25;
        private static readonly Guid DisplayStatus = new Guid("2B84C20E-AD23-4DDF-93DB-05FFBD7EFCA5");

        [DllImport("user32.dll", SetLastError = true)]
        private static extern IntPtr RegisterPowerSettingNotification(IntPtr window, ref Guid setting, uint flags);

        [DllImport("user32.dll")]
        private static extern bool UnregisterPowerSettingNotification(IntPtr registration);

        [DllImport("wtsapi32.dll", SetLastError = true)]
        private static extern bool WTSQuerySessionInformationW(IntPtr server, int session, int infoClass,
            out IntPtr buffer, out int bytes);

        [DllImport("wtsapi32.dll")]
        private static extern void WTSFreeMemory(IntPtr buffer);

        [DllImport("kernel32.dll")]
        private static extern uint WTSGetActiveConsoleSessionId();

        // The native Level 1 union is aligned on eight bytes, followed by session ID, state and flags.
        private const int SessionFlagsOffset = 16;
        private readonly string tvOnScript;
        private readonly string statusFile;
        private readonly int sessionId;
        private readonly IntPtr registration;
        private readonly Timer timer;
        private Process powerOn;
        private DateTime startedAt;
        private DateTime lastAttempt = DateTime.MinValue;
        private int previousDisplay = -1;

        public DisplayWake(string tvOnScript, string statusFile)
        {
            this.tvOnScript = tvOnScript;
            this.statusFile = statusFile;
            using (Process current = Process.GetCurrentProcess())
                sessionId = current.SessionId;
            CreateHandle(new CreateParams { Caption = "TvBesturing Display Wake" });
            Guid setting = DisplayStatus;
            registration = RegisterPowerSettingNotification(Handle, ref setting, 0);
            if (registration == IntPtr.Zero)
            {
                int error = Marshal.GetLastWin32Error();
                DestroyHandle();
                throw new Win32Exception(error);
            }
            timer = new Timer { Interval = 1000 };
            timer.Tick += CheckPowerOn;
            Record("Gereed");
        }

        public int ReadSessionFlags()
        {
            IntPtr buffer;
            int bytes;
            if (!WTSQuerySessionInformationW(IntPtr.Zero, sessionId, SessionInfoEx, out buffer, out bytes))
                return -1;
            try
            {
                if (bytes < SessionFlagsOffset + sizeof(int) || Marshal.ReadInt32(buffer) != 1)
                    return -1;
                return Marshal.ReadInt32(buffer, SessionFlagsOffset);
            }
            finally { WTSFreeMemory(buffer); }
        }

        public static bool ShouldWake(int previous, int current, bool locked)
        {
            return previous == 0 && current == 1 && locked;
        }

        protected override void WndProc(ref Message message)
        {
            if (message.Msg == PowerBroadcast && message.WParam.ToInt32() == PowerSettingChange &&
                message.LParam != IntPtr.Zero &&
                (Guid)Marshal.PtrToStructure(message.LParam, typeof(Guid)) == DisplayStatus &&
                Marshal.ReadInt32(message.LParam, 16) >= sizeof(int))
            {
                int current = Marshal.ReadInt32(message.LParam, 20);
                if (previousDisplay == 0 && current == 1)
                {
                    bool locked = WTSGetActiveConsoleSessionId() == (uint)sessionId && ReadSessionFlags() == 0;
                    if (ShouldWake(previousDisplay, current, locked))
                        StartPowerOn();
                }
                previousDisplay = current;
            }
            base.WndProc(ref message);
        }

        private void StartPowerOn()
        {
            if (String.IsNullOrEmpty(tvOnScript) || powerOn != null || DateTime.UtcNow - lastAttempt < TimeSpan.FromSeconds(45))
                return;
            lastAttempt = DateTime.UtcNow;
            try
            {
                var command = new ProcessStartInfo
                {
                    FileName = Path.Combine(Environment.SystemDirectory, @"WindowsPowerShell\v1.0\powershell.exe"),
                    Arguments = "-NoLogo -NoProfile -NonInteractive -ExecutionPolicy RemoteSigned -File \"" + tvOnScript + "\"",
                    WorkingDirectory = Path.GetDirectoryName(tvOnScript),
                    CreateNoWindow = true,
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true
                };
                powerOn = Process.Start(command);
                startedAt = DateTime.UtcNow;
                powerOn.BeginOutputReadLine();
                powerOn.BeginErrorReadLine();
                timer.Start();
                Record("Tv-aan gestart");
            }
            catch (Exception exception)
            {
                if (!(exception is Win32Exception) && !(exception is InvalidOperationException))
                    throw;
                if (powerOn != null)
                    timer.Start();
                Record("Tv-aan kon niet starten");
            }
        }

        private void CheckPowerOn(object sender, EventArgs args)
        {
            if (!powerOn.HasExited && DateTime.UtcNow - startedAt < TimeSpan.FromSeconds(50))
                return;
            if (powerOn.HasExited)
                Record(powerOn.ExitCode == 0 ? "Tv-aan bevestigd" : "Tv-aan mislukt");
            else
            {
                try { powerOn.Kill(); }
                catch (InvalidOperationException) { }
                Record("Tv-aan duurde te lang");
            }
            powerOn.Dispose();
            powerOn = null;
            timer.Stop();
        }

        private void Record(string status)
        {
            if (String.IsNullOrEmpty(statusFile))
                return;
            try { File.WriteAllText(statusFile, DateTimeOffset.Now.ToString("o") + " " + status); }
            catch (IOException) { }
            catch (UnauthorizedAccessException) { }
        }

        public void Dispose()
        {
            timer.Dispose();
            if (powerOn != null)
                powerOn.Dispose();
            UnregisterPowerSettingNotification(registration);
            DestroyHandle();
        }
    }
}
