all: prod
prod: Sources/*.adb Sources/*.ads
	gprbuild -d -P$(CURDIR)/pacman.gpr -XSpecific_build_modes=Production

dev: Sources/*.adb Sources/*.ads
	gprbuild -d -P$(CURDIR)/pacman.gpr -XSpecific_build_modes=Development

perform: Sources/*.adb Sources/*.ads
	gprbuild -d -P$(CURDIR)/pacman.gpr -XSpecific_build_modes=Performance


adacurses: 
	make -C AdaCurses/

doc: Sources/*.adb Sources/*.ads
	gnatdoc -P$(CURDIR)/pacman.gpr --no-subprojects -XSpecific_build_modes=Production --enable-build -w -p -l

clean:
	gprclean -r -P$(CURDIR)/pacman.gpr -XSpecific_build_modes=Production
	gprclean -r -P$(CURDIR)/pacman.gpr -XSpecific_build_modes=Development
	gprclean -r -P$(CURDIR)/pacman.gpr -XSpecific_build_modes=Performance
