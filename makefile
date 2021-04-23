# makefile

.PHONY : dib check_requirements check_docker check_docker_compose \
         check_kompose check_kubectl check_bash install link uninstall build discard

source_folder = .
app_name = dib
bin_path = /usr/local/bin/$(app_name)
destination_folder = /usr/local/lib/$(app_name)
main_program = $(destination_folder)/$(app_name).sh
copy_exclusions = $(source_folder)/exclude-files.txt
build_version = v1.0.0-rc5
build_location = $(source_folder)/build
build = $(build_location)/$(app_name)-$(build_version).zip
build_exclusions = -x '*.git*' -x '*build/*' -x '*.DS_Store*'

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
	test -d $(destination_folder) || mkdir -p $(destination_folder)
	rsync -av --exclude-from=$(copy_exclusions) $(source_folder)/ $(destination_folder)

link:
	test -x $(main_program) || chmod +x $(main_program)
	test -h $(bin_path) || ln -s $(main_program) $(bin_path)

uninstall:
	@echo Removing $(bin_path) ...
	test ! -e $(bin_path) || unlink $(bin_path)
	test ! -d $(destination_folder) || rm -rf $(destination_folder)

build:
	@echo Bundling app to $(build) ...
	zip -r $(build) $(source_folder)/ $(build_exclusions)

discard:
	@echo Discarding $(build) ...
	test ! -f $(build) || rm -f $(build)