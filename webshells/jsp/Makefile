.PHONY: all
all: webshell.war

webshell.war: webshell.jsp WEB-INF/web.xml
	jar -cf $@ $^

.PHONY: clean
clean:
	rm -f webshell.war
