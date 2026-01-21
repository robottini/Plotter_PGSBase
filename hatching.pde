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

void intersectionConcentric(PShape shape, int ic, float distContour) {
  PShape polygon = shape;
  if (polygon == null || (polygon.getChildCount() == 0 && polygon.getVertexCount() == 0)) {
    return;
  }
  if (distContour > 0) {
    try {
      PShape eroded = PGS_Morphology.buffer(polygon, -distContour);
      if (eroded != null) {
        polygon = eroded;
      } else {
        return;
      }
    } catch (Exception e) {
      return;
    }
  }
  if (polygon == null || (polygon.getChildCount() == 0 && polygon.getVertexCount() == 0)) {
    return;
  }
  float[] bounds = getPShapeBounds(polygon);
  int maxIter = 1;
  if (bounds != null) {
    float minDim = min(bounds[2] - bounds[0], bounds[3] - bounds[1]);
    if (minDim > 0 && stepSVG > 0) {
      maxIter = max(1, (int) (minDim / stepSVG) + 2);
    }
  }
  int iter = 0;
  while (polygon != null && iter < maxIter) {
    if (polygon.getChildCount() == 0 && polygon.getVertexCount() == 0) {
      break;
    }
    PShape outline = null;
    try {
      org.locationtech.jts.geom.Geometry geom = PGS_Conversion.fromPShape(polygon);
      if (geom != null) {
        org.locationtech.jts.geom.Geometry boundary = geom.getBoundary();
        outline = PGS_Conversion.toPShape(boundary);
      }
    } catch (Exception e) {
      outline = null;
    }
    if (outline == null) {
      outline = normalizeOutlineShape(polygon);
    }
    if (outline != null) {
      addPShapeToFormaList(outline, ic);
    }
    PShape nextPolygon;
    try {
      nextPolygon = PGS_Morphology.buffer(polygon, -stepSVG);
    } catch (Exception e) {
      break;
    }
    if (nextPolygon == null) {
      break;
    }
    polygon = nextPolygon;
    iter++;
  }
}

void intersectionConcentricGeom(org.locationtech.jts.geom.Geometry geom, int ic, float distContour) {
  if (geom == null || hasNaN(geom)) return;
  try {
    geom = geom.buffer(0);
  } catch (Exception e) {
    return;
  }
  if (geom == null || geom.isEmpty()) return;
  if (distContour > 0) {
    try {
      geom = geom.buffer(-distContour);
    } catch (Exception e) {
      return;
    }
  }
  if (geom == null || geom.isEmpty()) return;
  org.locationtech.jts.geom.Envelope env = geom.getEnvelopeInternal();
  float minDim = min((float) env.getWidth(), (float) env.getHeight());
  int maxIter = 1;
  if (minDim > 0 && stepSVG > 0) {
    maxIter = max(1, (int) (minDim / stepSVG) + 2);
  }
  int iter = 0;
  while (geom != null && !geom.isEmpty() && iter < maxIter) {
    org.locationtech.jts.geom.Geometry boundary;
    try {
      boundary = geom.getBoundary();
    } catch (Exception e) {
      break;
    }
    if (boundary != null && !boundary.isEmpty()) {
      PShape outline = null;
      try {
        outline = PGS_Conversion.toPShape(boundary);
      } catch (Exception e) {
        outline = null;
      }
      if (outline != null) {
        addPShapeToFormaList(outline, ic);
      }
    }
    try {
      geom = geom.buffer(-stepSVG);
    } catch (Exception e) {
      break;
    }
    iter++;
  }
}

PShape normalizeOutlineShape(PShape shape) {
  if (shape == null) return null;
  if (shape.getChildCount() > 0) {
    PShape group = createShape(GROUP);
    for (int i = 0; i < shape.getChildCount(); i++) {
      PShape child = normalizeOutlineShape(shape.getChild(i));
      if (child != null) {
        group.addChild(child);
      }
    }
    return group;
  }
  if (shape.getVertexCount() == 0) return null;
  int kind = shape.getKind();
  int startIndex = 0;
  if (kind == TRIANGLE_FAN && shape.getVertexCount() > 2) {
    startIndex = 1;
  }
  PShape out = createShape();
  out.beginShape();
  for (int i = startIndex; i < shape.getVertexCount(); i++) {
    PVector v = shape.getVertex(i);
    out.vertex(v.x, v.y);
  }
  out.endShape(CLOSE);
  return out;
}

org.locationtech.jts.geom.Geometry subtractInnerShapes(PShape outer, RShape outerR, ArrayList<RShape> shapes, int outerIndex) {
  if (outer == null) return null;
  
  float[] outerBounds = getRShapeBounds(outerR);
  if (outerBounds == null) return null;

  org.locationtech.jts.geom.Geometry outerGeom = null;
  org.locationtech.jts.geom.Geometry holesUnion = null;
  double outerArea = 0;

  for (int i = 0; i < shapes.size(); i++) {
    if (i == outerIndex) continue;
    
    RShape innerR = shapes.get(i);
    float[] innerBounds = getRShapeBounds(innerR);
    if (innerBounds == null) continue;
    
    // Fast bounding box check
    if (innerBounds[2] < outerBounds[0] || innerBounds[0] > outerBounds[2] || 
        innerBounds[3] < outerBounds[1] || innerBounds[1] > outerBounds[3]) {
      continue;
    }
    
    // Initialize outerGeom if not done yet
    if (outerGeom == null) {
      try {
        outerGeom = PGS_Conversion.fromPShape(sanitizePShapeVertices(outer));
        if (outerGeom != null) {
           sanitizeJTS(outerGeom);
           // ALWAYS fix topology with buffer(0)
           try { 
             outerGeom = outerGeom.buffer(0); 
           } catch(Exception e) {}
           if (!outerGeom.isValid()) {
             // Try harder to fix
             try { outerGeom = outerGeom.buffer(0.01).buffer(-0.01); } catch(Exception e) {}
           }
           outerArea = outerGeom.getArea();
        }
      } catch (Exception e) {
        return null;
      }
      if (outerGeom == null || outerGeom.isEmpty()) {
        return null;
      }
    }

    PShape innerShape = sanitizePShapeVertices(RShapeToPShape(innerR));
    org.locationtech.jts.geom.Geometry innerGeom;
    try {
      innerGeom = PGS_Conversion.fromPShape(innerShape);
    } catch (Exception e) {
      continue;
    }
    if (innerGeom == null) continue;
    sanitizeJTS(innerGeom);
    
    // ALWAYS fix topology with buffer(0) for inner as well
    try {
      innerGeom = innerGeom.buffer(0);
    } catch (Exception e) {
      continue;
    }
    
    if (innerGeom.isEmpty()) continue;
    
    double innerArea = innerGeom.getArea();
    if (innerArea <= 0.1) continue;
    if (innerArea >= outerArea * 1.1) continue; // Inner should be smaller or roughly equal
    
    boolean isInside = false;
    
    // Check intersection/containment
    try {
      if (outerGeom.intersects(innerGeom)) {
        org.locationtech.jts.geom.Geometry inter = outerGeom.intersection(innerGeom);
        double interArea = inter.getArea();
        double ratio = interArea / innerArea;
        
        if (ratio > 0.4) {
           isInside = true;
        }
      }
    } catch (Exception e) {
      isInside = false;
    }

    if (isInside) {
      if (holesUnion == null) {
        holesUnion = innerGeom;
      } else {
        try {
          holesUnion = holesUnion.union(innerGeom);
        } catch (Exception e) {
          continue;
        }
      }
    }
  }
  
  if (holesUnion == null) return outerGeom;
  
  org.locationtech.jts.geom.Geometry clipped;
  try {
    holesUnion = holesUnion.buffer(0);
    clipped = outerGeom.difference(holesUnion);
  } catch (Exception e) {
    return outerGeom;
  }
  return clipped;
}

void sanitizeJTS(org.locationtech.jts.geom.Geometry geom) {
  if (geom == null) return;
  org.locationtech.jts.geom.Coordinate[] coords = geom.getCoordinates();
  for (int i = 0; i < coords.length; i++) {
    coords[i].z = 0; // Force Z to 0 to avoid 2D/3D mismatch issues
  }
  geom.geometryChanged();
}

float[] getRShapeBounds(RShape r) {
  if (r == null) return null;
  float minX = Float.MAX_VALUE, minY = Float.MAX_VALUE;
  float maxX = -Float.MAX_VALUE, maxY = -Float.MAX_VALUE;
  RPoint[][] points = r.getPointsInPaths();
  if (points == null) return null;
  boolean found = false;
  for (RPoint[] path : points) {
    if (path == null) continue;
    for (RPoint p : path) {
       if (Float.isNaN(p.x) || Float.isNaN(p.y)) continue;
       if (p.x < minX) minX = p.x;
       if (p.y < minY) minY = p.y;
       if (p.x > maxX) maxX = p.x;
       if (p.y > maxY) maxY = p.y;
       found = true;
    }
  }
  if (!found) return null;
  return new float[]{minX, minY, maxX, maxY};
}

boolean hasNaN(org.locationtech.jts.geom.Geometry geom) {
  if (geom == null) return true;
  org.locationtech.jts.geom.Coordinate[] coords = geom.getCoordinates();
  for (int i = 0; i < coords.length; i++) {
    org.locationtech.jts.geom.Coordinate c = coords[i];
    if (Float.isNaN((float) c.x) || Float.isNaN((float) c.y)) {
      return true;
    }
  }
  return false;
}

PShape sanitizePShapeVertices(PShape shape) {
  if (shape == null) return null;
  if (shape.getChildCount() > 0) {
    PShape group = createShape(GROUP);
    for (int i = 0; i < shape.getChildCount(); i++) {
      PShape child = sanitizePShapeVertices(shape.getChild(i));
      if (child != null && child.getVertexCount() > 0) {
        group.addChild(child);
      }
    }
    return group;
  }
  PShape out = createShape();
  int kind = shape.getKind();
  if (kind != 0) {
    out.beginShape(kind);
  } else {
    out.beginShape();
  }
  
  ArrayList<PVector> cleanVerts = new ArrayList<PVector>();
  for (int i = 0; i < shape.getVertexCount(); i++) {
    PVector v = shape.getVertex(i);
    if (v == null) continue;
    if (Float.isNaN(v.x) || Float.isNaN(v.y)) continue;
    cleanVerts.add(v);
  }
  
  for (PVector v : cleanVerts) {
    out.vertex(v.x, v.y);
  }
  
  boolean shouldClose = false;
  if (cleanVerts.size() > 2) {
    PVector start = cleanVerts.get(0);
    PVector end = cleanVerts.get(cleanVerts.size()-1);
    // Use same tolerance as RShapeToPShape
    if (start.dist(end) < 2.0) {
      shouldClose = true;
    }
  }

  if (shouldClose) {
    out.endShape(CLOSE);
  } else {
    out.endShape();
  }
  return out;
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
        if (Float.isNaN(pt.x) || Float.isNaN(pt.y)) continue;
        child.vertex(pt.x, pt.y);
      }
      
      // Check closure
      RPoint start = path[0];
      RPoint end = path[path.length-1];
      // Aumentata tolleranza per chiusura shape da 0.01 a 2.0
      if (dist(start.x, start.y, end.x, end.y) < 2.0) {
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
