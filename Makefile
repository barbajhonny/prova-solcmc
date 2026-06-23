# Makefile per SolCMC

export LD_LIBRARY_PATH := /usr/local/lib:$(LD_LIBRARY_PATH)

SOLC = solc
SOLC_FLAGS = --model-checker-engine all \
             --model-checker-invariants contract \
             --model-checker-solvers z3 \
             --model-checker-show-unproved \
             --model-checker-targets assert

SRC_DIR = src
RESULTS_DIR = results
LOG_FILE = $(RESULTS_DIR)/output.log

# Assicura che la cartella results esista
$(shell mkdir -p $(RESULTS_DIR))

# Trova tutti i file .sol in src/
SOURCES = $(wildcard $(SRC_DIR)/*.sol)

# Target principale: esegue SolCMC su tutti i contratti
solcmc: $(SOURCES)
	@echo "Running SolCMC on all contracts..."
	@for f in $(SOURCES); do \
		echo "=== Processing $$(basename $$f) ==="; \
		$(SOLC) $(SOLC_FLAGS) $$f 2>&1 | tee -a $(LOG_FILE); \
		echo ""; \
	done

# Target per un singolo contratto (utile per debug)
%: $(SRC_DIR)/%.sol
	@echo "Running SolCMC on $<"
	$(SOLC) $(SOLC_FLAGS) $< 2>&1 | tee $(RESULTS_DIR)/$*.log

# Pulizia
clean:
	rm -rf $(RESULTS_DIR)
	find . -name "*.log" -delete