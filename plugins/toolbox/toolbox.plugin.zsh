if [[ $? -eq 0 ]] && ! type toolbox &>/dev/null; then
  print "[oh-my-zsh] toolbox plugin: shell function 'toolbox' not defined.\n" \
    "Please check toolbox" >&2
  return
fi

function is_in_toolbox() {
  if [[ -f /run/.containerenv && -f /run/.toolboxenv ]]; then
    return 0
  else
    return 1
  fi
}

function toolbox_prompt_info() {
  if is_in_toolbox; then
    echo "⬢ "
  else
    return 0
  fi
}

# Automatically enter Git projects in the default toolbox container. Toolbox
# container can be overridden by placing a .toolbox file in the project root
# with a container name in it.
#
function toolbox_cwd {
  if [[ -z "$TOOLBOX_CWD" ]]; then
    local TOOLBOX_CWD=1
    # Get absolute path, resolving symlinks
    local PROJECT_ROOT="${PWD:A}"
    while [[ "$PROJECT_ROOT" != "/" && ! -e "$PROJECT_ROOT/.toolbox" &&
      ! -d "$PROJECT_ROOT/.git" ]]; do
      PROJECT_ROOT="${PROJECT_ROOT:h}"
    done

    if 
    # Check for toolbox name override
    if [[ -f "$PROJECT_ROOT/.toolbox" ]]; then
      TOOLBOX_NAME="$(cat "$PROJECT_ROOT/.toolbox")"
    elif [[ -d "$PROJECT_ROOT/.git" && -n $TOOLBOX_DEFAULT_CONTAINER ]]; then
      TOOLBOX_NAME="$TOOLBOX_DEFAULT_CONTAINER"
    else
      unset TOOLBOX_NAME
    fi

    if [[ -n $TOOLBOX_NAME ]]; then
      if ! is_in_toolbox; then
        if ! $(podman container exists $TOOLBOX_NAME); then
          tbc $TOOLBOX_NAME
        fi
        toolbox --container $TOOLBOX_NAME run sudo hostname $TOOLBOX_NAME
        toolbox enter $TOOLBOX_NAME
      fi
    elif [[ "$(hostname)" != "toolbox" && ! $DISABLE_TOOLBOX_EXIT -eq 1 ]]; then
      if is_in_toolbox; then
        exit
      fi
    fi
  fi
}

if [[ ! $DISABLE_TOOLBOX_ENTER -eq 1 ]]; then

  # Append workon_cwd to the chpwd_functions array, so it will be called on cd
  # http://zsh.sourceforge.net/Doc/Release/Functions.html
  autoload -Uz add-zsh-hook
  add-zsh-hook chpwd toolbox_cwd
  add-zsh-hook precmd toolbox_cwd
fi

if [[ -n "$TOOLBOX_DEFAULT_IMAGE" ]]; then
  alias tbc="toolbox create --image $TOOLBOX_DEFAULT_IMAGE"
else
  alias tbc="toolbox create"
fi
alias tbi="echo $TOOLBOX_DEFAULT_CONTAINER > .toolbox && toolbox_cwd"
alias tb="toolbox"
alias tbe="toolbox enter"
alias tbrm="toolbox rm"
alias tbrmi="toolbox rmi"
alias tbl="toolbox list"
alias tbr="toolbox run"