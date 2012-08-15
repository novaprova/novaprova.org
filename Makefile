#
# Makefile for NovaProva website
#


DELIVERABLES = \
    docs.html \
    faq.html \
    index.html \
    novaprova.css \
    jquery-1.7.2.min.js \
    iStock_000007540791Small_scaled.jpg \
    doc-1.0/get-start/index.html

all: $(addprefix build/,$(DELIVERABLES))

DESTINATION_install = \
    $(USER),novaprova@web.sourceforge.net:/home/project-web/novaprova/htdocs
DESTINATION_test = \
    /tmp/novaprova

install test: 
	rsync -vad -e ssh build/ $(DESTINATION_$@)

build/%.html: %.html
	@mkdir -p $(@D)
	( \
	    sed -n -e '1,/^---/p' < $< ;\
	    cat head.html ;\
	    sed -e '1,/^---/d' < $< ;\
	    cat foot.html ;\
	) | mustache > $@

build/doc-1.0/%: doc-1.0.tar.bz2
	( cd build ; tar -xvf ../doc-1.0.tar.bz2 )

build/%.css: %.css
	@mkdir -p $(@D)
	cp $< $@

build/%.js: %.js
	@mkdir -p $(@D)
	cp $< $@

build/%.jpg: %.jpg
	@mkdir -p $(@D)
	cp $< $@

