# Plotter 60x50 SelfColor V4

Questo sketch Processing converte immagini SVG in GCODE per un plotter da disegno (60x50cm). Supporta la gestione dei colori e genera riempimenti (hatching) avanzati.

## Funzionalità Principali

*   **Importazione SVG**: Carica file SVG e analizza le forme e i colori tramite la libreria Geomerative.
*   **Gestione Colori**: Separa le forme in base al colore per gestire cambi penna o pennello automatici/manuali.
*   **Hatching (Riempimento)**:
    *   **Lineare**: Riempimento classico a linee parallele con angolazione variabile.
    *   **Concentrico (Smart)**: Riempimento che segue il contorno della forma verso l'interno (offset).
        *   **Gestione Forme Interne**: Rilevamento automatico delle forme interne (buchi, occhi, bocche in ritratti) per evitare sovrapposizioni. Il riempimento "gira intorno" alle forme interne preservandole, invece di coprirle.
*   **Ottimizzazione Geometria**:
    *   Sanitizzazione dei vertici per prevenire errori topologici (es. coordinate NaN).
    *   Correzione automatica di forme aperte o malformate prima dell'elaborazione geometrica (JTS/PGS).
*   **Generazione GCODE**: Esporta istruzioni GCODE ottimizzate, inclusi movimenti Z (pen up/down), gestione tool change e percorsi di pulizia/ricarica colore.
*   **Anteprima e Stima**: Visualizzazione a schermo del percorso e stima accurata del tempo di esecuzione.

## Librerie Richieste

Per eseguire questo sketch sono necessarie le seguenti librerie Processing:
*   **Geomerative**: Per il parsing e la manipolazione vettoriale SVG.
*   **PGS (Processing Geometry Suite)**: Per operazioni geometriche avanzate (buffering, operazioni booleane, conversioni JTS).

## Ultimi Aggiornamenti

*   **Fix Hatching Concentrico**: Risolto problema di sovrapposizione su forme interne (es. iridi, bocche). Ora l'algoritmo sottrae correttamente le forme contenute prima di generare le linee concentriche.
*   **Robustezza**: Aggiunti controlli per `TopologyException` e sanitizzazione proattiva delle `PShape` per evitare crash su SVG complessi o imperfetti.

## Utilizzo

1.  Aprire lo sketch in Processing.
2.  Avviare l'esecuzione.
3.  Selezionare un file `.svg` dalla finestra di dialogo.
4.  Attendere l'elaborazione (visualizzata a console).
5.  Il GCODE risultante verrà salvato nella sottocartella `GCODE/` insieme a un'anteprima PNG.
