module Check

extend analysis::typepal::TypePal;

import Syntax;
import Parser;

// Tipo minimo: solo para marcar objetos
data AType = objectType(str nombre);

// Rol
data IdRole = objectId();

// DEFINE: cada "object X ..." registra el nombre X
void collect(current: (DefinicionObjeto) `object <Id name> <DefinicionGenerico? gs> <ConstructorParametros? cps> <Herencia? hs>`, Collector c) {
  c.define("<name>", objectId(), name, defType(objectType("<name>")));
  collect(gs, cps, hs, c);
}

// USE: en "extends T", el tipo T debe existir
void collect(current: (Herencia) `extends <Tipo t>`, Collector c) {
  collect(t, c);
}

// USE: un tipo con nombre (como Animal) se busca como objeto
void collect(current: (Tipo) `<Id name>`, Collector c) {
  c.use(name, {objectId()});
}

// Punto de entrada: ahora sí le pasamos el arbol concreto (NO el AST)
TModel revisarArchivo(loc archivo) = collectAndSolve(parsePrograma(archivo));