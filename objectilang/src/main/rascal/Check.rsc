module Check

import Message;

extend analysis::typepal::TypePal;

import Syntax;
import Parser;
import ParseTree;

// Idioma de tiposss
//Es la lista de todos los tipos que el lenguaje entiende, pero, en el idioma de TypePal.
//Es como un "diccionario de tipos" para el TypePal
data AType
  = objectType(str nombre)
  | anyType()
  | intType()
  | boolType()
  | strType()
  | charType()
  ;


//Traduce para los mensajes de error. Sin esto,
//los mensajes de error pueden decir tipo:
//el valor es intType(), cuando queriamos decir "Integer"
str pretty(intType())  = "Integer";
str pretty(boolType()) = "Boolean";
str pretty(strType())  = "String";
str pretty(charType()) = "Char";
str pretty(objectType(str n)) = n;
default str pretty(AType _) = "?";

// Cada nombre que registramos es un objeto o una variable
//Esto nos sirve para cuando buscamos un nombre, comomo un objeto llamado tal
//Evita confundir con variables
data IdRole
  = objectId()
  | variableId()
  ;

// Nombres especiales
//Estos sirven para guardar los nombres genericos y de los campos/parametros
//No son ni objetos ni variables normales, pero aparecene n el codigo.
//La idea es que este apoye el punto 6, para que no de falsos errores en los archivos genericos. 

set[str] genericos = {};        // A, B, ... de los object[+A]
set[str] camposYParams = {};    // campos (val item: T) y parametros de metodos

// Convertimos una anotacion a tipo
//Convierte un escrito en el programa en un Atype, sirve para poder compararlo
//Esto nos ayuda a cumplir parte del punto 5
AType aTipo((Tipo) `Integer`)   = intType();
AType aTipo((Tipo) `Boolean`)   = boolType();
AType aTipo((Tipo) `String`)    = strType();
AType aTipo((Tipo) `Char`)      = charType();
AType aTipo((Tipo) `<Id name>`) = objectType("<name>");
AType aTipo((Tipo) `<Id name>[<{Tipo ","}+ _>]`) = objectType("<name>");
default AType aTipo(Tipo _) = anyType();

// Calcular el tipo de un valor
//Mira un valor que va despues del = y dice que tipo es
//Esto cumple la otra parte del punto 5, y es saber el tipo real del valor.

AType tipoDeExpresion(Expresion e) {
  AType res = anyType();
  top-down-break visit (e) {
    case (NuevaInstancia)`new <Tipo t> <Argumentos? _> <CuerpoInstancia? _>`: res = aTipo(t);
    case LiteralBooleano _: res = boolType();
    case LiteralString  _: res = strType();
    case LiteralChar    _: res = charType();
    case Entero         _: res = intType();
  }
  return res;
}

// Es para que "anotemos" que existe un objeto llamado tal
//Esto es como la base del punto 6, para verificar que algo exista primero hay que registrar que sí existe (el define)
void collect(current: (DefinicionObjeto) `object <Id name> <DefinicionGenerico? gs> <ConstructorParametros? cps> <Herencia? hs>`, Collector c) {
  c.define("<name>", objectId(), name, defType(objectType("<name>")));
  collect(gs, cps, hs, c);
}
void collect(current: (Herencia) `extends <Tipo t>`, Collector c) {
  collect(t, c);
}
// Buscamos que eso exista, si no existe, error. Esto es lo del punto 6
void collect(current: (Tipo) `<Id name>`, Collector c) {
  if ("<name>" notin genericos)
    c.use(name, {objectId()});
}

// Variables
//Registra la variable, y compara el tipo kdeclarado con el tipo del valor. SI no existe, error.
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

//Punto de entrada
//La funcion que arranca todo
//Parsea el archivo, recolecta los nombres, y finalmente puede ejecutar para producir resultado
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

// Imprime solo los errores de un archivo
//Así podemos ver si el checker funciona jiji. 
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