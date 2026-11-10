module Check

extend analysis::typepal::TypePal;

import Syntax;
import Parser;

// ===== Tipos que entiende el chequeador =====
data AType
  = objectType(str nombre)
  | anyType()
  | intType()
  | boolType()
  | strType()
  | charType()
  ;

// nombre bonito para los mensajes de error
str pretty(intType())  = "Integer";
str pretty(boolType()) = "Boolean";
str pretty(strType())  = "String";
str pretty(charType()) = "Char";
str pretty(objectType(str n)) = n;
default str pretty(AType _) = "?";

// ===== Roles =====
data IdRole
  = objectId()
  | variableId()
  ;

// ===== Convertir una anotacion de Tipo a AType =====
AType aTipo((Tipo) `Integer`)   = intType();
AType aTipo((Tipo) `Boolean`)   = boolType();
AType aTipo((Tipo) `String`)    = strType();
AType aTipo((Tipo) `Char`)      = charType();
AType aTipo((Tipo) `<Id name>`) = objectType("<name>");
default AType aTipo(Tipo _) = anyType();

// ===== Calcular el tipo de un valor (casos simples: literales) =====
AType tipoDeExpresion(Expresion e) {
  if (/LiteralBooleano _ := e) return boolType();
  if (/LiteralString  _ := e) return strType();
  if (/LiteralChar    _ := e) return charType();
  if (/Entero         _ := e) return intType();
  return anyType();   // objetos, variables, etc.: no los revisamos aun
}

// ===== OBJETOS =====
void collect(current: (DefinicionObjeto) `object <Id name> <DefinicionGenerico? gs> <ConstructorParametros? cps> <Herencia? hs>`, Collector c) {
  c.define("<name>", objectId(), name, defType(objectType("<name>")));
  collect(gs, cps, hs, c);
}
void collect(current: (Herencia) `extends <Tipo t>`, Collector c) {
  collect(t, c);
}
void collect(current: (Tipo) `<Id name>`, Collector c) {
  c.use(name, {objectId()});
}

// ===== VARIABLES =====
// CON anotacion: define Y chequea que el valor coincida con el tipo (tarea 5)
void collect(current: (DeclaracionVariable) `<Modificador m> <Id name> : <Tipo t> = <Expresion e>`, Collector c) {
  c.define("<name>", variableId(), name, defType(aTipo(t)));
  collect(e, c);
  AType declarado = aTipo(t);
  AType valor = tipoDeExpresion(e);
  c.require("tipo de <name>", current, [],
    void (Solver s) {
      if (declarado != anyType() && valor != anyType() && declarado != valor)
        s.report(error(current, "El valor es <pretty(valor)> pero se declaro como <pretty(declarado)>"));
    });
}
// SIN anotacion: solo define
void collect(current: (DeclaracionVariable) `<Modificador m> <Id name> = <Expresion e>`, Collector c) {
  c.define("<name>", variableId(), name, defType(anyType()));
  collect(e, c);
}
// USO de una variable suelta
void collect(current: (ElementoBase) `<Id name>`, Collector c) {
  c.use(name, {variableId()});
}

// ===== Punto de entrada =====
TModel revisarArchivo(loc archivo) = collectAndSolve(parsePrograma(archivo));


// Evita los avisos "Missing collect" de nodos que no revisamos
default void collect(Tree t, Collector c) { collectParts(t, c); }