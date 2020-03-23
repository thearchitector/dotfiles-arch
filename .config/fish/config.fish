
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
eval /home/egabriel/miniconda3/bin/conda "shell.fish" "hook" $argv | source
# <<< conda initialize <<<

###
### PATCH [auto-condaenv] ###
###
set CONDAPROJECT "/"

function __conda_autoenv --on-variable PWD
    status --is-command-substitution; and return
    
    if test -e ".conda-env"
        set -l env (head -n 1 .conda-env)
        echo $PATH | grep -q "$env"
      
        if test $status -eq 1
            set CONDAPROJECT (pwd)
            set_color -io yellow
            echo "Project-specific Conda environment detected! Switching..."
            set_color normal
            conda activate $env
        end
    end

    pwd | grep -q "$CONDAPROJECT"
    if test $status -eq 1
        set CONDAPROJECT "/"
        set_color -d white
        echo "Leaving project directory. Conda environment reset."
        set_color normal
        conda activate base
    end
end
### END ###

export VISUAL=nvim
export EDITOR=$VISUAL
