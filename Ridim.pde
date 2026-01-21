
// Helper methods for PShape manipulation
void scalePShape(PShape sh, float scaleFactor) {
  if (sh.getFamily() == GROUP) {
    for (int i = 0; i < sh.getChildCount(); i++) {
      scalePShape(sh.getChild(i), scaleFactor);
    }
  } else {
    for (int i = 0; i < sh.getVertexCount(); i++) {
      PVector v = sh.getVertex(i);
      v.mult(scaleFactor);
      sh.setVertex(i, v);
    }
  }
}

void translatePShape(PShape sh, float tx, float ty) {
  if (sh.getFamily() == GROUP) {
    for (int i = 0; i < sh.getChildCount(); i++) {
      translatePShape(sh.getChild(i), tx, ty);
    }
  } else {
    for (int i = 0; i < sh.getVertexCount(); i++) {
      PVector v = sh.getVertex(i);
      v.add(tx, ty, 0);
      sh.setVertex(i, v);
    }
  }
}

// Returns {minX, minY, maxX, maxY}
float[] getPShapeBounds(PShape sh) {
  try {
    PShape bbox = PGS_Hull.boundingBox(sh);
    if (bbox == null) return null;
    
    float minX = Float.MAX_VALUE;
    float minY = Float.MAX_VALUE;
    float maxX = -Float.MAX_VALUE;
    float maxY = -Float.MAX_VALUE;
    
    for (int i = 0; i < bbox.getVertexCount(); i++) {
        PVector v = bbox.getVertex(i);
        if (v.x < minX) minX = v.x;
        if (v.y < minY) minY = v.y;
        if (v.x > maxX) maxX = v.x;
        if (v.y > maxY) maxY = v.y;
     }
     
     if (bbox.getFamily() == GROUP) {
       for (int i = 0; i < bbox.getChildCount(); i++) {
         PShape child = bbox.getChild(i);
         for (int j = 0; j < child.getVertexCount(); j++) {
           PVector v = child.getVertex(j);
           if (v.x < minX) minX = v.x;
           if (v.y < minY) minY = v.y;
           if (v.x > maxX) maxX = v.x;
           if (v.y > maxY) maxY = v.y;
         }
       }
     }
    
    if (minX == Float.MAX_VALUE) return null;
    return new float[] {minX, minY, maxX, maxY};
  } catch (Exception e) {
    return null;
  }
}

ArrayList<ArrayList<PVector>> extractContours(PShape sh) {
  ArrayList<ArrayList<PVector>> contours = new ArrayList<ArrayList<PVector>>();
  if (sh.getFamily() == GROUP) {
    for (int i = 0; i < sh.getChildCount(); i++) {
      contours.addAll(extractContours(sh.getChild(i)));
    }
  } else {
    ArrayList<PVector> pts = new ArrayList<PVector>();
    for (int i = 0; i < sh.getVertexCount(); i++) {
      pts.add(sh.getVertex(i));
    }
    if (pts.size() > 0) {
      contours.add(pts);
    }
  }
  return contours;
}

// Helper per clonare PShape (deep copy della geometria)
PShape clonePShape(PShape original) {
  PShape clone;
  if (original.getFamily() == GROUP) {
    clone = createShape(GROUP);
    for (int i = 0; i < original.getChildCount(); i++) {
      clone.addChild(clonePShape(original.getChild(i)));
    }
  } else {
    // Tenta di preservare il tipo di shape (POINTS, LINES, ecc.)
    // Se getKind() restituisce 0 (POLYGON), usa il default.
    int kind = original.getKind();
    
    // createShape() senza argomenti crea una forma geometrica complessa vuota
    clone = createShape();
    
    if (kind != 0) {
      clone.beginShape(kind);
    } else {
      clone.beginShape();
    }
    
    // Copia vertici
    for (int i = 0; i < original.getVertexCount(); i++) {
      PVector v = original.getVertex(i);
      // PVector.z è ignorato nel costruttore vertex(x,y) se non siamo in P3D, 
      // ma qui assumiamo 2D per sicurezza o usiamo x,y.
      clone.vertex(v.x, v.y); 
    }
    
    // Per chiudere la forma, dovremmo sapere se era chiusa. 
    // Geomerative e PGS solitamente duplicano il primo punto alla fine se chiuso.
    // Quindi endShape() senza CLOSE va bene se i vertici sono già chiusi.
    clone.endShape();
  }
  return clone;
}

///ridimensiona la lista di shape secondo le dimensioni della carta
void ridimPaper() {
  //orderList();
  //calcola il minimo e il massimo delle figure ridimensionate
  float xMin=100000.0;
  float yMin=10000.0;
  float xMax=0.0;
  float yMax=0.0;
  // per ogni shape calcola il fattore di scala e la traslazione
  //inverti l'asse x
  for (int i=0; i<formaList.size(); i++) {
    // Clona la shape per non modificare l'originale in formaList
    PShape s = clonePShape(formaList.get(i).sh);
    int    iCol=formaList.get(i).ic;
    int    typeC=formaList.get(i).type;
    
    scalePShape(s, factor); //scala secondo il fattore di riduzione
    translatePShape(s, xOffset, yOffset);

    paperFormList.add(new Forma(s, iCol, typeC));
    
    float[] bounds = getPShapeBounds(s);
    if (bounds != null) {
      if (bounds[0] < xMin) xMin = bounds[0];
      if (bounds[1] < yMin) yMin = bounds[1];
      if (bounds[2] > xMax) xMax = bounds[2];
      if (bounds[3] > yMax) yMax = bounds[3];
    }
  }
  println("Xmin:"+xMin+"  Ymin:"+yMin);
  println("Xmax:"+xMax+"  Ymax:"+yMax);
  noFill();
  stroke(0);
  xxMax=xMax;
  // rect(xOffset, yOffset, xDim, yDim);
}

////////////////////////////////////////////////////////////////////////////////////////////
/// crea la lista di linee LineaList a partire dalle shape di paperFormList
void creaLista() {
  
  for (int i=0; i<paperFormList.size(); i++) {
    // turn the PShape into contours
    PShape s = paperFormList.get(i).sh;
    ArrayList<ArrayList<PVector>> contours = extractContours(s);
    
    for (ArrayList<PVector> points : contours) {
       if (points.size() < 2) continue;
       
       PVector startS = points.get(0);
       PVector endS = null;
       
       for (int j = 1; j < points.size(); j++) {
         endS = points.get(j);
         lineaList.add(new Linea(startS, endS, paperFormList.get(i).ic, paperFormList.get(i).type));
         startS = endS;
       }
       // Chiudi dall'ultimo punto della shape al primo
       lineaList.add(new Linea(endS, points.get(0), paperFormList.get(i).ic, paperFormList.get(i).type));
    }
  }

  println("Before remove duplicate:"+lineaList.size());

  /*
  //////////rimuovi le linee duplicate
   
   for (int i=1; i<lineaList.size(); i++) {
   Linea curr=lineaList.get(i);
   if (curr.start.dist(curr.end) < 0.1) // Modificato dist(...) con PVector.dist()
   lineaList.remove(i--);
   }
   for (int i=0; i<lineaList.size(); i++) {
   Linea curr=lineaList.get(i);
   for (int j=i+1; j<lineaList.size(); j++) {
   Linea prev=lineaList.get(j);
   boolean confronto=((prev.start.x==curr.start.x) && (prev.start.y == curr.start.y) && (prev.end.x == curr.end.x) && (prev.end.y == curr.end.y) && (prev.ic==curr.ic) && (prev.type==curr.type));
   if (confronto) {
   lineaList.remove(j--);
   }
   }
   }
   println("After remove duplicate:"+lineaList.size());
   */
}
//////////////////////////////////////////////////////////////////////////////////////
/// Ordina la lista delle shape su carta per colore
void  orderList() {
  ArrayList<Linea> ordLineaList = new ArrayList<Linea>();
  Linea ordLinea=lineaList.get(0);
  lineaList.remove(0);
  ordLineaList.add(ordLinea);
  int iColor=ordLinea.ic;
  while (lineaList.size()>0) {
    //  boolean trovato=false;
    int indElem=0;
    //   while (!trovato && indElem < lineaList.size()) {
    while (indElem < lineaList.size()) {
      ordLinea = lineaList.get(indElem);
      if (iColor == ordLinea.ic) {
        lineaList.remove(indElem);
        ordLineaList.add(ordLinea);
      } else {
        indElem++;
      }
    }
    if ((indElem) >= lineaList.size()) {
      if (lineaList.size() >0) {
        ordLinea = lineaList.get(0);
        lineaList.remove(0);
        ordLineaList.add(ordLinea);
        iColor=ordLinea.ic;
      }
    }
  }
  //////////rimuovi le linee duplicate
  for (int i=1; i<ordLineaList.size(); i++) {
    Linea curr=ordLineaList.get(i);
    if (curr.start.dist(curr.end) < 0.1) // Modificato dist(...) con PVector.dist()
      ordLineaList.remove(i--);
  }

  for (int i=0; i<ordLineaList.size(); i++) {
    Linea curr = ordLineaList.get(i);
    color currColor = curr.ic;

    for (int j=i+1; j<ordLineaList.size(); j++) {
      Linea prev = ordLineaList.get(j);

      if (currColor != prev.ic) {
        j = ordLineaList.size();
        continue;
      }

      // Controllo linee duplicate esatte
      boolean confrontoEsatto = ((prev.start.x == curr.start.x) &&
        (prev.start.y == curr.start.y) &&
        (prev.end.x == curr.end.x) &&
        (prev.end.y == curr.end.y) &&
        (prev.ic == curr.ic) &&
        (prev.type == curr.type));

      // Controllo linee sovrapposte inverse
      boolean confrontoInverso = ((prev.start.x == curr.end.x) &&
        (prev.start.y == curr.end.y) &&
        (prev.end.x == curr.start.x) &&
        (prev.end.y == curr.start.y) &&
        (prev.ic == curr.ic) &&
        (prev.type == curr.type));

      if (confrontoEsatto || confrontoInverso) {
        ordLineaList.remove(j--);
      }
    }
  }

  println("After remove duplicate:" + ordLineaList.size());
  //copy the list
  lineaList.clear();
  lineaList.addAll(ordLineaList);

  //////// calcola la lunghezza totale della lista per confronto con le spezzate
  float lungLista2=0;
  for (int i=0; i<lineaList.size(); i++) {
    Linea t=lineaList.get(i);
    lungLista2=lungLista2+t.start.dist(t.end);
  }// Modificato dist(...) con PVector.dist()
  //  println("Lunghezza totale linee lista:"+lungLista);

  ////// spezza le linee in pezzi più piccoli se maggiori di maxDist
  ordLineaList.clear();
  for (int i=0; i<lineaList.size(); i++) {
    Linea t=lineaList.get(i);
    float lungLinea=t.start.dist(t.end); // Modificato dist(...) con PVector.dist()
    if (lungLinea > maxDist) { //verifica se la linea è maggiore della max linea da dipingere
      float numPezzi=int(lungLinea/maxDist); //numero di pezzi in cui spezzare
      float restoLinea=lungLinea; //resto della linea che rimane da spezzare
      PVector s=t.start;
      PVector e=t.end;
      
      for (int j=0; j<int(numPezzi)+1; j++) {
        // cLine = new RCommand(s.x, s.y, e.x, e.y);  //crea una linea con il pezzo rimanenente
        float rappLung=maxDist/restoLinea; // //prendi il punto sulla linea che corrisponde alla fine della maxDist
        PVector onLine;
        if (rappLung>1)
          onLine=e;
        else {
          onLine = PVector.lerp(s, e, rappLung);
        }
        ordLineaList.add(new Linea(s, onLine, t.ic, t.type)); //aggiungi una linea alla lista fino a distMax
        s=onLine; //nuovo inizio della linea
        restoLinea=restoLinea-maxDist;
      }
    } else {
      ordLineaList.add(t);
    }
  }
  //copy the list
  lineaList.clear();
  lineaList.addAll(ordLineaList);
  //////// calcola la lunghezza totale della lista per confronto con le spezzate
  float lungLista=0;
  for (int i=0; i<lineaList.size(); i++) {
    Linea t=lineaList.get(i);
    lungLista=lungLista+t.start.dist(t.end); // Modificato dist(...) con PVector.dist()
  }
  // println("Lunghezza totale linee lista after:"+lineaList.size());
  // println("Lunghezza totale linee lista after:"+lungLista);
}




//////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
void  orderBrigh() {
  // crea un vettore con la lista dei colori ordinati per brightness
  int totColori=palette.length;
  for (int i = 0; i < totColori; i++) {
    brighCol.add(new cBrigh(palette[i], i));
  }

  //for(int i = 0; i < totColori; i++)
  //  println(brighCol.get(i).indice+"  "+ hex(brighCol.get(i).colore));

  // ordina i colori sulla base della brightness (bubble sort)
  for (int i = 0; i < totColori; i++) {
    boolean flag = false;
    for (int j = 0; j < totColori-1; j++) {
      //Se l' elemento j è minore del successivo allora
      //scambiamo i valori
      float a=red(brighCol.get(j).colore)*red(brighCol.get(j).colore)+ green(brighCol.get(j).colore)*green(brighCol.get(j).colore)+blue(brighCol.get(j).colore)*blue(brighCol.get(j).colore);
      float b=red(brighCol.get(j+1).colore)*red(brighCol.get(j+1).colore)+ green(brighCol.get(j+1).colore)*green(brighCol.get(j+1).colore)+blue(brighCol.get(j+1).colore)*blue(brighCol.get(j+1).colore);
      //    if(brightness(brighCol.get(j).colore)< (brightness(brighCol.get(j+1).colore))) {
      if (a < b) {
        cBrigh k =  brighCol.get(j);
        brighCol.set(j, brighCol.get(j+1));
        brighCol.set(j+1, k);
        flag=true; //Lo setto a true per indicare che é avvenuto uno scambio
      }
    }
    if (!flag) break; //Se flag=false allora vuol dire che nell' ultima iterazione
    //non ci sono stati scambi, quindi il metodo può terminare
    //poiché l' array risulta ordinato
  }

  for (int i = 0; i < totColori; i++)
    print("Colore "+i+": "+ hex(brighCol.get(i).colore)+" - ");
  println("");

  //crea una lista e copia sopra lineaList
  ArrayList<Linea> lineaBrigh = new ArrayList<Linea>();
  lineaBrigh.clear();
  lineaBrigh.addAll(lineaList);
  //azzera lineaList
  lineaList.clear();
  for (int i=0; i<totColori; i++) {
    //fai un ciclo e riempi la lista con le righe di brightness ordinate
    for (int j=0; j<lineaBrigh.size(); j++) {
      Linea curr=lineaBrigh.get(j);
      if (curr.ic==brighCol.get(i).indice) {  //cerca la linea del colore corretto
        curr.ic=i;
        lineaList.add(curr);
        lineaBrigh.remove(j--);
      }
    }
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
/// Scrivi linee nel file
// scrivi in un file tutte le linee da dipingere
void scriviLineeFile() {
  for (int i=1; i<lineaList.size(); i++) {
    Linea curr=lineaList.get(i);
    String outLinee="Start:"+nf(curr.start.x, 0, 2)+" "+nf(curr.start.y, 0, 2)+"  End:"+nf(curr.end.x, 0, 2)+" "+nf(curr.end.y, 0, 2)+"  ic:"+curr.ic+"  type:"+curr.type+" lenght:"+nf(curr.start.dist(curr.end), 0, 2);
    linee.println(outLinee);
  }
}


float distV(PVector start, PVector end) {
  return sqrt((end.x-start.x)*(end.x-start.x)+(end.y-start.y)*(end.y-start.y));
}
