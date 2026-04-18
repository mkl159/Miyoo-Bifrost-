// =====================================================================
//  Miyoo Bifrost - Windows EXE Installer
//  Compile via BUILD_EXE.bat  (csc.exe .NET Framework 4.x)
// =====================================================================
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Reflection;
using System.Security.Principal;
using System.Text.RegularExpressions;
using System.Threading;
using System.Windows.Forms;

// =====================================================================
static class Program
{
    [STAThread]
    static void Main()
    {
        // --- Auto-elevation (UAC) ---
        bool isAdmin = new WindowsPrincipal(WindowsIdentity.GetCurrent())
                           .IsInRole(WindowsBuiltInRole.Administrator);
        if (!isAdmin)
        {
            try
            {
                ProcessStartInfo psi = new ProcessStartInfo();
                psi.FileName        = Assembly.GetExecutingAssembly().Location;
                psi.Verb            = "runas";
                psi.UseShellExecute = true;
                Process.Start(psi);
            }
            catch (Exception ex)
            {
                MessageBox.Show(
                    "L'installeur necessite les droits administrateur.\n\n" +
                    "Clic droit > Executer en tant qu'administrateur.\n\n" +
                    ex.Message,
                    "Miyoo Bifrost", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            }
            return;
        }

        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);

        string lang = ShowLangDialog();
        if (lang == null) return;

        Application.Run(new InstallerForm(lang));
    }

    static string ShowLangDialog()
    {
        Form dlg = new Form();
        dlg.Text            = "Miyoo Bifrost";
        dlg.ClientSize      = new Size(310, 178);
        dlg.FormBorderStyle = FormBorderStyle.FixedDialog;
        dlg.MaximizeBox     = false;
        dlg.StartPosition   = FormStartPosition.CenterScreen;
        dlg.Font            = new Font("Segoe UI", 9f);
        dlg.BackColor       = Color.FromArgb(32, 32, 32);
        dlg.ForeColor       = Color.White;

        Label lbl = new Label();
        lbl.Text      = "Choisissez / Choose / Elige:";
        lbl.Location  = new Point(15, 14);
        lbl.AutoSize  = true;
        lbl.ForeColor = Color.FromArgb(80, 200, 255);

        RadioButton r1 = new RadioButton();
        r1.Text = "Francais (FR)"; r1.Location = new Point(22, 44); r1.AutoSize = true; r1.Checked = true; r1.ForeColor = Color.White;
        RadioButton r2 = new RadioButton();
        r2.Text = "English (EN)";  r2.Location = new Point(22, 68); r2.AutoSize = true; r2.ForeColor = Color.White;
        RadioButton r3 = new RadioButton();
        r3.Text = "Espanol (ES)";  r3.Location = new Point(22, 92); r3.AutoSize = true; r3.ForeColor = Color.White;

        Button btn = new Button();
        btn.Text         = "OK";
        btn.Location     = new Point(100, 130);
        btn.Size         = new Size(110, 30);
        btn.DialogResult = DialogResult.OK;
        btn.Font         = new Font("Segoe UI", 9f, FontStyle.Bold);
        btn.BackColor    = Color.FromArgb(0, 120, 215);
        btn.ForeColor    = Color.White;
        btn.FlatStyle    = FlatStyle.Flat;

        dlg.Controls.AddRange(new Control[] { lbl, r1, r2, r3, btn });
        dlg.AcceptButton = btn;

        if (dlg.ShowDialog() != DialogResult.OK) return null;
        if (r1.Checked) return "FR";
        if (r2.Checked) return "EN";
        return "ES";
    }
}

// =====================================================================
class InstallerForm : Form
{
    readonly string _lang;
    readonly Dictionary<string,string> _L;
    readonly string _logPath;
    readonly string _scriptDir;

    RichTextBox _logBox;
    ProgressBar _progress;
    Label       _status;
    Button      _btnStart;
    Button      _btnClose;
    volatile bool _installing = false;

    public InstallerForm(string lang)
    {
        _lang      = lang;
        _L         = GetMessages(lang);
        _logPath   = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.Desktop),
            "bifrost_install.log");
        _scriptDir = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);

        File.WriteAllText(_logPath, "");
        BuildUI();

        Log("=== Bifrost Installer start ===");
        Log("EXE:  " + Assembly.GetExecutingAssembly().Location);
        Log("User: " + Environment.UserName);
        Log("OS:   " + Environment.OSVersion.VersionString);
        Log("Lang: " + lang);

        AppendLog("Miyoo Bifrost — Dual Boot Installer", Color.FromArgb(80, 200, 255));
        AppendLog(_L["ready"]);
    }

    // ------------------------------------------------------------------
    void BuildUI()
    {
        Text            = _L["title"];
        ClientSize      = new Size(710, 540);
        FormBorderStyle = FormBorderStyle.FixedSingle;
        MaximizeBox     = false;
        StartPosition   = FormStartPosition.CenterScreen;
        BackColor       = Color.FromArgb(25, 25, 25);
        ForeColor       = Color.White;
        Font            = new Font("Segoe UI", 9f);

        Label header = new Label();
        header.Text      = "Miyoo Bifrost — Dual Boot Installer";
        header.Location  = new Point(10, 8);
        header.Size      = new Size(690, 28);
        header.Font      = new Font("Segoe UI", 13f, FontStyle.Bold);
        header.ForeColor = Color.FromArgb(80, 200, 255);
        header.TextAlign = ContentAlignment.MiddleCenter;
        Controls.Add(header);

        _logBox = new RichTextBox();
        _logBox.Location    = new Point(10, 44);
        _logBox.Size        = new Size(690, 395);
        _logBox.BackColor   = Color.FromArgb(12, 12, 12);
        _logBox.ForeColor   = Color.LightGreen;
        _logBox.ReadOnly    = true;
        _logBox.ScrollBars  = RichTextBoxScrollBars.Vertical;
        _logBox.Font        = new Font("Consolas", 8.5f);
        _logBox.BorderStyle = BorderStyle.FixedSingle;
        Controls.Add(_logBox);

        _progress = new ProgressBar();
        _progress.Location = new Point(10, 447);
        _progress.Size     = new Size(690, 18);
        _progress.Minimum  = 0;
        _progress.Maximum  = 8;
        _progress.Value    = 0;
        _progress.Style    = ProgressBarStyle.Continuous;
        Controls.Add(_progress);

        _status = new Label();
        _status.Location  = new Point(10, 470);
        _status.Size      = new Size(690, 20);
        _status.ForeColor = Color.Silver;
        _status.Text      = _L["ready"];
        Controls.Add(_status);

        _btnStart = new Button();
        _btnStart.Text      = _L["start"];
        _btnStart.Location  = new Point(490, 502);
        _btnStart.Size      = new Size(100, 28);
        _btnStart.BackColor = Color.FromArgb(0, 120, 215);
        _btnStart.ForeColor = Color.White;
        _btnStart.FlatStyle = FlatStyle.Flat;
        _btnStart.Font      = new Font("Segoe UI", 9f, FontStyle.Bold);
        _btnStart.Click    += BtnStart_Click;
        Controls.Add(_btnStart);

        _btnClose = new Button();
        _btnClose.Text      = _L["close"];
        _btnClose.Location  = new Point(600, 502);
        _btnClose.Size      = new Size(100, 28);
        _btnClose.BackColor = Color.FromArgb(55, 55, 55);
        _btnClose.ForeColor = Color.White;
        _btnClose.FlatStyle = FlatStyle.Flat;
        _btnClose.Click    += delegate { Close(); };
        Controls.Add(_btnClose);

        FormClosing += delegate(object s, System.Windows.Forms.FormClosingEventArgs ev)
        {
            if (_installing)
            {
                DialogResult r = MessageBox.Show(this,
                    _L["closeWarn"],
                    "Bifrost", MessageBoxButtons.YesNo, MessageBoxIcon.Warning);
                if (r != DialogResult.Yes) ev.Cancel = true;
            }
        };
    }

    // ------------------------------------------------------------------
    void BtnStart_Click(object sender, EventArgs e)
    {
        _btnStart.Enabled = false;
        _logBox.Clear();

        // --- Select paths on UI thread ---
        AppendLog(_L["selectSD"] + "...", Color.Yellow);
        string sd = SelectFolder(_L["selectSD"], _scriptDir);
        if (sd == null)
        {
            AppendLog(_L["cancelled"], Color.OrangeRed);
            Log("SD: annule");
            _btnStart.Enabled = true; return;
        }
        Log("SD: " + sd);
        AppendLog("  SD: " + sd, Color.Cyan);

        AppendLog(_L["selectOnion"] + "...", Color.Yellow);
        string onion = SelectFolder(_L["selectOnion"], _scriptDir);
        if (onion == null)
        {
            AppendLog(_L["cancelled"], Color.OrangeRed);
            Log("OnionOS: annule");
            _btnStart.Enabled = true; return;
        }
        Log("OnionOS: " + onion);
        AppendLog("  OnionOS: " + onion, Color.Cyan);

        AppendLog(_L["selectTelmi"] + "...", Color.Yellow);
        string telmi = SelectFolder(_L["selectTelmi"], _scriptDir);
        if (telmi == null)
        {
            AppendLog(_L["cancelled"], Color.OrangeRed);
            Log("TelmiOS: annule");
            _btnStart.Enabled = true; return;
        }
        Log("TelmiOS: " + telmi);
        AppendLog("  TelmiOS: " + telmi, Color.Cyan);
        AppendLog("");

        // --- Spawn background thread ---
        Thread worker = new Thread(delegate() { RunInstall(sd, onion, telmi); });
        worker.IsBackground = true;
        worker.Start();
    }

    // ------------------------------------------------------------------
    void RunInstall(string sd, string onion, string telmi)
    {
        _installing = true;
        try
        {
            // ==== Drive type check ====
            string driveLetter = sd.Length >= 1 ? sd.Substring(0, 1).ToUpper() : "C";
            try
            {
                DriveInfo di   = new DriveInfo(driveLetter);
                long sizeGB    = di.TotalSize / (1024L * 1024L * 1024L);
                string fs      = di.DriveFormat;
                Log("Drive " + driveLetter + ": " + sizeGB + " GB, FS=" + fs + ", Type=" + di.DriveType);
                AppendLog(string.Format("  {0}: {1} GB, {2}: {3}",
                    _L["fat32Detected"], sizeGB, _L["fat32Current"], fs), Color.Cyan);

                // Warn if not a removable drive
                if (di.DriveType != DriveType.Removable)
                {
                    Log("Drive is not removable: " + di.DriveType);
                    AppendLog("  [WARN] " + di.DriveType, Color.Yellow);
                    bool proceed = false;
                    Invoke((Action)delegate
                    {
                        DialogResult r = MessageBox.Show(this,
                            _L["driveWarn"],
                            "Bifrost", MessageBoxButtons.YesNo, MessageBoxIcon.Warning);
                        proceed = (r == DialogResult.Yes);
                    });
                    if (!proceed)
                    {
                        AppendLog(_L["cancelled"], Color.OrangeRed);
                        Done(false); return;
                    }
                }

                if (fs != "FAT32")
                {
                    AppendLog(_L["fat32Warn"],    Color.OrangeRed);
                    AppendLog(_L["fat32Req"],     Color.OrangeRed);
                    AppendLog(_L["fat32NoExfat"], Color.OrangeRed);

                    bool doFormat  = false;
                    bool doAnyway  = false;
                    Invoke((Action)delegate
                    {
                        DialogResult r = MessageBox.Show(this,
                            _L["fat32Warn"]    + "\n\n" +
                            _L["fat32Req"]     + "\n"   +
                            _L["fat32NoExfat"] + "\n\n" +
                            _L["fat32Ask"],
                            "FAT32", MessageBoxButtons.YesNo, MessageBoxIcon.Warning);
                        doFormat = (r == DialogResult.Yes);
                    });

                    if (doFormat)
                    {
                        AppendLog(_L["fat32Progress"], Color.Yellow);
                        bool ok = FormatFAT32(driveLetter);
                        if (!ok)
                        {
                            AppendLog(_L["fat32Fail"],  Color.OrangeRed);
                            AppendLog(_L["fat32Rufus"], Color.Yellow);
                            ShowError(_L["fat32Fail"], _L["fat32RufusDetail"]);
                            Done(false); return;
                        }
                        AppendLog("  " + _L["fat32Ok"], Color.LightGreen);
                    }
                    else
                    {
                        // Ask if user wants to continue without formatting
                        Invoke((Action)delegate
                        {
                            DialogResult r2 = MessageBox.Show(this,
                                _L["fat32SkipWarn"] + "\n\n" + _L["fat32SkipAsk"],
                                "FAT32", MessageBoxButtons.YesNo, MessageBoxIcon.Question);
                            doAnyway = (r2 == DialogResult.Yes);
                        });
                        if (doAnyway)
                        {
                            Log("FAT32 skip: l'utilisateur continue quand meme");
                            AppendLog("  " + _L["fat32Skipped"], Color.Yellow);
                        }
                        else
                        {
                            AppendLog(_L["fat32Abort"], Color.OrangeRed);
                            Done(false); return;
                        }
                    }
                }
                else
                {
                    AppendLog("  " + _L["fat32Good"], Color.LightGreen);
                }
            }
            catch (Exception ex)
            {
                Log("DriveInfo err: " + ex.Message + " (ignored)");
            }

            // ==== Validate bin/ ====
            string srcBin = Path.Combine(onion, "miyoo", "app", ".tmp_update", "bin");
            if (!Directory.Exists(srcBin))
                srcBin = Path.Combine(onion, ".tmp_update", "bin");
            if (!Directory.Exists(srcBin))
            {
                string msg = _L["errBin"] + "\n" + srcBin;
                AppendLog(msg, Color.OrangeRed);
                ShowError(msg, _L["errBinDetail"]);
                Done(false); return;
            }

            // ==== Validate DualBoot ====
            string srcDual = Path.Combine(_scriptDir, "DualBoot");
            if (!Directory.Exists(srcDual))
            {
                AppendLog(_L["errNoDual"] + ":\n  " + srcDual, Color.OrangeRed);
                ShowError(_L["errNoDual"] + ":\n" + srcDual, _L["errNoDualDetail"]);
                Done(false); return;
            }

            AppendLog("  bin/: " + srcBin, Color.Cyan);
            AppendLog("");

            // ==== STEP 1: Clean ====
            SetStep(_L["step1"], 1);
            foreach (string d in new string[] { Path.Combine(sd, "DualBoot"), Path.Combine(sd, ".tmp_update") })
            {
                if (Directory.Exists(d))
                {
                    Directory.Delete(d, true);
                    AppendLog("  del: " + d, Color.Gray);
                    Log("del: " + d);
                }
            }
            string[] rootFiles = new string[] {
                "bootmenu_onion.png","bootmenu_telmios.png",
                "generate_bootmenu.py","system.json","cachefile","autorun.inf"
            };
            foreach (string f in rootFiles)
            {
                string fp = Path.Combine(sd, f);
                if (File.Exists(fp)) { File.Delete(fp); Log("del: " + fp); }
            }
            AppendLog("  OK", Color.LightGreen);

            // ==== STEP 2: Bootloader ====
            SetStep(_L["step2"], 2);
            string cfgDst  = Path.Combine(sd, ".tmp_update", "config", "dualboot.cfg");
            string savedCfg = null;
            if (File.Exists(cfgDst))
            {
                savedCfg = File.ReadAllText(cfgDst);
                AppendLog("  Config existante sauvegardee", Color.Gray);
                Log("Config sauvegardee (" + savedCfg.Length + " chars)");
            }
            CopyDir(Path.Combine(srcDual, ".tmp_update"), Path.Combine(sd, ".tmp_update"));
            AppendLog("  DualBoot\\.tmp_update  ->  " + sd + "\\.tmp_update", Color.Gray);

            if (savedCfg != null)
            {
                File.WriteAllText(cfgDst, savedCfg);
                AppendLog("  Config precedente restauree", Color.Gray);
            }
            else
            {
                string cfg = File.ReadAllText(cfgDst);
                cfg = Regex.Replace(cfg, @"(?m)^LANG=.*$", "LANG=" + _lang);
                File.WriteAllText(cfgDst, cfg);
                AppendLog("  LANG=" + _lang + " defini dans dualboot.cfg", Color.Gray);
            }
            string autorunSrc = Path.Combine(srcDual, "autorun.inf");
            if (File.Exists(autorunSrc))
                File.Copy(autorunSrc, Path.Combine(sd, "autorun.inf"), true);
            AppendLog("  OK", Color.LightGreen);

            // ==== STEP 3: Updater ====
            SetStep(_L["step3"], 3);
            string updSrc = Path.Combine(onion, ".tmp_update", "updater");
            if (File.Exists(updSrc))
            {
                File.Copy(updSrc, Path.Combine(sd, ".tmp_update", "updater"), true);
                AppendLog("  updater copie", Color.Gray);
            }
            else
                AppendLog("  [WARN] updater non trouve: " + updSrc, Color.Yellow);
            AppendLog("  OK", Color.LightGreen);

            // ==== STEP 4: bin/ ====
            SetStep(_L["step4"], 4);
            AppendLog("  " + _L["slowCopy"], Color.Silver);
            Directory.CreateDirectory(Path.Combine(sd, ".tmp_update", "bin"));
            CopyDir(srcBin, Path.Combine(sd, ".tmp_update", "bin"));
            int binCnt = CountFiles(Path.Combine(sd, ".tmp_update", "bin"));
            Log("bin/ copie: " + binCnt + " fichiers");
            AppendLog("  " + binCnt + " fichiers", Color.Gray);
            AppendLog("  OK", Color.LightGreen);

            // ==== STEP 5: lib/ ====
            SetStep(_L["step5"], 5);
            AppendLog("  " + _L["slowCopy"], Color.Silver);
            string libSrc = Path.Combine(telmi, ".tmp_update", "lib");
            if (!Directory.Exists(libSrc))
            {
                AppendLog("  [WARN] lib/ non trouve: " + libSrc, Color.Yellow);
                Log("lib/ introuvable: " + libSrc);
            }
            else
            {
                Directory.CreateDirectory(Path.Combine(sd, ".tmp_update", "lib"));
                CopyDir(libSrc, Path.Combine(sd, ".tmp_update", "lib"));
                int libCnt = CountFiles(Path.Combine(sd, ".tmp_update", "lib"));
                Log("lib/ copie: " + libCnt + " fichiers");
                AppendLog("  " + libCnt + " fichiers", Color.Gray);
            }
            AppendLog("  OK", Color.LightGreen);

            // ==== STEP 6: TelmiOS ====
            SetStep(string.Format("{0} {1}\\telmios\\", _L["step6_pre"], sd), 6);
            AppendLog("  " + _L["slowMinutes"], Color.Silver);
            string sdTelmi = Path.Combine(sd, "telmios");
            foreach (string t in new string[] { Path.Combine(sd, "Telmios"), sdTelmi })
                if (Directory.Exists(t)) { Directory.Delete(t, true); Log("del: " + t); }
            CopyDir(telmi, sdTelmi);
            int telmiCnt = CountFiles(sdTelmi);
            Log("TelmiOS copie: " + telmiCnt + " fichiers");
            AppendLog(string.Format("  TelmiOS -> telmios\\  ({0} fichiers)", telmiCnt), Color.Gray);
            AppendLog("  OK", Color.LightGreen);

            // Telmi-Sync: Stories / Saves / Music -> racine SD
            AppendLog("  [Telmi-Sync] Placement des donnees a la racine...", Color.Silver);
            foreach (string dir in new string[] { "Stories", "Saves", "Music" })
            {
                string src2 = Path.Combine(sdTelmi, dir);
                string dst2 = Path.Combine(sd, dir);
                if (Directory.Exists(src2))
                {
                    if (Directory.Exists(dst2))
                    {
                        Directory.Delete(src2, true);
                        Log("telmios\\" + dir + " supprime (racine conservee)");
                    }
                    else
                    {
                        MoveDir(src2, dst2);
                        Log("Deplace telmios\\" + dir + " -> " + dst2);
                        AppendLog("  [Telmi-Sync] telmios\\" + dir + " -> \\" + dir, Color.Gray);
                    }
                }
            }
            if (!Directory.Exists(Path.Combine(sd, "Saves")))
                Directory.CreateDirectory(Path.Combine(sd, "Saves"));
            string paramF = Path.Combine(sd, "Saves", ".parameters");
            if (!File.Exists(paramF))
            {
                File.WriteAllText(paramF, "{}");
                Log("Saves\\.parameters cree");
                AppendLog("  [Telmi-Sync] Saves\\.parameters cree", Color.Gray);
            }

            // ==== STEP 7: OnionOS ====
            SetStep(string.Format("{0} {1}\\onion\\", _L["step7_pre"], sd), 7);
            AppendLog("  " + _L["slowMinutes"], Color.Silver);
            string sdOnion = Path.Combine(sd, "onion");
            if (Directory.Exists(sdOnion)) { Directory.Delete(sdOnion, true); Log("del: " + sdOnion); }
            CopyDir(onion, sdOnion);
            int onionCnt = CountFiles(sdOnion);
            Log("OnionOS copie: " + onionCnt + " fichiers");
            AppendLog(string.Format("  OnionOS -> onion\\  ({0} fichiers)", onionCnt), Color.Gray);
            AppendLog("  OK", Color.LightGreen);

            // ==== STEP 8: Boot menu images ====
            SetStep(_L["step8"], 8);
            // Verifier si les images .raw sont deja presentes (bundlees dans DualBoot, copiees etape 2)
            string rawCheck = Path.Combine(sd, ".tmp_update", "res", "bootmenu_onion_FR.raw");
            if (File.Exists(rawCheck))
            {
                Log("Images .raw deja presentes (bundlees) - generation Python ignoree");
                AppendLog("  OK - Images deja presentes (bundlees)", Color.LightGreen);
            }
            else
            {
            string pyScript = Path.Combine(_scriptDir, "generate_bootmenu.py");
            if (!File.Exists(pyScript))
            {
                AppendLog("  [IGNORE] generate_bootmenu.py non trouve", Color.Yellow);
                Log("generate_bootmenu.py manquant: " + pyScript);
            }
            else
            {
                string pyCmd = FindPython();
                if (pyCmd == null)
                {
                    AppendLog("  [IGNORE] Python non trouve — installe Python 3 puis lance generate_bootmenu.py", Color.Yellow);
                    Log("Python non trouve");
                }
                else
                {
                    Log("Python: " + pyCmd);
                    AppendLog("  Python: " + pyCmd, Color.Silver);

                    // Verifier la compatibilite Python / Pillow (Pillow n'a pas de wheel pour Python >= 3.14)
                    bool pyTooNew = false;
                    string pyVerOut = "";
                    try {
                        ProcessStartInfo pv = new ProcessStartInfo();
                        pv.FileName = pyCmd; pv.Arguments = "--version";
                        pv.UseShellExecute = false; pv.RedirectStandardOutput = true; pv.RedirectStandardError = true; pv.CreateNoWindow = true;
                        Process pProc = Process.Start(pv);
                        pyVerOut = pProc.StandardOutput.ReadToEnd() + pProc.StandardError.ReadToEnd();
                        pProc.WaitForExit();
                        var m = System.Text.RegularExpressions.Regex.Match(pyVerOut, @"Python (\d+)\.(\d+)");
                        if (m.Success) {
                            int maj = int.Parse(m.Groups[1].Value), min = int.Parse(m.Groups[2].Value);
                            if (maj > 3 || (maj == 3 && min >= 14)) {
                                pyTooNew = true;
                                Log("Python " + maj + "." + min + " trop recent - Pillow indisponible (necessite <= 3.13)");
                                AppendLog("  [AVERT] Python " + maj + "." + min + " trop recent pour Pillow.", Color.Orange);
                                AppendLog("  Installe Python 3.11 ou 3.12 pour generer les images.", Color.Orange);
                                AppendLog("  Installation continue - ecran noir au boot (OK apres 60s).", Color.Orange);
                            }
                        }
                    } catch { }

                    if (!pyTooNew)
                    {
                        if (RunCommand(pyCmd, "-c \"import PIL\"") != 0)
                        {
                            AppendLog("  Installation de Pillow...", Color.Silver);
                            // --only-binary=:all: evite la compilation source qui bloque indefiniment
                            int pipRet = RunCommand(pyCmd, "-m pip install Pillow --only-binary=:all: --quiet");
                            if (pipRet != 0)
                            {
                                AppendLog("  [AVERT] Pillow indisponible pour cette version Python.", Color.Orange);
                                pyTooNew = true;
                            }
                        }
                    }

                    if (!pyTooNew)
                    {
                        AppendLog("  Generation des images RAW (FR/EN/ES)...", Color.Silver);
                        // Si le chemin se termine par \ (ex: E:\), doubler le \ avant la quote
                        // fermante pour eviter que \" soit interprete comme quote echappee
                        string sdArg = sd.EndsWith("\\") ? sd + "\\" : sd;
                        int ret = RunCommandLog(pyCmd, "\"" + pyScript + "\" \"" + sdArg + "\"");
                        if (ret == 0)
                            AppendLog("  OK - Images generees", Color.LightGreen);
                        else
                            AppendLog("  ERREUR generate_bootmenu.py (code " + ret + ")", Color.OrangeRed);
                    }
                }
            }
            } // fin du bloc else (images non bundlees)

            // ==== Final verification ====
            AppendLog("");
            AppendLog(_L["verif"], Color.Yellow);
            Log("--- VERIFICATION FINALE ---");
            int errors = 0;
            string[] checks = new string[] {
                Path.Combine(sd, ".tmp_update", "runtime.sh"),
                Path.Combine(sd, ".tmp_update", "updater"),
                Path.Combine(sd, ".tmp_update", "bin", "prompt"),
                Path.Combine(sd, ".tmp_update", "lib", "libSDL-1.2.so.0"),
                Path.Combine(sd, ".tmp_update", "config", "dualboot.cfg"),
                Path.Combine(sd, "telmios", ".tmp_update", "runtime.sh")
            };
            foreach (string chk in checks)
            {
                bool ok = File.Exists(chk);
                AppendLog((ok ? "  [OK] " : "  [MANQUANT] ") + chk,
                          ok ? Color.LightGreen : Color.OrangeRed);
                if (ok) Log("OK: " + chk);
                else  { Log("MANQUANT: " + chk); errors++; }
            }

            bool onionOk = File.Exists(Path.Combine(sdOnion, "miyoo","app",".tmp_update","install.sh"))
                        || File.Exists(Path.Combine(sdOnion, ".tmp_update","runtime.sh"));
            AppendLog(onionOk ? "  [OK] onion/ pret" : "  [MANQUANT] onion/ incomplet",
                      onionOk ? Color.LightGreen : Color.OrangeRed);
            if (!onionOk) { Log("MANQUANT: onion/"); errors++; }
            else Log("OK: onion/");

            bool hasImg = File.Exists(Path.Combine(sd,".tmp_update","res","bootmenu_onion_FR.raw"))
                       || File.Exists(Path.Combine(sd,".tmp_update","res","bootmenu_onion.raw"));
            AppendLog(hasImg
                ? "  [OK] Images .raw presentes"
                : "  [AVERT] Images .raw manquantes — lance generate_bootmenu.py avec la SD inseree",
                hasImg ? Color.LightGreen : Color.Yellow);

            AppendLog("");
            AppendLog("========================================", Color.Cyan);
            if (errors == 0)
            {
                Log("=== INSTALLATION REUSSIE ===");
                AppendLog("  " + _L["success"], Color.LightGreen);
                AppendLog("========================================", Color.Cyan);
                AppendLog("");
                AppendLog("  " + _L["eject"]);
                AppendLog("  " + _L["insertSD"]);
                AppendLog("");
                AppendLog("  " + _L["atBoot"]);
                AppendLog("    " + _L["navOS"]);
                AppendLog("    " + _L["confirm"]);
                AppendLog("    " + _L["lastOS"]);
            }
            else
            {
                Log("=== INSTALLATION INCOMPLETE: " + errors + " erreur(s) ===");
                AppendLog("  " + errors + " " + _L["missingFiles"], Color.OrangeRed);
                AppendLog("========================================", Color.Cyan);
                AppendLog("  " + _L["checkFolders"]);
                AppendLog("  " + _L["checkSameDir"]);
            }
            AppendLog("");
            AppendLog("  " + _L["logSaved"] + ":", Color.Silver);
            AppendLog("  " + _logPath, Color.Silver);
            Log("=== FIN ===  Log: " + _logPath);

            Done(errors == 0);
        }
        catch (Exception ex)
        {
            Log("EXCEPTION: " + ex);
            AppendLog("ERREUR INATTENDUE: " + ex.Message, Color.OrangeRed);
            ShowError("Erreur inattendue:\n" + ex.Message,
                      "Consultez le log pour les details:\n" + _logPath);
            Done(false);
        }
    }

    // ------------------------------------------------------------------
    //  Helpers
    // ------------------------------------------------------------------

    string SelectFolder(string desc, string initial)
    {
        string result = null;
        Action act = delegate
        {
            FolderBrowserDialog fbd = new FolderBrowserDialog();
            fbd.Description       = desc;
            fbd.ShowNewFolderButton = false;
            if (initial != null && Directory.Exists(initial))
                fbd.SelectedPath  = initial;
            if (fbd.ShowDialog(this) == DialogResult.OK)
            {
                string p = fbd.SelectedPath.TrimEnd('\\');
                // "E:" -> "E:\" (Path.Combine("E:", "foo") = "E:foo" which is wrong)
                if (p.Length == 2 && p[1] == ':')
                    p += "\\";
                result = p;
            }
            fbd.Dispose();
        };
        if (InvokeRequired) Invoke(act); else act();
        return result;
    }

    static void CopyDir(string src, string dst)
    {
        Directory.CreateDirectory(dst);
        foreach (string f in Directory.GetFiles(src))
            File.Copy(f, Path.Combine(dst, Path.GetFileName(f)), true);
        foreach (string d in Directory.GetDirectories(src))
            CopyDir(d, Path.Combine(dst, Path.GetFileName(d)));
    }

    static void MoveDir(string src, string dst)
    {
        try
        {
            Directory.Move(src, dst);
        }
        catch
        {
            // Cross-volume fallback
            CopyDir(src, dst);
            Directory.Delete(src, true);
        }
    }

    static int CountFiles(string path)
    {
        if (!Directory.Exists(path)) return 0;
        int count = Directory.GetFiles(path).Length;
        foreach (string d in Directory.GetDirectories(path))
            count += CountFiles(d);
        return count;
    }

    static string FindPython()
    {
        foreach (string cmd in new string[] { "python", "python3" })
        {
            try
            {
                ProcessStartInfo psi = new ProcessStartInfo();
                psi.FileName               = cmd;
                psi.Arguments              = "--version";
                psi.UseShellExecute        = false;
                psi.RedirectStandardOutput = true;
                psi.RedirectStandardError  = true;
                psi.CreateNoWindow         = true;
                Process p = Process.Start(psi);
                p.WaitForExit();
                if (p.ExitCode == 0) return cmd;
            }
            catch { }
        }
        return null;
    }

    int RunCommand(string cmd, string args)
    {
        try
        {
            ProcessStartInfo psi = new ProcessStartInfo();
            psi.FileName               = cmd;
            psi.Arguments              = args;
            psi.UseShellExecute        = false;
            psi.RedirectStandardOutput = true;
            psi.RedirectStandardError  = true;
            psi.CreateNoWindow         = true;
            Process p = Process.Start(psi);
            // Read stderr async to avoid deadlock when both buffers fill
            string e = "";
            p.ErrorDataReceived += delegate(object s, DataReceivedEventArgs ev)
            {
                if (ev.Data != null) e += ev.Data + "\n";
            };
            p.BeginErrorReadLine();
            string o = p.StandardOutput.ReadToEnd();
            p.WaitForExit();
            if (o.Trim().Length > 0) Log("stdout: " + o.Trim());
            if (e.Trim().Length > 0) Log("stderr: " + e.Trim());
            return p.ExitCode;
        }
        catch (Exception ex) { Log("RunCommand err: " + ex.Message); return -1; }
    }

    int RunCommandLog(string cmd, string args)
    {
        try
        {
            ProcessStartInfo psi = new ProcessStartInfo();
            psi.FileName               = cmd;
            psi.Arguments              = args;
            psi.UseShellExecute        = false;
            psi.RedirectStandardOutput = true;
            psi.RedirectStandardError  = true;
            psi.CreateNoWindow         = true;
            Process p = Process.Start(psi);
            string e = "";
            p.ErrorDataReceived += delegate(object s, DataReceivedEventArgs ev)
            {
                if (ev.Data != null) e += ev.Data + "\n";
            };
            p.BeginErrorReadLine();
            string o = p.StandardOutput.ReadToEnd();
            p.WaitForExit();
            if (o.Trim().Length > 0) { Log("stdout: " + o.Trim()); AppendLog(o.Trim(), Color.Silver); }
            if (e.Trim().Length > 0) { Log("stderr: " + e.Trim()); AppendLog(e.Trim(), Color.Yellow); }
            return p.ExitCode;
        }
        catch (Exception ex) { Log("RunCommandLog err: " + ex.Message); return -1; }
    }

    bool FormatFAT32(string driveLetter)
    {
        string tmpF = Path.GetTempFileName();
        try
        {
            File.WriteAllText(tmpF,
                "select volume " + driveLetter + "\r\n" +
                "format fs=fat32 label=MiyooBoot quick\r\n" +
                "exit\r\n");
            Log("diskpart script: " + tmpF);
            ProcessStartInfo psi = new ProcessStartInfo();
            psi.FileName               = "diskpart.exe";
            psi.Arguments              = "/s \"" + tmpF + "\"";
            psi.UseShellExecute        = false;
            psi.RedirectStandardOutput = true;
            psi.CreateNoWindow         = true;
            Process p = Process.Start(psi);
            string output = p.StandardOutput.ReadToEnd();
            p.WaitForExit();
            Log("diskpart: " + output.Replace("\r\n", " | "));
            try
            {
                DriveInfo di = new DriveInfo(driveLetter);
                return di.DriveFormat == "FAT32";
            }
            catch { return false; }
        }
        finally
        {
            try { File.Delete(tmpF); } catch { }
        }
    }

    void AppendLog(string text)
    {
        AppendLog(text, Color.White);
    }

    void AppendLog(string text, Color color)
    {
        Action act = delegate
        {
            _logBox.SelectionStart  = _logBox.TextLength;
            _logBox.SelectionLength = 0;
            _logBox.SelectionColor  = color;
            _logBox.AppendText(text + "\n");
            _logBox.ScrollToCaret();
        };
        if (InvokeRequired) Invoke(act); else act();
    }

    void Log(string msg)
    {
        string line = "[" + DateTime.Now.ToString("HH:mm:ss") + "] " + msg;
        try { File.AppendAllText(_logPath, line + "\n"); } catch { }
    }

    void SetStep(string msg, int step)
    {
        Log("--- STEP " + step + ": " + msg);
        AppendLog("");
        AppendLog(msg, Color.Yellow);
        Action act = delegate
        {
            _progress.Value = step;
            _status.Text    = msg.Length > 80 ? msg.Substring(0, 77) + "..." : msg;
        };
        if (InvokeRequired) Invoke(act); else act();
    }

    void Done(bool success)
    {
        _installing = false;
        Action act = delegate
        {
            if (success) _progress.Value = 8;
            _status.Text      = success ? _L["success"] : _L["failed"];
            _status.ForeColor = success ? Color.LightGreen : Color.OrangeRed;
            _btnStart.Enabled = true;
            _btnStart.Text    = _L["restart"];
        };
        if (InvokeRequired) Invoke(act); else act();
    }

    void ShowError(string msg, string detail)
    {
        string full = msg;
        if (detail != null && detail.Length > 0) full += "\n\n" + detail;
        Invoke((Action)delegate
        {
            MessageBox.Show(this, full, "Bifrost Installer",
                            MessageBoxButtons.OK, MessageBoxIcon.Error);
        });
    }

    // ------------------------------------------------------------------
    //  Localized messages
    // ------------------------------------------------------------------
    static Dictionary<string,string> GetMessages(string lang)
    {
        Dictionary<string,string> d = new Dictionary<string,string>();

        if (lang == "FR")
        {
            d["title"]           = "Miyoo Bifrost — Installation";
            d["ready"]           = "Pret. Cliquez sur Demarrer pour installer.";
            d["start"]           = "Demarrer";
            d["restart"]         = "Recommencer";
            d["close"]           = "Fermer";
            d["selectSD"]        = "Selectionnez votre CARTE SD (ex: E:\\)";
            d["selectOnion"]     = "Selectionnez le dossier ONIONOS (ex: Onion-v4.3.1-1)";
            d["selectTelmi"]     = "Selectionnez le dossier TELMIOS (ex: TelmiOS_v1.10.1)";
            d["cancelled"]       = "Annule.";
            d["fat32Detected"]   = "Carte SD detectee";
            d["fat32Current"]    = "format actuel";
            d["fat32Warn"]       = "!! ATTENTION : La carte n'est pas en FAT32 !!";
            d["fat32Req"]        = "Le firmware Miyoo ne supporte que FAT32 pour demarrer.";
            d["fat32NoExfat"]    = "Une carte exFAT ou NTFS ne bootera PAS.";
            d["fat32Ask"]        = "Formater en FAT32 maintenant ?\n(Toutes les donnees seront effacees)";
            d["fat32Progress"]   = "  Formatage FAT32 en cours (diskpart)...";
            d["fat32Ok"]         = "FAT32 OK !";
            d["fat32Fail"]       = "ECHEC du formatage automatique.";
            d["fat32Rufus"]      = "Utilise Rufus manuellement : https://rufus.ie (FAT32, 32 Ko)";
            d["fat32RufusDetail"]= "Formate la carte avec Rufus (FAT32, 32 Ko) puis relance l'installeur.\nhttps://rufus.ie";
            d["fat32Abort"]      = "ARRET : Formate la carte en FAT32 avant de continuer.";
            d["fat32SkipWarn"]   = "La carte n'a pas ete formatee en FAT32.\nLe Miyoo Mini risque de ne pas demarrer correctement.";
            d["fat32SkipAsk"]    = "Continuer quand meme sans formater ?";
            d["fat32Skipped"]    = "[AVERT] Installation continuee sans FAT32 — la carte risque de ne pas booter.";
            d["fat32Good"]       = "FAT32 detecte — parfait !";
            d["step1"]           = "ETAPE 1/8 — Nettoyage de l'ancienne structure...";
            d["step2"]           = "ETAPE 2/8 — Installation du bootloader Bifrost...";
            d["step3"]           = "ETAPE 3/8 — Copie du fichier 'updater'...";
            d["step4"]           = "ETAPE 4/8 — Copie des binaires (bin/)...";
            d["step5"]           = "ETAPE 5/8 — Copie des librairies (lib/)...";
            d["step6_pre"]       = "ETAPE 6/8 — Installation de TelmiOS dans";
            d["step7_pre"]       = "ETAPE 7/8 — Installation de OnionOS dans";
            d["step8"]           = "ETAPE 8/8 — Generation des images du menu de boot...";
            d["slowCopy"]        = "(Peut prendre 1-2 minutes...)";
            d["slowMinutes"]     = "(Peut prendre quelques minutes...)";
            d["verif"]           = "Verification de la structure finale...";
            d["success"]         = "INSTALLATION REUSSIE !";
            d["failed"]          = "Installation incomplete.";
            d["eject"]           = "Ejecte la carte SD (clic droit > Ejecter)";
            d["insertSD"]        = "puis insere-la dans le Miyoo Mini / Mini Plus.";
            d["atBoot"]          = "Au demarrage :";
            d["navOS"]           = "D-pad gauche/droite = changer d'OS";
            d["confirm"]         = "A = confirmer";
            d["lastOS"]          = "B = relancer le dernier OS";
            d["missingFiles"]    = "fichier(s) manquant(s)";
            d["checkFolders"]    = "Verifie que les dossiers Onion* et Telmi*";
            d["checkSameDir"]    = "sont bien dans le meme dossier que cet installeur.";
            d["errBin"]          = "ERREUR : Dossier bin/ introuvable dans OnionOS";
            d["errBinDetail"]    = "Assure-toi d'avoir selectionne le bon dossier OnionOS.\nIl doit contenir miyoo\\app\\.tmp_update\\bin\\ ou .tmp_update\\bin\\.";
            d["errNoSD"]         = "ERREUR : Le chemin '{0}' n'est pas accessible !";
            d["errNoDual"]       = "ERREUR : Dossier DualBoot introuvable";
            d["errNoDualDetail"] = "Le dossier DualBoot doit se trouver dans le meme dossier que cet installeur.";
            d["logSaved"]        = "Log complet sauvegarde sur le Bureau";
            d["closeWarn"]       = "L'installation est en cours !\nFermer maintenant peut corrompre la carte SD.\n\nVraiment quitter ?";
            d["driveWarn"]       = "ATTENTION : Le lecteur selectionne n'est pas amovible.\nEs-tu sur de vouloir installer sur ce lecteur ?";
        }
        else if (lang == "EN")
        {
            d["title"]           = "Miyoo Bifrost — Installer";
            d["ready"]           = "Ready. Click Start to install.";
            d["start"]           = "Start";
            d["restart"]         = "Restart";
            d["close"]           = "Close";
            d["selectSD"]        = "Select your SD CARD folder (ex: E:\\)";
            d["selectOnion"]     = "Select the ONIONOS folder (ex: Onion-v4.3.1-1)";
            d["selectTelmi"]     = "Select the TELMIOS folder (ex: TelmiOS_v1.10.1)";
            d["cancelled"]       = "Cancelled.";
            d["fat32Detected"]   = "SD card detected";
            d["fat32Current"]    = "current format";
            d["fat32Warn"]       = "!! WARNING: The card is not FAT32 !!";
            d["fat32Req"]        = "The Miyoo firmware only supports FAT32 for booting.";
            d["fat32NoExfat"]    = "An exFAT or NTFS card will NOT boot.";
            d["fat32Ask"]        = "Format to FAT32 now?\n(All data will be erased)";
            d["fat32Progress"]   = "  Formatting to FAT32 (diskpart)...";
            d["fat32Ok"]         = "FAT32 OK!";
            d["fat32Fail"]       = "Automatic format failed.";
            d["fat32Rufus"]      = "Use Rufus manually: https://rufus.ie (FAT32, 32 KB)";
            d["fat32RufusDetail"]= "Format the card with Rufus (FAT32, 32 KB) then relaunch the installer.\nhttps://rufus.ie";
            d["fat32Abort"]      = "STOPPED: Format the card to FAT32 before continuing.";
            d["fat32SkipWarn"]   = "The card was not formatted to FAT32.\nThe Miyoo Mini may not boot correctly.";
            d["fat32SkipAsk"]    = "Continue anyway without formatting?";
            d["fat32Skipped"]    = "[WARN] Installation continued without FAT32 — the card may not boot.";
            d["fat32Good"]       = "FAT32 detected — perfect!";
            d["step1"]           = "STEP 1/8 — Cleaning old structure...";
            d["step2"]           = "STEP 2/8 — Installing Bifrost bootloader...";
            d["step3"]           = "STEP 3/8 — Copying 'updater' file...";
            d["step4"]           = "STEP 4/8 — Copying binaries (bin/)...";
            d["step5"]           = "STEP 5/8 — Copying libraries (lib/)...";
            d["step6_pre"]       = "STEP 6/8 — Installing TelmiOS into";
            d["step7_pre"]       = "STEP 7/8 — Installing OnionOS into";
            d["step8"]           = "STEP 8/8 — Generating boot menu images...";
            d["slowCopy"]        = "(May take 1-2 minutes...)";
            d["slowMinutes"]     = "(May take a few minutes...)";
            d["verif"]           = "Checking final structure...";
            d["success"]         = "INSTALLATION SUCCESSFUL!";
            d["failed"]          = "Installation incomplete.";
            d["eject"]           = "Eject the SD card (right-click > Eject)";
            d["insertSD"]        = "then insert it into your Miyoo Mini / Mini Plus.";
            d["atBoot"]          = "At startup:";
            d["navOS"]           = "D-pad left/right = switch OS";
            d["confirm"]         = "A = confirm";
            d["lastOS"]          = "B = relaunch last OS";
            d["missingFiles"]    = "missing file(s)";
            d["checkFolders"]    = "Make sure the Onion* and Telmi* folders";
            d["checkSameDir"]    = "are in the same folder as this installer.";
            d["errBin"]          = "ERROR: bin/ folder not found in OnionOS";
            d["errBinDetail"]    = "Make sure you selected the correct OnionOS folder.\nIt must contain miyoo\\app\\.tmp_update\\bin\\ or .tmp_update\\bin\\.";
            d["errNoSD"]         = "ERROR: Path '{0}' is not accessible!";
            d["errNoDual"]       = "ERROR: DualBoot folder not found";
            d["errNoDualDetail"] = "The DualBoot folder must be in the same directory as this installer.";
            d["logSaved"]        = "Full log saved to Desktop";
            d["closeWarn"]       = "Installation is in progress!\nClosing now may corrupt the SD card.\n\nReally quit?";
            d["driveWarn"]       = "WARNING: The selected drive is not removable.\nAre you sure you want to install to this drive?";
        }
        else // ES
        {
            d["title"]           = "Miyoo Bifrost — Instalacion";
            d["ready"]           = "Listo. Haz clic en Iniciar para instalar.";
            d["start"]           = "Iniciar";
            d["restart"]         = "Reiniciar";
            d["close"]           = "Cerrar";
            d["selectSD"]        = "Selecciona la carpeta de tu TARJETA SD (ej: E:\\)";
            d["selectOnion"]     = "Selecciona la carpeta ONIONOS (ej: Onion-v4.3.1-1)";
            d["selectTelmi"]     = "Selecciona la carpeta TELMIOS (ej: TelmiOS_v1.10.1)";
            d["cancelled"]       = "Cancelado.";
            d["fat32Detected"]   = "Tarjeta SD detectada";
            d["fat32Current"]    = "formato actual";
            d["fat32Warn"]       = "!! ATENCION: La tarjeta no esta en FAT32 !!";
            d["fat32Req"]        = "El firmware Miyoo solo soporta FAT32 para arrancar.";
            d["fat32NoExfat"]    = "Una tarjeta exFAT o NTFS NO arrancara.";
            d["fat32Ask"]        = "Formatear a FAT32 ahora?\n(Todos los datos seran borrados)";
            d["fat32Progress"]   = "  Formateando a FAT32 (diskpart)...";
            d["fat32Ok"]         = "FAT32 OK!";
            d["fat32Fail"]       = "Fallo el formateo automatico.";
            d["fat32Rufus"]      = "Usa Rufus manualmente: https://rufus.ie (FAT32, 32 KB)";
            d["fat32RufusDetail"]= "Formatea la tarjeta con Rufus (FAT32, 32 KB) y relanza el instalador.\nhttps://rufus.ie";
            d["fat32Abort"]      = "DETENIDO: Formatea la tarjeta en FAT32 antes de continuar.";
            d["fat32SkipWarn"]   = "La tarjeta no fue formateada en FAT32.\nEl Miyoo Mini puede no arrancar correctamente.";
            d["fat32SkipAsk"]    = "Continuar de todas formas sin formatear?";
            d["fat32Skipped"]    = "[AVERT] Instalacion continuada sin FAT32 — la tarjeta puede no arrancar.";
            d["fat32Good"]       = "FAT32 detectado — perfecto!";
            d["step1"]           = "PASO 1/8 — Limpiando estructura antigua...";
            d["step2"]           = "PASO 2/8 — Instalando bootloader Bifrost...";
            d["step3"]           = "PASO 3/8 — Copiando archivo 'updater'...";
            d["step4"]           = "PASO 4/8 — Copiando binarios (bin/)...";
            d["step5"]           = "PASO 5/8 — Copiando librerias (lib/)...";
            d["step6_pre"]       = "PASO 6/8 — Instalando TelmiOS en";
            d["step7_pre"]       = "PASO 7/8 — Instalando OnionOS en";
            d["step8"]           = "PASO 8/8 — Generando imagenes del menu de arranque...";
            d["slowCopy"]        = "(Puede tardar 1-2 minutos...)";
            d["slowMinutes"]     = "(Puede tardar unos minutos...)";
            d["verif"]           = "Verificando estructura final...";
            d["success"]         = "INSTALACION EXITOSA!";
            d["failed"]          = "Instalacion incompleta.";
            d["eject"]           = "Expulsa la tarjeta SD (clic derecho > Expulsar)";
            d["insertSD"]        = "luego insertala en tu Miyoo Mini / Mini Plus.";
            d["atBoot"]          = "Al encender:";
            d["navOS"]           = "D-pad izquierda/derecha = cambiar OS";
            d["confirm"]         = "A = confirmar";
            d["lastOS"]          = "B = relanzar el ultimo OS";
            d["missingFiles"]    = "archivo(s) faltante(s)";
            d["checkFolders"]    = "Verifica que las carpetas Onion* y Telmi*";
            d["checkSameDir"]    = "esten en la misma carpeta que este instalador.";
            d["errBin"]          = "ERROR: carpeta bin/ no encontrada en OnionOS";
            d["errBinDetail"]    = "Asegurate de haber seleccionado la carpeta OnionOS correcta.\nDebe contener miyoo\\app\\.tmp_update\\bin\\ o .tmp_update\\bin\\.";
            d["errNoSD"]         = "ERROR: La ruta '{0}' no es accesible!";
            d["errNoDual"]       = "ERROR: Carpeta DualBoot no encontrada";
            d["errNoDualDetail"] = "La carpeta DualBoot debe estar en el mismo directorio que este instalador.";
            d["logSaved"]        = "Log completo guardado en el Escritorio";
            d["closeWarn"]       = "La instalacion esta en curso!\nCerrar ahora puede corromper la tarjeta SD.\n\nRealmente salir?";
            d["driveWarn"]       = "ATENCION: La unidad seleccionada no es extraible.\nEstas seguro de querer instalar en esta unidad?";
        }

        return d;
    }
}
