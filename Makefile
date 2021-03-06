#
# Makefile for NovaProva website
#

comma=,
define space
 
endef

UNAME_S=$(shell uname -s)

MUSTACHE_FILES = \
    docs.html \
    download.html \
    faq.html \
    index.html \
    support.html \
    darwin.html

DOC_VERSIONS = 	1.0 1.1 1.2

DOC_FILES = \
    $(sort \
	$(foreach v,\
	    $(DOC_VERSIONS),\
	    $(shell tar -tf doc-$v.tar.bz2 | egrep -v '/$$' | egrep -v '\.(o|a)$$' | egrep -v testrunner)\
	)\
    )

_versions_yaml=\
	[ "$(subst $(space),"$(comma)$(space)",$(DOC_VERSIONS))" ]

PLAIN_FILES = \
    novaprova.css \
    jquery-1.7.2.min.js \
    iStock_000007540791Small_scaled.jpg \
    googlec696ef6eb0b0b2f3.html \
    lca2013-novaprova-final.odp \
    robots.txt sitemap.xml

all: $(addprefix build/,$(PLAIN_FILES) $(MUSTACHE_FILES) $(DOC_FILES))

DEPLOY_REPO_URL=	git@github.com:novaprova/novaprova.github.io.git
DESTINATION__deploy = \
    deploy
DESTINATION_test = \
    /tmp/novaprova

test:
	rsync -vad -e ssh build/ $(DESTINATION_$@)

install:
	if [ ! -d deploy ] ; then \
	    git clone $(DEPLOY_REPO_URL) deploy ;\
	else \
	    ( \
		cd deploy || exit 1; \
		git checkout master ;\
		git ls-files -o -z | xargs -0 $(RM) ;\
		git fetch $(DEPLOY_REPO_URL) master ;\
		git reset --hard origin/master ;\
	    ) ;\
	fi
	rsync -vad build/ deploy/
	( \
	    cd deploy || exit 1 ;\
	    git ls-files -o -z | xargs -0 git add ;\
	    git commit -a -m "Automatic commit by 'make install'" ;\
	    git push origin master ;\
	)


# Mustachify the css file for inlining by mustache
css.mustache: novaprova.css
	cp $< $@

# Usage: $(call mustache, foo.yaml, bar.html) > baz.html
ifeq ($(UNAME_S),Darwin)
define mustache
mustache $(1) $(2)
endef
else
define mustache
( echo "---" ; cat $(1) ; echo "---" ; cat $(2) ) | mustache
endef
endif

$(addprefix build/,$(MUSTACHE_FILES)) : build/%.html : %.html head.html foot.html css.mustache
	@mkdir -p $(@D)
	( \
	    echo 'versions: $(_versions_yaml)' ;\
	    sed -e '1d' -e '/^---/,$$d' < $< \
	) > $@.tmp.yaml
	( \
	    cat head.html ;\
	    sed -e '1,/^---/d' < $< ;\
	    cat foot.html ;\
	) > $@.tmp.html
	$(call mustache, $@.tmp.yaml, $@.tmp.html) > $@
	$(RM) $@.tmp.yaml $@.tmp.html

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
	    dir=`dirname $$file` ;\
	    addcss="" ;\
	    cssfiles=`cd $$dir && ls *.css 2>/dev/null` ;\
	    if [ -n "$$cssfiles" ] ; then \
		for css in $$cssfiles ; do \
		    [ -n "$$addcss" ] && addcss="$$addcss, " ;\
		    addcss="$$addcss{path: $$css}" ;\
		done ;\
	    fi ;\
	    ( \
		sed -n -e 's/.*<title>\(.*\)<\/title>.*/\1/p' < $$file | sed -e 's/://g' -e 's/^/title: /' ;\
		echo 'pathup: '`echo $@ | sed -e 's|[^/][^/]*|..|g'`/;\
		echo "addcss: [$$addcss]" ;\
		echo "css_is_separate: yes" ;\
	    ) > $$file.tmp.yaml ;\
	    ( \
		cat head.html ;\
		echo '<div id="docs" class="column">' ;\
		sed -e '1,/<body>/d' -e '/<\/body>/,$$d' < $$file ;\
		echo '</div>' ;\
		cat foot.html ;\
	    ) > $$file.tmp.html ;\
	    $(call mustache, $$file.tmp.yaml, $$file.tmp.html) > $$file.new ;\
	    mv -f $$file.new $$file ;\
	    $(RM) $$file.tmp.yaml $$file.tmp.html ;\
	done
	touch $@


clean:
	$(RM) -r $(addprefix doc-,$(DOC_VERSIONS)) build $(DESTINATION_test) css.mustache
