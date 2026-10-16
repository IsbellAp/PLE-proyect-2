module Implode

import ParseTree;
import IO;
import Parser;
import AST;

Programa implodePrograma(Tree arbol) = implode(#Programa, arbol);

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
  for (archivo <- ["prueba1", "prueba2", "prueba3", "prueba4", "prueba5"]) {
    mostrar(|project://objectilang/instance/<archivo>.olang|);
}
  prueba(|project://objectilang/instance/prueba1.olang|);
  prueba(|project://objectilang/instance/prueba2.olang|);
  prueba(|project://objectilang/instance/prueba3.olang|);
  prueba(|project://objectilang/instance/prueba4.olang|);
  prueba(|project://objectilang/instance/prueba5.olang|);
  return 0;
}
