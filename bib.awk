#!/usr/bin/awk -f

BEGIN {

    ###################
    #  Configuration  #
    ###################

    BIBFILE = ENVIRON["HOME"] "/Documents/LaTeX/hjref.bib"
    BIBUKEY = ENVIRON["BIB_UNI_KEY"]
    PDFPATH = ENVIRON["HOME"] "/Documents/Papers/"
    READER = ( ENVIRON["READER"] == "" ? "xdg-open" : ENVIRON["READER"] )
    EDITOR = ( ENVIRON["EDITOR"] == "" ? "xdg-open" : ENVIRON["EDITOR"] )
    BROWSER = ( ENVIRON["BROWSER"] == "" ? "xdg-open" : ENVIRON["BROWSER"] )
    TEXTEMP = ENVIRON["HOME"] "/.local/bin/hjapps/bib.awk/template.tex"
    CLIPINW = "xclip -selection clipboard" # copy into clipboard
    CLIPOUT = "xclip -o -selection clipboard" # copy out from clipboard

    ################
    #  Parameters  #
    ################

    NTEPATH = PDFPATH "Notes/"
    LIBPATH = PDFPATH "Libs/"
    APXPATH = PDFPATH "Appendices/"

    #####################
    #  Start of script  #
    #####################

    RS = "\f"
    menu[1] = "search on crossref by text" RS \
	      "search on crossref by metadata" RS \
	      "search on google scholar" RS \
	      "open pdf file" RS \
	      "copy BibTeX label" RS \
	      "write note" RS \
	      "edit existing BibTeX entry" RS \
	      "manually build database" RS \
	      "automatically update database"
    menu[2] = RS
    menu[3] = 1
    menu[4] = "Choose action:"
    menu[5] = "Main menu"

    split(menu[1], choice, RS)

    list = menu[1]; delim = menu[2]; num = menu[3]; tmsg = menu[4]; bmsg = menu[5];

    while ("shellect -c \"" list \
	      "\" -d '" delim \
	      "' -n " num \
	      " -t '" tmsg \
	      "' -b '" bmsg \
	      "' -i -l" | \
	      getline response) {
	close("shellect -c \"" list \
	      "\" -d '" delim \
	      "' -n " num \
	      " -t '" tmsg \
	      "' -b '" bmsg \
	      "' -i -l")
	layer++

	#####################
	#  Action Matching  #
	#####################

	# search on crossref: by text or by metadata
	if (response == choice[1] || \
	    response ~ /^[[:alpha:]]*:[[:blank:]][[:blank:]]+.*$/) {
	    if (response == choice[1]) {
		string = notify("Type string to search on crossref:", string)
		clear_screen()
		str = string
		gsub(/ /, "+", string)
	    }
	    if (response ~ /^[[:alpha:]]*:[[:blank:]][[:blank:]]+.*$/) {
	        gsub(/^[[:alpha:]]*:[[:blank:]][[:blank:]]+/, "", response)
		string = response
		str = string
		gsub(/ /, "+", string)
	    }
	    crossref_json_process(string)
	    gscholar = "Search on Google Scholar...\n\n\n\n\n"
	    back_last = "Go Back... \n\n\n\n\n"
	    save()
	    list = jsonlist "\f" gscholar "\f" back_last;
	    delim = "\f";
	    num = 6;
	    tmsg = "Search result";
	    bmsg = "Action: search \"" str "\" on crossref";
	    continue
	}

	# search on crossref by metadata / build database
	if (response == choice[2] || response == choice[8]) {
	    cmd = "printf '%s\n' " PDFPATH "*.pdf"
	    cmd | getline pdf
	    gsub(PDFPATH, "", pdf)
	    save()
	    list = pdf;
	    delim = "\n";
	    num = 1;
	    tmsg = ( response == choice[2] ? \
		 "Choose pdf for metadata" : \
		 "Choose pdf to build database" )
	    bmsg = ( response == choice[2] ? \
		 "Action: search pdf metadata on crossref" : \
		 "Action: manually build database" )
	    action = response
	    continue
	}

	# search on google scholar
	if (response == choice[3] || response == gscholar) {
	    if (response == choice[3]) {
		string = notify("Type string to search on google scholar:", string)
		clear_screen()
		gsub(/ /, "+", string)
	    }
	    system(BROWSER " " BIBUKEY \
		      "https://scholar.google.com/scholar?q=" \
		      string " 2>&1 1>/dev/null &")
	    wait_clip()
	    if (bibtex ~ /^@[[:alpha:]]*{.*$/) {
		## alternate the label
		bibtex = label_alter(bibtex)

		notify("BibTeX listed below, press enter to continue...\n" bibtex)
		yesno("Add this BibTeX to" BIBFILE "?")
		bib_get = 1;
		continue
	    }
	    else {
		notify("Not copying bibtex; press enter to go to main menu")
		back = 1
	    }
	}

	# bib entry selection
	if (response == choice[4] || \
	    response == choice[5] || \
	    response == choice[6] || \
	    response == choice[7]) {
	    ref_gen(BIBFILE)
	    save()
	    list = biblist "\f" "Go Back...\n\n\n\n\n";
	    delim = "\f";
	    num = 6;
	    tmsg = "Choose bib entry to " response ":";
	    bmsg = "Action: " response;
	    action = response
	    continue
	}

	if (response == choice[9]) {
	    faillist = ""
	    ref_gen(BIBFILE)
	    cmd = "printf '%s\n' " PDFPATH "*.pdf"
	    cmd | getline pdf
	    split(pdf, pdfarr, "\n")
	    split(metalist, metalistarr, "\f")
	    for (file in pdfarr) {
		# path = pdfarr[file]
		basename = pdfarr[file]
		# extension = pdfarr[file]
		# gsub(/[^\/]*\..*$/, "", path)
		gsub(/\.[^\.]*$|^.*\//, "", basename)
		# gsub(/.*\./, "", extension)
		match(metalist, basename)
		# print basename
		if (RSTART) {
		    continue
		}
		else {
		    cmd = "pdfinfo \"" pdfarr[file] "\""
		    cmd | getline info
		    match(info, "Title:          ")
		    if (RSTART) {
			gsub(/.*Title:          |\n.*/, "", info)
			if (info != "") {
			    match(metalist, info)
			    if (RSTART) {
				for (data in metalistarr) {
				    match(metalistarr[data], info)
				    if (RSTART) {
					split(metalistarr[data], metaarr, "\n")
					meta_to_file(basename ".pdf", \
						     metaarr[1], metaarr[2], \
						     metaarr[5], metaarr[4], \
						     metaarr[6])
					system("rm \"" pdfarr[file] "\";" \
					       "mv \"/tmp/" basename ".pdf\" " \
					       "\"" PDFPATH metaarr[1] ".pdf\"" )
				    }
				}
			    }
			    else {
				# faillist[++i] = pdfarr[file]
				faillist = faillist "\f" basename ".pdf"
			    }
			}
			else {
			    # faillist[++i] = pdfarr[file]
			    faillist = faillist "\f" basename ".pdf"
			}
		    }
		    else {
			# faillist[++i] = pdfarr[file]
			faillist = faillist "\f" basename ".pdf"
		    }

		}
	    }

	    faillist = substr(faillist, 2)
	    save()
	    list = ( faillist == "" ? \
		     "All PDF files in database is updated!" :
		     faillist );
	    delim = "\f";
	    num = 1;
	    tmsg = "Choose file to encode metadata manually:";
	    bmsg = "Action: " response;
	    action = response
	    if (faillist == "") {
	        back = 1
	    }
	    else {
		back = 0
		continue
	    }
	}

	# search on crossref: get bibtex
	if (response ~ /.*Title: .*\n\tCategory: .*\n\tDOI: .*/) {
	    # pre_res = response
	    bib_get = 1
	    split(response, fieldarr, "\n")
	    gsub(/\tDOI: /, "", fieldarr[6])
	    cmd = "curl -s \"http://api.crossref.org/works/" \
		fieldarr[6] \
		"/transform/application/x-bibtex\""
	    cmd | getline bibtex
	    close(cmd)

	    ## alternate the label
	    bibtex = label_alter(bibtex)

	    notify("BibTeX listed below, press enter to continue...\n" bibtex)
	    yesno("Add this BibTeX to" BIBFILE "?")
	    continue
	}

	if (response ~ /.*\.pdf/) {
	    if (action == choice[2]) {
		# search on crossref by pdf metadata
		cmd = "pdfinfo " PDFPATH response
		cmd | getline info
		save()
		list = info;
		delim = "\n";
		num = 1;
		tmsg = "Choose metadata to search"
		bmsg = "Action: search pdf metadata on crossref"
		continue
	    }
	    if (action == choice[8] || action == choice[9]) {
		# manually build database
		ref_gen(BIBFILE)
		save()
		list = biblist "\f" "Go Back...\n\n\n\n\n";
		delim = "\f";
		num = 6;
	        tmsg = "Choose BibTeX entry to build database: "
		bmsg = "Action: manually build database"
		file = response
	    }
	}

	# bib entry selection
	if (response ~ /.*BibTeX: .*\n\tTitle: .*\n\tYear: .*\n\tAuthor\(s\): .*/) {
	    split(response, fieldarr, "\n")
	    gsub(/BibTeX:[[:blank:]]*/, "", fieldarr[1]);
	    label = fieldarr[1]
	    gsub(/[[:blank:]]*Title:[[:blank:]]*/, "", fieldarr[2]);
	    title = fieldarr[2]
	    gsub(/[[:blank:]]*Year:[[:blank:]]*/, "", fieldarr[3]);
	    year = fieldarr[3]
	    gsub(/[[:blank:]]*Journal:[[:blank:]]*/, "", fieldarr[4]);
	    journal = fieldarr[4]
	    gsub(/[[:blank:]]*Author\(s\):[[:blank:]]*/, "", fieldarr[5]);
	    author = fieldarr[5]
	    gsub(/[[:blank:]]*DOI:[[:blank:]]*/, "", fieldarr[6]);
	    doi = fieldarr[6]
	    if (action == choice[4]) { # open pdf
		cmd = "xdotool getactivewindow"
		cmd | getline wid
		close(cmd)
		system("xdotool windowunmap " wid)
		system(READER " " PDFPATH label ".pdf")
		system("xdotool windowmap " wid)
		back = 1
	    }
	    if (action == choice[5]) { # copy label
		system("printf '%s' \"" label "\" | " CLIPINW)
		notify(label " has copied to clipboard using " \
		       CLIPINW "; press enter to continue...")
		back = 1
	    }
	    if (action == choice[6]) { # write notes
		system("mkdir -p " NTEPATH label)
		tex_template(NTEPATH label "/" label ".tex", title, author)
		system(EDITOR " " NTEPATH label "/" label ".tex")
	    }
	    if (action == choice[7]) { # edit bibtex entry
		getline BIB < BIBFILE
		close(BIBFILE)
		split(BIB, bibarr, "@")
		delete bibarr[1]
		regex = label ".*"
		srand()
		tmpfile = "/tmp/" sprintf("%x", 8539217*rand()) ".tmp"
		bibtmpfile = "/tmp/" sprintf("%x", 7129358*rand()) ".tmp"
		for (entry in bibarr) {
		    if (bibarr[entry] ~ regex) {
			printf("@%s", bibarr[entry]) > tmpfile
			system(EDITOR " " tmpfile)
			getline ENTRY < tmpfile
			close(tmpfile)
			printf("%s", ENTRY) >> bibtmpfile
		    }
		    else {
			printf("@%s", bibarr[entry]) >> bibtmpfile
		    }
		}
		system("cp " bibtmpfile " " BIBFILE \
		       "; rm " tmpfile " " bibtmpfile)
	    }
	    if (action == choice[8] || action == choice[9]) { # manually build database
		meta_to_file(file, label, title, author, journal, doi)
		yesno("Update " file " to " label)
		database = ( action == choice[8] ? 1 : 2 )
		continue
	    }
	}

	############
	#  Finale  #
	############

	if (response == "Yes") {
	    ## search on crossref: bib_get
	    if (bib_get == 1) {
		print "\n" bibtex "\n" >> BIBFILE
		yesno("Download corresponding pdf file?")
		download = 1; bib_get = 0;
		continue
	    }
	    ## search on crossref: download
	    if (download == 1) {
		split(bibtex, bibtexarr, "\n")
		for (line in bibtexarr) {
		    if (bibtexarr[line] ~ /^[[:blank:]]*url[[:blank:]]?=[[:blank:]]?{.*/) {
			gsub(/^[[:blank:]]*url[[:blank:]]?=[[:blank:]]?{|}.*/, "", bibtexarr[line])
			url = bibtexarr[line]
		    }
		}
		system(BROWSER " " BIBUKEY url " 2>&1 1>/dev/null &")
		system("mkdir -p " NTEPATH label "; " \
		       "mkdir -p " LIBPATH label "; " \
		       "mkdir -p " APXPATH label "; " )

		notify("Open in " label " in " BROWSER \
		       " and create \n" \
		       NTEPATH label "\n" \
		       LIBPATH label "\n" \
		       APXPATH label "\n" \
		       "for notes, sublibraries and appendices respectively.\n" \
		       "press enter to continue")
		back = 1; download = 0
	    }
	    ## update database
	    if (database == 1) {
		system("rm \"" PDFPATH file "\";" \
		       "mv \"/tmp/" label ".pdf\" \
			   \"" PDFPATH label ".pdf\"" )
		notify(label " updated; press enter to continue")
		back = 1; database = 0
	    }
	    if (database == 2) {
		system("rm \"" PDFPATH file "\";" \
		       "mv \"/tmp/" label ".pdf\" \
			   \"" PDFPATH label ".pdf\"" )
		gsub(file, "", faillist)
		gsub(/\f\f/, "\f", faillist)

		save()
		list = ( faillist == "" ? \
			 "All PDF files in database is updated!" :
			 faillist );
		delim = "\f";
		num = 1;
		tmsg = "Choose file to encode metadata manually:";
		bmsg = "Action: " action;

		if (faillist == "") {
		    back = 1
		}
		else {
		    back = 0
		    continue
		}
	    }
	}

	if (response == "No") {
	    back = 1
	}


	#####################################
	#  Back to last layer or main menu  #
	#####################################


	if (response ~ /.*Go Back\.\.\..*/) {
	    layer--
	    load()
	    layer--
	    continue
	}

	if (back == 1) {
	    restore()
	    back = 0
	}
    }

}

function load() {
    list = saved[layer*5 - 4]
    delim = saved[layer*5 - 3]
    num = saved[layer*5 - 2]
    tmsg = saved[layer*5 - 1]
    bmsg = saved[layer*5]
}

function save() {
    saved[layer*5 - 4] = list
    saved[layer*5 - 3] = delim
    saved[layer*5 - 2] = num
    saved[layer*5 - 1] = tmsg
    saved[layer*5] = bmsg
}

function clear_screen() { # clear screen and move cursor to 0, 0
    printf "\033\1332J\033\133H"
}

function tex_template(file, title, author) {
    if (getline template < TEXTEMP == 0) {
	gsub(/TITLE/, title, template)
	gsub(/AUTHOR/, author, template)
	gsub(/BIB/, BIBFILE, template)
	print template > file
    }
}

function restore() {
    clear_screen()
    split("", saved, ":") # delete saved array
    list = menu[1]; delim = menu[2]; num = menu[3]; tmsg = menu[4]; bmsg = menu[5];
    jsonlist = ""; biblist = ""; bibtex = "";
    bib_get = 0; download = 0; database = 0;
}

function notify(msg, str) {
    system("stty -cread icanon echo 1>/dev/null 2>&1")
    print msg
    RS = "\n" # stop getline by enter
    getline str < "-"
    RS = "\f"
    return str
    system("stty sane")
}

function yesno(topmsg) {
    clear_screen()

    save()
    list = "Yes" "\f" "No" "\f" "Go Back...";
    delim = RS;
    num = 1;
    tmsg = topmsg
    bmsg = "Yes-No Question"
}

function meta_to_file(file, label, title, author, journal, doi) {
    system("gs -o \"/tmp/" label ".pdf\" \\" \
	   "-sDEVICE=pdfwrite \\" \
	   "-f \"" PDFPATH file "\"   \\" \
	   "-c \"[ /Title (" title ")" \
	   "/Author (" author ")" \
	   "/Subject (" journal " doi:" doi ")" \
	   "/DOCINFO pdfmark\" 1>/dev/null 2>&1; ")
}

function label_alter(bibtex) {
    split(bibtex, bibtexarr, "\n")
    for (line in bibtexarr) {
	if (bibtexarr[line] ~ /^@.*/) {
	    orig = bibtexarr[line]
	    gsub(/{.*/, "", bibtexarr[line])
	    category = bibtexarr[line]
	    if (category ~ /.*@book.*/) {
		journal = "Book"
	    }
	    bibtexarr[line] = orig
	    continue
	}
	if (bibtexarr[line] ~ /.*year.*/) {
	    orig = bibtexarr[line]
	    gsub(/.*year ?= ?{?|}?,?$/, "", bibtexarr[line])
	    year = bibtexarr[line]
	    bibtexarr[line] = orig
	    continue
	}
	if (bibtexarr[line] ~ /.*author.*/) {
	    orig = bibtexarr[line]
	    gsub(/.*author ?= ?{?|}?,?$/, "", bibtexarr[line])
	    split(bibtexarr[line], authorarr, " and ")
	    for (name in authorarr) {
		gsub(/.* /, "", authorarr[name])
		author = author "_" authorarr[name]
	    }
	    author = substr(author, 2)
	    bibtexarr[line] = orig
	    continue
	}
	if (bibtexarr[line] ~ /.*journal.*/) {
	    orig = bibtexarr[line]
	    gsub(/.*journal ?= ?{?|}?,?$/, "", bibtexarr[line])
	    if (bibtexarr[line] ~ /.* .*/) {
		gsub(/[^A-Z]/, "", bibtexarr[line])
	    }
	    journal = bibtexarr[line]
	    bibtexarr[line] = orig
	    continue
	}
	if (bibtexarr[line] ~ /.*booktitle.*/) {
	    orig = bibtexarr[line]
	    gsub(/.*booktitle ?= ?{?|}?,?$/, "", bibtexarr[line])
	    booktitle = bibtexarr[line]
	    bibtexarr[line] = orig
	    continue
	}
    }

    if (journal) {
	label = author " " year " " journal
    }
    else {
	label = author " " year " " booktitle
    }
    gsub(/ /, "_", label)

    for (line in bibtexarr) {
	if (bibtexarr[line] ~ /^@.*/) {
	    bibtex = category "{" label ","
	}
	else {
	    bibtex = bibtex "\n" bibtexarr[line]
	}
    }
    return bibtex
}

# Detect whether a program exists in path.
# Return the name if the program call writes anything to stdout;
# Otherwise, return a null string.
function detectprog(prog, arg) {
    cmd = "command -v " prog " 1>/dev/null 2>&1; echo $?"
    cmd | getline temp
    close(cmd)
    if (temp == 0) {
        return prog " " arg
    }
    else {
	return ""
    }
}

function wait_clip() {
    count = 1; countmax = 360;
    # clear clipboard
    system("printf '%s' "" | " CLIPINW)
    while (bibtex == "" && count <= countmax) {
	print "Go copy bibtex within " countmax " seconds;\n" \
	      "Already " count " seconds past"
	cmd = CLIPOUT "; sleep 1;"
	cmd | getline bibtex
	close(cmd)
	clear_screen()
	count++
    }
}

function ref_gen(BIBFILE) {
    biblist = ""
    metalist = ""
    getline BIB < BIBFILE
    close(BIBFILE)
    split(BIB, bibarr, "@")
    delete bibarr[1]
    for (entry in bibarr) {
	split(bibarr[entry], entryarr, "\n")
	for (line in entryarr) {
	    if (entryarr[line] ~ /^[[:alpha:]]*{.*$/) {
		gsub(/^.*{|,$/, "", entryarr[line])
		meta_label = entryarr[line]
		label = sprintf("BibTeX: %s", entryarr[line])
	    }
	    if (entryarr[line] ~ /.*year.*/) {
		gsub(/[^0-9]*/, "", entryarr[line])
		meta_year = entryarr[line]
		year = sprintf("\tYear: %s", entryarr[line])
	    }
	    if (entryarr[line] ~ /.*title.*/) {
		gsub(/^[[:blank:]]*title[[:blank:]]?=[[:blank:]]?{|},$/, "", entryarr[line])
		meta_title = entryarr[line]
		title = sprintf("\tTitle: %s", entryarr[line])
	    }
	    if (entryarr[line] ~ /.*author.*/) {
		gsub(/^[[:blank:]]*author[[:blank:]]?=[[:blank:]]?{|},$/, "", entryarr[line])
		meta_author = entryarr[line]
		author = sprintf("\tAuthor(s): %s", entryarr[line])
	    }
	    if (entryarr[line] ~ /.*journal.*/) {
		gsub(/^[[:blank:]]*journal[[:blank:]]?=[[:blank:]]?{|}.*/, "", entryarr[line])
		meta_journal = entryarr[line]
		journal = sprintf("\tJournal: %s", entryarr[line])
	    }
	    if (entryarr[line] ~ /^[[:blank:]]*doi[[:blank:]]?=[[:blank:]]?{.*/) {
		gsub(/^[[:blank:]]*doi[[:blank:]]?=[[:blank:]]?{|}.*/, "", entryarr[line])
		meta_doi = entryarr[line]
		doi = sprintf("\tDOI: %s", entryarr[line])
	    }
	}

	# bibarr[entry] = label "\n" title "\n" year "\n" journal "\n" author "\n" doi
	biblist = biblist "\f" \
		  label "\n" \
		  title "\n" \
		  year "\n" \
		  journal "\n" \
		  author "\n" \
		  doi
	metalist = metalist "\f" \
		   meta_label "\n" \
		   meta_title "\n" \
		   meta_year "\n" \
		   meta_journal "\n" \
		   meta_author "\n" \
		   meta_doi

	# biblist = biblist "\f" bibarr[entry]
	label = ""; title = ""; year = "";
	journal = ""; author = ""; doi = "";
	meta_label = ""; meta_title = ""; meta_year = "";
	meta_journal = ""; meta_author = ""; meta_doi = "";
    }
    biblist = substr(biblist, 2)
    metalist = substr(metalist, 2)
    return biblist metalist
}

function crossref_json_process(string) {
    jsonlist = ""
    cmd = "curl -s \"https://api.crossref.org/works?query.bibliographic=" \
	   string \
	   "&select=indexed,title,author,type,DOI,published-print,published-online,container-title\""
    cmd | getline json
    close(cmd)
    split(json, jsonarr, "\"indexed\"")
    delete jsonarr[1]
    for (entry in jsonarr) {
	split(jsonarr[entry], entryarr, "[][\"}{]")
	for (line in entryarr) {
	    if (entryarr[line - 3] == "title") {
	        title = sprintf("Title: %s", entryarr[line])
	    }
	    if (entryarr[line - 3] == "container-title") {
	        journal = sprintf("\tJournal: %s", entryarr[line])
	    }
	    if (entryarr[line - 2] == "type") {
	        category = sprintf("\tCategory: %s", entryarr[line])
	    }
	    if (entryarr[line - 2] == "DOI") {
		gsub(/\\/, "", entryarr[line])
	        doi = sprintf("\tDOI: %s", entryarr[line])
	    }
	    if (entryarr[line - 6] == "published-print") {
		gsub(/,/, "/", entryarr[line])
	        date = sprintf("\tDate: %s", entryarr[line])
	    }
	    else if (entryarr[line - 6] == "published-online") {
		gsub(/,/, "/", entryarr[line])
	        date = sprintf("\tDate: %s", entryarr[line])
	    }

	    if (entryarr[line - 2] == "given") {
	        given = entryarr[line]
	    }
	    if (entryarr[line - 2] == "family") {
	        family = entryarr[line]
	        if (author == "") {
	            author = sprintf("\tAuthor(s): %s %s", given, family)
	        }
		else {
	    	author = author " and " given " " family
	        }
	    }
	}
	jsonarr[entry] = title "\n" category "\n" date "\n" \
	       journal "\n" author "\n" doi

	title = ""; category = ""; date = "";
	journal = ""; author = ""; doi = "";
	jsonlist = jsonlist "\f" jsonarr[entry]
    }
    jsonlist = substr(jsonlist, 2)
    return jsonlist
}
