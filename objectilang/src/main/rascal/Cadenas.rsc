module Cadenas

import Syntax;
import ParseTree;
import String;

// Cada parte de un string: <clase, contenido, árbol>
//   <"texto", texto ya sin escapes, _>
//   <"variable", nombre de la variable, _>
//   <"expresion", "", árbol de la expresión dentro de ${ }>
alias Parte = tuple[str clase, str contenido, Tree arbol];

// Vuelve a leer un string crudo (con comillas) y devuelve sus partes en orden.
list[Parte] partesDe(str crudo) {
  Tree s = parse(#LiteralString, crudo);
  list[Parte] res = [];
  top-down-break visit (s) {
    case t:appl(prod(label("texto", _), _, _), _):
      res += [<"texto", desescapar("<t>"), t>];
    case t:appl(prod(label("interpVariable", _), _, _), args):
      res += [<"variable", "<args[1]>", t>];
    case t:appl(prod(label("interpExpresion", _), _, _), args):
      res += [<"expresion", "", args[2]>];
  }
  return res;
}

// Reemplaza las secuencias de escape: \" -> "   \$ -> $   \\ -> \   \' -> '   \n -> salto de línea
str desescapar(str s) {
  str res = "";
  int i = 0;
  while (i < size(s)) {
    if (s[i] == "\\" && i + 1 < size(s)) {
      str c = s[i + 1];
      res += (c == "n") ? "\n" : c;
      i += 2;
    } else {
      res += s[i];
      i += 1;
    }
  }
  return res;
}

