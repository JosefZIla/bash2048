default:
	./main.sh

build:
	@echo "nothing to build"

unlink:
	rm -f /usr/local/bin/2048

uninstall: unlink
	rm -rf /opt/2048

link: unlink
	ln -s "$(PWD)/main.sh" /usr/local/bin/2048

install: unlink uninstall
	mkdir -p /opt/2048
	cp *sh /opt/2048/
	ln -s /opt/2048/main.sh /usr/local/bin/2048

alias:
	@echo "add alias in to '.bashrc'"
	@echo "alias 2048='$PWD/main.sh'"
