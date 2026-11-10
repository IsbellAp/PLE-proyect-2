module Check

import Message;

extend analysis::typepal::TypePal;

import Syntax;
import Parser;
import ParseTree;

// ===== Tipos que entiende el chequeador =====
data AType
  = objectType(str nombre)
  | anyType()
  | intType()
  | boolType()
  | strType()
  | charType()
  ;

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

// ===== Nombres especiales del programa (se llenan antes de chequear) =====
set[str] genericos = {};        // A, B, ... de los object[+A]
set[str] camposYParams = {};    // campos (val item: T) y parametros de metodos

// ===== Convertir una anotacion de Tipo a AType =====
AType aTipo((Tipo) `Integer`)   = intType();
AType aTipo((Tipo) `Boolean`)   = boolType();
AType aTipo((Tipo) `String`)    = strType();
AType aTipo((Tipo) `Char`)      = charType();
AType aTipo((Tipo) `<Id name>`) = objectType("<name>");
default AType aTipo(Tipo _) = anyType();

// ===== Tipo de un valor (casos simples: literales) =====
AType tipoDeExpresion(Expresion e) {
  if (/LiteralBooleano _ := e) return boolType();
  if (/LiteralString  _ := e) return strType();
  if (/LiteralChar    _ := e) return charType();
  if (/Entero         _ := e) return intType();
  return anyType();
}

// ===== OBJETOS =====
void collect(current: (DefinicionObjeto) `object <Id name> <DefinicionGenerico? gs> <ConstructorParametros? cps> <Herencia? hs>`, Collector c) {
  c.define("<name>", objectId(), name, defType(objectType("<name>")));
  collect(gs, cps, hs, c);
}
void collect(current: (Herencia) `extends <Tipo t>`, Collector c) {
  collect(t, c);
}
// USE: un tipo con nombre se busca como objeto... salvo que sea un generico (A, B)
void collect(current: (Tipo) `<Id name>`, Collector c) {
  if ("<name>" notin genericos)
    c.use(name, {objectId()});
}

// ===== VARIABLES =====
void collect(current: (DeclaracionVariable) `<Modificador m> <Id name> : <Tipo t> = <Expresion e>`, Collector c) {
  c.define("<name>", variableId(), name, defType(aTipo(t)));
  collect(t, e, c);
  AType declarado = aTipo(t);
  AType valor = tipoDeExpresion(e);
  c.require("tipo de <name>", current, [],
    void (Solver s) {
      if (declarado != anyType() && valor != anyType() && declarado != valor)
        s.report(error(current, "El valor es <pretty(valor)> pero se declaro como <pretty(declarado)>"));
    });
}
void collect(current: (DeclaracionVariable) `<Modificador m> <Id name> = <Expresion e>`, Collector c) {
  c.define("<name>", variableId(), name, defType(anyType()));
  collect(e, c);
}
// USO de variable... salvo que sea un campo o parametro (esos viven en los metodos)
void collect(current: (ElementoBase) `<Id name>`, Collector c) {
  if ("<name>" notin camposYParams)
    c.use(name, {variableId()});
}

// ===== Punto de entrada =====
TModel revisarArchivo(loc archivo) {
  start[Programa] pt = parsePrograma(archivo);
  genericos = {};
  camposYParams = {};
  visit (pt) {
    case (ParametroGenerico)`<Varianza? _> <Id id>`: genericos += {"<id>"};
    case (ParametroConstructor)`val <Id id> : <Tipo _>`: camposYParams += {"<id>"};
    case (Parametro)`<Id id> : <Tipo _>`: camposYParams += {"<id>"};
  }
  return collectAndSolve(pt);
}

// Imprime solo los errores de un archivo (limpio, sin el TModel gigante)
void errores(loc archivo) {
  TModel m = revisarArchivo(archivo);
  list[Message] errs = [ msg | msg <- m.messages, msg is error ];
  if (errs == [])
    println("<archivo.file>: sin errores :) yey");
  else {
    println("<archivo.file>: <size(errs)> error(es):");
    for (e <- errs) println("  - <e.msg>");
  }
}