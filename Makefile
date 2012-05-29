#
# Makefile for NovaProva website
#


DELIVERABLES = \
    docs.html \
    faq.html \
    index.html \
    novaprova.css \
    jquery-1.7.2.min.js \
    stock-photo-7540791-eye-chart-series.jpg

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

build/%.css: %.css
	@mkdir -p $(@D)
	cp $< $@

build/%.js: %.js
	@mkdir -p $(@D)
	cp $< $@

build/%.jpg: %.jpg
	@mkdir -p $(@D)
	cp $< $@

