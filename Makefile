DIR     := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
PROJECT := $(shell basename ${DIR})
BRANCH  := $(shell git rev-parse --abbrev-ref HEAD)
ARCHIVE := ${PROJECT}-${BRANCH}
DOC     := PerconaSetup

dist: ${ARCHIVE}.zip ${ARCHIVE}.tgz

test: composer.lock vendor
	composer test

tangle:
	emacs --batch -q --no-site-file --eval '(require (quote org))' --eval '(org-babel-tangle-file "ge-utility-server.org")'

composer.lock: composer.json
	composer update

doc: ${DOC}.pdf ${DOC}.docx

${DOC}.odt: ${DOC}.org
	emacs --batch -q --no-site-file --find-file ${DOC}.org --funcall org-odt-export-to-odt

${DOC}.docx: ${DOC}.odt
	soffice --headless --convert-to docx --outdir ${DIR} ${DIR}/${DOC}.odt

${DOC}.pdf: ${DOC}.docx
	soffice --headless --convert-to pdf --outdir ${DIR} ${DIR}/${DOC}.docx

clean:
	rm -f *.sh *~ *.tex *.odt *.txt PXC.te
	rm -rf ${ARCHIVE}.zip ${ARCHIVE}.tar ${ARCHIVE}.tgz ${DOC}.pdf ${DOC}.docx vendor

${ARCHIVE}.tgz: ${ARCHIVE}.tar
	gzip < ${ARCHIVE}.tar > ${ARCHIVE}.tgz

${ARCHIVE}.zip ${ARCHIVE}.tar: ${DOC}.pdf
	git archive --prefix ${PROJECT}/ --format $(subst .,,$(suffix $@)) ${BRANCH} > $@

.PHONY: test dist clean doc tangle
