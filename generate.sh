#!/bin/sh

set -e # stop on error

usage() {
  echo 'Usage : generate.sh [training-subject]'
  exit
}

if [ "$1" != "" ]; then # training-subject is specified in call
  if [ ! -d "docs/$1" ]; then
    RED='\033[0;31m'
    echo "${RED}Folder docs/$1 does not exist"
    exit 1
  fi
else
  echo "\n*** No training-subject given as script parameter, everything will be generated ***"
fi

# checking local docker image without requiring internet access, then pulling if not present
LOCAL_IMAGE_REF=$(docker images -q asciidoctor/docker-asciidoctor:latest 2>/dev/null)
if [ "$LOCAL_IMAGE_REF" = "" ]; then
  echo "\nAsciidoctor Docker image not present locally, pulling..."
  docker image pull asciidoctor/docker-asciidoctor:latest
fi

echo -n "\nReinitializing 'build-docs' output folder... "
rm -rf build-docs # else plantuml diagrams won't be rebuilt
cp -r docs build-docs

rm -f build-docs/*/_*.adoc # remove _README.adoc from training folders

# putting images and libraries in reveal.js for runtime usage
mkdir reveal
cp -r build-docs/* reveal/
mv reveal build-docs/

if [ "$1" != "" ]; then   # when folder is specified
  rm -f build-docs/*.adoc # don't generate root docs
  mv build-docs/$1/*.adoc build-docs/
  cp -r build-docs/themes build-docs/reveal/
else # generating all
  mv build-docs/*/*.adoc build-docs/
fi
echo "OK"

cd build-docs
echo "\nThese documents will be processed : "
ls -1 *.adoc
cd ..

# the only docker tag available to date (01/01/2020) is 'latest' :(

echo -n "\nGenerating HTML... "
docker run --rm -v $PWD/build-docs:/documents asciidoctor/docker-asciidoctor asciidoctor -r asciidoctor-diagram -r /documents/lib/c3js-block-macro.rb -r /documents/lib/cloud-block-macro.rb -a icons=font -a experimental=true -a idprefix="" -a idseparator="-" -a plantuml-config=themes/plantuml.cfg -a screenshot-dir-name=screenshots -a source-highlighter=highlight.js -a highlightjsdir=lib/highlight -a highlightjs-theme=gruvbox-dark -a toc=left -a toclevels=2 -a sectanchors=true -a sectnums=true -a sectlinks=true -a favicon=themes/favicon.png -a linkcss=true -a stylesheet=html-zenika.css -a stylesdir=themes/css '*.adoc'
echo "OK"

# removing files needing only HTML generation
rm -f /build-docs/index.adoc

echo -n "Generating Reveal.js... "
docker run --rm -v $PWD/build-docs:/documents asciidoctor/docker-asciidoctor asciidoctor-revealjs -r asciidoctor-diagram -r /documents/lib/c3js-block-macro.rb -r /documents/lib/cloud-block-macro.rb -a icons=font -a experimental=true -a idprefix="" -a idseparator="-" -a plantuml-config=themes/plantuml.cfg -a screenshot-dir-name=screenshots -a source-highlighter=highlightjs -a highlightjs-theme=lib/highlight/styles/gruvbox-dark.min.css -a revealjsdir=https://cdnjs.cloudflare.com/ajax/libs/reveal.js/3.8.0 -a revealjs_transition=slide -a revealjs_slideNumber=true -a revealjs_width=1100 -a revealjs_height=700 -a revealjs_plugins=revealjs-plugins/revealjs-plugins.js -a revealjs_plugins_configuration=revealjs-plugins/revealjs-plugins-conf.js -a docinfo=shared -a toc=macro -a toclevels=1 -a revealjs_plugin_pdf -a plantuml-config=themes/plantuml.cfg -D reveal '*.adoc'
echo "OK"

echo -n "Generating PDF... "
docker run --rm -v $PWD/build-docs:/documents asciidoctor/docker-asciidoctor asciidoctor-pdf -r asciidoctor-diagram -a icons=font -a experimental=true -a plantuml-config=themes/plantuml.cfg -a screenshot-dir-name=screenshots -a source-highlighter=coderay -a toclevels=2 -a toc -a title-page -a pagenums -a pdf-style=themes/pdf-theme.yml -a pdf-fontsdir=themes/fonts/pdf -a allow-uri-read '*.adoc'
echo "OK\n"
