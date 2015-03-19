p() {
    [ "$PYENV" ] || {
        echo "\$PYENV not set ..."
        return
    }
    if [ "$1" ]; then
        if [ "$1" == "-h" ]; then
            echo "p [-h][--help][-d][-a][-m MODULE][.][..][ENV]"
            return
        elif [ "$1" == "--help" ]; then
            cat << EOF
simple virtualenv management for bash
p           - list virtualenvs
p -h        - short help
p --help    - long help
p -d        - deactivate current virtualenv and run post-deactivate hook
p -a        - revert -d
p -m MODULE - cd to directory where module lives
p .         - cd to site-packages of current virtualenv
p ..        - cd to root of current virtualenv
p ENV       - deactivate current virtualenv and activate ENV with hooks
hooks:
    bin/post-activate   - sourced after the virtualenv is activated
    bin/post-deactivate - sourced after the virtualenv is deactivated
EOF
            return
        elif [ "$1" == "." -a "$VIRTUAL_ENV" ]; then
            local site_packages=$($VIRTUAL_ENV/bin/python -c \
            "import distutils;print(distutils.sysconfig.get_python_lib())")
            [ "$site_packages" ] && cd $site_packages
            return
        elif [ "$1" == ".." -a "$VIRTUAL_ENV" ]; then
            cd $VIRTUAL_ENV
            return
        elif [ "$1" = "-m" ]; then
            shift
            [ "$1" ] || return
pth=$(
python <<EOF
import os.path
try:
    import $1
except ImportError:
    pass
else:
    try:
        print os.path.dirname(os.path.realpath($1.__file__[:-1]))
    except AttributeError:
        pass
EOF
)
            [ "$pth" ] || return
            cd "$pth"
        elif [ "$1" = "-a" ]; then
            [ "$VIRTUAL_ENV" ] && {
                echo "Already in virtualenv $(basename $VIRTUAL_ENV)"
                return
            }
            [ "$OLD_VIRTUAL_ENV" ] || {
                echo '$OLD_VIRTUAL_ENV not set'
                return
            }
            source "$PYENV/$OLD_VIRTUAL_ENV/bin/activate"
            source "$PYENV/$OLD_VIRTUAL_ENV/bin/post-activate" 2>/dev/null
            return
        fi
        [ "$1" == "-d" -o -f "$PYENV/$1/bin/activate" ] && {
            # deactivate current virtualenv and run post-deactivate hook
            [ "$VIRTUAL_ENV" ] && {
                OLD_VIRTUAL_ENV="$(basename $VIRTUAL_ENV)"
                deactivate 2>/dev/null
                source "$PYENV/$OLD_VIRTUAL_ENV/bin/post-deactivate" 2>/dev/null
            }
        }
        [ -f "$PYENV/$1/bin/activate" ] && {
            # activate new virtualenv and run post-activate hook
            source "$PYENV/$1/bin/activate"
            source "$PYENV/$1/bin/post-activate" 2>/dev/null
        }
    else
        # list available virtualenvs
        ls -1 $PYENV
    fi
}
# tab completion
_p() {
    cur="${COMP_WORDS[COMP_CWORD]}"
    COMPREPLY=( $(compgen -W '$(command ls "$PYENV")' -- "$cur") )
}
complete -F _p p
