/**
 * Funzione per creare un effetto di hatching (tratteggio) su una forma
 * Utilizza la libreria PGS per le elaborazioni geometriche.
 * 
 * @param shape - La forma PShape da riempire con l'hatching
 * @param ic - Indice del colore da utilizzare per le linee di hatching
 * @param distContour - Distanza delle linee di hatching dal bordo della forma
 */
void intersection(PShape shape, int ic, float distContour) {
  // println("DEBUG: intersection called");
  // 1. La forma è già PShape, la usiamo direttamente come poligono base
  PShape polygon = shape;
  
  // Verifica se il poligono è valido
  if (polygon == null || (polygon.getChildCount() == 0 && polygon.getVertexCount() == 0)) {
    // println("DEBUG Hatching: Input polygon invalid/empty");
    return;
  }
  
  // DEBUG: Verifica cosa arriva
   // println("DEBUG Hatching: Processing shape with " + polygon.getChildCount() + " children and " + polygon.getVertexCount() + " vertices. DistContour: " + distContour);
   
   // 2. Erosione (distContour) tramite PGS
  if (distContour > 0) {
    try {
       // PGS_Morphology.buffer con valore negativo esegue l'erosione
       PShape eroded = PGS_Morphology.buffer(polygon, -distContour);
       if (eroded != null) {
         polygon = eroded;
       } else {
         println("DEBUG Hatching: Erosion returned null for dist=" + distContour);
       }
    } catch (Exception e) {
       println("Errore durante l'erosione (buffer negativo) PGS: " + e.getMessage());
       return; 
    }
  }
  
  // Verifica se il poligono esiste ancora
  if (polygon == null || (polygon.getChildCount() == 0 && polygon.getVertexCount() == 0)) {
    println("DEBUG Hatching: Polygon empty after erosion");
    return;
  }

  // 3. Calcolo Bounding Box e Angolo tramite PGS
  // Utilizziamo PGS_Hull.boundingBox() come richiesto
  PShape envelope = PGS_Hull.boundingBox(polygon);
  if (envelope == null) {
    println("DEBUG Hatching: Envelope is null");
    return;
  }
  
  float[] bounds = {Float.MAX_VALUE, Float.MAX_VALUE, -Float.MAX_VALUE, -Float.MAX_VALUE};
  updateBoundsRecursively(envelope, bounds);
  
  float minX = bounds[0];
  float minY = bounds[1];
  float maxX = bounds[2];
  float maxY = bounds[3];
  
  if (minX == Float.MAX_VALUE) {
     println("DEBUG Hatching: Could not determine bounds from envelope (no vertices found).");
     return;
  }
  
  float dx = maxX - minX;
  float dy = maxY - minY;
  
  float angleRadians = atan2(dy, dx);
  // Manteniamo la logica originale per l'angolo: gradi + 0/90/180...
  float angle = degrees(angleRadians) + 90 * random(0, 2);
  
  float diag = sqrt(pow(dx, 2) + pow(dy, 2));
  int num = 2 + int(diag / stepSVG);
  
  // DEBUG
  // println("DEBUG Hatching: BBox [" + minX + ", " + minY + ", " + maxX + ", " + maxY + "] dx=" + dx + " dy=" + dy + " diag=" + diag + " stepSVG=" + stepSVG + " numLines=" + num);
  
  float hatchLength = diag * 2.0; 
  
  float cx = (minX + maxX) / 2;
  float cy = (minY + maxY) / 2;
  
  // 4. Creazione fascio di linee (Line Field) come PShape
  PShape linesShape = createShape(GROUP);
  float angRad = radians(angle);
  
  for (int i = -num/2 - 2; i < num/2 + 2; i++) { 
     float yOff = i * stepSVG;
     
     // Creazione linea orizzontale centrata
     PVector v1 = new PVector(-hatchLength/2, yOff);
     PVector v2 = new PVector(hatchLength/2, yOff);
     
     // Rotazione
     v1.rotate(angRad);
     v2.rotate(angRad);
     
     // Traslazione
     v1.add(cx, cy, 0);
     v2.add(cx, cy, 0);
     
     PShape l = createShape();
     l.beginShape(LINES);
     l.vertex(v1.x, v1.y);
     l.vertex(v2.x, v2.y);
     l.endShape();
     linesShape.addChild(l);
  }
  
  // 5. Intersezione (Clipping)
  PShape hatched = PGS_ShapeBoolean.intersect(polygon, linesShape);
  
  // DEBUG
  if (hatched != null) {
    // println("DEBUG Hatching: Generated " + hatched.getChildCount() + " lines/shapes (Vertex count: " + hatched.getVertexCount() + ")");
  } else {
    // println("DEBUG Hatching: Result is null");
  }

  // 6. Conversione risultato (PShape) -> RShape e aggiunta a formaList
  if (hatched != null) {
      addPShapeToFormaList(hatched, ic);
  }
}

// Helper ricorsivo per aggiungere PShape a formaList
void addPShapeToFormaList(PShape ps, int ic) {
  // Se è un gruppo, itera sui figli
  if (ps.getChildCount() > 0) {
    for (int i = 0; i < ps.getChildCount(); i++) {
      addPShapeToFormaList(ps.getChild(i), ic);
    }
  } else {
    // Se è una forma geometrica con vertici
    if (ps.getVertexCount() > 0) {
       // Aggiungiamo direttamente la PShape alla lista
       // Nota: PGS restituisce forme chiuse o linee. 
       // Se vogliamo mantenere la struttura "spezzata" in linee come prima, dovremmo creare singole linee,
       // ma ora Forma accetta PShape generiche, quindi possiamo aggiungere la forma intera.
       // Tuttavia, per coerenza con la logica precedente (type=1 per fill), passiamo type=1.
       // Cloniamo la shape per sicurezza se fa parte di un gruppo
       formaList.add(new Forma(ps, ic, 1));
    }
  }
}

/////////////////////////////////////////////////////////
// clasee di shape usata sia per lo schermo che per la lista su carta
class Forma {
  PShape sh;  //shape (Sostituito RShape con PShape)
  int   ic;   //indexColor
  int   type;  //type 0=contour, type 1=fill

  Forma(PShape sh, int ic, int type) {
    this.sh=sh;
    this.ic=ic;
    this.type=type;
  }
}

// Helper per convertire RShape in PShape (appiattendo le curve)
PShape RShapeToPShape(RShape r) {
  PShape p = createShape(GROUP);
  RPoint[][] points = r.getPointsInPaths(); // Questo discretizza le curve
  
  if (points != null) {
    for (RPoint[] path : points) {
      if (path == null || path.length < 2) continue;
      PShape child = createShape();
      child.beginShape();
      for (RPoint pt : path) {
        child.vertex(pt.x, pt.y);
      }
      
      // Check closure
      RPoint start = path[0];
      RPoint end = path[path.length-1];
      if (dist(start.x, start.y, end.x, end.y) < 0.01) {
         child.endShape(CLOSE);
      } else {
         child.endShape();
      }
      p.addChild(child);
    }
  }
  return p;
}

////////////////////////////////////////////////////////////////
// classe con due punti che formano la linea che sarà poi dipinta
class Linea {
  PVector start;  //line start point
  PVector end;    //line end point
  int   ic;   //indexColor
  int   type;  //type 0=contour, type 1=fill

  Linea(PVector start, PVector end, int ic, int type) {
    this.start=start;
    this.end=end;
    this.ic=ic;
    this.type=type;
  }
}



////////////////////////////////////////////////////////////////
// classe per ordinare i colori in base alla brightness
class cBrigh {
  color colore;  //line start point
  int   indice;    //line end point

  cBrigh(color colore, int indice) {
    this.colore=colore;
    this.indice=indice;
  }
}

// Helper per aggiornare i bounds ricorsivamente
void updateBoundsRecursively(PShape ps, float[] bounds) {
  for (int i = 0; i < ps.getVertexCount(); i++) {
    PVector v = ps.getVertex(i);
    if (v.x < bounds[0]) bounds[0] = v.x;
    if (v.y < bounds[1]) bounds[1] = v.y;
    if (v.x > bounds[2]) bounds[2] = v.x;
    if (v.y > bounds[3]) bounds[3] = v.y;
  }
  for (int i = 0; i < ps.getChildCount(); i++) {
    updateBoundsRecursively(ps.getChild(i), bounds);
  }
}
