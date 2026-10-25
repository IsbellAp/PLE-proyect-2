module Implode

import ParseTree;
import IO;
import Parser;
import AST;
import Exception;
import Cadenas;
import String;


Programa implodePrograma(Tree arbol) = convertir(implode(#Programa, arbol));

// Recorre el AST: convierte los strings en partes y quita comillas y escapes de los Char.
&T convertir(&T ast) = visit(ast) {
  case litString(str crudo) => litString([ aParte(p) | p <- partesDe(crudo) ])
  case litChar(str crudo)   => litChar(desescapar(substring(crudo, 1, size(crudo) - 1)))
};

ParteString aParte(<"texto", str c, _>)     = texto(c);
ParteString aParte(<"variable", str c, _>)  = interpVariable(c);
ParteString aParte(<"expresion", _, Tree e>) = interpExpresion(convertir(implode(#Expresion, e)));

// Parsea e implota un archivo; informa si pasa o en que linea falla.
void prueba(loc archivo) {
  try {
    t = parsePrograma(archivo);
    ast = implodePrograma(t.top);
    println("OK    <archivo.file>");
  } catch Ambiguity(l, _, _): {
    println("AMBIGUO <archivo.file> en <l>");
  } catch ParseError(l): {
    println("ERROR DE SINTAXIS <archivo.file> en linea <l.begin.line>, columna <l.begin.column>");
  }
}

// Imprime el AST de un archivo (para inspeccionarlo a mano).
void mostrar(loc archivo) {
  println(implodePrograma(parsePrograma(archivo).top));
}

int main() {
  for (archivo <- ["prueba1", "prueba2", "prueba3", "prueba4", "prueba5", "prueba6"]) {
    mostrar(|project://objectilang/instance/<archivo>.ol|);
}
  prueba(|project://objectilang/instance/prueba1.ol|);
  prueba(|project://objectilang/instance/prueba2.ol|);
  prueba(|project://objectilang/instance/prueba3.ol|);
  prueba(|project://objectilang/instance/prueba4.ol|);
  prueba(|project://objectilang/instance/prueba5.ol|);
  prueba(|project://objectilang/instance/prueba6.ol|);
  return 0;
}
