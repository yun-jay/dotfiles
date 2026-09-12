# Make Homebrew tools available in non-interactive SSH shells (e.g. mosh-server).
if [[ -d /opt/homebrew/bin ]]; then
  case ":$PATH:" in
    *:/opt/homebrew/bin:*) ;;
    *) export PATH="/opt/homebrew/bin:$PATH" ;;
  esac
fi
