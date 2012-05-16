#
# Makefile for NovaProva website
#

all:

DELIVERABLES = \
    docs.html \
    faq.html \
    index.html \
    novaprova.css \
    stock-photo-7540791-eye-chart-series.jpg

DESTINATION_install = \
    $(USER),novaprova@web.sourceforge.net:/home/project-web/novaprova/htdocs
DESTINATION_test = \
    /tmp/novaprova

install test:
	rsync -vad -e ssh $(DELIVERABLES) $(DESTINATION_$@)
