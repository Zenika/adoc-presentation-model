#!/bin/bash
 
if [ "$#" -ne 1 ]; then
  echo "Usage : $0 <workspaceDirectory>" >&2
  exit 1
fi
if ! [ -e "$1" ]; then
  echo "$1 not found" >&2
  exit 1
fi
if ! [ -d "$1" ]; then
  echo "$1 not a directory" >&2
  exit 1
fi

echo "Getting last tag..."
lastTag=`git describe --tags --abbrev=0`

for projectRoot in . cg-utils cg-msg-tracker cg-elastic
do 
  #create the history folder if not exist
  targetDir=$1/$projectRoot/target/generated-docs/history
  sourceFiles=$1/$projectRoot/src/docs/asciidoc/*.adoc
  mkdir --parents $targetDir
  for adocFile in $sourceFiles
  do
    echo "Getting git log for $adocFile file..."
    #get the log from git and write it in CSV in a saved history file, for asciidoc usage
	#"follow" helps not loosing history after file rename
    git log --follow --max-count=30 --date=short --pretty=format:\|%cd\|%an\|%s -- $adocFile > $targetDir/`basename $adocFile`.psv
	echo "...Successfully written $targetDir/`basename $adocFile`.psv"
	echo "Getting git diff since last tag ($lastTag) for $adocFile file..."
	#the four first lines are git diff data, not usefull for doc reader, we remove them
	git diff $lastTag.. -- $adocFile | tail -n +5 > $targetDir/`basename $adocFile`.diff
	echo "...Successfully written $targetDir/`basename $adocFile`.diff"
  done
  ls -lrt $targetDir
done
