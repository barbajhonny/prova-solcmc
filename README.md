# Prova SolCMC

Progetto minimo per testare il model checker di Solidity (SolCMC) con Z3.

## Struttura

- `src/`: contratti Solidity da verificare
- `Makefile`: esegue SolCMC su tutti i contratti in `src/`

## Utilizzo

```bash
make solcmc
