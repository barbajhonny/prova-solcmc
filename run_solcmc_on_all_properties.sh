#!/bin/bash

VERSIONS_DIR="contracts/bank/versions"
SOLCMC_DIR="contracts/bank/solcmc"
TMP_DIR="tmp_combined"
RESULTS_DIR="results"

mkdir -p $TMP_DIR $RESULTS_DIR

BANK_VERSION="Bank_v1"
BANK_FILE="$VERSIONS_DIR/${BANK_VERSION}.sol"

CSV_FILE="$RESULTS_DIR/results_${BANK_VERSION}.csv"
echo "Property,Result" > $CSV_FILE

for prop_file in $SOLCMC_DIR/*.sol; do
    prop_name=$(basename $prop_file .sol)
    echo "Testing $prop_name on $BANK_VERSION..."

    # Estrai la funzione invariant (tutto il contenuto del file, che è solo la funzione)
    invariant_code=$(cat $prop_file)

    # Crea il file combinato
    combined_file="$TMP_DIR/${BANK_VERSION}_${prop_name}.sol"
    {
        # Copia il contratto Bank senza la parentesi graffa finale
        sed -n '/^contract Bank/,/^}/p' $BANK_FILE | head -n -1
        echo ""
        echo "    /// @custom:invariant"
        # Indenta la funzione invariant con 4 spazi per essere dentro il contratto
        echo "$invariant_code" | sed 's/^/    /'
        echo "}"
    } > $combined_file

    # Esegui SolCMC
    output=$(solc \
        --model-checker-engine all \
        --model-checker-invariants contract \
        --model-checker-solvers z3 \
        --model-checker-show-unproved \
        --model-checker-targets assert \
        $combined_file 2>&1)

    # Analizza il risultato
      if echo "$output" | grep -q "Assertion violation"; then
        result="FAIL"
    elif echo "$output" | grep -q "proved safe"; then
        result="PASS"
    else
        result="ERROR"
    fi

    echo "$prop_name,$result" >> $CSV_FILE
    echo "$output" > "$RESULTS_DIR/${BANK_VERSION}_${prop_name}.log"

    # Pulisci
    rm $combined_file
done

rmdir $TMP_DIR
echo "Done. Results saved in $CSV_FILE"