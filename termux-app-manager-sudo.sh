#!/usr/bin/env sh
set -eu

mkdir -p ".termux-app-manager"
cd ".termux-app-manager"

PROJECT_NAME="${1:-termux-app-manager-ui-demo}"

if ! command -v cargo >/dev/null 2>&1; then
  echo "错误：未找到 cargo。请先在 Termux 里安装 Rust："
  echo "  pkg install rust"
  exit 1
fi

write_if_changed() {
  target="$1"
  tmp="${target}.tmp.$$"

  cat >"$tmp"

  if [ -f "$target" ] && cmp -s "$target" "$tmp"; then
    rm "$tmp"
    echo "未变化：$target"
  else
    mv "$tmp" "$target"
    echo "已更新：$target"
  fi
}

if [ -d "$PROJECT_NAME" ]; then
  if [ ! -f "$PROJECT_NAME/Cargo.toml" ]; then
    echo "错误：目录 '$PROJECT_NAME' 已存在，但它不是 Cargo 项目。"
    exit 1
  fi
  echo "检测到项目已存在：$PROJECT_NAME"
else
  if [ -e "$PROJECT_NAME" ]; then
    echo "错误：'$PROJECT_NAME' 已存在，但不是目录。"
    exit 1
  fi
  cargo new "$PROJECT_NAME" --bin
fi

cd "$PROJECT_NAME"
mkdir -p src

if [ ! -f whitelist.txt ]; then
  cat >whitelist.txt <<'EOF'
# 用户白名单：冻结全部、冻结、卸载时会跳过这些包名
# 一行一个包名，# 开头是注释
# 没有代码内置强制保护名单，保护完全由这个文件控制。

com.termux
com.termux.api
com.termux.boot
com.termux.gui
com.termux.widget
com.termux.window
com.android.settings
com.android.systemui
com.android.permissioncontroller
com.google.android.inputmethod.latin
com.android.vending
com.google.android.gms
com.google.android.dialer
com.google.android.contacts
com.google.android.apps.messaging
EOF
fi

if [ ! -f app_aliases.txt ]; then
  cat >app_aliases.txt <<'EOF'
# 应用别名：用于把动态获取到的包名显示成更好读的名称
# 格式：包名=显示名

com.android.settings=Settings
com.android.vending=Play Store
com.sonyericsson.android.camera=Camera
com.sonymobile.photopro=Photo Pro
com.sonymobile.cinemapro=Cinema Pro
com.sonymobile.susrescheck=Sony SusResCheck
com.android.chrome=Chrome
com.google.android.apps.messaging=Messages
com.google.android.apps.photos=Photos
com.google.android.calculator=Calculator
com.google.android.contacts=Contacts
com.google.android.deskclock=Clock
com.google.android.dialer=Dialer
com.google.android.gm=Gmail
com.google.android.youtube=YouTube
com.google.android.apps.nbu.files=Files
com.google.android.apps.googleassistant=Assistant
com.google.android.googlequicksearchbox=Google
com.google.android.inputmethod.latin=Gboard
com.omarea.vtools=VTools
com.eg.android.AlipayGphone=Alipay
com.taobao.taobao=Taobao
com.tencent.mm=WeChat
com.tencent.qqmusic=QQ Music
com.tencent.lolm=LoL Mobile
com.termux=Termux
com.termux.api=Termux API
com.termux.boot=Termux Boot
com.termux.gui=Termux GUI
com.termux.widget=Termux Widget
com.termux.window=Termux Float
com.maazm7d.termuxhub=TermuxHub
com.limelight.qiin=Moonlight
com.resukisu.resukisu=ResuKisu
notion.id=Notion
tv.danmaku.bili=Bilibili
EOF
fi

write_if_changed Cargo.toml <<'EOF'
[package]
name = "termux-app-manager-ui-demo"
version = "0.1.0"
edition = "2021"

[dependencies]
ratatui = "0.30.1"
crossterm = "0.29"
EOF

write_if_changed src/main.rs <<'EOF'
use std::{
    collections::{HashMap, HashSet, VecDeque},
    error::Error,
    fs,
    io::{self, Stdout},
    process::Command,
    sync::mpsc::{self, Receiver},
    thread,
    time::{Duration, Instant},
};

use crossterm::{
    event::{
        self, DisableFocusChange, DisableMouseCapture, EnableFocusChange, EnableMouseCapture,
        Event, KeyCode, KeyEventKind, MouseButton, MouseEvent, MouseEventKind,
    },
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};

use ratatui::{
    backend::CrosstermBackend,
    layout::{Alignment, Constraint, Direction, Layout, Rect},
    style::{Color, Modifier, Style},
    text::{Line, Span},
    widgets::{Block, Borders, Clear, Paragraph, Wrap},
    Frame, Terminal,
};

type AppResult<T> = Result<T, Box<dyn Error>>;

const MAX_LOGS: usize = 240;
const CLICK_MOVE_TOLERANCE: u16 = 2;
const ROOT_CMD: &str = "sudo";
const USER_WHITELIST_FILE: &str = "whitelist.txt";
const APP_ALIASES_FILE: &str = "app_aliases.txt";

fn main() -> AppResult<()> {
    let mut tui = Tui::new()?;
    let mut app = App::new();

    app.log_info("Session started");
    app.log_info(format!("Current Android user: {}", app.current_user));
    app.log_warn("Real command mode enabled. Dangerous actions use popup confirmation.");
    app.reload_apps_and_statuses();

    while app.running {
        app.tick();

        tui.terminal.draw(|frame| ui(frame, &mut app))?;

        if event::poll(Duration::from_millis(50))? {
            let ev = event::read()?;
            app.handle_event(ev);
        }
    }

    Ok(())
}

struct Tui {
    terminal: Terminal<CrosstermBackend<Stdout>>,
}

impl Tui {
    fn new() -> AppResult<Self> {
        enable_raw_mode()?;

        let mut stdout = io::stdout();

        execute!(
            stdout,
            EnterAlternateScreen,
            EnableMouseCapture,
            EnableFocusChange
        )?;

        let backend = CrosstermBackend::new(stdout);
        let terminal = Terminal::new(backend)?;

        Ok(Self { terminal })
    }
}

impl Drop for Tui {
    fn drop(&mut self) {
        let _ = disable_raw_mode();

        let _ = execute!(
            self.terminal.backend_mut(),
            LeaveAlternateScreen,
            DisableMouseCapture,
            DisableFocusChange
        );

        let _ = self.terminal.show_cursor();
    }
}

#[derive(Debug, Clone)]
struct CmdResult {
    success: bool,
    code: Option<i32>,
    stdout: String,
    stderr: String,
}

impl CmdResult {
    fn summary(&self) -> String {
        let stdout = self.stdout.trim();
        let stderr = self.stderr.trim();

        if !stdout.is_empty() {
            short_text(stdout, 180)
        } else if !stderr.is_empty() {
            short_text(stderr, 180)
        } else {
            format!("exit_code={:?}", self.code)
        }
    }
}

fn run_command(program: &str, args: &[String]) -> CmdResult {
    match Command::new(program).args(args).output() {
        Ok(output) => CmdResult {
            success: output.status.success(),
            code: output.status.code(),
            stdout: String::from_utf8_lossy(&output.stdout).to_string(),
            stderr: String::from_utf8_lossy(&output.stderr).to_string(),
        },
        Err(err) => CmdResult {
            success: false,
            code: None,
            stdout: String::new(),
            stderr: err.to_string(),
        },
    }
}

fn format_command(program: &str, args: &[String]) -> String {
    let mut parts = Vec::new();
    parts.push(program.to_string());
    parts.extend(args.iter().cloned());
    parts.join(" ")
}

fn detect_current_user() -> String {
    let args = vec!["get-current-user".to_string()];
    let result = run_command("am", &args);

    let value = result.stdout.trim();

    if result.success && !value.is_empty() {
        value.to_string()
    } else {
        "0".to_string()
    }
}

fn query_launcher_activities(current_user: &str) -> CmdResult {
    let args = vec![
        "package".to_string(),
        "query-activities".to_string(),
        "--user".to_string(),
        current_user.to_string(),
        "--brief".to_string(),
        "-a".to_string(),
        "android.intent.action.MAIN".to_string(),
        "-c".to_string(),
        "android.intent.category.LAUNCHER".to_string(),
    ];

    let result = run_command("cmd", &args);
    if result.success && !result.stdout.trim().is_empty() {
        return result;
    }

    let mut sudo_args = vec!["cmd".to_string()];
    sudo_args.extend(args);

    run_command(ROOT_CMD, &sudo_args)
}

fn query_package_list(current_user: &str, disabled_only: bool) -> CmdResult {
    let mut args = vec![
        "package".to_string(),
        "list".to_string(),
        "packages".to_string(),
        "--user".to_string(),
        current_user.to_string(),
    ];

    if disabled_only {
        args.push("-d".to_string());
    }

    let result = run_command("cmd", &args);

    if disabled_only {
        if result.success {
            return result;
        }
    } else if result.success && !result.stdout.trim().is_empty() {
        return result;
    }

    let mut sudo_args = vec!["cmd".to_string()];
    sudo_args.extend(args);

    run_command(ROOT_CMD, &sudo_args)
}

fn parse_launcher_components(output: &str) -> Vec<String> {
    let mut seen = HashSet::new();
    let mut result = Vec::new();

    for raw in output.lines() {
        let line = raw.trim();

        if line.is_empty() || line.contains("activities found") {
            continue;
        }

        let candidate = line
            .split_whitespace()
            .last()
            .unwrap_or(line)
            .trim()
            .trim_matches(':');

        if !candidate.contains('/') || !candidate.contains('.') {
            continue;
        }

        let component = candidate.to_string();

        if seen.insert(component.clone()) {
            result.push(component);
        }
    }

    result
}

fn parse_package_list(output: &str) -> HashSet<String> {
    output
        .lines()
        .filter_map(|line| {
            let line = line.trim();

            if line.is_empty() {
                return None;
            }

            let line = line.strip_prefix("package:").unwrap_or(line);

            let pkg = match line.rsplit_once('=') {
                Some((_, pkg)) => pkg,
                None => line,
            };

            let pkg = pkg.trim();

            if pkg.is_empty() {
                None
            } else {
                Some(pkg.to_string())
            }
        })
        .collect()
}

fn load_simple_set_file(path: &str) -> HashSet<String> {
    let text = fs::read_to_string(path).unwrap_or_default();

    text.lines()
        .filter_map(|line| {
            let clean = line.split('#').next().unwrap_or("").trim();

            if clean.is_empty() {
                None
            } else {
                Some(clean.to_string())
            }
        })
        .collect()
}

fn save_whitelist(set: &HashSet<String>) -> Result<(), String> {
    let mut packages: Vec<String> = set.iter().cloned().collect();
    packages.sort();

    let mut text = String::new();
    text.push_str("# 用户白名单：冻结全部、冻结、卸载时会跳过这些包名\n");
    text.push_str("# 一行一个包名，# 开头是注释\n\n");

    for package in packages {
        text.push_str(&package);
        text.push('\n');
    }

    fs::write(USER_WHITELIST_FILE, text).map_err(|err| err.to_string())
}

fn load_aliases() -> HashMap<String, String> {
    let text = fs::read_to_string(APP_ALIASES_FILE).unwrap_or_default();
    let mut map = HashMap::new();

    for raw in text.lines() {
        let clean = raw.split('#').next().unwrap_or("").trim();

        if clean.is_empty() {
            continue;
        }

        let Some((package, alias)) = clean.split_once('=') else {
            continue;
        };

        let package = package.trim();
        let alias = alias.trim();

        if !package.is_empty() && !alias.is_empty() {
            map.insert(package.to_string(), alias.to_string());
        }
    }

    map
}

fn save_aliases(map: &HashMap<String, String>) -> Result<(), String> {
    let mut pairs: Vec<(String, String)> = map
        .iter()
        .map(|(package, alias)| (package.clone(), alias.clone()))
        .collect();

    pairs.sort_by(|a, b| a.0.cmp(&b.0));

    let mut text = String::new();
    text.push_str("# 应用别名：用于把动态获取到的包名显示成更好读的名称\n");
    text.push_str("# 格式：包名=显示名\n\n");

    for (package, alias) in pairs {
        text.push_str(&package);
        text.push('=');
        text.push_str(&alias);
        text.push('\n');
    }

    fs::write(APP_ALIASES_FILE, text).map_err(|err| err.to_string())
}

fn package_from_component(component: &str) -> String {
    match component.split_once('/') {
        Some((pkg, _)) => pkg.to_string(),
        None => component.to_string(),
    }
}

fn display_name_for(package: &str, component: Option<&str>, aliases: &HashMap<String, String>) -> String {
    if let Some(alias) = aliases.get(package) {
        return alias.clone();
    }

    if let Some(component) = component {
        return short_activity_name(component);
    }

    titleish(package.rsplit('.').next().unwrap_or(package))
}

fn short_activity_name(component: &str) -> String {
    let package = package_from_component(component);

    let pkg_tail = package
        .rsplit('.')
        .next()
        .unwrap_or(package.as_str())
        .trim();

    let activity = component
        .split_once('/')
        .map(|(_, a)| a)
        .unwrap_or("")
        .trim_start_matches('.');

    let act_tail = activity
        .rsplit('.')
        .next()
        .unwrap_or(activity)
        .trim();

    if act_tail.is_empty()
        || act_tail.eq_ignore_ascii_case("MainActivity")
        || act_tail.eq_ignore_ascii_case("LauncherActivity")
        || act_tail.eq_ignore_ascii_case("HomeActivity")
    {
        titleish(pkg_tail)
    } else {
        format!("{}:{}", titleish(pkg_tail), short_text(act_tail, 12))
    }
}

fn titleish(s: &str) -> String {
    let s = s.replace('_', " ").replace('-', " ");
    let mut chars = s.chars();

    match chars.next() {
        Some(first) => format!("{}{}", first.to_uppercase(), chars.collect::<String>()),
        None => "App".to_string(),
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum AppStatus {
    Running,
    Frozen,
    Removed,
}

impl AppStatus {
    fn label(self) -> &'static str {
        match self {
            AppStatus::Running => "运行中",
            AppStatus::Frozen => "已冻结",
            AppStatus::Removed => "已卸载",
        }
    }

    fn color(self) -> Color {
        match self {
            AppStatus::Running => Color::LightGreen,
            AppStatus::Frozen => Color::LightBlue,
            AppStatus::Removed => Color::LightRed,
        }
    }
}

#[derive(Debug, Clone)]
struct AppEntry {
    name: String,
    package: String,
    component: Option<String>,
    status: AppStatus,
}

#[derive(Debug, Clone, Copy)]
struct PointerDown {
    column: u16,
    row: u16,
    button: MouseButton,
}

#[derive(Debug, Clone, Copy)]
struct AppHitBox {
    app_index: usize,
    rect: Rect,
}

#[derive(Debug, Clone, Copy)]
struct ActionHitBox {
    action: ActionKind,
    rect: Rect,
}

#[derive(Debug, Clone, Copy)]
struct DialogHitBox {
    dialog_rect: Rect,
    cancel_rect: Rect,
    confirm_rect: Rect,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum DialogClick {
    Cancel,
    Confirm,
    Inside,
    Outside,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum ActionKind {
    Freeze,
    Launch,
    Uninstall,
    FreezeAll,
    UnfreezeAll,
}

impl ActionKind {
    fn block_bg(self) -> Color {
        match self {
            ActionKind::Freeze => Color::Rgb(25, 95, 180),
            ActionKind::Launch => Color::Rgb(25, 140, 90),
            ActionKind::Uninstall => Color::Rgb(170, 45, 55),
            ActionKind::FreezeAll => Color::Rgb(190, 130, 25),
            ActionKind::UnfreezeAll => Color::Rgb(20, 135, 150),
        }
    }

    fn symbol(self) -> &'static str {
        match self {
            ActionKind::Freeze => "[*]",
            ActionKind::Launch => "[>]",
            ActionKind::Uninstall => "[x]",
            ActionKind::FreezeAll => "[**]",
            ActionKind::UnfreezeAll => "[~]",
        }
    }

    fn all() -> [ActionKind; 5] {
        [
            ActionKind::Freeze,
            ActionKind::Launch,
            ActionKind::Uninstall,
            ActionKind::FreezeAll,
            ActionKind::UnfreezeAll,
        ]
    }
}

#[derive(Debug, Clone)]
struct ConfirmDialog {
    action: ActionKind,
    title: String,
    lines: Vec<String>,
    targets: Vec<String>,
    color: Color,
    confirm_label: String,
    cancel_label: String,
}

#[derive(Debug, Clone)]
struct RenameDialog {
    package: String,
    old_name: String,
    input: String,
}

#[derive(Default, Debug, Clone)]
struct TargetPreview {
    targets: Vec<String>,
    skipped_whitelist: u64,
    skipped_removed: u64,
    skipped_frozen: u64,
    skipped_running: u64,
}

#[derive(Debug, Clone)]
struct JobProgress {
    package: String,
    name: String,
    success: bool,
    summary: String,
}

enum JobEvent {
    Progress(JobProgress),
    Finished,
}

struct RunningJob {
    action: ActionKind,
    title: String,
    total: usize,
    done: usize,
    ok: usize,
    fail: usize,
    current: String,
    last_message: String,
    color: Color,
    rx: Receiver<JobEvent>,
    finished_at: Option<Instant>,
    refreshed: bool,
}

impl RunningJob {
    fn ratio(&self) -> f64 {
        if self.total == 0 {
            1.0
        } else {
            (self.done as f64 / self.total as f64).clamp(0.0, 1.0)
        }
    }

    fn finished(&self) -> bool {
        self.finished_at.is_some()
    }
}

struct App {
    running: bool,
    current_user: String,

    apps: Vec<AppEntry>,
    selected: usize,
    scroll: usize,
    visible_rows: usize,

    app_hit_boxes: Vec<AppHitBox>,
    action_hit_boxes: Vec<ActionHitBox>,
    app_list_inner: Option<Rect>,
    dialog_hit_box: Option<DialogHitBox>,
    pointer_down: Option<PointerDown>,

    user_whitelist: HashSet<String>,
    aliases: HashMap<String, String>,
    confirm_dialog: Option<ConfirmDialog>,
    rename_dialog: Option<RenameDialog>,
    running_job: Option<RunningJob>,

    logs: VecDeque<String>,
    last_event: String,

    freeze_count: u64,
    launch_count: u64,
    uninstall_count: u64,
    freeze_all_count: u64,
    unfreeze_all_count: u64,
    select_count: u64,
}

impl App {
    fn new() -> Self {
        Self {
            running: true,
            current_user: detect_current_user(),

            apps: Vec::new(),
            selected: 0,
            scroll: 0,
            visible_rows: 1,

            app_hit_boxes: Vec::new(),
            action_hit_boxes: Vec::new(),
            app_list_inner: None,
            dialog_hit_box: None,
            pointer_down: None,

            user_whitelist: load_simple_set_file(USER_WHITELIST_FILE),
            aliases: load_aliases(),
            confirm_dialog: None,
            rename_dialog: None,
            running_job: None,

            logs: VecDeque::with_capacity(MAX_LOGS),
            last_event: "暂无事件".to_string(),

            freeze_count: 0,
            launch_count: 0,
            uninstall_count: 0,
            freeze_all_count: 0,
            unfreeze_all_count: 0,
            select_count: 0,
        }
    }

    fn tick(&mut self) {
        let mut events = Vec::new();

        if let Some(job) = self.running_job.as_mut() {
            loop {
                match job.rx.try_recv() {
                    Ok(ev) => events.push(ev),
                    Err(_) => break,
                }
            }
        }

        for ev in events {
            self.handle_job_event(ev);
        }

        let should_close = self
            .running_job
            .as_ref()
            .and_then(|job| job.finished_at)
            .map(|at| at.elapsed() >= Duration::from_millis(1400))
            .unwrap_or(false);

        if should_close {
            self.running_job = None;
            self.log_info("Execution popup closed");
        }
    }

    fn handle_job_event(&mut self, ev: JobEvent) {
        match ev {
            JobEvent::Progress(progress) => {
                let action = self.running_job.as_ref().map(|job| job.action);

                if let Some(job) = self.running_job.as_mut() {
                    job.done += 1;

                    if progress.success {
                        job.ok += 1;
                    } else {
                        job.fail += 1;
                    }

                    job.current = progress.name.clone();
                    job.last_message = progress.summary.clone();
                }

                if progress.success {
                    if let Some(action) = action {
                        match action {
                            ActionKind::Uninstall => {
                                self.set_status_for_package(&progress.package, AppStatus::Removed);
                            }
                            ActionKind::FreezeAll => {
                                self.set_status_for_package(&progress.package, AppStatus::Frozen);
                            }
                            ActionKind::UnfreezeAll => {
                                self.set_status_for_package(&progress.package, AppStatus::Running);
                            }
                            _ => {}
                        }
                    }
                }

                if progress.success {
                    self.log_success(format!(
                        "Job OK: {} | {}",
                        progress.name, progress.summary
                    ));
                } else {
                    self.log_error(format!(
                        "Job FAILED: {} | {}",
                        progress.name, progress.summary
                    ));
                }
            }

            JobEvent::Finished => {
                let mut should_refresh = false;
                let mut summary = None;

                if let Some(job) = self.running_job.as_mut() {
                    job.finished_at = Some(Instant::now());

                    if !job.refreshed {
                        job.refreshed = true;
                        should_refresh = true;
                    }

                    summary = Some(format!(
                        "Execution finished: {} | ok={} fail={} total={}",
                        job.title, job.ok, job.fail, job.total
                    ));
                }

                if let Some(summary) = summary {
                    self.log_success(summary);
                }

                if should_refresh {
                    self.refresh_statuses_from_system();
                }
            }
        }
    }

    fn selected_app(&self) -> Option<&AppEntry> {
        self.apps.get(self.selected)
    }

    fn log(&mut self, level: &str, msg: impl Into<String>) {
        let text = format!("{:<7} | {}", level, msg.into());
        self.last_event = text.clone();

        if self.logs.len() >= MAX_LOGS {
            self.logs.pop_front();
        }

        self.logs.push_back(text);
    }

    fn log_info(&mut self, msg: impl Into<String>) {
        self.log("INFO", msg);
    }

    fn log_success(&mut self, msg: impl Into<String>) {
        self.log("SUCCESS", msg);
    }

    fn log_warn(&mut self, msg: impl Into<String>) {
        self.log("WARN", msg);
    }

    fn log_error(&mut self, msg: impl Into<String>) {
        self.log("ERROR", msg);
    }

    fn reload_config(&mut self) {
        self.user_whitelist = load_simple_set_file(USER_WHITELIST_FILE);
        self.aliases = load_aliases();

        self.log_info(format!(
            "Config reloaded: whitelist={} aliases={}",
            self.user_whitelist.len(),
            self.aliases.len()
        ));
    }

    fn reload_apps_and_statuses(&mut self) {
        self.reload_config();

        let old_selected_package = self.selected_app().map(|app| app.package.clone());

        let mut old_by_package: HashMap<String, AppEntry> = HashMap::new();
        for app in &self.apps {
            old_by_package
                .entry(app.package.clone())
                .or_insert_with(|| app.clone());
        }

        let launcher_result = query_launcher_activities(&self.current_user);

        if !launcher_result.success {
            self.log_error(format!(
                "Failed to query launcher activities: {}",
                launcher_result.summary()
            ));
            return;
        }

        let components = parse_launcher_components(&launcher_result.stdout);
        let disabled_result = query_package_list(&self.current_user, true);

        let disabled_packages = if disabled_result.success {
            parse_package_list(&disabled_result.stdout)
        } else {
            HashSet::new()
        };

        let mut apps = Vec::new();
        let mut seen_components = HashSet::new();
        let mut seen_packages = HashSet::new();

        for component in components {
            if !seen_components.insert(component.clone()) {
                continue;
            }

            let package = package_from_component(&component);
            let name = display_name_for(&package, Some(&component), &self.aliases);

            seen_packages.insert(package.clone());

            apps.push(AppEntry {
                name,
                package,
                component: Some(component),
                status: AppStatus::Running,
            });
        }

        for package in &disabled_packages {
            if seen_packages.contains(package) {
                continue;
            }

            if let Some(old) = old_by_package.get(package) {
                let mut entry = old.clone();
                entry.name =
                    display_name_for(&entry.package, entry.component.as_deref(), &self.aliases);
                entry.status = AppStatus::Frozen;
                apps.push(entry);
            } else {
                let name = display_name_for(package, None, &self.aliases);

                apps.push(AppEntry {
                    name,
                    package: package.clone(),
                    component: None,
                    status: AppStatus::Frozen,
                });
            }
        }

        apps.sort_by(|a, b| {
            a.name
                .to_lowercase()
                .cmp(&b.name.to_lowercase())
                .then(a.package.cmp(&b.package))
        });

        self.apps = apps;
        self.refresh_statuses_from_system();

        if let Some(pkg) = old_selected_package {
            if let Some(pos) = self.apps.iter().position(|app| app.package == pkg) {
                self.selected = pos;
            } else {
                self.selected = 0;
            }
        } else {
            self.selected = 0;
        }

        self.ensure_selected_visible();

        self.log_success(format!("Apps reloaded: {}", self.apps.len()));
    }

    fn refresh_statuses_from_system(&mut self) {
        let installed_result = query_package_list(&self.current_user, false);

        if !installed_result.success {
            self.log_error(format!(
                "Status refresh failed: cannot list installed packages | {}",
                installed_result.summary()
            ));
            return;
        }

        let installed_packages = parse_package_list(&installed_result.stdout);

        if installed_packages.is_empty() {
            self.log_warn("Status refresh skipped: installed package list is empty");
            return;
        }

        let disabled_result = query_package_list(&self.current_user, true);

        let disabled_packages = if disabled_result.success {
            parse_package_list(&disabled_result.stdout)
        } else {
            HashSet::new()
        };

        let mut running = 0u64;
        let mut frozen = 0u64;
        let mut removed = 0u64;

        for app in &mut self.apps {
            if !installed_packages.contains(&app.package) {
                app.status = AppStatus::Removed;
                removed += 1;
            } else if disabled_packages.contains(&app.package) {
                app.status = AppStatus::Frozen;
                frozen += 1;
            } else {
                app.status = AppStatus::Running;
                running += 1;
            }
        }

        self.log_info(format!(
            "Status refreshed: running={} frozen={} removed={} total={}",
            running,
            frozen,
            removed,
            self.apps.len()
        ));
    }

    fn clear_logs(&mut self) {
        self.logs.clear();
        self.last_event = "INFO    | Logs cleared".to_string();
    }

    fn ensure_selected_visible(&mut self) {
        if self.apps.is_empty() {
            self.selected = 0;
            self.scroll = 0;
            return;
        }

        if self.selected >= self.apps.len() {
            self.selected = self.apps.len().saturating_sub(1);
        }

        let visible = self.visible_rows.max(1);

        if self.selected < self.scroll {
            self.scroll = self.selected;
        } else if self.selected >= self.scroll + visible {
            self.scroll = self.selected + 1 - visible;
        }

        let max_scroll = self.apps.len().saturating_sub(visible);
        if self.scroll > max_scroll {
            self.scroll = max_scroll;
        }
    }

    fn move_selection(&mut self, delta: i32) {
        if self.apps.is_empty() {
            return;
        }

        let old = self.selected;
        let max = self.apps.len().saturating_sub(1) as i32;
        let next = (self.selected as i32 + delta).clamp(0, max) as usize;

        self.selected = next;
        self.ensure_selected_visible();

        if old != next {
            if let Some(app) = self.selected_app() {
                self.log_info(format!(
                    "Selection -> [{}] {} ({})",
                    self.selected + 1,
                    app.name,
                    app.status.label()
                ));
            }
        }
    }

    fn toggle_whitelist_selected(&mut self) {
        let Some(app) = self.selected_app() else {
            return;
        };

        let package = app.package.clone();
        let name = app.name.clone();

        if self.user_whitelist.contains(&package) {
            self.user_whitelist.remove(&package);

            match save_whitelist(&self.user_whitelist) {
                Ok(_) => self.log_info(format!("Removed from whitelist: {} | {}", name, package)),
                Err(err) => self.log_error(format!("Failed to save whitelist: {}", err)),
            }
        } else {
            self.user_whitelist.insert(package.clone());

            match save_whitelist(&self.user_whitelist) {
                Ok(_) => self.log_success(format!("Added to whitelist: {} | {}", name, package)),
                Err(err) => self.log_error(format!("Failed to save whitelist: {}", err)),
            }
        }
    }

    fn open_rename_dialog(&mut self) {
        let Some(app) = self.selected_app() else {
            self.log_warn("Rename skipped: no selected app");
            return;
        };

        let package = app.package.clone();
        let old_name = app.name.clone();

        self.rename_dialog = Some(RenameDialog {
            package: package.clone(),
            old_name: old_name.clone(),
            input: old_name.clone(),
        });

        self.log_info(format!("Rename dialog opened: {} | {}", old_name, package));
    }

    fn save_rename_dialog(&mut self) {
        let Some(dialog) = self.rename_dialog.take() else {
            return;
        };

        let new_name = dialog.input.trim().to_string();

        if new_name.is_empty() {
            self.rename_dialog = Some(dialog);
            self.log_error("Rename failed: name cannot be empty");
            return;
        }

        self.aliases.insert(dialog.package.clone(), new_name.clone());

        match save_aliases(&self.aliases) {
            Ok(_) => {
                for app in &mut self.apps {
                    if app.package == dialog.package {
                        app.name = new_name.clone();
                    }
                }

                self.log_success(format!(
                    "Renamed: {} -> {} | {}",
                    dialog.old_name, new_name, dialog.package
                ));
            }
            Err(err) => {
                self.log_error(format!("Rename save failed: {}", err));
            }
        }
    }

    fn cancel_rename_dialog(&mut self, reason: impl Into<String>) {
        if let Some(dialog) = self.rename_dialog.take() {
            self.log_warn(format!(
                "Rename canceled: {} | {}",
                dialog.old_name,
                reason.into()
            ));
        }
    }

    fn current_package(&self) -> Option<String> {
        self.selected_app().map(|app| app.package.clone())
    }

    fn current_component(&self) -> Option<String> {
        self.selected_app().and_then(|app| app.component.clone())
    }

    fn app_name_for_package(&self, package: &str) -> String {
        self.apps
            .iter()
            .find(|app| app.package == package)
            .map(|app| app.name.clone())
            .unwrap_or_else(|| {
                self.aliases
                    .get(package)
                    .cloned()
                    .unwrap_or_else(|| package.to_string())
            })
    }

    fn status_for_package(&self, package: &str) -> Option<AppStatus> {
        self.apps
            .iter()
            .find(|app| app.package == package)
            .map(|app| app.status)
    }

    fn set_status_for_package(&mut self, package: &str, status: AppStatus) {
        for app in &mut self.apps {
            if app.package == package {
                app.status = status;
            }
        }
    }

    fn preview_freeze_current(&self) -> TargetPreview {
        let mut preview = TargetPreview::default();

        let Some(package) = self.current_package() else {
            return preview;
        };

        if self.user_whitelist.contains(&package) {
            preview.skipped_whitelist += 1;
            return preview;
        }

        match self.status_for_package(&package) {
            Some(AppStatus::Removed) | None => preview.skipped_removed += 1,
            Some(AppStatus::Frozen) => preview.skipped_frozen += 1,
            Some(AppStatus::Running) => preview.targets.push(package),
        }

        preview
    }

    fn preview_uninstall_current(&self) -> TargetPreview {
        let mut preview = TargetPreview::default();

        let Some(package) = self.current_package() else {
            return preview;
        };

        if self.user_whitelist.contains(&package) {
            preview.skipped_whitelist += 1;
            return preview;
        }

        match self.status_for_package(&package) {
            Some(AppStatus::Removed) | None => preview.skipped_removed += 1,
            Some(_) => preview.targets.push(package),
        }

        preview
    }

    fn preview_freeze_all_targets(&self) -> TargetPreview {
        let mut preview = TargetPreview::default();

        for app in &self.apps {
            let package = &app.package;

            if self.user_whitelist.contains(package) {
                preview.skipped_whitelist += 1;
                continue;
            }

            match app.status {
                AppStatus::Removed => preview.skipped_removed += 1,
                AppStatus::Frozen => preview.skipped_frozen += 1,
                AppStatus::Running => preview.targets.push(package.clone()),
            }
        }

        preview
    }

    fn preview_unfreeze_all_targets(&self) -> TargetPreview {
        let mut preview = TargetPreview::default();

        for app in &self.apps {
            match app.status {
                AppStatus::Removed => preview.skipped_removed += 1,
                AppStatus::Frozen => preview.targets.push(app.package.clone()),
                AppStatus::Running => preview.skipped_running += 1,
            }
        }

        preview
    }

    fn open_confirm_dialog(&mut self, dialog: ConfirmDialog) {
        self.confirm_dialog = Some(dialog);
    }

    fn cancel_dialog(&mut self, reason: impl Into<String>) {
        if let Some(dialog) = self.confirm_dialog.take() {
            self.log_warn(format!("Dialog canceled: {} | {}", dialog.title, reason.into()));
        }
    }

    fn confirm_dialog(&mut self) {
        let Some(dialog) = self.confirm_dialog.take() else {
            return;
        };

        self.start_execution_job(dialog);
    }

    fn start_execution_job(&mut self, dialog: ConfirmDialog) {
        let action = dialog.action;
        let current_user = self.current_user.clone();

        let targets: Vec<(String, String)> = dialog
            .targets
            .iter()
            .map(|pkg| (pkg.clone(), self.app_name_for_package(pkg)))
            .collect();

        let total = targets.len();
        let (tx, rx) = mpsc::channel::<JobEvent>();

        thread::spawn(move || {
            for (package, name) in targets {
                let args = match action {
                    ActionKind::Uninstall => vec![
                        "pm".to_string(),
                        "uninstall".to_string(),
                        "--user".to_string(),
                        current_user.clone(),
                        package.clone(),
                    ],
                    ActionKind::FreezeAll => vec![
                        "pm".to_string(),
                        "disable-user".to_string(),
                        "--user".to_string(),
                        current_user.clone(),
                        package.clone(),
                    ],
                    ActionKind::UnfreezeAll => vec![
                        "pm".to_string(),
                        "enable".to_string(),
                        "--user".to_string(),
                        current_user.clone(),
                        package.clone(),
                    ],
                    _ => Vec::new(),
                };

                let result = run_command(ROOT_CMD, &args);
                let command = format_command(ROOT_CMD, &args);

                let summary = if result.success {
                    format!("{} | {}", command, result.summary())
                } else {
                    format!("{} | {}", command, result.summary())
                };

                let _ = tx.send(JobEvent::Progress(JobProgress {
                    package,
                    name,
                    success: result.success,
                    summary,
                }));
            }

            let _ = tx.send(JobEvent::Finished);
        });

        self.running_job = Some(RunningJob {
            action,
            title: dialog.title,
            total,
            done: 0,
            ok: 0,
            fail: 0,
            current: "准备执行...".to_string(),
            last_message: String::new(),
            color: dialog.color,
            rx,
            finished_at: None,
            refreshed: false,
        });

        self.log_warn(format!("Execution started: total={}", total));
    }

    fn handle_event(&mut self, ev: Event) {
        self.tick();

        match ev {
            Event::Key(key) => {
                if key.kind != KeyEventKind::Press {
                    return;
                }

                if self.running_job.is_some() {
                    match key.code {
                        KeyCode::Char('q') | KeyCode::Esc => {
                            self.log_warn("Job is running; input ignored.");
                        }
                        _ => {}
                    }
                    return;
                }

                if self.confirm_dialog.is_some() {
                    match key.code {
                        KeyCode::Esc | KeyCode::Char('q') => {
                            self.cancel_dialog("keyboard cancel");
                        }
                        KeyCode::Enter => {
                            self.confirm_dialog();
                        }
                        _ => {}
                    }
                    return;
                }

                if self.rename_dialog.is_some() {
                    match key.code {
                        KeyCode::Esc => {
                            self.cancel_rename_dialog("Esc pressed");
                        }
                        KeyCode::Enter => {
                            self.save_rename_dialog();
                        }
                        KeyCode::Backspace => {
                            if let Some(dialog) = self.rename_dialog.as_mut() {
                                dialog.input.pop();
                            }
                        }
                        KeyCode::Char(ch) => {
                            if let Some(dialog) = self.rename_dialog.as_mut() {
                                if dialog.input.chars().count() < 40 {
                                    dialog.input.push(ch);
                                }
                            }
                        }
                        _ => {}
                    }
                    return;
                }

                match key.code {
                    KeyCode::Char('q') | KeyCode::Esc => {
                        self.log_info("Quit");
                        self.running = false;
                    }
                    KeyCode::Char('c') => {
                        self.clear_logs();
                    }
                    KeyCode::Char('u') => {
                        self.reload_apps_and_statuses();
                    }
                    KeyCode::Char('w') => {
                        self.toggle_whitelist_selected();
                    }
                    KeyCode::Char('r') => {
                        self.open_rename_dialog();
                    }
                    KeyCode::Char(' ') => {
                        self.log_warn("Space is reserved for future yazi-style multi-select.");
                    }
                    KeyCode::Up => {
                        self.move_selection(-1);
                    }
                    KeyCode::Down => {
                        self.move_selection(1);
                    }
                    KeyCode::Enter => {
                        self.run_action(ActionKind::Launch);
                    }
                    _ => {
                        self.log_info(format!(
                            "Key: code={:?}, modifiers={:?}",
                            key.code, key.modifiers
                        ));
                    }
                }
            }

            Event::Mouse(mouse) => {
                self.handle_mouse(mouse);
            }

            Event::Resize(w, h) => {
                self.log_info(format!("Resize: width={}, height={}", w, h));
            }

            Event::FocusGained => {
                self.log_info("Focus gained");
            }

            Event::FocusLost => {
                self.log_info("Focus lost");
            }

            Event::Paste(text) => {
                if let Some(dialog) = self.rename_dialog.as_mut() {
                    for ch in text.chars() {
                        if dialog.input.chars().count() < 40 {
                            dialog.input.push(ch);
                        }
                    }
                } else {
                    self.log_info(format!("Paste: {:?}", text));
                }
            }
        }
    }

    fn handle_mouse(&mut self, mouse: MouseEvent) {
        match mouse.kind {
            MouseEventKind::Down(button) => {
                self.pointer_down = Some(PointerDown {
                    column: mouse.column,
                    row: mouse.row,
                    button,
                });
            }

            MouseEventKind::Up(button) => {
                if self.running_job.is_some() {
                    return;
                }

                if self.confirm_dialog.is_some() {
                    match self.detect_dialog_click(mouse.column, mouse.row) {
                        DialogClick::Confirm => self.confirm_dialog(),
                        DialogClick::Cancel => self.cancel_dialog("Cancel clicked"),
                        DialogClick::Outside => self.cancel_dialog("outside clicked"),
                        DialogClick::Inside => {}
                    }
                    return;
                }

                if self.rename_dialog.is_some() {
                    match self.detect_dialog_click(mouse.column, mouse.row) {
                        DialogClick::Confirm => self.save_rename_dialog(),
                        DialogClick::Cancel => self.cancel_rename_dialog("Cancel clicked"),
                        DialogClick::Outside => self.cancel_rename_dialog("outside clicked"),
                        DialogClick::Inside => {}
                    }
                    return;
                }

                if let Some(hit) = self.detect_click(mouse.column, mouse.row, button) {
                    match hit {
                        HitTarget::App(index) => {
                            self.selected = index;
                            self.ensure_selected_visible();
                            self.select_count += 1;

                            if let Some(app) = self.selected_app() {
                                self.log_info(format!(
                                    "App selected: [{}] {} | {}",
                                    index + 1,
                                    app.name,
                                    app.package
                                ));
                            }
                        }

                        HitTarget::Action(action) => {
                            self.run_action(action);
                        }
                    }
                }
            }

            MouseEventKind::Drag(_) => {}
            MouseEventKind::Moved => {}

            MouseEventKind::ScrollUp => {
                if self.running_job.is_none()
                    && self.confirm_dialog.is_none()
                    && self.rename_dialog.is_none()
                    && self.in_app_list(mouse.column, mouse.row)
                {
                    self.move_selection(-1);
                }
            }

            MouseEventKind::ScrollDown => {
                if self.running_job.is_none()
                    && self.confirm_dialog.is_none()
                    && self.rename_dialog.is_none()
                    && self.in_app_list(mouse.column, mouse.row)
                {
                    self.move_selection(1);
                }
            }

            MouseEventKind::ScrollLeft => {}
            MouseEventKind::ScrollRight => {}
        }
    }

    fn detect_dialog_click(&self, column: u16, row: u16) -> DialogClick {
        let Some(hit) = self.dialog_hit_box else {
            return DialogClick::Outside;
        };

        if rect_contains(hit.confirm_rect, column, row) {
            DialogClick::Confirm
        } else if rect_contains(hit.cancel_rect, column, row) {
            DialogClick::Cancel
        } else if rect_contains(hit.dialog_rect, column, row) {
            DialogClick::Inside
        } else {
            DialogClick::Outside
        }
    }

    fn detect_click(
        &mut self,
        column: u16,
        row: u16,
        button: MouseButton,
    ) -> Option<HitTarget> {
        let down = self.pointer_down.take()?;

        if down.button != button {
            return None;
        }

        let dx = column.abs_diff(down.column);
        let dy = row.abs_diff(down.row);

        if dx > CLICK_MOVE_TOLERANCE || dy > CLICK_MOVE_TOLERANCE {
            return None;
        }

        for hit in &self.app_hit_boxes {
            if rect_contains(hit.rect, column, row) {
                return Some(HitTarget::App(hit.app_index));
            }
        }

        for hit in &self.action_hit_boxes {
            if rect_contains(hit.rect, column, row) {
                return Some(HitTarget::Action(hit.action));
            }
        }

        None
    }

    fn in_app_list(&self, column: u16, row: u16) -> bool {
        match self.app_list_inner {
            Some(rect) => rect_contains(rect, column, row),
            None => false,
        }
    }

    fn run_action(&mut self, action: ActionKind) {
        match action {
            ActionKind::Freeze => {
                let preview = self.preview_freeze_current();

                if preview.targets.is_empty() {
                    self.log_warn(format!(
                        "Freeze skipped: no target | whitelist={} removed={} frozen={}",
                        preview.skipped_whitelist,
                        preview.skipped_removed,
                        preview.skipped_frozen
                    ));
                    return;
                }

                self.freeze_targets(preview.targets, "Freeze");
            }

            ActionKind::Launch => {
                self.launch_current();
            }

            ActionKind::Uninstall => {
                let preview = self.preview_uninstall_current();

                if preview.targets.is_empty() {
                    self.log_warn(format!(
                        "Uninstall skipped: no target | whitelist={} removed={}",
                        preview.skipped_whitelist,
                        preview.skipped_removed
                    ));
                    return;
                }

                let package = &preview.targets[0];
                let lines = vec![
                    "确认卸载当前应用？".to_string(),
                    "".to_string(),
                    format!("应用：{}", self.app_name_for_package(package)),
                    format!("包名：{}", package),
                    "".to_string(),
                    "点击确认后才会开始执行，执行过程会显示进度。".to_string(),
                ];

                self.open_confirm_dialog(ConfirmDialog {
                    action,
                    title: "Confirm Uninstall / 确认卸载".to_string(),
                    lines,
                    targets: preview.targets,
                    color: Color::LightRed,
                    confirm_label: "Uninstall 卸载".to_string(),
                    cancel_label: "Cancel 取消".to_string(),
                });
            }

            ActionKind::FreezeAll => {
                let preview = self.preview_freeze_all_targets();

                if preview.targets.is_empty() {
                    self.log_warn(format!(
                        "Freeze All skipped: no target | whitelist={} removed={} frozen={}",
                        preview.skipped_whitelist,
                        preview.skipped_removed,
                        preview.skipped_frozen
                    ));
                    return;
                }

                let lines = vec![
                    "确认冻结全部？".to_string(),
                    "".to_string(),
                    format!("将冻结：{} 个应用", preview.targets.len()),
                    format!("白名单跳过：{}", preview.skipped_whitelist),
                    format!("已卸载/不存在跳过：{}", preview.skipped_removed),
                    format!("已冻结跳过：{}", preview.skipped_frozen),
                    "".to_string(),
                    "点击确认后才会开始执行，执行过程会显示进度。".to_string(),
                ];

                self.open_confirm_dialog(ConfirmDialog {
                    action,
                    title: "Confirm Freeze All / 确认冻结全部".to_string(),
                    lines,
                    targets: preview.targets,
                    color: Color::Yellow,
                    confirm_label: "Freeze All 冻结全部".to_string(),
                    cancel_label: "Cancel 取消".to_string(),
                });
            }

            ActionKind::UnfreezeAll => {
                let preview = self.preview_unfreeze_all_targets();

                if preview.targets.is_empty() {
                    self.log_warn(format!(
                        "Unfreeze skipped: no target | removed={} running={}",
                        preview.skipped_removed,
                        preview.skipped_running
                    ));
                    return;
                }

                let lines = vec![
                    "确认解冻全部？".to_string(),
                    "".to_string(),
                    format!("将解冻：{} 个应用", preview.targets.len()),
                    format!("已卸载/不存在跳过：{}", preview.skipped_removed),
                    format!("未冻结跳过：{}", preview.skipped_running),
                    "".to_string(),
                    "点击确认后才会开始执行，执行过程会显示进度。".to_string(),
                ];

                self.open_confirm_dialog(ConfirmDialog {
                    action,
                    title: "Confirm Unfreeze All / 确认解冻全部".to_string(),
                    lines,
                    targets: preview.targets,
                    color: Color::Cyan,
                    confirm_label: "Unfreeze 解冻".to_string(),
                    cancel_label: "Cancel 取消".to_string(),
                });
            }
        }
    }

    fn launch_current(&mut self) {
        self.launch_count += 1;

        let Some(app) = self.selected_app().cloned() else {
            self.log_warn("Launch skipped: no selected app");
            return;
        };

        if app.status == AppStatus::Removed {
            self.log_error(format!("Launch blocked: {} 已卸载，不能启动", app.name));
            return;
        }

        if app.status == AppStatus::Frozen {
            let args = vec![
                "pm".to_string(),
                "enable".to_string(),
                "--user".to_string(),
                self.current_user.clone(),
                app.package.clone(),
            ];

            let result = run_command(ROOT_CMD, &args);
            let command = format_command(ROOT_CMD, &args);

            if result.success {
                self.set_status_for_package(&app.package, AppStatus::Running);
                self.log_success(format!("Enable before launch OK: {}", app.name));
            } else {
                self.log_error(format!(
                    "Enable before launch FAILED: {} | cmd={} | {}",
                    app.name,
                    command,
                    result.summary()
                ));
                return;
            }
        }

        if let Some(component) = self.current_component() {
            let args = vec![
                "start".to_string(),
                "--user".to_string(),
                self.current_user.clone(),
                "-n".to_string(),
                component.clone(),
            ];

            let result = run_command("am", &args);
            let command = format_command("am", &args);

            if result.success {
                self.set_status_for_package(&app.package, AppStatus::Running);

                self.log_success(format!(
                    "Launch OK: {} | cmd={} | {}",
                    app.name,
                    command,
                    result.summary()
                ));
            } else {
                self.log_error(format!(
                    "Launch FAILED: {} | cmd={} | {}",
                    app.name,
                    command,
                    result.summary()
                ));
            }
        } else {
            let args = vec![
                "-p".to_string(),
                app.package.clone(),
                "-c".to_string(),
                "android.intent.category.LAUNCHER".to_string(),
                "1".to_string(),
            ];

            let result = run_command("monkey", &args);
            let command = format_command("monkey", &args);

            if result.success {
                self.set_status_for_package(&app.package, AppStatus::Running);

                self.log_success(format!(
                    "Launch by monkey OK: {} | cmd={} | {}",
                    app.name,
                    command,
                    result.summary()
                ));
            } else {
                self.log_error(format!(
                    "Launch by monkey FAILED: {} | cmd={} | {}",
                    app.name,
                    command,
                    result.summary()
                ));
            }
        }
    }

    fn freeze_targets(&mut self, targets: Vec<String>, label: &str) {
        self.freeze_count += targets.len() as u64;

        let mut ok = 0u64;
        let mut fail = 0u64;

        for package in targets {
            let name = self.app_name_for_package(&package);

            let args = vec![
                "pm".to_string(),
                "disable-user".to_string(),
                "--user".to_string(),
                self.current_user.clone(),
                package.clone(),
            ];

            let result = run_command(ROOT_CMD, &args);

            if result.success {
                self.set_status_for_package(&package, AppStatus::Frozen);
                ok += 1;
            } else {
                fail += 1;
                self.log_error(format!("{} FAILED: {} | {}", label, name, result.summary()));
            }
        }

        self.log_warn(format!("{} finished: ok={} fail={}", label, ok, fail));
        self.refresh_statuses_from_system();
    }
}

#[derive(Debug, Clone, Copy)]
enum HitTarget {
    App(usize),
    Action(ActionKind),
}

fn rect_contains(rect: Rect, column: u16, row: u16) -> bool {
    column >= rect.x
        && column < rect.x.saturating_add(rect.width)
        && row >= rect.y
        && row < rect.y.saturating_add(rect.height)
}

fn log_color(text: &str) -> Color {
    if text.contains("ERROR") {
        Color::LightRed
    } else if text.contains("WARN") {
        Color::Yellow
    } else if text.contains("SUCCESS") {
        Color::LightGreen
    } else if text.contains("INFO") {
        Color::LightBlue
    } else {
        Color::White
    }
}

fn ui(frame: &mut Frame, app: &mut App) {
    let area = frame.area();

    let root = Layout::default()
        .direction(Direction::Vertical)
        .constraints([Constraint::Length(14), Constraint::Min(12)])
        .split(area);

    draw_event_log(frame, app, root[0]);
    draw_bottom(frame, app, root[1]);

    if app.running_job.is_some() {
        draw_running_job_dialog(frame, app, area);
    } else if app.confirm_dialog.is_some() {
        draw_confirm_dialog(frame, app, area);
    } else if app.rename_dialog.is_some() {
        draw_rename_dialog(frame, app, area);
    }
}

fn draw_event_log(frame: &mut Frame, app: &App, area: Rect) {
    let title = if app.running_job.is_some() {
        " Event Log | EXECUTING "
    } else if app.confirm_dialog.is_some() {
        " Event Log | CONFIRM ACTIVE "
    } else if app.rename_dialog.is_some() {
        " Event Log | RENAME ACTIVE "
    } else {
        " Event Log  事件日志 "
    };

    let block = Block::default()
        .title(title)
        .borders(Borders::ALL)
        .border_style(if app.running_job.is_some() || app.confirm_dialog.is_some() || app.rename_dialog.is_some() {
            Style::default().fg(Color::Yellow)
        } else {
            Style::default().fg(Color::Cyan)
        });

    let inner = block.inner(area);
    let mut lines: Vec<Line> = Vec::new();

    if let Some(selected) = app.selected_app() {
        let tag = if app.user_whitelist.contains(&selected.package) {
            "WHITE"
        } else {
            ""
        };

        lines.push(Line::from(vec![
            Span::styled("SELECTED ", Style::default().fg(Color::Cyan).add_modifier(Modifier::BOLD)),
            Span::styled(
                format!("[{}] {}", app.selected + 1, selected.name),
                Style::default().fg(Color::LightCyan).add_modifier(Modifier::BOLD),
            ),
            Span::raw("   "),
            Span::styled("STATUS ", Style::default().fg(Color::Cyan).add_modifier(Modifier::BOLD)),
            Span::styled(
                selected.status.label(),
                Style::default()
                    .fg(selected.status.color())
                    .add_modifier(Modifier::BOLD),
            ),
            Span::raw("   "),
            Span::styled("USER ", Style::default().fg(Color::Cyan).add_modifier(Modifier::BOLD)),
            Span::styled(app.current_user.as_str(), Style::default().fg(Color::LightYellow)),
            Span::raw("   "),
            Span::styled(tag, Style::default().fg(Color::Yellow).add_modifier(Modifier::BOLD)),
        ]));

        lines.push(Line::from(vec![
            Span::styled("PACKAGE ", Style::default().fg(Color::Cyan).add_modifier(Modifier::BOLD)),
            Span::styled(selected.package.as_str(), Style::default().fg(Color::White)),
        ]));
    } else {
        lines.push(Line::from(Span::styled(
            "No apps loaded. Press u to update.",
            Style::default().fg(Color::Yellow),
        )));
        lines.push(Line::from(""));
    }

    lines.push(Line::from(vec![Span::styled(
        format!(
            "apps={} whitelist={} aliases={} freeze={} launch={} uninstall={} freeze_all={} unfreeze={}",
            app.apps.len(),
            app.user_whitelist.len(),
            app.aliases.len(),
            app.freeze_count,
            app.launch_count,
            app.uninstall_count,
            app.freeze_all_count,
            app.unfreeze_all_count
        ),
        Style::default().fg(Color::LightYellow),
    )]));

    let used_header_lines = lines.len() as u16;
    let log_capacity = inner.height.saturating_sub(used_header_lines) as usize;
    let start = app.logs.len().saturating_sub(log_capacity);

    for log in app.logs.iter().skip(start) {
        lines.push(Line::from(Span::styled(
            log.clone(),
            Style::default().fg(log_color(log)),
        )));
    }

    let para = Paragraph::new(lines)
        .wrap(Wrap { trim: false })
        .block(block);

    frame.render_widget(para, area);
}

fn draw_bottom(frame: &mut Frame, app: &mut App, area: Rect) {
    let cols = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([Constraint::Percentage(62), Constraint::Percentage(38)])
        .split(area);

    draw_app_list(frame, app, cols[0]);
    draw_actions(frame, app, cols[1]);
}

fn draw_app_list(frame: &mut Frame, app: &mut App, area: Rect) {
    let block = Block::default()
        .title(" Applications  应用列表 ")
        .borders(Borders::ALL)
        .border_style(Style::default().fg(Color::LightCyan));

    let inner = block.inner(area);
    app.app_list_inner = Some(inner);
    app.app_hit_boxes.clear();

    let footer_height = 1;
    let visible = inner.height.saturating_sub(footer_height) as usize;
    app.visible_rows = visible.max(1);
    app.ensure_selected_visible();

    let mut lines: Vec<Line> = Vec::new();

    for row_idx in 0..visible {
        let app_index = app.scroll + row_idx;

        if app_index >= app.apps.len() {
            lines.push(Line::from(""));
            continue;
        }

        let entry = app.apps[app_index].clone();
        let is_selected = app_index == app.selected;
        let is_white = app.user_whitelist.contains(&entry.package);

        let base_style = if is_selected {
            Style::default()
                .fg(Color::Black)
                .bg(Color::LightCyan)
                .add_modifier(Modifier::BOLD)
        } else {
            Style::default().fg(Color::White)
        };

        let dim_style = if is_selected {
            Style::default()
                .fg(Color::Black)
                .bg(Color::LightCyan)
                .add_modifier(Modifier::BOLD)
        } else {
            Style::default().fg(Color::DarkGray)
        };

        let status_style = if is_selected {
            Style::default()
                .fg(Color::Black)
                .bg(Color::LightCyan)
                .add_modifier(Modifier::BOLD)
        } else {
            Style::default().fg(entry.status.color())
        };

        let tag_style = if is_selected {
            Style::default()
                .fg(Color::Black)
                .bg(Color::LightCyan)
                .add_modifier(Modifier::BOLD)
        } else {
            Style::default().fg(Color::Yellow).add_modifier(Modifier::BOLD)
        };

        let cursor = if is_selected { "▶" } else { " " };

        let mut spans = vec![
            Span::styled(format!("{} {:02} ", cursor, app_index + 1), dim_style),
            Span::styled(format!("{:<16}", short_text(&entry.name, 16)), base_style),
            Span::styled(format!(" {}", entry.status.label()), status_style),
        ];

        if is_white {
            spans.push(Span::styled(" WHITE", tag_style));
        }

        lines.push(Line::from(spans));

        app.app_hit_boxes.push(AppHitBox {
            app_index,
            rect: Rect {
                x: inner.x,
                y: inner.y + row_idx as u16,
                width: inner.width,
                height: 1,
            },
        });
    }

    lines.push(Line::from(vec![Span::styled(
        " ↑/↓滚动 | u刷新 | w白名单 | r重命名 | Space预留 ",
        Style::default().fg(Color::DarkGray),
    )]));

    let para = Paragraph::new(lines)
        .wrap(Wrap { trim: false })
        .block(block);

    frame.render_widget(para, area);
}

fn draw_actions(frame: &mut Frame, app: &mut App, area: Rect) {
    let block = Block::default()
        .title(" Actions  操作 ")
        .borders(Borders::ALL)
        .border_style(Style::default().fg(Color::White));

    let inner = block.inner(area);
    app.action_hit_boxes.clear();

    frame.render_widget(block, area);

    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Ratio(1, 5),
            Constraint::Ratio(1, 5),
            Constraint::Ratio(1, 5),
            Constraint::Ratio(1, 5),
            Constraint::Ratio(1, 5),
        ])
        .split(inner);

    for (i, action) in ActionKind::all().iter().enumerate() {
        let rect = shrink_rect(chunks[i], 1, 0);
        let bg = action.block_bg();

        app.action_hit_boxes.push(ActionHitBox {
            action: *action,
            rect,
        });

        let (title, subtitle) = match action {
            ActionKind::Freeze => ("Freeze", "冻结"),
            ActionKind::Launch => ("Launch", "启动"),
            ActionKind::Uninstall => ("Uninstall", "卸载"),
            ActionKind::FreezeAll => ("Freeze All", "冻结全部"),
            ActionKind::UnfreezeAll => ("Unfreeze", "解冻全部"),
        };

        let text_style = Style::default()
            .fg(Color::White)
            .bg(bg)
            .add_modifier(Modifier::BOLD);

        let lines = vec![
            Line::from(Span::styled(action.symbol(), text_style)),
            Line::from(Span::styled(title, text_style)),
            Line::from(Span::styled(
                subtitle,
                Style::default().fg(Color::White).bg(bg),
            )),
        ];

        let button = Paragraph::new(lines)
            .alignment(Alignment::Center)
            .wrap(Wrap { trim: true })
            .style(Style::default().bg(bg))
            .block(
                Block::default()
                    .borders(Borders::ALL)
                    .style(Style::default().bg(bg))
                    .border_style(Style::default().fg(Color::White).bg(bg)),
            );

        frame.render_widget(button, rect);
    }
}

fn draw_confirm_dialog(frame: &mut Frame, app: &mut App, area: Rect) {
    let Some(dialog) = app.confirm_dialog.clone() else {
        app.dialog_hit_box = None;
        return;
    };

    let desired_height = (dialog.lines.len() as u16 + 7).clamp(10, 18);
    let dialog_rect = centered_rect(area, 88, desired_height);

    frame.render_widget(Clear, dialog_rect);

    let block = Block::default()
        .title(format!(" {} ", dialog.title))
        .borders(Borders::ALL)
        .border_style(Style::default().fg(dialog.color))
        .style(Style::default().bg(Color::Black));

    let inner = block.inner(dialog_rect);

    frame.render_widget(block, dialog_rect);

    let parts = Layout::default()
        .direction(Direction::Vertical)
        .constraints([Constraint::Min(4), Constraint::Length(3)])
        .split(inner);

    let mut lines = Vec::new();

    for line in &dialog.lines {
        let color = if line.contains("将") || line.contains("确认") {
            dialog.color
        } else if line.contains("跳过") {
            Color::LightYellow
        } else {
            Color::White
        };

        lines.push(Line::from(Span::styled(line.clone(), Style::default().fg(color))));
    }

    let body = Paragraph::new(lines)
        .alignment(Alignment::Left)
        .wrap(Wrap { trim: false });

    frame.render_widget(body, parts[0]);

    let buttons = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([
            Constraint::Percentage(48),
            Constraint::Percentage(4),
            Constraint::Percentage(48),
        ])
        .split(parts[1]);

    let cancel_rect = shrink_rect(buttons[0], 1, 0);
    let confirm_rect = shrink_rect(buttons[2], 1, 0);

    let cancel = Paragraph::new(Line::from(Span::styled(
        dialog.cancel_label,
        Style::default().fg(Color::White).add_modifier(Modifier::BOLD),
    )))
    .alignment(Alignment::Center)
    .block(
        Block::default()
            .borders(Borders::ALL)
            .border_style(Style::default().fg(Color::DarkGray)),
    );

    let confirm = Paragraph::new(Line::from(Span::styled(
        dialog.confirm_label,
        Style::default().fg(dialog.color).add_modifier(Modifier::BOLD),
    )))
    .alignment(Alignment::Center)
    .block(
        Block::default()
            .borders(Borders::ALL)
            .border_style(Style::default().fg(dialog.color)),
    );

    frame.render_widget(cancel, cancel_rect);
    frame.render_widget(confirm, confirm_rect);

    app.dialog_hit_box = Some(DialogHitBox {
        dialog_rect,
        cancel_rect,
        confirm_rect,
    });
}

fn draw_running_job_dialog(frame: &mut Frame, app: &mut App, area: Rect) {
    let Some(job) = app.running_job.as_ref() else {
        return;
    };

    let dialog_rect = centered_rect(area, 88, 15);

    frame.render_widget(Clear, dialog_rect);

    let title = if job.finished() {
        " Execution Finished / 执行完成 "
    } else {
        " Executing / 正在执行 "
    };

    let block = Block::default()
        .title(title)
        .borders(Borders::ALL)
        .border_style(Style::default().fg(job.color))
        .style(Style::default().bg(Color::Black));

    let inner = block.inner(dialog_rect);

    frame.render_widget(block, dialog_rect);

    let parts = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(5),
            Constraint::Length(3),
            Constraint::Min(3),
        ])
        .split(inner);

    let top_lines = vec![
        Line::from(vec![
            Span::styled("任务：", Style::default().fg(Color::DarkGray)),
            Span::styled(job.title.clone(), Style::default().fg(job.color).add_modifier(Modifier::BOLD)),
        ]),
        Line::from(vec![
            Span::styled("进度：", Style::default().fg(Color::DarkGray)),
            Span::styled(
                format!("{}/{}", job.done, job.total),
                Style::default().fg(Color::White).add_modifier(Modifier::BOLD),
            ),
            Span::raw("   "),
            Span::styled("成功：", Style::default().fg(Color::DarkGray)),
            Span::styled(job.ok.to_string(), Style::default().fg(Color::LightGreen)),
            Span::raw("   "),
            Span::styled("失败：", Style::default().fg(Color::DarkGray)),
            Span::styled(job.fail.to_string(), Style::default().fg(Color::LightRed)),
        ]),
        Line::from(vec![
            Span::styled("当前：", Style::default().fg(Color::DarkGray)),
            Span::styled(short_text(&job.current, 32), Style::default().fg(Color::LightYellow)),
        ]),
    ];

    frame.render_widget(
        Paragraph::new(top_lines).wrap(Wrap { trim: false }),
        parts[0],
    );

    frame.render_widget(
        Paragraph::new(progress_bar_ratio(job.ratio(), parts[1].width, job.color))
            .alignment(Alignment::Center),
        parts[1],
    );

    let status = if job.finished() {
        "执行完成，稍后自动关闭弹窗。"
    } else {
        "正在执行命令，请勿退出。"
    };

    let bottom_lines = vec![
        Line::from(Span::styled(status, Style::default().fg(Color::LightCyan))),
        Line::from(Span::styled(
            short_text(&job.last_message, 80),
            Style::default().fg(Color::DarkGray),
        )),
    ];

    frame.render_widget(
        Paragraph::new(bottom_lines).wrap(Wrap { trim: false }),
        parts[2],
    );
}

fn draw_rename_dialog(frame: &mut Frame, app: &mut App, area: Rect) {
    let Some(dialog) = app.rename_dialog.clone() else {
        app.dialog_hit_box = None;
        return;
    };

    let dialog_rect = centered_rect(area, 88, 14);

    frame.render_widget(Clear, dialog_rect);

    let block = Block::default()
        .title(" Rename App Alias / 重命名显示名 ")
        .borders(Borders::ALL)
        .border_style(Style::default().fg(Color::LightMagenta))
        .style(Style::default().bg(Color::Black));

    let inner = block.inner(dialog_rect);

    frame.render_widget(block, dialog_rect);

    let parts = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(8),
            Constraint::Length(3),
        ])
        .split(inner);

    let input = format!("{}▌", dialog.input);

    let lines = vec![
        Line::from(Span::styled(
            "输入新的应用显示名：",
            Style::default().fg(Color::LightMagenta).add_modifier(Modifier::BOLD),
        )),
        Line::from(""),
        Line::from(vec![
            Span::styled("包名：", Style::default().fg(Color::DarkGray)),
            Span::styled(dialog.package.clone(), Style::default().fg(Color::White)),
        ]),
        Line::from(vec![
            Span::styled("原名：", Style::default().fg(Color::DarkGray)),
            Span::styled(dialog.old_name.clone(), Style::default().fg(Color::LightYellow)),
        ]),
        Line::from(""),
        Line::from(Span::styled(
            input,
            Style::default()
                .fg(Color::Black)
                .bg(Color::LightMagenta)
                .add_modifier(Modifier::BOLD),
        )),
        Line::from(Span::styled(
            "Enter 保存 | Backspace 删除 | Esc 取消",
            Style::default().fg(Color::DarkGray),
        )),
    ];

    frame.render_widget(
        Paragraph::new(lines).alignment(Alignment::Left).wrap(Wrap { trim: false }),
        parts[0],
    );

    let buttons = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([
            Constraint::Percentage(48),
            Constraint::Percentage(4),
            Constraint::Percentage(48),
        ])
        .split(parts[1]);

    let cancel_rect = shrink_rect(buttons[0], 1, 0);
    let confirm_rect = shrink_rect(buttons[2], 1, 0);

    frame.render_widget(
        Paragraph::new(Line::from(Span::styled(
            "Cancel 取消",
            Style::default().fg(Color::White).add_modifier(Modifier::BOLD),
        )))
        .alignment(Alignment::Center)
        .block(Block::default().borders(Borders::ALL).border_style(Style::default().fg(Color::DarkGray))),
        cancel_rect,
    );

    frame.render_widget(
        Paragraph::new(Line::from(Span::styled(
            "Save 保存",
            Style::default().fg(Color::LightMagenta).add_modifier(Modifier::BOLD),
        )))
        .alignment(Alignment::Center)
        .block(Block::default().borders(Borders::ALL).border_style(Style::default().fg(Color::LightMagenta))),
        confirm_rect,
    );

    app.dialog_hit_box = Some(DialogHitBox {
        dialog_rect,
        cancel_rect,
        confirm_rect,
    });
}

fn progress_bar_ratio(ratio: f64, width: u16, main_color: Color) -> Line<'static> {
    let bar_width = width.saturating_sub(12).clamp(12, 48) as usize;
    let filled = ((bar_width as f64) * ratio).round() as usize;

    let mut spans = Vec::new();

    spans.push(Span::styled("[", Style::default().fg(Color::DarkGray)));

    for i in 0..bar_width {
        if i < filled {
            spans.push(Span::styled(
                "█",
                Style::default().fg(gradient_color(i, bar_width)),
            ));
        } else {
            spans.push(Span::styled(
                "░",
                Style::default().fg(Color::DarkGray),
            ));
        }
    }

    spans.push(Span::styled("] ", Style::default().fg(Color::DarkGray)));
    spans.push(Span::styled(
        format!("{:>3}%", (ratio * 100.0).round() as u64),
        Style::default().fg(main_color).add_modifier(Modifier::BOLD),
    ));

    Line::from(spans)
}

fn gradient_color(index: usize, total: usize) -> Color {
    if total <= 1 {
        return Color::Rgb(255, 80, 80);
    }

    let t = index as f64 / (total.saturating_sub(1)) as f64;

    let (r, g, b) = if t < 0.5 {
        let local = t / 0.5;
        interpolate_rgb((255, 70, 70), (255, 220, 80), local)
    } else {
        let local = (t - 0.5) / 0.5;
        interpolate_rgb((255, 220, 80), (80, 230, 170), local)
    };

    Color::Rgb(r, g, b)
}

fn interpolate_rgb(a: (u8, u8, u8), b: (u8, u8, u8), t: f64) -> (u8, u8, u8) {
    let t = t.clamp(0.0, 1.0);

    let r = a.0 as f64 + (b.0 as f64 - a.0 as f64) * t;
    let g = a.1 as f64 + (b.1 as f64 - a.1 as f64) * t;
    let b2 = a.2 as f64 + (b.2 as f64 - a.2 as f64) * t;

    (r.round() as u8, g.round() as u8, b2.round() as u8)
}

fn centered_rect(area: Rect, percent_x: u16, desired_height: u16) -> Rect {
    let width = area.width.saturating_mul(percent_x).saturating_div(100);
    let height = desired_height.min(area.height.saturating_sub(2)).max(8);

    let x = area.x + area.width.saturating_sub(width) / 2;
    let y = area.y + area.height.saturating_sub(height) / 2;

    Rect {
        x,
        y,
        width,
        height,
    }
}

fn shrink_rect(rect: Rect, horizontal: u16, vertical: u16) -> Rect {
    Rect {
        x: rect.x.saturating_add(horizontal),
        y: rect.y.saturating_add(vertical),
        width: rect.width.saturating_sub(horizontal.saturating_mul(2)),
        height: rect.height.saturating_sub(vertical.saturating_mul(2)),
    }
}

fn short_text(text: &str, width: usize) -> String {
    if text.chars().count() <= width {
        text.to_string()
    } else {
        let mut s = text.chars().take(width.saturating_sub(1)).collect::<String>();
        s.push('…');
        s
    }
}
EOF

echo
echo "开始运行 App Manager UI Demo..."
echo
echo "操作："
echo "  1. 左侧应用列表：点击选择应用"
echo "  2. ↑ / ↓ 或上下滑动：移动选择"
echo "  3. u：动态重新获取应用列表、重新加载 app_aliases.txt 和 whitelist.txt"
echo "  4. w：加入/移出 whitelist.txt 白名单"
echo "  5. r：重命名当前应用显示名，保存到 app_aliases.txt"
echo "  6. Enter：启动当前应用"
echo "  7. 卸载 / 冻结全部 / 解冻全部：先确认，点击确认后执行过程显示进度条"
echo "  8. c：清空日志"
echo "  9. q 或 Esc：退出"
echo
echo "todo 增加space功能 更改脚本名称，隐藏项目目录 增加注释 代码优化 "
echo

cargo run
