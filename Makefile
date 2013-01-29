#
# Makefile for NovaProva website
#

comma=,

MUSTACHE_FILES = \
    docs.html \
    download.html \
    faq.html \
    index.html \
    contact.html

DOC_VERSIONS = 	1.0 1.1 1.2

DOC_FILES = \
    $(sort \
	$(foreach v,\
	    $(DOC_VERSIONS),\
	    $(shell tar -tf doc-$v.tar.bz2 | egrep -v '/$$' | egrep -v '\.(o|a)$$' | egrep -v testrunner)\
	)\
    )

_versions_yaml=\
	$(subst $(comma)],],[$(foreach v,$(DOC_VERSIONS),{ v: "$v" }$(comma))])

PLAIN_FILES = \
    novaprova.css \
    jquery-1.7.2.min.js \
    iStock_000007540791Small_scaled.jpg \
    googlec696ef6eb0b0b2f3.html

all: $(addprefix build/,$(PLAIN_FILES) $(MUSTACHE_FILES) $(DOC_FILES))

DESTINATION_install = \
    $(USER),novaprova@web.sourceforge.net:/home/project-web/novaprova/htdocs
DESTINATION_test = \
    /tmp/novaprova

install test: 
	rsync -vad -e ssh build/ $(DESTINATION_$@)

$(addprefix build/,$(MUSTACHE_FILES)) : build/%.html : %.html
	@mkdir -p $(@D)
	( \
	    sed -n -e '1p' < $< ;\
	    echo 'versions: $(_versions_yaml)' ;\
	    sed -n -e '2,/^---/p' < $< ;\
	    cat head.html ;\
	    sed -e '1,/^---/d' < $< ;\
	    cat foot.html ;\
	) | mustache > $@

$(addprefix build/,$(PLAIN_FILES)) : build/% : %
	@mkdir -p $(@D)
	cp $< $@

$(addprefix build/,$(DOC_FILES)): $(foreach v,$(DOC_VERSIONS),doc-$v/.stamp)
	@mkdir -p $(@D)
	cp `echo $@ | sed -e 's|^build/||'` $@

doc-%/.stamp: doc-%.tar.bz2
	@echo "Extracting docs from $<"
	$(RM) -r doc-$*
	tar -xvf doc-$*.tar.bz2
	find doc-$* -type f -name '*.html' | while read file ; do \
	    echo "Munging $$file" ;\
	    ( \
		dir=`dirname $$file` ;\
		addcss="" ;\
		cssfiles=`cd $$dir && ls *.css 2>/dev/null` ;\
		if [ -n "$$cssfiles" ] ; then \
		    for css in $$cssfiles ; do \
			[ -n "$$addcss" ] && addcss="$$addcss, " ;\
			addcss="$$addcss{path: $$css}" ;\
		    done ;\
		fi ;\
		echo '---' ;\
		sed -n -e 's/.*<title>\(.*\)<\/title>.*/\1/p' < $$file | sed -e 's/://g' -e 's/^/title: /' ;\
		echo 'pathup: '`echo $@ | sed -e 's|[^/][^/]*|..|g'`/;\
		echo "addcss: [$$addcss]" ;\
		echo '---' ;\
		cat head.html ;\
		echo '<div id="docs" class="column">' ;\
		sed -e '1,/<body>/d' -e '/<\/body>/,$$d' < $$file ;\
		echo '</div>' ;\
		cat foot.html ;\
	    ) | mustache > $$file.new ;\
	    mv -f $$file.new $$file ;\
	done
	touch $@


clean:
	$(RM) -r $(addprefix doc-,$(DOC_VERSIONS)) build $(DESTINATION_test)
