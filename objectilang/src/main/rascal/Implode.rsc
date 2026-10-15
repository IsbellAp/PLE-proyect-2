module Implode

import ParseTree;
import IO;
import Parser;
import AST;

Programa implodePrograma(Tree arbol) = implode(#Programa, arbol);

int main(list[str] args) {
  t = parsePrograma(|project://objectilang/instance/prueba1.olang|);
  println(implodePrograma(t.top));

  return 0;
}
