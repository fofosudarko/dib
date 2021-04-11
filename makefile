# makefile

.PHONY : dib check_requirements check_docker check_docker_compose check_kompose check_kubectl check_bash install link clean

bin_path = /usr/local/bin/dib
destination_folder = /usr/local/lib/dib
main_program = $(destination_folder)/dib.sh
exclude_files = ./exclude-files.txt

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
	rsync -av --exclude-from=$(exclude_files) ./ $(destination_folder)

link:
	[[ -x $(main_program) ]] || chmod +x $(main_program)
	[[ -h $(bin_path) ]] || ln -s $(main_program) $(bin_path)

clean:
	unlink $(bin_path)
	rm -rf $(destination_folder)