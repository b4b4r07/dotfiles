# Check whether the vital file is loaded
if ! vitalize 2>/dev/null; then
    echo "cannot run as shell script" 1>&2
    return 1
fi

# For mac, aliases
if is_osx; then
    has "qlmanage" && alias ql='qlmanage -p "$@" >&/dev/null'
fi

if has 'git'; then
    alias gst='git status'
fi

if has 'richpager'; then
    alias cl='richpager'
fi

# Common aliases
alias ..='cd ..'
alias ld='ls -ld'          # Show info about the directory
alias lla='ls -lAF'        # Show hidden all files
alias ll='ls -lF'          # Show long file information
alias l='ls -1F'           # Show long file information
alias la='ls -AF'          # Show hidden files
alias lx='ls -lXB'         # Sort by extension
alias lk='ls -lSr'         # Sort by size, biggest last
alias lc='ls -ltcr'        # Sort by and show change time, most recent last
alias lu='ls -ltur'        # Sort by and show access time, most recent last
alias lt='ls -ltr'         # Sort by date, most recent last
alias lr='ls -lR'          # Recursive ls

# The ubiquitous 'll': directories first, with alphanumeric sorting:
#alias ll='ls -lv --group-directories-first'

alias cp="${ZSH_VERSION:+nocorrect} cp -i"
alias mv="${ZSH_VERSION:+nocorrect} mv -i"
alias mkdir="${ZSH_VERSION:+nocorrect} mkdir"

#autoload -Uz zmv
alias zmv='noglob zmv -W'

alias du='du -h'
alias job='jobs -l'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Use if colordiff exists
if has 'colordiff'; then
    alias diff='colordiff -u'
else
    alias diff='diff -u'
fi

alias vi="vim"

# Use plain vim.
alias nvim='vim -N -u NONE -i NONE'

# The first word of each simple command, if unquoted, is checked to see 
# if it has an alias. [...] If the last character of the alias value is 
# a space or tab character, then the next command word following the 
# alias is also checked for alias expansion
alias sudo='sudo '

# Global aliases
alias -g G='| grep'

#less_alias() {
#    local stdin
#    stdin="$(cat <&0)"
#    if [[ -n $stdin ]]; then
#        if [[ -f $stdin ]]; then
#            less $stdin
#        else
#            echo "$stdin" | less
#        fi
#    fi
#}
##alias -g L='| cat_alias | less'
#alias -g L='| less_alias'

alias -g W='| wc'
alias -g X='| xargs'
alias -g F='| "$(available $INTERACTIVE_FILTER)"'

(( $+galiases[H] )) || alias -g H='| head'
(( $+galiases[T] )) || alias -g T='| tail'

if has "emojify"; then
    alias -g E='| emojify'
fi

if is_osx; then
    alias -g CP='| pbcopy'
    alias -g CC='| tee /dev/tty | pbcopy'
fi

#cat_alias() {
#    local stdin
#    stdin="$(cat <&0)"
#    if [[ -n $stdin ]]; then
#        if [[ -f $stdin ]]; then
#            cat $stdin
#        else
#            echo "$stdin" | cat
#        fi
#    fi
#}
#alias -g C="| cat_alias"

#cat_all_alias() {
#    local i
#    for i in $(cat <&0)
#    do
#        if [[ -n $i ]]; then
#            if [[ -f $i ]]; then
#                cat $i
#            else
#                echo "$i" | cat
#            fi
#        fi
#    done
#}
#alias -g CA="| cat_all_alias"
#alias -g C="| cat_all_alias"

cat_alias() {
    local i stdin file=0
    stdin=("${(@f)$(cat <&0)}")
    for i in "${stdin[@]}"
    do
        if [[ -f $i ]]; then
            cat "$@" "$i"
            file=1
        fi
    done
    if [[ $file -eq 0 ]]; then
        echo "${(F)stdin}"
    fi
}
alias -g C="| cat_alias"

pygmentize_alias() {
    if has "pygmentize"; then
        local get_styles styles style
        get_styles="from pygments.styles import get_all_styles
        styles = list(get_all_styles())
        print('\n'.join(styles))"
        styles=( $(sed -e 's/^  *//g' <<<"$get_styles" | python) )

        style=${${(M)styles:#solarized}:-default}
        cat_alias "$@" | pygmentize -O style="$style" -f console256 -g
    else
        cat -
    fi
}
alias -g P="| pygmentize_alias"
alias -g L="| cat_alias | less"
alias -g LL="| less"

awk_alias() {
    if (( ${ZSH_VERSION%%.*} < 5 )); then
        #local one
        #one="$1"
        #shift
        #cat_alias | awk "$@" '{print $'"${one:-0}"'}'
        return
    fi

    local f=0 opt=
    if [[ $# -gt 0 && ${@[-1]} =~ ^[0-9]+$ ]]; then
        f=${@[-1]}
        opt=${@:1:-1}
    fi
    awk $opt '{print $'"$f"'}'
}
alias -g A="| awk_alias"

alias -g S="| sort"
alias -g V="| tovim"

alias -g N=" >/dev/null 2>&1"
alias -g N1=" >/dev/null"
alias -g N2=" 2>/dev/null"

vim_mru_files() {
    case "$1" in
        -h|--help)
            ;;
    esac

    local -a f
    f=(
    ~/.vim_mru_files(N)
    ~/.unite/file_mru(N)
    ~/.cache/ctrlp/mru/cache.txt(N)
    ~/.frill(N)
    )
    if [[ $#f -eq 0 ]]; then
        echo "There is no available MRU Vim plugins" >&2
        return 1
    fi

    local cmd q k res
    local line ok make_dir i arr
    local get_styles styles style
    while : ${make_dir:=0}; ok=("${ok[@]:-dummy_$RANDOM}"); cmd="$(
        cat <$f \
            | while read line; do [ -e "$line" ] && echo "$line"; done \
            | while read line; do [ "$make_dir" -eq 1 ] && echo "${line:h}/" || echo "$line"; done \
            | if [ "$make_dir" -eq 1 ]; then awk '!a[$0]++'; else cat -; fi \
            | sed -e '/^#/d;/^$/d' \
            | perl -pe 's/^(\/.*\/)(.*)$/\033[34m$1\033[m$2/' \
            | fzf --ansi --multi --query="$q" \
            --no-sort --exit-0 --prompt="MRU> " \
            --print-query --expect=ctrl-v,ctrl-x,ctrl-l,ctrl-q,ctrl-r,"?"
            )"; do
        q="$(head -1 <<< "$cmd")"
        k="$(head -2 <<< "$cmd" | tail -1)"
        res="$(sed '1,2d;/^$/d' <<< "$cmd")"
        [ -z "$res" ] && continue
        case "$k" in
            "?")
                cat <<HELP > /dev/tty
usage: vim_mru_files
    list up most recently files

keybind:
  ctrl-q  output files and quit
  ctrl-l  less files under the cursor
  ctrl-v  vim files under the cursor
  ctrl-r  change view type
  ctrl-x  remove files (two-step)
HELP
                return 1
                ;;
            ctrl-r)
                if [ $make_dir -eq 1 ]; then
                    make_dir=0
                else
                    make_dir=1
                fi
                continue
                ;;
            ctrl-l)
                arr=("${(@f)res}")
                if [[ -d ${arr[1]} ]]; then
                    ls -l "${(@f)res}" < /dev/tty | less > /dev/tty
                else
                    if has "pygmentize"; then
                        get_styles="from pygments.styles import get_all_styles
                        styles = list(get_all_styles())
                        print('\n'.join(styles))"
                        styles=( $(sed -e 's/^  *//g' <<<"$get_styles" | python) )
                        style=${${(M)styles:#solarized}:-default}
                        export LESSOPEN="| pygmentize -O style=$style -f console256 -g %s"
                    fi
                    less "${(@f)res}" < /dev/tty > /dev/tty
                fi
                ;;
            ctrl-x)
                if [[ ${(j: :)ok} == ${(j: :)${(@f)res}} ]]; then
                    eval '${${${(M)${+commands[gomi]}#1}:+gomi}:-rm} "${(@f)res}" 2>/dev/null'
                    ok=()
                else
                    ok=("${(@f)res}")
                fi
                ;;
            ctrl-v)
                vim -p "${(@f)res}" < /dev/tty > /dev/tty
                ;;
            ctrl-q)
                echo "$res" < /dev/tty > /dev/tty
                return $status
                ;;
            *)
                echo "${(@f)res}"
                break
                ;;
        esac
    done
}
alias -g mru='$(vim_mru_files)'

destination_directories() {
    local -a d
    d=(
    #${GOPATH%%:*}/src/github.com/**/*~**/*\.git/**(N-/)
    $DOTPATH/**/*~$DOTPATH/*\.git/**(N-/)
    $HOME/Dropbox(N-/)
    $HOME
    $OLDPWD
    $($DOTPATH/bin/tfp(N))
    )
    if [[ $#d -eq 0 ]]; then
        echo "There is no available directory" >&2
        return 1
    fi
    echo "${(F)d}" | fzf --tac --prompt="to> "
}
alias -g to='$(destination_directories)'
