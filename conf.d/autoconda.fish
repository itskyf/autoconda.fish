function autoconda --on-variable PWD --description "Automatic activation conda environment"
	if not status is-interactive
		return
	end

	# Iterate over parents (PWD included) to find environment.yaml
	for _dir in (string split -n '/' "$PWD")
		set -l _tree "$_tree/$_dir"

		if test -e "$_tree/environment.yaml"
			set _source "$_tree/environment.yaml"
			set -g __autoconda_old $__autoconda_new
			set -xg __autoconda_new $_tree # Export this for future runs

			break
		end
	end

	# *Not* in conda env and found environment.yaml, activate it and return
	if test -z "$CONDA_DEFAULT_ENV" -a -n "$_source"
		__autoconda_activate_from_file "$_source"

		# Already in an environment
	else if test -n "$CONDA_DEFAULT_ENV"
		# Check if CWD is an environment's child
		if test -n "$__autoconda_old"
			set _dir (string match "$__autoconda_old*" "$PWD")
		else
			set _dir ""
		end

		if test -z "$_dir" # Not an child
			if test -n "$_source" # Found environment.yaml
				__autoconda_activate_from_file "$_source"
			else
				echo "Not found any environment.yaml, deactivating"
				conda deactivate
				set -e __autoconda_new
				set -e __autoconda_old
			end
		end
	end
end

function __autoconda_activate_from_file --description "Activates environment.yml"
	set -l _env_path (string replace $HOME '~' $argv[1])
	echo "Found $_env_path, activating..."
	set -l env_line (cat $argv[1] | grep "^name:")
	set -l env_name (string split -n " " $env_line | sed -n 2p)
	conda activate $env_name
end
