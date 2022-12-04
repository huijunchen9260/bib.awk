#!/usr/bin/awk -f

BEGIN {

    ###################
    #  Configuration  #
    ###################

    ## Configuration explanation:
    ##   - If you want to use environment variable VAR: ENVIRON["VAR"]
    ##   - BIBFILE defines the location of your .bib file
    ##   - BIBUKEY defines the university url for journal authentication
    ##   - PDFPATH defines the location of all your research papers
    ##     - needs to have slash at the BEGINNING and the END of the string
    ##   - OPENER defines the system default file opener
    ##   - READER defines the pdf file opener
    ##   - EDITOR defines the text file opener
    ##   - BROWSER defines the browser to open url
    ##   - TEXTEMP defines the location for tex template for Notes
    ##     - needs to have slash at the BEGINNING of the string
    ##   - CLIPINW defines the command to copy into clipboard
    ##   - CLIPOUT defines the command to copy out from clipboard

    BIBFILE = ENVIRON["BIB"]
    BIBUKEY = ENVIRON["BIB_UNI_KEY"]
    PDFPATH = ENVIRON["BIB_PDF_PATH"]
    OPENER = ( ENVIRON["OSTYPE"] ~ /darwin.*/ ? "open" : "xdg-open" )
    READER = ( ENVIRON["READER"] == "" ? OPENER : ENVIRON["READER"] )
    EDITOR = ( ENVIRON["EDITOR"] == "" ? OPENER : ENVIRON["EDITOR"] )
    BROWSER = ( ENVIRON["BROWSER"] == "" ? OPENER : ENVIRON["BROWSER"] )
    TEXTEMP = ENVIRON["HOME"] "/.local/bin/hjapps/bib.awk/template.tex"
    CLIPINW = ( ENVIRON["OSTYPE"] ~ /darwin.*/ ? \
		"pbcopy" : \
		"xclip -selection clipboard" )
    CLIPOUT = ( ENVIRON["OSTYPE"] ~ /darwin.*/ ? \
		"pbpaste" : \
		"xclip -o -selection clipboard" )


    ################
    #  Parameters  #
    ################

    NTEPATH = PDFPATH "Notes/"		# Notes path
    LIBPATH = PDFPATH "Libs/"		# Libraries path
    APXPATH = PDFPATH "Appendices/"	# Appendices path
    movement = "default";		# movement cannot be empty

    #####################
    #  Start of script  #
    #####################

    init()

    RS = "\f"
    menu[1] = "search on crossref by text" RS \
	      "search on crossref by metadata" RS \
	      "search on google scholar" RS \
	      "open research paper" RS \
	      "open research paper website" RS \
	      "copy BibTeX label" RS \
	      "write note" RS \
	      "open research appendices" RS \
	      "edit existing BibTeX entry" RS \
	      "manually create file hierarchy" RS \
	      "automatically create file hierarchy" RS \
	      "manually build database" RS \
	      "automatically update database" RS \
	      "open sublibraries" RS \
	      "create sublibraries" RS \
	      "edit sublibraries"
    menu[2] = RS
    menu[3] = 1
    menu[4] = "Choose action:"
    menu[5] = "Main menu"

    split(menu[1], choice, RS)

    list = menu[1]; delim = menu[2]; num = menu[3]; tmsg = menu[4]; bmsg = menu[5];

    while (1) {

    response = menu_TUI(list, delim, num, tmsg, bmsg)

	#####################
	#  Action Matching  #
	#####################

	# search on crossref by text: layer 1
	# search on crossref by metadata: layer 3 if not doi
	if (response == "search on crossref by text" || \
	    response ~ /\/[[:alpha:]]*[[:blank:]]?\([[:blank:]]?.*\)/) {
	    if (response == "search on crossref by text") {
            string = notify("Type string to search on crossref:", string)
            clear_screen()
            str = string
            gsub(/ /, "+", string)
	    }

	    if (str ~ /10\.[[:digit:]][[:digit:]][[:digit:]][[:digit:]]*\/[-[:alnum:]]+/) {
            doi = str
            bib_get = 1
            clear_screen()
            cmd = "curl -LH \"Accept: text/bibliography; style=bibtex\" http://dx.doi.org/" doi
            # cmd = "curl --trace-time \"http://api.crossref.org/works/" doi "/transform/application/x-bibtex\""
            cmd | getline bibtex
            close(cmd)
            Nbibtex = split(bibtex, bibarr, "},")
            bibtex = ""
            for (i = 1; i <= Nbibtex; i++) {
                if (i == 1) {
                    match(bibarr[i], /,.*=/)
                    bibtex = bibtex "\n" substr(bibarr[i], 1, RSTART) "\n\t" substr(bibarr[i], RSTART+1) "},"
                }
                else if (i == Nbibtex) {
                    bibtex = bibtex "\n\t" substr(bibarr[i], 1, length(bibarr[i]) - 2) "\n}"
                }
               else {
                    bibtex = bibtex "\n\t" bibarr[i] "},"
                }
            }
            bibtex = substr(bibtex, 3)

            ## alternate the label
            bibtex = label_alter(bibtex)

            notify("BibTeX listed below, press enter to continue...\n" bibtex)
            yesno("Add this BibTeX to " BIBFILE "?")
            continue
	    }
        else {
            if (response ~ /\/[[:alpha:]]*[[:blank:]]?\([[:blank:]]?.*\)/) {
                gsub(/\/[[:alpha:]]*[[:blank:]]?\([[:blank:]]?|\)/, "", response)
                string = response
                str = string
                gsub(/ /, "+", string)
            }
            print "Wait for crossref API to response, may need 30s to 1 min depends on API connection."
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
	}

	# search on crossref by metadata: layer 1
	# manually build database: layer 1
	if (response == "search on crossref by metadata" || response == "manually build database") {
	    cmd = "printf '%s\n' " PDFPATH "*.pdf"
	    cmd | getline pdf
	    close(cmd)
	    gsub(PDFPATH, "", pdf)
	    save()
	    list = pdf "\n" "Go Back...";
	    delim = "\n";
	    num = 1;
	    tmsg = ( response == "search on crossref by metadata" ? \
		 "Choose pdf for metadata" : \
		 "Choose pdf to build database" )
	    bmsg = ( response == "search on crossref by metadata" ? \
		 "Action: search pdf metadata on crossref" : \
		 "Action: manually build database" )
	    action = response
	    continue
	}

	# search on google scholar: layer 1
	# search on crossref by text: layer 3 if gscholar
	if (response == "search on google scholar" || response == gscholar) {
	    if (response == "search on google scholar") {
            string = notify("Type string to search on google scholar:", string)
            clear_screen()
            gsub(/ /, "+", string)
	    }
	    system(BROWSER " " BIBUKEY \
		      "https://scholar.google.com/scholar?q=" \
		      string " 2>&1 1>/dev/null &")
	    clear_screen()
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

	# open research paper: layer 1
	# open research paper website: layer 1
	# copy BibTeX label: layer 1
	# write note: layer 1
	# open research appendices: layer 1
	# edit existing BibTeX entry: layer 1
	# manually create file hierarchy: layer 1
	# create sublibraries: layer 1
	if (response == "open research paper" || \
	    response == "open research paper website" || \
	    response == "copy BibTeX label" || \
	    response == "write note" || \
	    response == "open research appendices" || \
	    response == "edit existing BibTeX entry" || \
	    response == "manually create file hierarchy" || \
	    response == "create sublibraries") {
	    if (response == "create sublibraries") { # create sublibrary
            name = notify("Type the name of the sublibrary:", name)
            gsub(/ /, "_", name)
            clear_screen()
            file = LIBPATH name ".bib"
        }
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

	# automatically create file hierarchy: layer 1
	if (response == "automatically create file hierarchy") {
	    ref_gen(BIBFILE)
	    split(labellist, labellistarr, "\n")
	    for (line in labellistarr) {
		system("mkdir -p " NTEPATH labellistarr[line] "; " \
		       "mkdir -p " APXPATH labellistarr[line] "; " )
		pdflist = pdflist "\n" labellistarr[line]
		print "Create file hierarchy for " pdflist
	    }
	}

	# automatically build database: layer 1
	if (response == "automatically update database") {
	    faillist = ""
	    ref_gen(BIBFILE)
	    cmd = "printf '%s\n' " PDFPATH "*.pdf"
	    cmd | getline pdf
	    close(cmd)
	    split(pdf, pdfarr, "\n")
	    split(metalist, metalistarr, "\f")
	    for (file in pdfarr) {
		basename = pdfarr[file]
		gsub(/\.[^\.]*$|^.*\//, "", basename)
		match(labellist, basename)
		if (RSTART) {
		    continue
		}
		else {
		    meta_extract(pdfarr[file])
		    match(metadata, /^\/Title[[:blank:]]?\([[:blank:]]?.*$\)/)
		    if (RSTART) {
			metadata = substr(metadata, RSTART, RLENGTH)
			gsub(/\/Title[[:blank:]]?\([[:blank:]]?|\)/, "", metadata)
			if (metadata != "") {
			    match(metalist, metadata)
			    if (RSTART) {
				for (data in metalistarr) {
				    match(metalistarr[data], metadata)
				    if (RSTART) {
					split(metalistarr[data], metaarr, "\n")
					meta_to_file(pdfarr[file], \
						     metaarr[1], metaarr[2], \
						     metaarr[5], metaarr[4], \
						     metaarr[6])
					mv_rm(pdfarr[file], metaarr[1])
				    }
				}
			    }
			    else {
				faillist = faillist "\f" basename ".pdf"
			    }
			}
			else {
			    faillist = faillist "\f" basename ".pdf"
			}
		    }
		    else {
			faillist = faillist "\f" basename ".pdf"
		    }

		}
	    }
	    faillist = substr(faillist, 2)
	    save()
	    backtext = "All PDF files in database is updated!"
	    list = ( faillist == "" ?  backtext : faillist "\f" "Main Menu" );
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

	# open sublibraries: layer 1
	# edit sublibraries: layer 1
	if (response == "open sublibraries" || response == "edit sublibraries") {
	    cmd = "printf '%s\n' " LIBPATH "*.bib"
	    cmd | getline library
	    close(cmd)
	    gsub(LIBPATH, "", library)
	    save()
	    list = library "\n" "Go Back..."
	    delim = "\n";
	    num = 1;
	    tmsg = ( response == "open sublibraries" ? \
		     "Choose sublibrary to open" : \
		     "Choose sublibrary to edit" )
	    bmsg = ( response == "open sublibraries" ? \
		     "Action: open sublibraries" : \
		     "Action: edit sublibraries" )
	    action = response
	}


	# search on crossref by text: layer 2
	# search on crossref by metadata: layer 3 if doi
	if (response ~ /.*Title: .*\n\tCategory: .*\n\tDOI: .*/ || \
	    response ~ /^\/[-[:alpha:]]*[[:blank:]]?\([[:blank:]]?10\.[[:digit:]][[:digit:]][[:digit:]][[:digit:]]*\/[[:alnum:]]+\)$/) {
	    # response ~ /^\/[-[:alpha:]]*[[:blank:]]?\([[:blank:]]?10\.[[:digit:]][[:digit:]][[:digit:]][[:digit:]]*\/[-._;()/:[:alnum:]]+\)$/) {
	    bib_get = 1
	    if (response ~ /.*Title: .*\n\tCategory: .*\n\tDOI: .*/) {
		split(response, fieldarr, "\n")
		gsub(/\tDOI: /, "", fieldarr[6])
		doi = fieldarr[6]
	    }
	    # if (response ~ /^\/[-[:alpha:]]*[[:blank:]]?\([[:blank:]]?10\.[[:digit:]][[:digit:]][[:digit:]][[:digit:]]*\/[-._;()/:[:alnum:]]+\)$/) {
	    if (response ~ /^\/[-[:alpha:]]*[[:blank:]]?\([[:blank:]]?10\.[[:digit:]][[:digit:]][[:digit:]][[:digit:]]*\/[[:alnum:]]+\)$/) {
            gsub(/^\/[-[:alpha:]]*[[:blank:]]?\([[:blank:]]?|\)$/, "", response)
            doi = response
	    }
        clear_screen()
        cmd = "curl -LH \"Accept: text/bibliography; style=bibtex\" http://dx.doi.org/" doi
	    cmd | getline bibtex
	    close(cmd)
        Nbibtex = split(bibtex, bibarr, "},")
        bibtex = ""
        for (i = 1; i <= Nbibtex; i++) {
            if (i == 1) {
                match(bibarr[i], /,.*=/)
                bibtex = bibtex "\n" substr(bibarr[i], 1, RSTART) "\n\t" substr(bibarr[i], RSTART+1) "},"
            }
            else if (i == Nbibtex) {
                bibtex = bibtex "\n\t" substr(bibarr[i], 1, length(bibarr[i]) - 2) "\n}"
            }
            else {
                bibtex = bibtex "\n\t" bibarr[i] "},"
            }
        }
        bibtex = substr(bibtex, 3)

	    ## alternate the label
	    bibtex = label_alter(bibtex)

	    notify("BibTeX listed below, press enter to continue...\n" bibtex)
	    yesno("Add this BibTeX to " BIBFILE "?")
	    continue
	}

	# choosing a file
	if (response ~ /^.*\.[[:alpha:]][[:alpha:]][[:alpha:]]$/) {

	    ## search on crossref by metadata: layer 2
	    if (action == "search on crossref by metadata") { # search on crossref by pdf metadata
		meta_extract(PDFPATH response)
		save()
		list = metadata "\n" "Go Back...";
		delim = "\n";
		num = 1;
		tmsg = "Choose metadata to search"
		bmsg = "Action: search pdf metadata on crossref"
		continue
	    }

	    ## open research appendices: layer 2
	    if (action == "open research appendices") { # open appendices
            file = APXPATH label "/" response
            cmd = "file -i \"" file "\" 2>/dev/null"
            cmd | getline mimetype
            close(cmd)
            if (mimetype ~ /.*text\/.*|.*x-empty.*|.*json.*/) {
                finale()
                system(EDITOR " " file)
                init()
                clear_screen()
            }
            else if (ENVIRON["OSTYPE"] ~ /darwin.*/) {
                system(OPENER " " file)
                clear_screen()
            }
            else {
                cmd = "xdotool getactivewindow &"
                cmd | getline wid
                close(cmd)
                system("xdotool windowunmap " wid " &")
                system(OPENER " " file)
                system("xdotool windowmap " wid " &")
                clear_screen()
            }
            back = 1;
            continue
	    }

	    ## manually build database: layer 2
	    ## automatically update database: layer 2
	    if (action == "manually build database" || action == "automatically update database") {
            ref_gen(BIBFILE)
            save()
            list = biblist "\f" "Go Back...\n\n\n\n\n";
            delim = "\f";
            num = 6;
            tmsg = "Choose BibTeX entry to build database: "
            bmsg = "Action: manually build database"
            file = PDFPATH response
        }

	    ## open sublibraries: layer 2
	    if (action == "open sublibraries") { # open sublibrary
		file = LIBPATH response
		ref_gen(file)
		save()
		list = biblist "\f" "Go Back...\n\n\n\n\n";
		delim = "\f";
		num = 6;
	        tmsg = "Choose BibTeX in " response " to open research paper"
		bmsg = "Action: open sublibraries"
	    }

	    ## edit sublibraries: layer 2
	    if (action == "edit sublibraries") { # edit sublibrary
		file = LIBPATH response
		save()
		ADD = "Add BibTeX entry"
		DEL = "Delete BibTeX entry"
		RMV = "Remove sublibrary"
		list = ADD "\f" DEL "\f" RMV
		delim = "\f";
		num = 1;
	        tmsg = "Choose action for " response
		bmsg = "Action: edit sublibraries"
	    }
	}

	# edit sublibraries: layer 3
	if (response == ADD || response == DEL) {
	    if (response == ADD) {
	        ref_gen(BIBFILE)
	    }
	    else if (response == DEL) {
		ref_gen(file)
	    }
	    list = biblist "\f" "Go Back...\n\n\n\n\n";
	    delim = "\f";
	    num = 6;
	    tmsg = "Choose BibTeX to " response
	    bmsg = "Action: edit sublibraries"
	    movement = response
	    continue
	}

	# edit sublibraries: layer 3
	if (response == RMV) {
	    movement = response
	    yesno("Really remove " file "?")
	    continue
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

	    ## open research paper: layer 2
	    ## open sublibraries: layer 3
	    if (action == "open research paper" || action == "open sublibraries") { # open pdf
            if (ENVIRON["OSTYPE"] ~ /darwin.*/) {
                system(OPENER " " file)
                clear_screen()
            }
            else {
                cmd = "xdotool getactivewindow &"
                cmd | getline wid
                close(cmd)
                system("xdotool windowunmap " wid " &")
                system(READER " " PDFPATH label ".pdf")
                system("xdotool windowmap " wid " &")
                clear_screen()
                if (action == "open sublibraries") {
                    load()
                }
            }
            continue
	    }

	    ## open research paper website: layer 2
	    if (action == "open research paper website") {
            if (doi == "") {
                notify("Cannot find DOI; press enter to continue")
                # back = 1;
            }
            else {
                url = "https://doi.org/" doi
                system(BROWSER " " BIBUKEY url " 2>&1 1>/dev/null &")
                clear_screen()
                # back = 1
            }
            continue
	    }

	    ## copy BibTeX label: layer 2
	    if (action == "copy BibTeX label") {
            system("printf '%s' \"" label "\" | " CLIPINW)
            notify(label " has copied to clipboard using " \
                   CLIPINW "; press enter to continue...")
            # back = 1
            continue
	    }

	    ## write note: layer 2
	    if (action == "write note") {
            system("mkdir -p " NTEPATH label)
            tex_template(NTEPATH label "/" label ".tex", title, author)
            finale()
            system(EDITOR " " NTEPATH label "/" label ".tex")
            init()
            clear_screen()
	    }

	    ## open research appendices: layer 2
	    if (action == "open research appendices") {
            cmd = "printf '%s\n' " APXPATH label "/*"
            cmd | getline pdf
            close(cmd)
            gsub(APXPATH label "/", "", pdf)
            if (pdf ~ /\*/) {
                notify("No appendix found, press enter to continue")
                clear_screen()
                continue
            }
            save()

            sind = 0;
            list = pdf "Go Back...";
            delim = "\n";
            num = 1;
            tmsg = "Choose appendices file to open"
            bmsg = "Action: " action
            continue
	    }

	    ## edit existing BibTeX entry: layer 2
	    if (action == "edit existing BibTeX entry") {
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
                    finale()
                    system(EDITOR " " tmpfile)
                    init()
                    clear_screen()
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
            clear_screen()
            ref_gen(BIBFILE)
            list = biblist "\f" "Go Back...\n\n\n\n\n";
        }

	    ## manually create file hierarchy: layer 2
	    if (action == "manually create file hierarchy") {
		system("mkdir -p " NTEPATH label "; " \
		       "mkdir -p " APXPATH label "; " )

		notify( "Create \n" \
		       NTEPATH label "\n" \
		       APXPATH label "\n" \
		       "for notes, sublibraries and appendices respectively.\n" \
		       "press enter to continue")
		back = 1;
	    }

	    ## manually build database: layer 3
	    ## automatically update database: layer 3
	    if (action == "manually build database" || action == "automatically update database") {
            meta_to_file(file, label, title, author, journal, doi)
            yesno("Update " file " to " label)
            database = ( action == "manually build database" ? 1 : 2 )
            continue
        }

	    ## create sublibraries: layer 2
	    ## edit sublibraries: layer 4 if ADD
	    if (action == "create sublibraries" || movement == ADD) {
		getline FILE < file
		close(file)
		getline BIB < BIBFILE
		close(BIBFILE)
		split(BIB, bibarr, "@")
		delete bibarr[1]
		regex = ".*" label ".*"
		match(FILE, regex)
		if (RSTART) {
		    notify("Duplicated BibTeX entry; press enter to continue")
		    clear_screen()
		}
		else {
		    for (entry in bibarr) {
			if (bibarr[entry] ~ regex) {
			    print "@" bibarr[entry] >> file
			    notify(label " added to " file \
				   "; press enter to continue")
			    clear_screen()
			}
		    }
		}
		continue
	    }

	    ## edit sublibraries: layer 4 if DEL
	    if (movement == DEL) {
		content = ""
		getline FILE < file
		close(file)
		regex = ".*" label ".*"
		split(FILE, FILEarr, "@")
		srand()
		tmpfile = "/tmp/" sprintf("%x", 3480123*rand()) ".tmp"
		delete FILEarr[1]
		regex = ".*" label ".*"
		for (entry in FILEarr) {
		    if (FILEarr[entry] ~ regex) {
			continue
		    }
		    else {
			content = content "\n" "@" FILEarr[entry]

		    }
		}
		content = substr(content, 2)
		print content > tmpfile
		system("mv " tmpfile " " file)
		clear_screen()

		# regenerate list for next delete
		ref_gen(file)
		list = biblist "\f" "Go Back...\n\n\n\n\n";
		delim = "\f";
		num = 6;
		tmsg = "Choose BibTeX entry to delete"
		bmsg = "Action: edit sublibraries"
	    }
	}

	############
	#  Finale  #
	############

	if (response == "Yes") {

	    ## search on crossref: bib_get
	    if (bib_get == 1) {
            getline BIB < BIBFILE
            close(BIBFILE)
            regex = ".*" label ".*"
            match(BIB, regex)
            if (RSTART) {
                notify("Duplicated BibTeX entry; press enter to continue")
                clear_screen()
            }
            else {
                print "\n" bibtex "\n" >> BIBFILE
            }
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
                   "mkdir -p " APXPATH label "; " )
            notify("Open in " label " in " BROWSER \
                   " and create \n" \
                   NTEPATH label "\n" \
                   APXPATH label "\n" \
                   "for notes, sublibraries and appendices respectively.\n" \
                   "press enter to continue")
            back = 1; download = 0
        }

	    ## update database
	    if (database == 1) {
            mv_rm(file, label)
            notify(label " updated; press enter to continue")
            back = 1; database = 0
        }
	    if (database == 2) {
		mv_rm(file, label)
		orig = file; gsub(PDFPATH, "", file)
		name = file; file = orig; orig = "";
		match(faillist, name)
		if (length(faillist) == RSTART + RLENGTH - 1) { # last file
		    prev = substr(faillist, 1, RSTART - 2)
		    post = ""
		}
		else { # other file
		    prev = substr(faillist, 1, RSTART - 1)
		    post = substr(faillist, RSTART + RLENGTH + 1)
		}

		faillist = prev post

		save()
		backtext = "All PDF files in database is updated!"
		list = ( faillist == "" ? \
			backtext : \
			faillist "\f" "Main Menu" );
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

	    # remove sublibrary
	    if (movement == RMV) {
		system("rm " file)
		notify(file " has been removed")
		back = 1
	    }
	}

	if (response == "No") {
	    back = 1
	}


	#####################################
	#  Back to last layer or main menu  #
	#####################################


	if (response ~ /.*Go Back\.\.\..*/) {
	    load()
	    continue
	}

	if (back == 1 || response == backtext || response == "Main Menu") {
        restore()
        back = 0
    }
}

}

END {
    finale()
}

function load() {
    layer--
    response = saved[layer*6 - 5]
    list = saved[layer*6 - 4]
    delim = saved[layer*6 - 3]
    num = saved[layer*6 - 2]
    tmsg = saved[layer*6 - 1]
    bmsg = saved[layer*6]
}

function save() {
    saved[layer*6 - 5] = response
    saved[layer*6 - 4] = list
    saved[layer*6 - 3] = delim
    saved[layer*6 - 2] = num
    saved[layer*6 - 1] = tmsg
    saved[layer*6] = bmsg
    layer++
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
    list = menu[1]; delim = menu[2]; num = menu[3];
    tmsg = menu[4]; bmsg = menu[5];
    jsonlist = ""; biblist = ""; bibtex = "";
    metalist = ""; labellist = ""; file = "";
    string = ""; str = "";
    action = ""; movement = "default";
    ADD = ""; DEL = ""; RMV = "";
    bib_get = 0; download = 0; database = 0; sind = 0
}

function notify(msg, str) {
    clear_screen()
    RS = "\n" # stop getline by enter
    print msg
    system("stty icanon echo")
    printf "\033\133?25h" > "/dev/stderr" # show cursor
    cmd = "read -r ans; echo \"$ans\" 2>/dev/null"
    cmd | getline str
    close(cmd)
    printf "\033\133?25l" > "/dev/stderr" # hide cursor
    RS = "\f"
    system("stty -icanon -echo")
    return str
}

function yesno(topmsg) {
    clear_screen()

    save()
    list = "Yes" "\f" "No" "\f" "Go Back...";
    delim = RS;
    num = 1;
    tmsg = topmsg
    bmsg = "Yes-No Question"
    menu_TUI_page(list, delim)
}

function meta_to_file(file, label, title, author, journal, doi) {
    system("gs -o \"/tmp/" label ".pdf\" \\" \
	   "-sDEVICE=pdfwrite \\" \
	   "-f \"" file "\" \\" \
	   "-c \"[ /Title (" title ")" \
	   "/Author (" author ")" \
	   "/Subject (" journal ")" \
	   "/WPS-ARTICLEDOI (" doi ")" \
	   "/DOCINFO pdfmark\" 1>/dev/null 2>&1; ")
}

function mv_rm(file, label) {
    cmd = "mv \"/tmp/" label ".pdf\" \"" PDFPATH label ".pdf\"; echo $?"
    cmd | getline exitcode
    if (exitcode == 0 && file != (PDFPATH label ".pdf") ) {
	system("rm \"" file "\";")
    }
}

function meta_extract(file) {
    LANG = ENVIRON["LANG"];		# save LANG
    ENVIRON["LANG"] = C;		# simplest locale setting
    RS = "\n"
    i = 0
    while (getline < file > 0) {
	match($0, \
	    /\/Title[[:blank:]]?\([^\(]*\)|\/Author[[:blank:]]?\([^\(]*\)|\/Subject[[:blank:]]?\([^\(]*\)|\/WPS-ARTICLEDOI[[:blank:]]?\([^\(]*\)|\/CreationDate[[:blank:]]?\([^\(]*\)|\/ModDate[[:blank:]]?\([^\(]*\)/)
	if(RSTART) {
	    i++
	    temp[i] = substr($0, RSTART, RLENGTH)
	}
    }
    close(file)

    # metadata at the bottom of the file
    for (j = 0; j <= 6; j++) {
	info = info "\n" temp[i - j]
    }
    info = substr(info, 2)

    ENVIRON["LANG"] = LANG; # restore LANG
    RS = "\f"
    split("", temp, ":") # delete temp array
    metadata = info
    info = ""
    clear_screen()
}

function label_alter(bibtex) {

    label = "";
    author = ""; journal = ""; year = ""; category = ""; booktitle = "";

    Nbibtex = split(bibtex, bibtexarr, "\n")
    for (line in bibtexarr) {
        if (bibtexarr[line] ~ /^@.*/) {
            gsub(/\{.*/, "", bibtexarr[line])
            category = bibtexarr[line]
            if (category ~ /.*@book.*/) {
                journal = "Book"
            }
            continue
        }
        if (bibtexarr[line] ~ /.*year.*/) {
            gsub(/.*year ?= ?{?|}?,?$/, "", bibtexarr[line])
            year = bibtexarr[line]
            continue
        }
        if (bibtexarr[line] ~ /.*author.*/) {
            gsub(/.*author ?= ?{?|}?,?$/, "", bibtexarr[line])
            split(bibtexarr[line], authorarr, " and ")
            for (name in authorarr) {
                if (authorarr[name] ~ /.*,.*/) { # first is last name
                    gsub(/,.*/, "", authorarr[name])
                    author = author "_" authorarr[name]
                }
                else { # second is last name
                    gsub(/.* /, "", authorarr[name])
                    author = author "_" authorarr[name]
                }
            }
            author = substr(author, 2)
            continue
        }
        if (bibtexarr[line] ~ /.*journal.*/) {
            gsub(/.*journal ?= ?{?|}?,?$/, "", bibtexarr[line])
            if (bibtexarr[line] ~ /.* .*/) {
                gsub(/[^A-Z]/, "", bibtexarr[line])
            }
            journal = bibtexarr[line]
            continue
        }
        if (bibtexarr[line] ~ /.*booktitle.*/) {
            gsub(/.*booktitle ?= ?{?|}?,?$/, "", bibtexarr[line])
            booktitle = bibtexarr[line]
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
    gsub(/^@[^\n]*,\n/, category "{" label ",\n", bibtex)

    return bibtex
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
    labellist = ""
    label = ""; title = ""; year = "";
    journal = ""; author = ""; doi = "";
    meta_label = ""; meta_title = ""; meta_year = "";
    meta_journal = ""; meta_author = ""; meta_doi = "";

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
		gsub(/^[[:blank:]]*title[[:blank:]]?=[[:blank:]]?{|},?$/, "", entryarr[line])
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
	    if (entryarr[line] ~ /^[[:blank:]]*[dD][oO][iI][[:blank:]]?=[[:blank:]]?{.*/) {
		gsub(/^[[:blank:]]*[dD][oO][iI][[:blank:]]?=[[:blank:]]?{|}.*/, "", entryarr[line])
		meta_doi = entryarr[line]
		doi = sprintf("\tDOI: %s", entryarr[line])
	    }
	}

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
	labellist = labellist "\f" meta_label

	label = ""; title = ""; year = "";
	journal = ""; author = ""; doi = "";
	meta_label = ""; meta_title = ""; meta_year = "";
	meta_journal = ""; meta_author = ""; meta_doi = "";
    }
    biblist = substr(biblist, 2)
    metalist = substr(metalist, 2)
    labellist = substr(labellist, 2)
    return biblist metalist labellist
}

function crossref_json_process(string) {

    json = ""; jsonlist = ""
    given = ""; family = ""
    title = ""; category = ""; date = "";
    journal = ""; author = ""; doi = "";

    cmd = "curl --trace-time \"https://api.crossref.org/works?query.bibliographic=" \
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

        given = ""; family = ""
        title = ""; category = ""; date = "";
        journal = ""; author = ""; doi = "";
        jsonlist = jsonlist "\f" jsonarr[entry]
    }
    jsonlist = substr(jsonlist, 2)
    return jsonlist
}

function clear_screen() { # clear screen and move cursor to 0, 0
    printf "\033\1332J\033\133H"
}

###################
##  Start of TUI  #
###################


function CUP(lines, cols) {
    printf("\033\133%s;%sH", lines, cols)
}

function menu_TUI_page(list, delim) {
    answer = ""; page = 0; split("", pagearr, ":") # delete saved array
    cmd = "stty size"
    cmd | getline d
    close(cmd)
    split(d, dim, " ")
    top = 5; bottom = dim[1] - 4;
    fin = bottom - ( bottom - (top - 1) ) % num; end = fin + 1;
    dispnum = (end - top) / num
    Narr = split(list, disp, delim)
    move = int( ( dispnum <= Narr ? dispnum * 0.5 : Narr * 0.5 ) )
    dispnum = (dispnum <= Narr ? dispnum : Narr)

    # generate display content for each page (pagearr)
    for (entry = 1; entry <= Narr; entry++) {
        if ((+entry) % (+dispnum) == 1) { # if first item in each page
            pagearr[++page] = entry ". " disp[entry]
        }
        else {
            pagearr[page] = pagearr[page] "\n" entry ". " disp[entry]
        }
    }
    curpage = 1;
}

function search(list, delim, str) {
    find = ""; str = tolower(str); regex = ".*" str ".*";
    Narr = split(list, sdisp, delim)

    for (entry = 1; entry <= Narr; entry++) {
	match(tolower(sdisp[entry]), regex)
	if (RSTART) find = find delim sdisp[entry]
    }

    slist = substr(find, 2)
    return slist
}

function finale() {
    printf "\033\1332J\033\133H" >> "/dev/stderr" # clear screen
    printf "\033\133?7h" >> "/dev/stderr" # line wrap
    printf "\033\1338" >> "/dev/stderr" # restore cursor
    printf "\033\133?25h" >> "/dev/stderr" # show cursor
    printf "\033\133?1049l" >> "/dev/stderr" # back from alternate buffer
    system("stty isig icanon echo")
    ENVIRON["LANG"] = LANG; # restore LANG
}

function init() {
    system("stty -isig -icanon -echo")
    printf "\033\1332J\033\133H" >> "/dev/stderr" # clear screen
    printf "\033\133?1049h" >> "/dev/stderr" # alternate buffer
    printf "\033\1337" >> "/dev/stderr" # save cursor
    printf "\033\133?25l" >> "/dev/stderr" # hide cursor
    printf "\033\1335 q" >> "/dev/stderr" # blinking bar
    printf "\033\133?7l" >> "/dev/stderr" # line unwrap
    LANG = ENVIRON["LANG"]; # save LANG
    ENVIRON["LANG"] = C; # simplest locale setting
}

function key_collect(list, pagerind) {
    key = ""; rep = 0
    do {

        cmd = "trap 'printf WINCH' WINCH; dd ibs=1 count=1 2>/dev/null"
        cmd | getline ans;
        close(cmd)

        gsub(/[\\^\[\]]/, "\\\\&", ans) # escape special char
        if (ans ~ /.*WINCH/ && pagerind == 0) { # trap SIGWINCH
            cursor = 1; curpage = 1;
            menu_TUI_page(list, delim)
            redraw(tmsg, bmsg)
            gsub(/WINCH/, "", ans);
        }
        if (ans ~ /\033/ && rep == 1) { ans = ""; continue; } # first char of escape seq
        else { key = key ans; }
        if (key ~ /[^\x00-\x7f]/) { break } # print non-ascii char
        if (key ~ /^\\\[5$|^\\\[6$$/) { ans = ""; continue; } # PageUp / PageDown
    } while (ans !~ /[\x00-\x5a]|[\x5f-\x7f]/)
    # } while (ans !~ /[\006\025\033\003\177[:space:][:alnum:]><\}\{.~\/:!?*+-]|"|[|_$()]/)
    return key
}

function redraw(tmsg, bmsg) {
    printf "\033\1332J\033\133H" # clear screen and move cursor to 0, 0
    CUP(1, 1);
    hud = "page: [n]ext, [p]rev, [r]eload, [t]op, [b]ottom, [num+G]o; entry: [h/k/j/l]-[←/↑/↓/→], [/]search, [q]uit"
    gsub("[[]", "[\033\1331m", hud); gsub("[]]", "\033\133m]", hud)
    printf hud

    CUP(2, 1)
    hline = sprintf("%" dim[2] "s", "")
    gsub(/ /, "━", hline)
    printf hline
    CUP(top, 1); print pagearr[curpage]
    cursor = ( cursor+dispnum*(curpage-1) > Narr ? Narr - dispnum*(curpage-1) : cursor )
    Ncursor = cursor+dispnum*(curpage-1)
    CUP(top + cursor*num - num, 1); printf "%s\033\1330;7m%s\033\133m", Ncursor ". ", disp[Ncursor]
    CUP(3, 1); print tmsg
    CUP(dim[1] - 2, 1); print bmsg
    CUP(dim[1], 1)
    printf "Choose [\033\1331m1-%d\033\133m], current page num is \033\133;1m%d\033\133m, total page num is \033\133;1m%d\033\133m: ", Narr, curpage, page
}

function menu_TUI(list, delim, num, tmsg, bmsg) {

    cursor = 1
    if (sind == 1) {
        menu_TUI_page(slist, delim)
    }
    else {
        menu_TUI_page(list, delim)
    }

    while (answer !~ /^[[:digit:]]+$|Go\ Back\.\.\./) {

        redraw(tmsg, bmsg)

        while (1) {

            answer = key_collect(list, pagerind)

            #######################################
            #  Key: entry choosing and searching  #
            #######################################

            if ( answer ~ /[[:digit:]]/ || answer == "/" ) {
                system("stty icanon echo")
                CUP(dim[1], 1)
                printf "Choose [\033\1331m1-%d\033\133m], current page num is \033\133;1m%d\033\133m, total page num is \033\133;1m%d\033\133m: %s", Narr, curpage, page, answer
                RS = "\n"
                cmd = "read -r ans; echo \"$ans\" 2>/dev/null"
                cmd | getline ans
                close(cmd)
                RS = "\f"
                system("stty -icanon -echo")
                answer = answer ans; ans = ""

                if (answer ~ /\/[^[:cntrl:]*]/) {
                    slist = search(list, delim, substr(answer, 2))
                    if (slist != "") {
                        menu_TUI_page(slist, delim)
                        cursor = 1; curpage = 1; sind = 1
                    }
                    break
                }
                if ( (answer ~ /[[:digit:]]+G/) ) {
                    ans = answer; gsub(/G/, "", ans);
                    curpage = (+ans <= +page ? ans : page)
                    break
                }
                if (+answer > +Narr) answer = Narr
                if (+answer < 1) answer = 1
                break
            }

            ########################
            #  Key: Total Redraw   #
            ########################

            if ( answer == "r" ||
               ( answer == "h" && sind == 1 ) ||
               ( answer ~ /[[:digit:]]/ && (+answer > +Narr || +answer < 1) ) ) {
                   menu_TUI_page(list, delim)
                   curpage = (+curpage > +page ? page : curpage)
                   sind = 0;
                   break
               }
            if ( answer == "\r" || answer == "l" ) {
                answer = Ncursor;
                sind = 0;
                break
            }
            if ( answer == "q" ) exit
            if ( answer == "h" ) { answer = "Go Back..."; disp[answer] = "Go Back..."; break }
            if ( answer == "n" && +curpage < +page) { curpage++; break }
            if ( answer == "n" && +curpage == +page) { cursor = ( +curpage == +page ? Narr - dispnum*(curpage-1) : dispnum ); break }
            if ( answer == "p" && +curpage > 1) { curpage--; break }
            if ( answer == "p" && +curpage == 1) { cursor = 1; break }
            if ( answer == "t" ) { curpage = 1; cursor = 1; break }
            if ( answer == "b" ) { curpage = page; cursor = Narr - dispnum*(curpage-1); break }

            #########################
            #  Key: Partial Redraw  #
            #########################

            if ( answer == "j" && +cursor <= +dispnum ) { oldCursor = cursor; cursor++; }
            if ( answer == "j" && +cursor > +dispnum  && page > 1 ) { cursor = 1; curpage++; break }
            if ( answer == "k" && +cursor == 1  && curpage > 1 && page > 1 ) { cursor = dispnum; curpage--; break }
            if ( answer == "k" && +cursor >= 1 ) { oldCursor = cursor; cursor--; }
            if ( answer == "g" ) { oldCursor = cursor; cursor = 1; }
            if ( answer == "G" ) { oldCursor = cursor; cursor = ( +curpage == +page ? Narr - dispnum*(curpage-1) : dispnum ); }
           if ( (answer == "\006") && cursor <= +dispnum ) { oldCursor = cursor; cursor = cursor + move }
           if ( (answer == "\006") && +cursor > +dispnum && +curpage < +page && +page > 1 ) { cursor = cursor - dispnum; curpage++; break }
           if ( (answer == "\006") && +cursor > Narr - dispnum*(curpage-1) && +curpage == +page ) { cursor = ( +curpage == +page ? Narr - dispnum*(curpage-1) : dispnum ); break }
           if ( (answer == "\006") && +cursor == Narr - dispnum*(curpage-1) && +curpage == +page ) break

           if ( (answer == "\025") && cursor >= 1 ) { oldCursor = cursor; cursor = cursor - move }
           if ( (answer == "\025") && +cursor < 1 && +curpage > 1 ) { cursor = dispnum + cursor; curpage--; break }
           if ( (answer == "\025") && +cursor < 1 && +curpage == 1 ) { cursor = 1; break }
           if ( (answer == "\025") && +cursor == 1 && +curpage == 1 ) break

            ################################################
            #  Partial redraw: tmsg, old entry, new entry  #
            ################################################

            Ncursor = cursor+dispnum*(curpage-1); oldNcursor = oldCursor+dispnum*(curpage-1);
            if (Ncursor > Narr) { Ncursor = Narr; cursor = Narr - dispnum*(curpage-1); continue }
            if (Ncursor < 1) { Ncursor = 1; cursor = 1; continue }

            CUP(3, 1); # tmsg
            printf "\033\1332K" # clear line
            print tmsg

            CUP(top + oldCursor*num - num, 1); # old entry
            for (i = 1; i <= num; i++) {
                printf "\033\1332K" # clear line
                CUP(top + oldCursor*num - num + i, 1)
            }
            CUP(top + oldCursor*num - num, 1);
            printf "%s", oldNcursor ". " disp[oldNcursor]

            CUP(top + cursor*num - num, 1); # new entry
            for (i = 1; i <= num; i++) {
                printf "\033\1332K" # clear line
                CUP(top + cursor*num - num + i, 1)
            }

            CUP(top + cursor*num - num, 1);
            printf "%s\033\1330;7m%s\033\133m", Ncursor ". ", disp[Ncursor]

        }

    }

    return disp[answer]
}
