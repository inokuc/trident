# Trident
# by Shouta Inokuchi
# https://github.com/inokuc/trident
# MIT License

# Whether or not is a fresh session
set -g __trident_fresh_session 1

# Deactivate the default virtualenv prompt so that we can add our own
set -gx VIRTUAL_ENV_DISABLE_PROMPT 1

# Symbols

__trident_set_default trident_symbol_prompt "❯"
__trident_set_default trident_symbol_git_down_arrow "⇣"
__trident_set_default trident_symbol_git_up_arrow "⇡"
__trident_set_default trident_symbol_git_dirty "*"
__trident_set_default trident_symbol_horizontal_bar "—"

# Colors

__trident_set_default trident_color_red (set_color red)
__trident_set_default trident_color_green (set_color green)
__trident_set_default trident_color_blue (set_color blue)
__trident_set_default trident_color_yellow (set_color yellow)
__trident_set_default trident_color_cyan (set_color cyan)
__trident_set_default trident_color_gray (set_color 93A1A1)
__trident_set_default trident_color_normal (set_color normal)

__trident_set_default trident_username_color $trident_color_gray
__trident_set_default trident_host_color $trident_color_gray
__trident_set_default trident_root_color $trident_color_normal

# Determines whether the username and host are shown at the begining or end
# 0 - end of prompt, default
# 1 - start of prompt
# Any other value defaults to the default behaviour
__trident_set_default trident_user_host_location 0

# Max execution time of a process before its run time is shown when it exits
__trident_set_default trident_command_max_exec_time 5

function fish_prompt
  # Save previous exit code
  set -l exit_code $status

  # Set default color symbol to green meaning it's all good!
  set -l color_symbol $trident_color_green

  # Template

  set -l user_and_host ""
  set -l current_folder (__parse_current_folder)
  set -l git_branch_name ""
  set -l git_dirty ""
  set -l git_arrows ""
  set -l command_duration ""
  set -l prompt ""

  # Do not add a line break to a brand new session
  if test $__trident_fresh_session -eq 0
    set prompt $prompt "\n"
  end

  # Check if user is in an SSH session
  if [ "$SSH_CONNECTION" != "" ]
    set -l host (hostname -s)
    set -l user (whoami)

    if [ "$user" = "root" ]
      set user "$trident_root_color$user"
    else
      set user "$trident_username_color$user"
    end

    # Format user and host part of prompt
    set user_and_host "$user$trident_color_gray@$trident_host_color$host$trident_color_normal "
  end

  if test $trident_user_host_location -eq 1
    set prompt $prompt $user_and_host
  end

  # Format current folder on prompt output
  set prompt $prompt "$trident_color_blue$current_folder$trident_color_normal "

  # Handle previous failed command
  if test $exit_code -ne 0
    # Symbol color is red when previous command fails
    set color_symbol $trident_color_red
  end

  # Exit with code 1 if git is not available
  if not which git >/dev/null
    return 1
  end

  # Check if is on a Git repository
  set -l is_git_repository (command git rev-parse --is-inside-work-tree ^/dev/null)

  if test -n "$is_git_repository"
    set git_branch_name (__parse_git_branch)

    # Check if there are files to commit
    set -l is_git_dirty (command git status --porcelain --ignore-submodules ^/dev/null)

    if test -n "$is_git_dirty"
      set git_dirty $trident_symbol_git_dirty
    end

    # Check if there is an upstream configured
    command git rev-parse --abbrev-ref '@{upstream}' >/dev/null ^&1; and set -l has_upstream
    if set -q has_upstream
      set -l git_status (command git rev-list --left-right --count 'HEAD...@{upstream}' | sed "s/[[:blank:]]/ /" ^/dev/null)

      # Resolve Git arrows by treating `git_status` as an array
      set -l git_arrow_left (command echo $git_status | cut -c 1 ^/dev/null)
      set -l git_arrow_right (command echo $git_status | cut -c 3 ^/dev/null)

    # If arrow is not "0", it means it's dirty
      if test $git_arrow_left != 0
        set git_arrows " $trident_symbol_git_up_arrow"
      end

      if test $git_arrow_right != 0
        set git_arrows " $git_arrows$trident_symbol_git_down_arrow"
      end
    end

    # Format Git prompt output
    set prompt $prompt "$trident_color_gray$git_branch_name$git_dirty$trident_color_normal$trident_color_cyan$git_arrows$trident_color_normal "
  end

  if test $trident_user_host_location -ne 1
    set prompt $prompt $user_and_host
  end

  # Prompt command execution duration
  if test -n "$CMD_DURATION"
    set command_duration (__format_time $CMD_DURATION $trident_command_max_exec_time)
  end
  set prompt $prompt "$trident_color_yellow$command_duration$trident_color_normal\n"

  # Show python virtualenv name (if activated)
  if test -n "$VIRTUAL_ENV"
    set prompt $prompt $trident_color_gray(basename "$VIRTUAL_ENV")"$trident_color_normal "
  end

  set prompt $prompt "$color_symbol$trident_symbol_prompt$trident_color_normal "

  echo -e -s $prompt

  set __trident_fresh_session 0
end
