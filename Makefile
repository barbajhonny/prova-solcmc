# Makefile per SolCMC

SOLC = solc
# Aggiungi l'export per Z3
export LD_LIBRARY_PATH := /usr/local/lib:$(LD_LIBRARY_PATH)

# Percorso dei contratti
SRC_DIR = contracts/bank/versions
# Directory per i risultati
RESULTS_DIR = results
LOG_FILE = $(RESULTS_DIR)/output.log

# Flag per solc: base path e include path per risolvere gli import
SOLC_FLAGS = --model-checker-engine all \
             --model-checker-invariants contract \
             --model-checker-solvers z3 \
             --model-checker-show-unproved \
             --model-checker-targets assert \
             --base-path . \
             --include-path $(SRC_DIR) \
             --include-path $(SRC_DIR)/lib

# Crea la cartella results se non esiste
$(shell mkdir -p $(RESULTS_DIR))

# Trova tutti i file .sol in SRC_DIR (ricorsivamente)
SOURCES = $(shell find $(SRC_DIR) -name "*.sol" -type f)

# Target principale: esegue SolCMC su tutti i contratti
solcmc: $(SOURCES)
	@echo "Running SolCMC on all contracts..."
	@for f in $(SOURCES); do \
		echo "=== Processing $$(basename $$f) ==="; \
		$(SOLC) $(SOLC_FLAGS) $$f 2>&1 | tee -a $(LOG_FILE); \
		echo ""; \
	done

# Target per un singolo contratto (es. make Bank_v9)
%: $(SRC_DIR)/%.sol
	@echo "Running SolCMC on $<"
	$(SOLC) $(SOLC_FLAGS) $< 2>&1 | tee $(RESULTS_DIR)/$*.log

# Pulizia
clean:
	rm -rf $(RESULTS_DIR)
	find . -name "*.log" -delete