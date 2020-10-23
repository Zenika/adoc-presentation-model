#!/bin/sh

# https://github.com/asciidoctor/docker-asciidoctor/releases
ADOC_IMG_TAG="1.1.0" # latest as of 01/03/2020

set -e # stop on error

# usage() {
if [ "$ALL" != "true" ]; then
  echo 'Usage : generate.sh [all|<folder>] [all|html|reveal|pdf|zip] [live]'
fi
# exit
# }

if [ "$3" = "live" ]; then

  echo "\nFor browser live reload, launch a HTTP server in another shell, for example :"
  echo "cd build-docs ; python3 -m http.server\n"
  echo "Proceeding live-reload cycle indefinitely, stop it with CTRL+C..."
  inotifywait -r -m -e modify --format '%w%f' ./docs/$1 ./framework |
    while read FILE; do
      if [ -f "$FILE.double" ]; then
        # echo "there is already a $FILE.double file, it's a duplicate event from inotifywait, doing nothing"
        rm $FILE.double
      else
        # echo "creating a $FILE.double file and processing"
        touch $FILE.double
        export LIVE_RELOAD=true
        ./$0 $1 $2
      fi
    done

fi

if [ "$1" = "" ] || [ "$1" = "all" ]; then

  echo "\n*** 'all' or no folder given as script parameter, everything will be generated ***\n"

  export ALL=true

  cd docs
  FOLDER_LIST=$(echo */*)
  cd ..
  for FOLDER in $FOLDER_LIST; do
    echo "===> Generating for $FOLDER <==="
    ./$0 $FOLDER $2
  done

  echo -n "===> Generating index.html... "
  docker run --rm -v $PWD/build-docs:/documents asciidoctor/docker-asciidoctor:$ADOC_IMG_TAG asciidoctor \
    -a icons=font \
    -a experimental=true \
    -a sectlinks=true \
    -a favicon=framework/themes/favicon-white.png \
    -a linkcss=true \
    -a stylesheet=html-zenika.css \
    -a stylesdir=framework/themes/css \
    index.adoc
  echo "OK <===\n"

  exit

fi

# folder is specified in call

if [ ! -d "docs/$1" ]; then
  RED='\033[0;31m'
  echo "${RED}Folder ./docs/$1 does not exist"
  exit 1
fi

# checking local docker image without requiring internet access, then pulling if not present
LOCAL_IMAGE_REF=$(docker images -q asciidoctor/docker-asciidoctor:$ADOC_IMG_TAG 2>/dev/null)
if [ "$LOCAL_IMAGE_REF" = "" ]; then
  echo "\nAsciidoctor Docker image not present locally, pulling..."
  docker image pull asciidoctor/docker-asciidoctor:$ADOC_IMG_TAG
fi

SUBFOLDER=${1##*/}

echo -n "\nReinitializing 'build-docs' output folder... "
mkdir -p build-docs
rm -rf build-docs/$1/images/* # else plantuml diagrams won't be rebuilt
cp -r docs/* build-docs/
cp -r framework build-docs/
cp framework/docinfo-header.html build-docs/$1/ # it also removes traces of an eventual LIVE_RELOAD insert
cp -r framework/revealjs-plugins build-docs/$1/ # to have chalkboard pngs at runtime

if [ "$LIVE_RELOAD" = "true" ]; then
  echo
  # live.js is not added by defaut : it generates internet traffic and may geopardise a training when connexion is bad (?)
  echo "<script type=\"text/javascript\" src=\"http://livejs.com/live.js\"></script>" >>build-docs/$1/docinfo-header.html
fi
rm -f build-docs/*/*/_*.adoc # remove _README.adoc from training folders

echo "OK"

cd build-docs
echo "\nThese documents will be processed : "
ls -1 $1/*.adoc
cd ..

if [ "$2" = "html" ] || [ "$2" = "all" ] || [ -z "$2" ]; then

  echo -n "\nGenerating HTML... "
  # /!\ docinfo=shared is not useful for HTML, it was only added for live reloading. But it does not alter the experience. We could just have a docinfo-header.html with the live line.
  docker run --rm -v $PWD/build-docs:/documents asciidoctor/docker-asciidoctor:$ADOC_IMG_TAG asciidoctor \
    -r asciidoctor-diagram \
    -r /documents/framework/lib/c3js-block-macro.rb \
    -r /documents/framework/lib/cloud-block-macro.rb \
    -a icons=font \
    -a experimental=true \
    -a idprefix="" \
    -a idseparator="-" \
    -a plantuml-config=../../framework/themes/plantuml.cfg \
    -a screenshot-dir-name=screenshots \
    -a source-highlighter=highlight.js \
    -a highlightjsdir=../../framework/lib/highlight \
    -a highlightjs-theme=gruvbox-dark \
    -a docinfo=shared \
    -a toc=left \
    -a toclevels=2 \
    -a sectanchors=true \
    -a sectnums=true \
    -a sectlinks=true \
    -a favicon=../../framework/themes/favicon-white.png \
    -a linkcss=true \
    -a stylesheet=html-zenika.css \
    -a stylesdir=../../framework/themes/css \
    $1/*.adoc
  echo "OK"

fi

if [ "$2" = "reveal" ] || [ "$2" = "all" ] || [ -z "$2" ]; then

  echo -n "\nGenerating Reveal.js... "
  docker run --rm -v $PWD/build-docs:/documents asciidoctor/docker-asciidoctor:$ADOC_IMG_TAG asciidoctor-revealjs \
    --verbose \
    -r asciidoctor-diagram \
    -r /documents/framework/lib/c3js-block-macro.rb \
    -r /documents/framework/lib/cloud-block-macro.rb \
    -a icons=font \
    -a experimental=true \
    -a idprefix="" \
    -a idseparator="-" \
    -a plantuml-config=../../framework/themes/plantuml.cfg \
    -a screenshot-dir-name=screenshots \
    -a source-highlighter=highlightjs \
    -a highlightjs-theme=../../framework/lib/highlight/styles/gruvbox-dark.min.css \
    -a revealjsdir=https://cdnjs.cloudflare.com/ajax/libs/reveal.js/3.8.0 \
    -a revealjs_transition=slide \
    -a revealjs_slideNumber=true \
    -a revealjs_width=1100 \
    -a revealjs_height=700 \
    -a revealjs_plugins=framework/revealjs-plugins/revealjs-plugins.js \
    -a revealjs_plugins_configuration=framework/revealjs-plugins/revealjs-plugins-conf.js \
    -a revealjs_plugin_pdf \
    -a revealjs_history=true \
    -a docinfo=shared \
    -a toc=macro \
    -a toclevels=1 \
    -a outfilesuffix=".htm" \
    $1/*.adoc
  echo "OK"

fi

if [ "$2" = "pdf" ] || [ "$2" = "all" ] || [ -z "$2" ]; then

  echo -n "\nGenerating PDF... "
  docker run --rm -v $PWD/build-docs:/documents asciidoctor/docker-asciidoctor:$ADOC_IMG_TAG asciidoctor-pdf \
    -r asciidoctor-diagram \
    -a icons=font \
    -a experimental=true \
    -a plantuml-config=../../framework/themes/plantuml.cfg \
    -a screenshot-dir-name=screenshots \
    -a source-highlighter=coderay \
    -a toclevels=2 \
    -a toc \
    -a title-page \
    -a sectnums=true \
    -a pagenums \
    -a pdf-style=framework/themes/pdf-theme.yml \
    -a pdf-fontsdir=framework/themes/fonts/pdf \
    -a allow-uri-read \
    $1/*.adoc
  echo "OK"

fi

if [ "$ALL" != "true" ] && ([ "$2" = "zip" ] || [ "$2" = "all" ] || [ -z "$2" ]); then

  if [ ! -f "build-docs/$1/$SUBFOLDER.pdf" ]; then
    RED='\033[0;31m'
    echo "${RED}File build-docs/$1/$SUBFOLDER.pdf does not exist, please generate PDFs first"
    exit 1
  fi

  echo -n "\nGenerating build-docs/zenika-training-$SUBFOLDER.zip... "
  if [ -d "build-docs/$1/$SUBFOLDER-zip" ]; then rm -Rf build-docs/$1/$SUBFOLDER-zip; fi
  mkdir -p build-docs/$1/$SUBFOLDER-zip
  cp -r build-docs/$1/student/* build-docs/$1/$SUBFOLDER-zip/
  cp build-docs/$1/*.pdf build-docs/$1/$SUBFOLDER-zip/
  # you can put some contextual info in info.txt
  if [ -f "info.txt" ]; then cp info.txt build-docs/$1/$SUBFOLDER-zip/; fi
  cd build-docs/$1/$SUBFOLDER-zip
  zip --recurse-paths --quiet --display-counts ../zenika-training-$SUBFOLDER *
  echo "OK"

fi

echo ""
