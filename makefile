# makefile

.PHONY : dib check_requirements check_docker check_docker_compose \
				 check_kompose check_kubectl check_bash install link clean build

source_folder = .
app_name = dib
bin_path = /usr/local/bin/$(app_name)
destination_folder = /usr/local/lib/$(app_name)
main_program = $(destination_folder)/$(app_name).sh
copy_exclusions = $(source_folder)/exclude-files.txt
build_version = v1.0.0-rc1
build_location = $(source_folder)/build
build = $(build_location)/$(app_name)-$(build_version).zip
build_exclusions = -x '*.git*' -x '*build/*'

dib: check_requirements install link

check_requirements: check_docker check_docker_compose check_kompose check_kubectl check_bash

check_docker: 
	@echo Checking docker ...
	@which docker || { echo Please install docker and continue; exit 1; }

check_docker_compose:
	@echo Checking docker-compose ...
	@which docker-compose || { echo Please install docker-compose and continue; exit 1; }

check_kompose:
	@echo Checking kompose ...
	@which kompose || { echo Please install kompose and continue; exit 1; }

check_kubectl:
	@echo Checking kubectl ...
	@which kubectl || { echo Please install kubectl and continue; exit 1; }

check_bash:
	@echo Checking bash ...
	@which bash || { echo Please install bash and continue; exit 1; }

install:
	@echo Installing to $(destination_folder) ...
	[[ -d $(destination_folder) ]] || mkdir -p $(destination_folder)
	rsync -av --exclude-from=$(copy_exclusions) $(source_folder)/ $(destination_folder)

link:
	[[ -x $(main_program) ]] || chmod +x $(main_program)
	[[ -h $(bin_path) ]] || ln -s $(main_program) $(bin_path)

clean:
	unlink $(bin_path)
	rm -rf $(destination_folder)

build:
	@echo Bundling app to $(build) ...
	zip -r $(build) $(source_folder)/ $(build_exclusions)