# bib.awk

Bibliography manager written in awk

Just like [shbib](https://github.com/huijunchen9260/shbib), but better.

- Minimal (*only require **POSIX compliant awk***)
- Search BibTeX on **crossref** and **google scholar**
- Create and modify bib file on the fly
- Automatically and manually *rename* and *encode metadata* to pdf file
- Create, view and edit sublibrary
- Write notes for BibTeX entry

## Table of Content

<!-- vim-markdown-toc GFM -->

* [Preview](#preview)
    * [bib.awk Preview](#bibawk-preview)
* [Installation guide](#installation-guide)
* [Configuration](#configuration)
* [Requirement](#requirement)
* [Actions explained](#actions-explained)
* [Alternatives](#alternatives)

<!-- vim-markdown-toc -->

## Preview

<!-- ### bib.awk Preview -->
<!-- [![bib.awk preview](https://asciinema.org/a/Edb3nFO0Xeb4yDf1cT1A4FKzT.png)](https://asciinema.org/a/Edb3nFO0Xeb4yDf1cT1A4FKzT) -->

### bib.awk Preview
[![bib.awk preview](https://asciinema.org/a/WwcNHq3GmnGN9VZibSxnapooG.png)](https://asciinema.org/a/WwcNHq3GmnGN9VZibSxnapooG)

## Installation guide

Contribution to use it in repository in distro is welcome. Here is a simple guide for manual installation:

1. `git clone https://github.com/huijunchen9260/bib.awk` to download bib.awk to directory.
2. To install on linux:
    - Run `sudo make install` to install both `bib.awk`.
3. Configuration is necessary. You definitely need to set `BIBFILE` and `PDFPATH` for basic function to work. For detailed explanation, see [Configuration](#configuration).

## Configuration

Configuration is done within the first section of `bib.awk` file.

Configuration explanation:
  - If you want to use environment variable `VAR`: `ENVIRON["VAR"]`
  - `BIBFILE` defines the location of your `.bib` file
  - `BIBUKEY` defines the university url for journal authentication
  - `PDFPATH` defines the location of all your research papers
    `-` needs to have slash at the BEGINNING and the END of the string
  - `OPENER` defines the system default file opener
  - `READER` defines the pdf file opener
  - `EDITOR` defines the text file opener
  - `BROWSER` defines the browser to open url
  - `TEXTEMP` defines the location for tex template for Notes
    - needs to have slash at the BEGINNING of the string
  - `CLIPINW` defines the command to copy into clipboard
  - `CLIPOUT` defines the command to copy out from clipboard


## Requirement

- clipboard: `xclip` or `xsel` for linux (require configuration), `pbcopy` and `pbpaste` for Mac OS
- file opener: `xdg-open` for linux, `open` for Mac OS
- `gs` (ghostscript) for pdf metadata encoding, [[MacOS]](https://pages.uoregon.edu/koch/), [[Linux and Windows]](https://www.ghostscript.com/download/gsdnld.html)
- `curl` to search on Internet
- `xdotool` to hide / show terminal when open graphical software, not necessary
- other shell utilities: `rm`, `mv`, `file`, `printf`, `mkdir`, `stty`

## Actions explained

 - search on crossref by text
     - search on crossref using the following shell command:
         ```sh
         curl -s "https://api.crossref.org/works? \
             query.bibliographic=string+to+search \
             &select=indexed,title,author,type,DOI, \
             published-print,published-online,container-title"
         ```
         read the API manual!
        - directly pull out field needed.
        - If search text is DOI, then directly pull out bibtex.
 - search on crossref by metadata
 - search on google scholar
     - search using following url: `https://scholar.google.com/scholar?q=string+to+search 2>&1 1>/dev/null &`
 - open research paper
     - configure `PDFPATH` variable in `bib.awk`
 - open research paper website
 - copy BibTeX label
 - write note
     - Notes stored in `PDFPATH/Notes`
 - open research appendices
     - Appendices stored in `PDFPATH/appendices`
 - edit existing BibTeX entry
 - manually create file hierarchy
     - create `PDFPATH/Notes`, `PDFPATH/appendices`, and `PDFPATH/Libs` for selected BibTeX entry
 - automatically create file hierarchy
     - create `PDFPATH/Notes`, `PDFPATH/appendices`, and `PDFPATH/Libs` for all pdf files in `PDFPATH`
 - manually build database
     - encode metadata in chosen pdf file using `gs`.
 - automatically update database
     - loop over pdf files in `PDFPATH` and encode metadata if missing.
 - open sublibraries
     - Libraries stored in `PDFPATH/Libs`
 - create sublibraries
 - edit sublibraries
     - add/delete BibTeX entry
     - remove the chosen sublibrary

## Alternatives

- [papis](https://github.com/papis/papis)
- [pubs](https://github.com/pubs/pubs)
