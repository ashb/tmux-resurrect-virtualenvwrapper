# Virtualenvwrapper support for tmux-resurrect

Add's support for saving and restoring python active python virtual
environments to
[tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect). At the moment
it only recognizes virtualenvwrapper environments (as it utilises the hooks
provided by that project to get told about activation and deactivation of
environments.)

Requirements / dependencies: `tmux 1.9` or higher, `bash`, `tmux-resurrect`
**WITH UN-MERGED PR [#267][hooks-pr]**.

For this plugin to work it requires the hook support added to tmux-resurrect be
able to save and restore the active venv state. Until that PR is merged you
should use the `ashb/tmux-resurrect` fork in TPM.

[hooks-pr]: https://github.com/tmux-plugins/tmux-resurrect/pull/267

### Installation with [Tmux Plugin Manager](https://github.com/tmux-plugins/tpm) (recommended)

Add plugin to the list of TPM plugins in `.tmux.conf`:

    set -g @plugin 'ashb/tmux-resurrect-virtualenvwrapper'

Hit `prefix + I` to fetch the plugin and source it. You should now be able to
use the plugin.

### Manual Installation

Clone the repo:

    $ git clone https://github.com/ashb/tmux-resurrect-virtualenvwrapper ~/clone/path

Add this line to the bottom of `.tmux.conf`:

    run-shell ~/clone/path/resurrect-venvs.tmux
