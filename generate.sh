#!/bin/sh

# https://github.com/asciidoctor/docker-asciidoctor/releases
ADOC_DOCKER_REPO=asciidoctor
ADOC_IMG_TAG=1.60 # latest as of 12/12/2023

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

    echo "===> Generating root index.html <==="
    rsync -rtv --delete --quiet "framework" "build-docs/"
    cp docs/index.adoc build-docs/
    docker run --rm -v $PWD/build-docs:/documents $ADOC_DOCKER_REPO/docker-asciidoctor:$ADOC_IMG_TAG asciidoctor \
        -a icons=font \
        -a experimental=true \
        -a sectlinks=true \
        -a favicon=framework/themes/favicon-white.png \
        -a linkcss=true \
        -a stylesheet=html-zenika.css \
        -a stylesdir=framework/themes/css \
        index.adoc
    echo "OK\n"

    cd docs
    FOLDER_LIST=$(echo */*)
    cd ..
    for FOLDER in $FOLDER_LIST; do
        # group folders may contain also non folder files (a readme for example)
        if [ -d "docs/$FOLDER" ]; then
            echo "===> Generating for $FOLDER <==="
            ./$0 $FOLDER $2
        fi
    done

    exit

fi

# folder is specified in call

if [ ! -d "docs/$1" ]; then
    RED='\033[0;31m'
    echo "${RED}Folder ./docs/$1 does not exist"
    exit 1
fi

if [ "$ALL" = "true" ] && [ -f "docs/$1/no-auto-generation" ]; then
    echo "Found 'no-auto-generation' file, skipping folder 🙅‍♂️\n"
    exit 0
fi

# checking local docker image without requiring internet access, then pulling if not present
LOCAL_IMAGE_REF=$(docker images -q $ADOC_DOCKER_REPO/docker-asciidoctor:$ADOC_IMG_TAG)
if [ "$LOCAL_IMAGE_REF" = "" ]; then
    echo "\nDocker image $ADOC_DOCKER_REPO/docker-asciidoctor:$ADOC_IMG_TAG not present locally, pulling..."
    docker image pull $ADOC_DOCKER_REPO/docker-asciidoctor:$ADOC_IMG_TAG
fi

FOLDER=${1%/*}
SUBFOLDER=${1##*/}

if [ "$2" != "zip" ]; then
    echo -n "\nSynchronizing docs/$1 to build-docs/$1 ... "
    mkdir -p build-docs/$1

    if [ "$LIVE_RELOAD" = "true" ]; then
        rm -rf build-docs/$1/images/* # else plantuml diagrams won't be rebuilt
        cp -r docs/$1 build-docs/$FOLDER/
        html_docinfo="shared"
    else
        # not each time, else live reload will give mostly 404 errors in browsers
        rsync -rtv --delete --quiet "docs/$1" "build-docs/$FOLDER" #for debug : --info=DEL,STATS2
        html_docinfo="private"                                     # for now html and reveal.js share the same docinfo-*.html name T_T
    fi

    rsync -rtv --delete --quiet "framework" "build-docs/"
    # to be able to use emojis in pdf
    cp build-docs/framework/themes/plantuml.cfg build-docs/framework/themes/plantuml-pdf.cfg
    echo "skinparam defaultFontName Symbola" >>build-docs/framework/themes/plantuml-pdf.cfg

    cp framework/docinfo-*.html build-docs/$1/      # it also removes traces of an eventual LIVE_RELOAD insert
    cp -r framework/revealjs-plugins build-docs/$1/ # to have chalkboard pngs at runtime
fi

if [ "$LIVE_RELOAD" = "true" ]; then
    # live.js is not added by defaut : it generates internet traffic and may geopardise a training when connexion is bad (?)
    echo "<script type=\"text/javascript\" src=\"http://livejs.com/live.js\"></script>" >>build-docs/$1/docinfo-footer.html
fi
rm -f build-docs/*/*/_*.adoc # remove _README.adoc from training folders

echo "OK"

cd build-docs
echo "\nThese documents will be processed : "
ls -1 $1/*.adoc
cd ..

if [ "$2" = "html" ] || [ "$2" = "all" ] || [ -z "$2" ]; then

    echo -n "\nGenerating HTML... "
    start=$(date +%s)
    # icon-set=fas is advised in PDF but not available yet for HTML : https://github.com/asciidoctor/asciidoctor/issues/3694
    # /!\ docinfo=shared is not useful for HTML, it was only added for live reloading. But it does not alter the experience. We could just have a docinfo-header.html with the live line.
    docker run --rm -v $PWD/build-docs:/documents $ADOC_DOCKER_REPO/docker-asciidoctor:$ADOC_IMG_TAG asciidoctor \
        -r asciidoctor-kroki \
        -r /documents/framework/lib/c3js-block-macro.rb \
        -r /documents/framework/lib/cloud-block-macro.rb \
        -r /documents/framework/lib/copy-to-clipboard-docinfo-processor.rb \
        -a icons=font \
        -a experimental=true \
        -a idprefix="" \
        -a idseparator="-" \
        -a kroki-plantuml-include=../../framework/themes/plantuml.cfg \
        -a screenshot-dir-name=screenshots \
        -a source-highlighter=highlight.js \
        -a highlightjsdir=../../framework/lib/highlight \
        -a highlightjs-theme=gruvbox-dark \
        -a docinfo=$html_docinfo \
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
    end=$(date +%s)
    echo "OK in $(($end - $start))s"

fi

if [ "$2" = "reveal" ] || [ "$2" = "all" ] || [ -z "$2" ]; then

    if [ ! -d build-docs/reveal.js ]; then
        echo -n "\nDownloading core RevealJS files... "
        git clone -c advice.detachedHead=false --quiet --branch 4.1.2 --depth 1 https://github.com/hakimel/reveal.js.git build-docs/reveal.js
        echo "OK"
    fi

    # default highlight.js languages : https://highlightjs.org/download/

    echo -n "\nGenerating Reveal.js... "
    start=$(date +%s)
    # --verbose \
    docker run --rm -v $PWD/build-docs:/documents $ADOC_DOCKER_REPO/docker-asciidoctor:$ADOC_IMG_TAG asciidoctor-revealjs \
        -r asciidoctor-kroki \
        -r /documents/framework/lib/c3js-block-macro.rb \
        -r /documents/framework/lib/cloud-block-macro.rb \
        -a icons=font \
        -a experimental=true \
        -a idprefix="" \
        -a idseparator="-" \
        -a kroki-plantuml-include=../../framework/themes/plantuml.cfg \
        -a screenshot-dir-name=screenshots \
        -a source-highlighter=highlightjs \
        -a highlightjs-theme=../../framework/lib/highlight/styles/gruvbox-dark.min.css \
        -a highlightjs-languages=asciidoc \
        -a revealjsdir=../../reveal.js \
        -a revealjs_transition=slide \
        -a revealjs_slideNumber=true \
        -a revealjs_width=1100 \
        -a revealjs_height=700 \
        -a revealjs_plugins=framework/revealjs-plugins/revealjs-plugins.js \
        -a revealjs_plugins_configuration=framework/revealjs-plugins/revealjs-plugins-conf.js \
        -a revealjs_plugin_pdf \
        -a revealjs_hash=true \
        -a revealjs_history=false \
        -a docinfo=shared \
        -a toc=macro \
        -a toclevels=1 \
        -a outfilesuffix=".htm" \
        $1/*.adoc
    end=$(date +%s)
    echo "OK in $(($end - $start))s"

fi

if [ "$2" = "pdf" ] || [ "$2" = "all" ] || [ -z "$2" ]; then

    echo -n "\nGenerating PDF... "
    start=$(date +%s)
    # can't use asciidoctor-diagram, it needs third party tools install locally (for ex mmdc for mermaid)
    docker run --rm -v $PWD/build-docs:/documents $ADOC_DOCKER_REPO/docker-asciidoctor:$ADOC_IMG_TAG asciidoctor-pdf \
        --verbose --warnings --timings \
        -r asciidoctor-kroki \
        -a icons=font \
        -a experimental=true \
        -a kroki-plantuml-include=/documents/framework/themes/plantuml-pdf.cfg \
        -a screenshot-dir-name=screenshots \
        -a source-highlighter=coderay \
        -a toc -a toclevels=2 \
        -a title-page -a sectnums=true -a pagenums \
        -a pdf-theme=framework/themes/pdf-theme.yml -a pdf-fontsdir=framework/themes/fonts/pdf \
        -a allow-uri-read \
        $1/*.adoc
    end=$(date +%s)
    echo "OK in $(($end - $start))s"

fi

if [ "$ALL" != "true" ] && ([ "$2" = "zip" ] || [ "$2" = "all" ] || [ -z "$2" ]); then

    echo -n "\nGenerating build-docs/zenika-training-$SUBFOLDER.zip... "

    if ! ls build-docs/$1/*.pdf >/dev/null 2>&1; then
        RED='\033[0;31m'
        echo "\n${RED}No PDF in build-docs/$1/, please generate PDFs first"
        exit 1
    fi

    rm -Rf build-docs/$1/$SUBFOLDER-zip build-docs/$1/*.zip build-docs/$1/index.pdf
    mkdir -p build-docs/$1/$SUBFOLDER-zip
    if [ -d "build-docs/$1/student" ]; then
        cp -r build-docs/$1/student/* build-docs/$1/$SUBFOLDER-zip/
    fi
    if [ "$1" == "devops/kubernetes-user-2j" ]; then
        # take student files from kubernetes-user (same base)
        echo "copying student files from devops/kubernetes-user..."
        cp -r build-docs/devops/kubernetes-user/student/* build-docs/$1/$SUBFOLDER-zip/
    fi
    cp build-docs/$1/*.pdf build-docs/$1/$SUBFOLDER-zip/
    # you can put some contextual info in info.txt
    if [ -f "info.txt" ]; then cp info.txt build-docs/$1/$SUBFOLDER-zip/; fi
    cd build-docs/$1/$SUBFOLDER-zip
    zip --recurse-paths --quiet --display-counts ../zenika-training-$SUBFOLDER *
    echo "OK"

fi

echo ""
