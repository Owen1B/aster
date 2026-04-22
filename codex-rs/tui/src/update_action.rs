#[cfg(any(not(debug_assertions), test))]
use codex_install_context::InstallContext;
#[cfg(any(not(debug_assertions), test))]
use codex_install_context::StandalonePlatform;

/// Update action the CLI should perform after the TUI exits.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum UpdateAction {
    /// Update from the Aster GitHub Releases installer.
    NpmGlobalLatest,
    /// Update from the Aster GitHub Releases installer.
    BunGlobalLatest,
    /// Update from the Aster GitHub Releases installer.
    BrewUpgrade,
    /// Update from the Aster GitHub Releases installer.
    StandaloneUnix,
    /// Report that Aster does not publish Windows builds.
    StandaloneWindows,
}

impl UpdateAction {
    #[cfg(any(not(debug_assertions), test))]
    pub(crate) fn from_install_context(context: &InstallContext) -> Option<Self> {
        match context {
            InstallContext::Npm => Some(UpdateAction::NpmGlobalLatest),
            InstallContext::Bun => Some(UpdateAction::BunGlobalLatest),
            InstallContext::Brew => Some(UpdateAction::BrewUpgrade),
            InstallContext::Standalone { platform, .. } => Some(match platform {
                StandalonePlatform::Unix => UpdateAction::StandaloneUnix,
                StandalonePlatform::Windows => UpdateAction::StandaloneWindows,
            }),
            InstallContext::Other => None,
        }
    }

    /// Returns the list of command-line arguments for invoking the update.
    pub fn command_args(self) -> (&'static str, &'static [&'static str]) {
        match self {
            UpdateAction::NpmGlobalLatest
            | UpdateAction::BunGlobalLatest
            | UpdateAction::BrewUpgrade
            | UpdateAction::StandaloneUnix => (
                "sh",
                &[
                    "-c",
                    "curl -fsSL https://raw.githubusercontent.com/Owen1B/aster/main/scripts/install/install.sh | sh",
                ],
            ),
            UpdateAction::StandaloneWindows => (
                "powershell",
                &[
                    "-NoProfile",
                    "-Command",
                    "Write-Error 'Aster does not currently publish Windows builds. Use https://github.com/Owen1B/aster/releases/latest for Linux and macOS assets.'; exit 1",
                ],
            ),
        }
    }

    /// Returns string representation of the command-line arguments for invoking the update.
    pub fn command_str(self) -> String {
        let (command, args) = self.command_args();
        shlex::try_join(std::iter::once(command).chain(args.iter().copied()))
            .unwrap_or_else(|_| format!("{command} {}", args.join(" ")))
    }
}

#[cfg(not(debug_assertions))]
pub(crate) fn get_update_action() -> Option<UpdateAction> {
    if std::env::var_os("ASTER_ENABLE_UPDATE_CHECK").is_none() {
        return None;
    }

    UpdateAction::from_install_context(InstallContext::current())
}

#[cfg(test)]
mod tests {
    use super::*;
    use pretty_assertions::assert_eq;
    use std::path::PathBuf;

    #[test]
    fn maps_install_context_to_update_action() {
        let native_release_dir = PathBuf::from("/tmp/native-release");

        assert_eq!(
            UpdateAction::from_install_context(&InstallContext::Other),
            None
        );
        assert_eq!(
            UpdateAction::from_install_context(&InstallContext::Npm),
            Some(UpdateAction::NpmGlobalLatest)
        );
        assert_eq!(
            UpdateAction::from_install_context(&InstallContext::Bun),
            Some(UpdateAction::BunGlobalLatest)
        );
        assert_eq!(
            UpdateAction::from_install_context(&InstallContext::Brew),
            Some(UpdateAction::BrewUpgrade)
        );
        assert_eq!(
            UpdateAction::from_install_context(&InstallContext::Standalone {
                platform: StandalonePlatform::Unix,
                release_dir: native_release_dir.clone(),
                resources_dir: Some(native_release_dir.join("codex-resources")),
            }),
            Some(UpdateAction::StandaloneUnix)
        );
        assert_eq!(
            UpdateAction::from_install_context(&InstallContext::Standalone {
                platform: StandalonePlatform::Windows,
                release_dir: native_release_dir.clone(),
                resources_dir: Some(native_release_dir.join("codex-resources")),
            }),
            Some(UpdateAction::StandaloneWindows)
        );
    }

    #[test]
    fn standalone_update_commands_rerun_latest_installer() {
        assert_eq!(
            UpdateAction::StandaloneUnix.command_args(),
            (
                "sh",
                &[
                    "-c",
                    "curl -fsSL https://raw.githubusercontent.com/Owen1B/aster/main/scripts/install/install.sh | sh"
                ][..],
            )
        );
        assert_eq!(
            UpdateAction::StandaloneWindows.command_args(),
            (
                "powershell",
                &[
                    "-NoProfile",
                    "-Command",
                    "Write-Error 'Aster does not currently publish Windows builds. Use https://github.com/Owen1B/aster/releases/latest for Linux and macOS assets.'; exit 1"
                ][..],
            )
        );
    }
}
