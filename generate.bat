@echo off
setlocal enabledelayedexpansion

: https://github.com/asciidoctor/docker-asciidoctor/releases
: latest as of 01/03/2020
set ADOC_IMG_TAG="1.1.0"
set CURRENT_PATH=%~dp0
set CURRENT_SCRIPT=%~n0%~x0

if not "%ALL%" == "true" (
  echo Usage : generate.bat [all^|^<folder^>] [all^|html^|reveal^|pdf^|zip] [live]
) 

:: TODO Implements Live Reload
if  "%~3" == "live" (
  @echo browser live reload isn't currently supported for windows.
  @echo parameter live will be ignored
)

if "%~1" == "" goto AllParameter
if "%~1" == "all" goto AllParameter
goto notAllParameter
:AllParameter
echo *** 'all' or no folder given as script parameter, everything will be generated ***

set ALL=true

for /f "tokens=*" %%G in ('dir /b /a:d "docs"') do (
  for /f "tokens=*" %%H in ('dir /b /a:d  "docs/%%G"') do (
    @echo.
    @echo ===^> Generating for %%G\%%H ^<=== 
    call %CURRENT_PATH%%CURRENT_SCRIPT% "%%G\%%H" %~2
  )
)

@echo ===^> Generating index.html...  ^<===
call docker run --rm -v %CURRENT_PATH%build-docs:/documents asciidoctor/docker-asciidoctor:%ADOC_IMG_TAG% asciidoctor ^
  -a icons=font ^
  -a experimental=true ^
  -a sectlinks=true ^
  -a favicon=framework/themes/favicon-white.png ^
  -a linkcss=true ^
  -a stylesheet=html-zenika.css ^
  -a stylesdir=framework/themes/css ^
  index.adoc
@echo    =^> OK
goto end
:notAllParameter

: folder is specified in call
if not "%~1" == "" (
  if not exist %CURRENT_PATH%docs\%~1 (
    @echo Folder %CURRENT_PATH%docs\%~1 does not exist
    goto error
  )
)

: checking local docker image without requiring internet access, then pulling if not present
set returned=
for /f "delims=" %%i in ('"docker images -q asciidoctor/docker-asciidoctor:%ADOC_IMG_TAG%"') do set "returned=%%i"
if [%returned%] == [] (
    @echo Asciidoctor Docker image not present locally, pulling... 
    docker image pull asciidoctor/docker-asciidoctor:%ADOC_IMG_TAG%
) 
::TODO Implements Zip
:: SUBFOLDER=${1##*/}

@echo.
@echo   Reinitializing 'build-docs' output folder...
if not exist build-docs md build-docs
: else plantuml diagrams won't be rebuilt
if exist build-docs\%~1\images (
  del /Q build-docs\%~1\images\* > nul
  for /f "tokens=*" %%G in ('dir /b /a:d "build-docs\%~1\images\*.*"') do (
      rmdir "build-docs\%~1\images\%%G" /S /Q
  )
)
xcopy /I /E /Q /Y /F docs build-docs\ > nul
if not exist build-docs\framework md build-docs\framework

xcopy /I /E /Q /Y /F framework build-docs\framework\ > nul
: it also removes traces of an eventual LIVE_RELOAD insert
cd framework
xcopy /I /Q /Y /F docinfo-header.html %CURRENT_PATH%\build-docs\%~1\ > nul
: to have chalkboard pngs at runtime
xcopy /I /E /Q /Y /F revealjs-plugins %CURRENT_PATH%\build-docs\%~1\revealjs-plugins\ > nul
cd %CURRENT_PATH%

:: TODO implements LIVE RELOAD

: remove _README.adoc from training folders
cd build-docs\%~1
if exist _*.adoc (
  del _*.adoc
)
cd %CURRENT_PATH%

@echo    =^> OK

cd build-docs/%~1     
@echo. 
@echo   These documents will be processed : 
for /f "delims=" %%i in ('dir /b  *.adoc') do (
  @echo   * %~1\%%i
)
@echo. 
cd %CURRENT_PATH%


:fix name of .adoc path from windows to linux/doker
set ADOC_PATH=%~1
set ADOC_PATH=%ADOC_PATH:\=/%

if "%~2" == "html" goto HtmlParameter
if "%~2" == "all" goto HtmlParameter
if "%~2" == "" goto HtmlParameter
goto notHtmlParameter
:HtmlParameter

@echo   Generating HTML...
: /!\ docinfo=shared is not useful for HTML, it was only added for live reloading. But it does not alter the experience. We could just have a docinfo-header.html with the live line.
call docker run --rm -v %CURRENT_PATH%build-docs:/documents asciidoctor/docker-asciidoctor:%ADOC_IMG_TAG% asciidoctor ^
  -r asciidoctor-diagram ^
  -r /documents/framework/lib/c3js-block-macro.rb ^
  -r /documents/framework/lib/cloud-block-macro.rb ^
  -a icons=font ^
  -a experimental=true ^
  -a idprefix="" ^
  -a idseparator="-" ^
  -a plantuml-config=../../framework/themes/plantuml.cfg ^
  -a screenshot-dir-name=screenshots ^
  -a source-highlighter=highlight.js ^
  -a highlightjsdir=../../framework/lib/highlight ^
  -a highlightjs-theme=gruvbox-dark ^
  -a docinfo=shared ^
  -a toc=left ^
  -a toclevels=2 ^
  -a sectanchors=true ^
  -a sectnums=true ^
  -a sectlinks=true ^
  -a favicon=../../framework/themes/favicon-white.png ^
  -a linkcss=true ^
  -a stylesheet=html-zenika.css ^
  -a stylesdir=../../framework/themes/css ^
  %ADOC_PATH%/*.adoc
@echo    =^> OK
:notHtmlParameter


if "%~2" == "reveal" goto RevealParameter
if "%~2" == "all" goto RevealParameter
if "%~2" == "" goto RevealParameter
goto notRevealParameter
:RevealParameter

@echo   Generating Reveal.js...
docker run --rm -v %CURRENT_PATH%build-docs:/documents asciidoctor/docker-asciidoctor:%ADOC_IMG_TAG% asciidoctor-revealjs  ^
  -r asciidoctor-diagram  ^
  -r /documents/framework/lib/c3js-block-macro.rb  ^
  -r /documents/framework/lib/cloud-block-macro.rb  ^
  -a icons=font  ^
  -a experimental=true  ^
  -a idprefix=""  ^
  -a idseparator="-"  ^
  -a plantuml-config=../../framework/themes/plantuml.cfg  ^
  -a screenshot-dir-name=screenshots  ^
  -a source-highlighter=highlightjs  ^
  -a highlightjs-theme=../../framework/lib/highlight/styles/gruvbox-dark.min.css  ^
  -a revealjsdir=https://cdnjs.cloudflare.com/ajax/libs/reveal.js/3.8.0  ^
  -a revealjs_transition=slide  ^
  -a revealjs_slideNumber=true  ^
  -a revealjs_width=1100  ^
  -a revealjs_height=700  ^
  -a revealjs_plugins=framework/revealjs-plugins/revealjs-plugins.js  ^
  -a revealjs_plugins_configuration=framework/revealjs-plugins/revealjs-plugins-conf.js  ^
  -a docinfo=shared  ^
  -a toc=macro  ^
  -a toclevels=1  ^
  -a revealjs_plugin_pdf  ^
  -a revealjs_history=true  ^
  -a outfilesuffix=".htm"  ^
  %ADOC_PATH%/*.adoc
@echo    =^> OK
:notRevealParameter


if "%~2" == "pdf" goto PdfParameter
if "%~2" == "all" goto PdfParameter
if "%~2" == "" goto PdfParameter
goto notPdfParameter
:PdfParameter
@echo   Generating PDF...
docker run --rm -v %CURRENT_PATH%build-docs:/documents asciidoctor/docker-asciidoctor:%ADOC_IMG_TAG% asciidoctor-pdf  ^
  -r asciidoctor-diagram  ^
  -a icons=font  ^
  -a experimental=true  ^
  -a plantuml-config=../../framework/themes/plantuml.cfg  ^
  -a screenshot-dir-name=screenshots  ^
  -a source-highlighter=coderay  ^
  -a toclevels=2  ^
  -a toc  ^
  -a title-page  ^
  -a sectnums=true  ^
  -a pagenums  ^
  -a pdf-style=framework/themes/pdf-theme.yml  ^
  -a pdf-fontsdir=framework/themes/fonts/pdf  ^
  -a allow-uri-read  ^
  %ADOC_PATH%/*.adoc
@echo    =^> OK
:notPdfParameter

: TODO Implements Zip





:: skip error routine
goto end
:: stop on error with  `|| goto :error`
:error
cd %CURRENT_PATH%
exit /b %errorlevel%

:end
set ALL=
cd %CURRENT_PATH%