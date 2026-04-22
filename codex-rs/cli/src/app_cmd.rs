use clap::Parser;
use std::path::PathBuf;

#[derive(Debug, Parser)]
pub struct AppCommand {
    /// Workspace path for future Aster Desktop integration.
    #[arg(value_name = "PATH", default_value = ".")]
    pub path: PathBuf,

    /// Ignored in Aster builds; upstream desktop downloads are disabled.
    #[arg(long = "download-url", hide = true)]
    pub download_url_override: Option<String>,
}

pub async fn run_app(cmd: AppCommand) -> anyhow::Result<()> {
    let _ = cmd;
    anyhow::bail!("Aster Desktop integration is not available in this white-label build.")
}
