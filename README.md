# bib.awk

Bibliography manager written in awk

Just like [shbib](https://github.com/huijunchen9260/shbib), but better.

- Minimal (*only require **POSIX compliant awk***)
- Search BibTeX on **crossref** and **google scholar**
- Create and modify bib file on the fly
- Automatically and manually *rename* and *encode metadata* to pdf file
- Create, view and edit sublibrary
- Write notes for BibTeX entry

## Requirement

- Menu system: [shellect](https://github.com/huijunchen9260/shellect)
- clipboard: `xclip` or `xsel` for linux (require configuration), `pbcopy` and `pbpaste` for Mac OS
- file opener: `xdg-open` for linux, `open` for Mac OS
- `gs` for pdf metadata encoding, ~~[pdfinfo](https://linux.die.net/man/1/pdfinfo) to extract pdf metadata~~
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
 - search on crossref by metadata
     - ~~use [pdfinfo](https://linux.die.net/man/1/pdfinfo) to extract pdf metadata~~
 - search on google scholar
     - search using following url: `
https://scholar.google.com/scholar?q=string+to+search 2>&1 1>/dev/null &`
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
