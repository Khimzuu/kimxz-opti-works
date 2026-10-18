using System.Diagnostics;
using System.Text.Json;
using System.Text.Json.Nodes;
using Microsoft.Web.WebView2.WinForms;
using Microsoft.Web.WebView2.Core;

namespace KimXZ.OptiWorks;
internal static class Program {
 [STAThread] static void Main() { ApplicationConfiguration.Initialize(); Application.Run(new MainWindow()); }
}
public class MainWindow:Form {
 readonly WebView2 web=new(){Dock=DockStyle.Fill};
 readonly string root=Path.GetFullPath(Path.Combine(AppContext.BaseDirectory,"..","..","..","..",".."));
 readonly string stateDir=Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),"kim.xz-opti-works","jobs");
 string? jobId; Process? proc; System.Windows.Forms.Timer poll = new(){Interval=600};
 static readonly Dictionary<string,(string[] ops,bool elevate)> Tasks=new(){
 ["quick"]=(new[]{"inventory","temp","dns","startup-report"},false),
 ["balanced"]=(new[]{"inventory","temp","dns","visuals","storage-report","startup-report"},false),
 ["gaming"]=(new[]{"inventory","temp","dns","visuals","game-mode","startup-report","power-report"},false),
 ["deep"]=(new[]{"inventory","temp","dns","visuals","game-mode","storage-report","startup-report","power-report","disk-optimize"},true),
 ["cleanup"]=(new[]{"temp","dns","storage-report"},false),
 ["visuals"]=(new[]{"visuals"},false),
 ["storage"]=(new[]{"storage-report","disk-optimize"},true),
 ["gaming-group"]=(new[]{"game-mode","startup-report","power-report"},false),
 ["power"]=(new[]{"power-report","startup-report"},false),
 ["diagnostics"]=(new[]{"inventory","storage-report","power-report"},false),
 ["undo"]=(new[]{"undo"},false),
 ["sfc"]=(new[]{"sfc"},true),["dism"]=(new[]{"dism"},true),
 ["restore-point"]=(new[]{"restore-point"},true),
 ["disk-optimize"]=(new[]{"disk-optimize"},true)
 };
 public MainWindow(){Text="kim.xz OPTI WORKS | V1.04"; MinimumSize=new Size(970,650); Size=new Size(1450,900); StartPosition=FormStartPosition.CenterScreen; BackColor=Color.FromArgb(5,6,8); Controls.Add(web);
 Shown+=async (_,__)=>{try{await web.EnsureCoreWebView2Async(); web.CoreWebView2.Settings.AreDevToolsEnabled=false; web.CoreWebView2.WebMessageReceived+=OnMessage; var frontend=Path.Combine(root,"frontend","index.html"); if(!File.Exists(frontend))throw new FileNotFoundException(frontend); web.Source=new Uri(frontend); poll.Tick+=(_,__)=>TickJob();poll.Start();}catch(Exception ex){MessageBox.Show("WebView2 runtime missing or app files incomplete.\n"+ex.Message,"Startup problem");Close();}};
 FormClosing+=(_,args)=>{ if(proc is {HasExited:false}) { var result=MessageBox.Show("An optimization is running. Closing the window will not stop it. Close anyway?","Active task",MessageBoxButtons.YesNo);if(result==DialogResult.No) args.Cancel=true; } };
 }
 void Send(object data){if(web.CoreWebView2!=null)web.CoreWebView2.PostWebMessageAsJson(JsonSerializer.Serialize(data));}
 void OnMessage(object? sender,CoreWebView2WebMessageReceivedEventArgs e){
 try{var msg=JsonNode.Parse(e.WebMessageAsJson);var type=msg?["type"]?.GetValue<string>();
 if(type=="run"){var id=msg?["id"]?.GetValue<string>()??"";StartTask(id);}
 else if(type=="inventory"){StartTask("diagnostics");}
 else if(type=="openLogs") {var p=Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),"kim.xz-opti-works");Directory.CreateDirectory(p);Process.Start(new ProcessStartInfo("explorer.exe",$"\"{p}\""){UseShellExecute=true});}
 else if(type=="openStartup")Process.Start(new ProcessStartInfo("explorer.exe","shell:startup"){UseShellExecute=true});
 }catch(Exception ex){Send(new{type="error",message=ex.Message});}
 }
 void StartTask(string id){
 if(proc is {HasExited:false}) {Send(new{type="error",message="Another task is running. Wait for it to finish."});return;}
 if(!Tasks.TryGetValue(id,out var task)){Send(new{type="error",message="Unknown task"});return;}
 if(id is "deep" or "disk-optimize" or "storage" or "sfc" or "dism" or "restore-point") {
 var prompt=id=="deep"?"Deep Tune includes Windows-managed drive optimization and may take some time. Continue?":$"Run {id}? This operation may take a long time or require administrator permission.";
 if(MessageBox.Show(prompt,"Confirm operation",MessageBoxButtons.YesNo,MessageBoxIcon.Warning)!=DialogResult.Yes)return;
 }
 Directory.CreateDirectory(stateDir);jobId=Guid.NewGuid().ToString("N");
 var spec=Path.Combine(stateDir,jobId+".json"); File.WriteAllText(spec,JsonSerializer.Serialize(new{operations=task.ops,id}));
 var worker=Path.Combine(root,"backend","worker.ps1");if(!File.Exists(worker)){Send(new{type="error",message="Missing backend/worker.ps1"});return;}
 var psi=new ProcessStartInfo("powershell.exe") {UseShellExecute=true,Verb=task.elevate?"runas":"",WindowStyle=ProcessWindowStyle.Hidden,WorkingDirectory=root};
 psi.ArgumentList.Add("-NoProfile");psi.ArgumentList.Add("-NonInteractive");psi.ArgumentList.Add("-WindowStyle");psi.ArgumentList.Add("Hidden");psi.ArgumentList.Add("-File");psi.ArgumentList.Add(worker);psi.ArgumentList.Add("-JobFile");psi.ArgumentList.Add(spec);
 try{proc=Process.Start(psi);Send(new{type="started",id,jobId});}catch(System.ComponentModel.Win32Exception ex) {jobId=null;Send(new{type="error",message=ex.NativeErrorCode==1223?"Administrator permission was declined.":ex.Message});}catch(Exception ex){jobId=null;Send(new{type="error",message=ex.Message});}
 }
 void TickJob(){if(jobId==null)return;try{
 var path=Path.Combine(stateDir,jobId+".events.jsonl");if(File.Exists(path)){var lines=File.ReadAllLines(path);var evts=new List<JsonNode>();foreach(var line in lines){try{var v=JsonNode.Parse(line);if(v!=null)evts.Add(v);}catch {}}Send(new{type="events",events=evts});}
 if(proc==null || proc.HasExited){var result=proc?.ExitCode??-1;Send(new{type="ended",exitCode=result});jobId=null;proc?.Dispose();proc=null;}
 }catch(Exception ex){Send(new{type="error",message=ex.Message});}}
}
