# regression.tcl
#
# Automatski pokrece Canny UVM testove preko:
#
#   +UVM_TESTNAME
#
# Dostupne grupe testova:
#
#   real       - dve realne slike
#   synthetic  - crna i pola crna/pola bela slika
#   all        - svi testovi
#
# Pokretanje svih testova:
#
#   source scripts/regression.tcl
#
# Pokretanje samo testova sa realnim slikama:
#
#   set CANNY_SUITE real
#   source scripts/regression.tcl
#
# Pokretanje samo sintetickih testova:
#
#   set CANNY_SUITE synthetic
#   source scripts/regression.tcl


# ============================================================
# Liste testova
# ============================================================

set real_tests {
    canny_base_test
    canny_image2_test
}

set synthetic_tests {
    canny_black_test
    canny_half_test
}

set all_tests [
    concat \
        $real_tests \
        $synthetic_tests
]


# ============================================================
# Izbor grupe testova
#
# Ako CANNY_SUITE nije prethodno postavljen,
# podrazumevano se pokrecu svi testovi.
# ============================================================

if {
    ![info exists CANNY_SUITE]
} {

    set CANNY_SUITE all

}


if {
    $CANNY_SUITE eq "real"
} {

    set tests $real_tests

    puts ""
    puts "Pokrecem Canny testove sa realnim slikama."


} elseif {
    $CANNY_SUITE eq "synthetic"
} {

    set tests $synthetic_tests

    puts ""
    puts "Pokrecem Canny sinteticke testove."


} elseif {
    $CANNY_SUITE eq "all"
} {

    set tests $all_tests

    puts ""
    puts "Pokrecem sve Canny UVM testove."


} else {

    puts ""
    puts "GRESKA: Nepoznata vrednost CANNY_SUITE=$CANNY_SUITE"
    puts "Dozvoljene vrednosti su:"
    puts "  real"
    puts "  synthetic"
    puts "  all"
    puts ""

    unset CANNY_SUITE

    return

}


# ============================================================
# Putanje
#
# Skripta se pokrece iz otvorenog Vivado projekta.
# DIRECTORY svojstvo vraca glavni direktorijum projekta.
# ============================================================

set project_dir [
    file normalize [
        get_property DIRECTORY [
            current_project
        ]
    ]
]


set sim_xsim_dir [
    file join \
        $project_dir \
        "canny_verification.sim" \
        "sim_1" \
        "behav" \
        "xsim"
]


# XSim coverage baza koja se generise tokom simulacije.

set cov_source [
    file join \
        $sim_xsim_dir \
        "xsim.covdb"
]


# Glavni direktorijum za rezultate regresije.

set regression_root_dir [
    file join \
        $project_dir \
        "regression_results"
]


set cov_runs_dir [
    file join \
        $regression_root_dir \
        "coverage_runs"
]


set report_root_dir [
    file join \
        $regression_root_dir \
        "coverage_report"
]


set single_reports_dir [
    file join \
        $report_root_dir \
        "single_tests"
]


set merged_report_dir [
    file join \
        $report_root_dir \
        "merged"
]


set logs_dir [
    file join \
        $regression_root_dir \
        "logs"
]


# ============================================================
# Brisanje rezultata prethodne regresije
# ============================================================

if {
    [file exists $regression_root_dir]
} {

    puts ""
    puts "Brisem rezultate prethodne regresije:"
    puts "  $regression_root_dir"

    file delete \
        -force \
        $regression_root_dir

}


file mkdir $cov_runs_dir
file mkdir $single_reports_dir
file mkdir $merged_report_dir
file mkdir $logs_dir


puts ""
puts "================================================"
puts " CANNY UVM REGRESSION"
puts "================================================"
puts "Project directory:"
puts "  $project_dir"
puts ""
puts "Izabrana grupa testova:"
puts "  $CANNY_SUITE"
puts ""
puts "Broj testova:"
puts "  [llength $tests]"
puts "================================================"
puts ""


# ============================================================
# Pokretanje testova
# ============================================================

foreach test_name $tests {

    puts ""
    puts "================================================"
    puts " Pokrecem test: $test_name"
    puts "================================================"
    puts ""


    # Zatvaranje prethodne simulacije, ako je otvorena.

    close_sim -quiet


    # Brisanje prethodne XSim coverage baze kako se ne bi
    # slucajno sacuvali podaci starog testa.

    if {
        [file exists $cov_source]
    } {

        file delete \
            -force \
            $cov_source

    }


    # Postavljanje imena UVM testa.
    #
    # Ovo automatski menja vrednost koja se inace rucno
    # postavlja u:
    #
    # Simulation Settings
    # xsim.simulate.xsim.more_options

    set_property \
        -name {xsim.simulate.xsim.more_options} \
        -value "-testplusarg UVM_TESTNAME=$test_name -testplusarg UVM_VERBOSITY=UVM_LOW" \
        -objects [
            get_filesets sim_1
        ]


    # Pokretanje Behavioral Simulation.

    launch_simulation


    # Simulacija se izvrsava dok UVM test ne zavrsi i pozove
    # $finish. Na ovaj nacin ne zavisimo od unapred zadatog
    # simulacionog vremena.

    run all


    puts ""
    puts "Test $test_name je zavrsen."
    puts ""


    # ========================================================
    # Cuvanje simulation log fajla
    # ========================================================

    set simulate_log [
        file join \
            $sim_xsim_dir \
            "simulate.log"
    ]


    if {
        [file exists $simulate_log]
    } {

        set saved_log [
            file join \
                $logs_dir \
                "${test_name}.log"
        ]


        file copy \
            -force \
            $simulate_log \
            $saved_log


        puts "Simulation log je sacuvan u:"
        puts "  $saved_log"

    } else {

        puts "UPOZORENJE: simulate.log nije pronadjen:"
        puts "  $simulate_log"

    }


    # ========================================================
    # Cuvanje coverage baze pojedinacnog testa
    # ========================================================

    if {
        [file exists $cov_source]
    } {

        set test_cov_dir [
            file join \
                $cov_runs_dir \
                $test_name
        ]


        if {
            [file exists $test_cov_dir]
        } {

            file delete \
                -force \
                $test_cov_dir

        }


        file mkdir $test_cov_dir


        set saved_cov_db [
            file join \
                $test_cov_dir \
                "xsim.covdb"
        ]


        file copy \
            -force \
            $cov_source \
            $saved_cov_db


        puts ""
        puts "Coverage baza je sacuvana u:"
        puts "  $saved_cov_db"


        # ====================================================
        # Generisanje pojedinacnog HTML coverage report-a
        # ====================================================

        set single_report_dir [
            file join \
                $single_reports_dir \
                $test_name
        ]


        if {
            [file exists $single_report_dir]
        } {

            file delete \
                -force \
                $single_report_dir

        }


        file mkdir $single_report_dir


        puts ""
        puts "Generisem pojedinacni HTML coverage report za:"
        puts "  $test_name"


        if {
            [catch {

                exec xcrg \
                    -report_format html \
                    -dir $saved_cov_db \
                    -report_dir $single_report_dir

            } xcrg_msg]
        } {

            puts ""
            puts "UPOZORENJE:"
            puts "Pojedinacni xcrg report nije napravljen za:"
            puts "  $test_name"
            puts ""
            puts "xcrg poruka:"
            puts "  $xcrg_msg"

        } else {

            puts ""
            puts "Pojedinacni coverage report je napravljen:"
            puts "  [file join $single_report_dir dashboard.html]"

        }

    } else {

        puts ""
        puts "UPOZORENJE:"
        puts "XSim coverage baza nije pronadjena:"
        puts "  $cov_source"
        puts ""
        puts "Test je ipak izvrsen."
        puts "Ovo upozorenje samo znaci da XSim code coverage"
        puts "nije ukljucen ili coverage baza nije generisana."

    }


    puts ""
    puts "================================================"
    puts " Zavrsen test: $test_name"
    puts "================================================"
    puts ""

}


# ============================================================
# Zavrsena regresija
# ============================================================

puts ""
puts "================================================"
puts " CANNY UVM REGRESIJA JE ZAVRSENA"
puts "================================================"
puts ""
puts "Izvrseni testovi:"

foreach test_name $tests {

    puts "  - $test_name"

}

puts ""
puts "Log fajlovi:"
puts "  $logs_dir"
puts ""


# ============================================================
# Generisanje zbirnog coverage report-a
#
# Ovaj deo se izvrsava samo ako postoje coverage baze.
# ============================================================

set xcrg_args [
    list \
        xcrg \
        -report_format html
]


set available_cov_count 0


foreach test_name $tests {

    set test_cov_db [
        file join \
            $cov_runs_dir \
            $test_name \
            "xsim.covdb"
    ]


    if {
        [file exists $test_cov_db]
    } {

        lappend xcrg_args \
            -dir \
            $test_cov_db

        incr available_cov_count

    } else {

        puts "UPOZORENJE: Preskacem coverage merge za:"
        puts "  $test_name"
        puts "Ne postoji:"
        puts "  $test_cov_db"
        puts ""

    }

}


if {
    $available_cov_count > 0
} {

    lappend xcrg_args \
        -report_dir \
        $merged_report_dir


    puts "================================================"
    puts " Generisem zbirni HTML coverage report"
    puts "================================================"
    puts ""


    if {
        [catch {

            exec {*}$xcrg_args

        } xcrg_merge_msg]
    } {

        puts "UPOZORENJE:"
        puts "Zbirni xcrg coverage report nije napravljen."
        puts ""
        puts "Ovo ne znaci da su UVM testovi pali."
        puts "Pojedinacni log fajlovi su sacuvani."
        puts ""
        puts "xcrg poruka:"
        puts "  $xcrg_merge_msg"

    } else {

        puts "Zbirni coverage report je napravljen:"
        puts "  [file join $merged_report_dir dashboard.html]"

    }

} else {

    puts "================================================"
    puts " Zbirni coverage report nije generisan"
    puts "================================================"
    puts ""
    puts "Nijedna XSim coverage baza nije pronadjena."
    puts "UVM testovi su ipak pokrenuti i njihovi rezultati"
    puts "se mogu proveriti u sacuvanim log fajlovima."

}


puts ""
puts "================================================"
puts " REGRESSION OBRADA JE ZAVRSENA"
puts "================================================"
puts ""


# Brisanje promenljive kako pri sledecem pokretanju ne bi
# ostao prethodni izbor grupe testova.

unset CANNY_SUITE