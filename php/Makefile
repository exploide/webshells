.PHONY: all
all: webshell.phar

webshell.phar: webshell.php
	php -d phar.readonly=0 -r '$$p = new Phar("$@"); $$p->addFile("$^"); $$p->setDefaultStub("$^", "$^"); $$p->compressFiles(Phar::GZ);'

.PHONY: clean
clean:
	rm -f *.phar
