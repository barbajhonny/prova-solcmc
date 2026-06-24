#!/bin/bash

# Directory
VERSIONS_DIR="contracts/bank/versions"
SOLCMC_DIR="contracts/bank/solcmc"
TMP_DIR="tmp_combined"
RESULTS_DIR="results"
mkdir -p $TMP_DIR $RESULTS_DIR

# Flag di SolCMC (presi dal Makefile del benchmark)
SOLC_FLAGS="--model-checker-engine chc \
            --model-checker-invariants contract,reentrancy \
            --model-checker-solvers z3 \
            --model-checker-show-unproved \
            --model-checker-targets assert \
            --model-checker-timeout 60000"

# Timeout per ogni test (in secondi)
TIMEOUT=120

# File CSV di output (matrice completa)
CSV_FILE="$RESULTS_DIR/results_matrix.csv"
echo "Version,Property,Result" > $CSV_FILE

# Loop su tutte le versioni
for bank_file in $VERSIONS_DIR/Bank_v*.sol; do
    version=$(basename $bank_file .sol)
    echo "Testing $version..."

    # Loop su tutte le proprietà
    for prop_file in $SOLCMC_DIR/*.sol; do
        prop_name=$(basename $prop_file .sol)
        echo "  $prop_name..."

        # Estrai la funzione invariant (tutto il contenuto del file)
        invariant_code=$(cat $prop_file)

        # Crea il file combinato
        combined_file="$TMP_DIR/${version}_${prop_name}.sol"
        {
            # Copia il contratto Bank senza l'ultima parentesi graffa
            sed -n '/^contract Bank/,/^}/p' $bank_file | head -n -1
            echo ""
            echo "    /// @custom:invariant"
            echo "$invariant_code" | sed 's/^/    /'
            echo "}"
        } > $combined_file

        # Esegui SolCMC con timeout
        output=$(timeout $TIMEOUT solc $SOLC_FLAGS $combined_file 2>&1)
        exit_code=$?

        # Analizza il risultato
        if [ $exit_code -eq 124 ]; then
            result="TIMEOUT"
        elif echo "$output" | grep -q "Assertion violation"; then
            result="FAIL"
        elif echo "$output" | grep -q "proved safe"; then
            result="PASS"
        else
            result="ERROR"
        fi

        # Salva nel CSV
        echo "$version,$prop_name,$result" >> $CSV_FILE

        # Salva il log completo (opzionale)
        echo "$output" > "$RESULTS_DIR/${version}_${prop_name}.log"

        # Pulisci il file temporaneo
        rm $combined_file
    done
done

# Rimuovi la cartella temporanea
rmdir $TMP_DIR

echo "Done. Results saved in $CSV_FILE"