default:
	./main.sh

build:
	@echo "nothing to build"

uninstall:
	rm -f /usr/local/bin/2048

install: uninstall
	ln -s "$(PWD)/main.sh" /usr/local/bin/2048

alias:
	echo "alias 2048='$PWD/main.sh'" >> .bashrc
