#!/bin/bash

set -eaou pipefail

LOCALINSTALLDIR=~/Miniconda
MINICONDAINSTALLSCRIPT=/home/cal/Masternode_config/Bootstrap/Files/Anaconda/Miniconda3-2025.06-0-Linux-x86.sh
                                                                           #Miniconda3-py313_25.3.1-1-Linux-x86_64.sh 
COL_LRED="\033[1;31m";
COL_LYELLOW="\033[1;33m";
COL_LCYAN="\033[1;36m";
COL_NC="\033[0m";

IS_DONE=0
trap TrapExit EXIT

function TrapExit()
{
	if [ $IS_DONE != 1 ]; then
		echo -e "  "$COL_LRED"TRAPED ERROR:"$COL_NC" script did not run correctly!"
	fi
}

function Err()
{
	echo -e "  "$COL_LRED"ERROR: "$COL_NC"$@"
	exit -1
}

function Warn()
{
	echo -e "  "$COL_LYELLOW"WARN: "$COL_NC"$@"
}

function Echo()
{
	echo -e $COL_LCYAN"$@"$COL_NC
}

function WipeMiniconda()
{
	local M=~/Miniconda/
	test ! -d $M  ||  (Warn "removing dir '$M'" && rm -rf $M)
}

function Init()
{
	Echo "INIT.."
	module rm anaconda-2022.05 || true
	module rm anaconda-2024.02 || true
	module rm anaconda-2025.06 || true 
	module is-loaded anaconda-latest  && module rm anaconda-latest
	module is-loaded anaconda-env     && module rm anaconda-env
	local M=`module list | grep -v "Currently Loaded"`	
	(echo $M | grep anaconda >/dev/null && Err "still has some anaconda modules enabled! Please use 'module rm .. ' to remove them. Current modules was $M.") || true
}

function Mamba()
{
	$LOCALINSTALLDIR/bin/mamba -y $@
}

function Install()
{	
	Echo "INSTALL.."
	
	test -f $MINICONDAINSTALLSCRIPT || Err "missing file '$MINICONDAINSTALLSCRIPT', can not continue installation!"
	test ! -d $LOCALINSTALLDIR      || Warn "directory '$LOCALINSTALLDIR' already exsist, skipping new installation."

	# INSTALL miniconda: -b=batch mode, -m=no menus, -p <dir>=install dir
	test -d $LOCALINSTALLDIR  || $MINICONDAINSTALLSCRIPT -b -m -p $LOCALINSTALLDIR
	touch $LOCALINSTALLDIR/CACHEDIR.TAG	
	
	$LOCALINSTALLDIR/bin/conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main 
	$LOCALINSTALLDIR/bin/conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r 
}

function InstallModules()
{
	$LOCALINSTALLDIR/bin/conda update -y -n base -c conda-forge conda
	$LOCALINSTALLDIR/bin/conda install -y mamba micromamba
	Mamba install scikit-learn matplotlib pandas
	Mamba install keras
	Mamba install tensorflow
}
	
function InstallModulesExtra()
{
	Mamba install opencv
	#Mamba install pytorch torchvision # uninstalls tensorflow
	Mamba install jupyterlab jupyterhub notebook
	Mamba install mpi4py py-cpuinfo seaborn mypy pylint pyflakes	

	Mamba install -c conda-forge jupyterhub-idle-culler jupyter_contrib_nbextensions jupyter_nbextensions_configurator nb_conda_kernels pycurl
	Mamba install -c conda-forge datasets tqdm transformers tiktoken wandb # for nanoGPT, for ultralytics, thop not available
	#$INSTALLBIN/jupyter nbextensions_configurator enable --user
}

#function InstallMiniconda()
#{
#    local MINICONDA=Miniconda3-2025.06-0-Linux-x86.sh
#    #miniconda_py312_24.1.2.sh
#
#    Info "INSTALL[$MINICONDA].."
#    
#    CleanInstallDir
#    
#    #wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh    
#    $MYSUDO $BOOTSTRAP_DIR/Files/Anaconda/$MINICONDA -b -u -f -p $INSTALLDIR 2>&1 | grep -v "entry_point.py:256: DeprecationWarning:"
#
#    CondaBase tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main 
#    CondaBase tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r 
#
#    #Conda python=3.12.0 # 3.13 cannot install tensorflow-gpu
#    Conda python=3.12.11=h22baa00_0 
#
#    CondaBase tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main
#    CondaBase tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r
#
#    Conda -c conda-forge mamba micromamba
#    Conda -c conda-forge tensorflow-gpu # already in tensorflow install: keras tensorboard
#    Conda -c conda-forge opencv 
#    Conda -c conda-forge pytorch torchvision # no more a package, torchaudio, ?
#
#    Conda scikit-learn jupyterlab jupyterhub notebook # _ipyw_jlab_nb_ext_conf
#    
#    # NOTE: possible fix of sqlite problems, reinstall sqlite,
#    #       see https://stackoverflow.com/questions/78990030/undefined-symbol-sqlite3-deserialize-in-jupyter-notebook-visual-studio-code
#    # ImportError: /mnt/scratch/opt/anaconda-2025.06/lib/python3.12/lib-dynload/_sqlite3.cpython-312-x86_64-linux-gnu.so: undefined symbol: sqlite3_deserialize
#    # ModuleNotFoundError: No module named 'pysqlite2'
#    # install pysqlite2, use sqlite reinstall trick instead
#    # ONLY for 2025.11, but not anymore (dec. 2025)??
#    # CondaBase remove -y sqlite
#    Conda sqlite
#
#    Conda -c conda-forge jupyterhub-idle-culler jupyter_contrib_nbextensions jupyter_nbextensions_configurator nb_conda_kernels pycurl
#    Conda -c conda-forge datasets tqdm transformers tiktoken wandb # for nanoGPT, for ultralytics, thop not available
#    Conda mpi4py py-cpuinfo matplotlib seaborn mypy pylint pyflakes
#    
#    $INSTALLBIN/jupyter nbextensions_configurator enable --user
#    
#    CondaBase clean -y --force-pkgs-dirs
#
#    Ok "INSTALL[$MINICONDA]: DONE"
#}

function Modules()
{
	#module add use.own
	module add miniconda
	local M=`module list | grep -v "Currently Loaded"`
	echo "  CURRENT MODULES: $M" 
}

function Test()
{
	Echo "CURRENT SETUP.."

	Modules
	local WHICHCONDA=`which conda   || Err "could not locate 'conda'"`
	local WHICHPYTHON=`which python || Err "could not locate 'python'"`
	local VERCONDA=`conda   --version`
	local VERPYTHON=`python --version`

	echo "  CONDA BIN      : $WHICHCONDA"
	echo "  PYTHON BIN     : $WHICHPYTHON"
	echo "  CONDA VERSION  : $VERCONDA"
	echo "  PYTHON VERSION : $VERPYTHON"
	echo "  PYTHONPATH     : $PYTHONPATH"
}

function Cleanup()
{
	Echo "CLEANUP.."
	conda clean --all --yes
}

Echo "INSTALL MINICONDA.."

WipeMiniconda
Init
Install
InstallModules
InstallModulesExtra
./Unused/keras_demo.py
Test
Cleanup

IS_DONE=1
Echo "DONE"
