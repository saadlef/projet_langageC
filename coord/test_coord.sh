#!/bin/bash
# Petit script bash qui test la conformance des fichiers rendus
#
# /!\ NE PAS MODIFIER /!\

logfile="checkerror.log"
err=0

check_fichier () {
    if [ ! -f "$1" ]; then
        echo "Je ne trouve pas le fichier $1 ! Vérifiez que vous êtes bien dans le bon répertoire..."
        echo "Fichier $1 absent" >>$logfile
        err=1
        return 1
    fi

    echo "Vérification de la syntaxe pour $1 :" >>$logfile
    echo "gcc -std=c99 -c -Wall -Wextra -pedantic -Werror -fsyntax-only -x c $1" >>$logfile 
    gcc -std=c99 -c -Wall -Wextra -pedantic -Werror -fsyntax-only -x c "$1" >>$logfile 2>&1

    if [ $? -ne 0 ]; then
        echo "Je n'arrive pas à compiler le fichier $1... Veuillez corriger les erreurs et recommencer"
        err=1
    fi
}

check_garde () {
    include="$1"
    anchor="$2"
    tmpfile="__tmp_${include}"

    if [ -f "${tmpfile}" ]; then
        rm "${tmpfile}"
    fi

    # Ajoute une constante statique
    sed "/$anchor/a\
        static const int x = 1;" ${include} > ${tmpfile}
 
    read -r -d '' RESULT <<END_DOC
#include "${tmpfile}"
#include "${tmpfile}"

void test() {}
END_DOC

    echo "" >>$logfile
    echo "[le header ${include} est correctement gardé]" >>$logfile
    echo "==code" >>$logfile
    echo "$code" >>$logfile
    echo "==endcode" >>$logfile
    echo "$RESULT" | gcc -c -fsyntax-only -x c - >>$logfile 2>&1

    rm "${tmpfile}"

    if [[ ($neg -eq 0 && $? -ne 0) || ($neg -eq 1 && $? -eq 0) ]]; then
        echo "Erreur : le header ${include} n'est pas correctement gardé !"
        err=1
        return 1
    fi

    return 0
}

check () {
    name=""
    include=""
    code=""
    errmsg=""
    neg=0

    if [[ $1 == "-n" ]]; then
        name="$2"
        include="$3"
        code="$4"
        errmsg="$5"
        neg=1
    else
        name="$1"
        include="$2"
        code="$3"
        errmsg="$4"
    fi

    read -r -d '' RESULT <<END_DOC
#include "${include}"

void test() {
${code}
}
END_DOC

    echo "" >>$logfile
    echo "[${name}]" >>$logfile
    echo "==code" >>$logfile
    echo "$code" >>$logfile
    echo "==endcode" >>$logfile
    echo "$RESULT" | gcc -c -Wall -Wextra -pedantic -Werror -fsyntax-only -x c - >>$logfile 2>&1

    if [[ ($neg -eq 0 && $? -ne 0) || ($neg -eq 1 && $? -eq 0) ]]; then
        echo "Erreur : ${errmsg}"
        err=1
        return 1
    fi

    return 0
}

if [ -f $logfile ]; then
    rm $logfile
fi

echo "Vérification des fichiers..."

check_fichier "coord.h"
check_fichier "coord.c"

if [ $err -ne 0 ]; then
    echo "Les erreurs des fichiers testés empêchent de poursuivre le test..."
    echo "Consultez le fichier ${logfile} pour voir les messages d'erreur obtenu"
    exit -1
fi

gerr=0

check_garde "coord.h" "creer_coord(0, 0);"

check \
    "Définition de coord_t" \
    "coord.h" \
    "coord_t c; (void) c;" \
    "Le type coord_t n'est pas accessible ou n'a pas le bon nom (peut-être avez-vous oublié un typedef ?)" \
&& check \
    "Définition de creer_coord" \
    "coord.h" \
    "coord_t c = creer_coord((int) 0, (int) 0); (void) c;" \
    "La fonction creer_coord n'existe pas ou n'a pas la bonne signature" \
&& check \
    "Définition de get_x" \
    "coord.h" \
    "coord_t c = creer_coord(0, 0); int x = get_x(c); (void) x;" \
    "La fonction get_x n'existe pas ou n'a pas la bonne signature" \
&& check \
    "Définition de get_y" \
    "coord.h" \
    "coord_t c = creer_coord(0, 0); int y = get_y(c); (void) y;" \
    "La fonction get_y n'existe pas ou n'a pas la bonne signature" \
&& check \
    "Définition de set_x" \
    "coord.h" \
    "coord_t c = creer_coord(0, 0); set_x(&c, (int) 1);" \
    "La fonction set_x n'existe pas ou n'a pas la bonne signature" \
&& check \
    "Définition de set_y" \
    "coord.h" \
    "coord_t c = creer_coord(0, 0); set_y(&c, (int) 1);" \
    "La fonction set_y n'existe pas ou n'a pas la bonne signature" \
&& check \
    "Définition de memes_coord" \
    "coord.h" \
    "coord_t c = creer_coord(0,0); bool r = memes_coord(c, c); (void) r;" \
    "La fonction memes_coord n'existe pas ou n'a pas la bonne signature" \
&& check \
    "Définition de translation" \
    "coord.h" \
    "coord_t c = creer_coord(0,0); c = translation(c, (int) 1, (int) 2); (void) c;" \
    "La fonction translation n'existe pas ou n'a pas la bonne signature" \
&& check \
    "Définition de distance_euclidienne" \
    "coord.h" \
    "coord_t c = creer_coord(0,0); float r = distance_euclidienne(c, c); (void) r;" \
    "La fonction distance_euclidienne n'existe pas ou n'a pas la bonne signature"

if [ $err -ne 0 ]; then
    echo "Le fichier coord.h n'est pas conforme"
    gerr=1
fi

echo "Compilation..."

gcc -c test_coord.c -o test_coord.o -O0 && \
gcc -c coord.c -o coord.o -O0 && \
gcc test_coord.o coord.o -o test_coord -L. -lt -lm

if [ $? -ne 0 ]; then
    echo "Impossible de compiler le test :("
    gerr=2
fi

if [ $gerr -eq 0 ]; then
    echo "Check ok."
else
    exit -2
fi

echo "Lancement des tests..."

./test_coord





