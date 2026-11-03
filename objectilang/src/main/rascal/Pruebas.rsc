module Pruebas

import IO;
import List;
import String;
import ParseTree;
import Parser;
import Implode;

loc carpetaPruebas = |project://objectilang/instance|;

// Devuelve "OK", "AMBIGUO ..." o "ERROR DE SINTAXIS ..." para un archivo.
str resultadoDe(loc archivo) {
  try {
    implodePrograma(parsePrograma(archivo).top);
    return "OK";
  } catch Ambiguity(l, _, _): {
    return "AMBIGUO en <l>";
  } catch ParseError(l): {
    return "ERROR DE SINTAXIS en linea <l.begin.line>, columna <l.begin.column>";
  }
}

int main() {
  list[str] archivos = sort([ f | f <- listEntries(carpetaPruebas), endsWith(f, ".ol") ]);
  int fallidas = 0;
  for (f <- archivos) {
    str res = resultadoDe(carpetaPruebas + f);
    bool debeFallar = startsWith(f, "falla_");
    bool pasa = debeFallar ? startsWith(res, "ERROR DE SINTAXIS") : res == "OK";
    if (!pasa) fallidas += 1;
    str esperado = debeFallar ? "debe fallar" : "debe parsear";
    println("<pasa ? "PASA " : "FALLA"> <f> (<esperado>): <res>");
  }
  println("<size(archivos) - fallidas> de <size(archivos)> pruebas pasan");
  return fallidas;
}
