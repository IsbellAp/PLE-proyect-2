module Generador

// Generador de código Java a partir del AST de Objectilang (punto 2 del enunciado).
// Sigue la sección 6 del tutorial:
//   - el programa .ol se parsea y se implota (Listing 6, generator1),
//   - hay una función por cada constructor del AST (sobrecarga de funciones, sección 6.1),
//   - las tablas de objetos y campos se arman con comprensiones (sección 6.3),
//   - el código se arma con plantillas de strings, se imprime con println y se escribe con writeFile.
// Además, como pide el enunciado, el .java generado se ejecuta y su salida se muestra en la consola.
//
// Uso desde el terminal de Rascal:
//   import Generador;
//   ejecutar(|project://objectilang/instance/ejec01_aritmetica.ol|);   un programa
//   main();                                                           todos los ejemplos ejecutables

import IO;
import List;
import String;
import ParseTree;
import util::ShellExec;
import util::SystemAPI;
import Parser;
import Implode;
import AST;

// ===== Información global del programa (como allPersons y allPlans en el Listing 5) =====
set[str] objetos = {};   // nombres de los objetos definidos
set[str] campos = {};    // nombres de los campos (parámetros de constructor) de todos los objetos
int contador = 0;        // para nombres únicos de variables auxiliares en los for

loc carpetaSalida = |project://objectilang/instance/output|;

// ===== Punto de entrada (Listing 6) =====

// Parsea, implota y genera el Java. Imprime el código y lo escribe en instance/output.
// Devuelve la ubicación del archivo .java generado.
loc generator1(loc archivo) {
  cast = parsePrograma(archivo);
  ast = implodePrograma(cast.top);
  str clase = nombreClase(archivo);
  str rVal = generar(ast, clase, archivo.file);
  println(rVal);
  if (!exists(carpetaSalida)) mkDirectory(carpetaSalida);
  loc salida = carpetaSalida + "<clase>.java";
  writeFile(salida, rVal);
  return salida;
}

// Genera el Java, lo ejecuta con java y muestra la salida del programa en la consola.
str ejecutar(loc archivo) {
  loc salida = generator1(archivo);
  str resultado = correrJava(salida);
  println("===== Salida de <archivo.file> =====");
  println(resultado);
  return resultado;
}

void main() {
  for (n <- ["ejec01_aritmetica", "ejec02_condicional", "ejec03_metodos", "ejec04_herencia",
             "ejec05_campos", "ejec06_override", "ejec07_tuplas_for",
             "enunciado1", "enunciado2", "enunciado3", "enunciado4", "cadenas",
             "errorEjec_operador", "errorEjec_sinCuerpo", "errorEjec_variable"]) {
    ejecutar(|project://objectilang/instance/<n>.ol|);
  }
}

// Nombre de la clase Java: OL_ más el nombre del archivo, sin la extensión.
str nombreClase(loc archivo) = "OL_" + replaceAll(archivo[extension = ""].file, "-", "_");

// Ejecuta el archivo .java con el mismo Java que ejecuta Rascal (java Archivo.java compila y
// ejecuta en un solo paso). Si el código no compila, devuelve los errores del compilador.
str correrJava(loc archivoJava) {
  str java = getSystemProperty("java.home") + "/bin/java";
  pid = createProcess(java, args = [resolveLocation(archivoJava).path]);
  str salida = readEntireStream(pid);
  str errores = readEntireErrStream(pid);
  killProcess(pid);
  return (errores == "") ? salida : salida + "Error de compilacion del Java generado:\n" + errores;
}

// ===== Programa =====

str generar(programa(list[Definicion] defs, metodoMain(Bloque cuerpoMain)), str clase, str origen) {
  // Tablas con comprensiones (sección 6.3 del tutorial)
  objetos = { od.nombre | defObjeto(od) <- defs };
  campos = { c | defObjeto(od) <- defs, constructor(ps) <- od.constructor, parametro(c, _) <- ps };
  contador = 0;
  list[DefinicionObjetoMetodo] metodos = [ m | defMetodo(m) <- defs ];
  return
    "// Codigo Java generado por Generador.rsc a partir de <origen>
    'public class <clase> {
    '<for (defObjeto(od) <- defs) {>
    '  <generar(od, [ m | m <- metodos, m.objeto == od.nombre ])>
    '<}><for (m <- metodos, m.objeto notin objetos) {>
    '  // El metodo <m.objeto>.<m.nombre> no se genera: el objeto <m.objeto> no esta definido.
    '<}>
    '  public static void main(String[] args$) {
    '    try {
    '      <generarSentencias(cuerpoMain)>
    '    } catch (RuntimeException e$) {
    '      OL.reportar(e$);
    '    }
    '  }
    '
    '  <runtimeOL>
    '}
    '";
}

// ===== Objetos =====

// object Nombre[...](val c: T, ...) extends Padre  ==>  static class Nombre extends Padre { ... }
str generar(objeto(str n, _, list[ConstructorParametros] cs, list[Herencia] hs), list[DefinicionObjetoMetodo] ms) {
  list[ParametroConstructor] ps = [ p | constructor(lista) <- cs, p <- lista ];
  list[str] padres = [ nombreDe(t) | herencia(t) <- hs ];
  str ext = (padres != [] && padres[0] in objetos) ? " extends <padres[0]>" : "";
  return
    "static class <n><ext> {
    '  <for (parametro(c, t) <- ps) {>final <tipoJava(t)> <id(c)>;
    '  <}><if (ps != []) {><n>() { <for (parametro(c, _) <- ps) {>this.<id(c)> = null; <}>}
    '  <}><n>(<intercalate(", ", [ "Object <id(c)>$" | parametro(c, _) <- ps ])>) {
    '    <for (parametro(c, t) <- ps) {>this.<id(c)> = (<tipoJava(t)>) <id(c)>$;
    '    <}>
    '  }
    '  <for (m <- ms) {>
    '  <generar(m)>
    '  <}>
    '}";
}

// Objeto.metodo = method(p: T, ...): R { ... }  ==>  public R metodo(Object p$) { ... }
str generar(metodo(_, str n, Parametros ps, Tipo r, list[Bloque] cuerpo))
  = generarMetodo(n, ps, r, cuerpo);

// override metodo(p: T, ...): R = { ... }  (dentro de new)  ==>  el mismo método en una clase anónima
str generar(sobrescribir(str n, Parametros ps, Tipo r, Bloque cuerpo))
  = generarMetodo(n, ps, r, [cuerpo]);

str generarMetodo(str n, parametros(list[Parametro] ps), Tipo r, list[Bloque] cuerpo)
  = "public <tipoJava(r)> <id(n)>(<intercalate(", ", [ "Object <id(p)>$" | parametroMetodo(p, _) <- ps ])>) {
    '  <for (parametroMetodo(p, t) <- ps) {>final <tipoJava(t)> <id(p)> = (<tipoJava(t)>) <id(p)>$;
    '  <}><if ([Bloque b] := cuerpo) {><generarRetorno(b, tipoJava(r))><} else {>throw new RuntimeException(\"el metodo <n> no tiene cuerpo\");<}>
    '}";

// ===== Tipos =====
// Los tipos de Objectilang los verifica TypePal (Persona 2). En Java solo se conservan los objetos
// definidos, para poder llamar sus métodos; el resto se maneja como Object.
str tipoJava(tipoNombre(str n)) = (n in objetos) ? n : "Object";
str tipoJava(tipoGenerico(str n, _)) = (n in objetos) ? n : "Object";
default str tipoJava(Tipo _) = "Object";

str nombreDe(tipoNombre(str n)) = n;
str nombreDe(tipoGenerico(str n, _)) = n;
default str nombreDe(Tipo _) = "";

// ===== Bloques y sentencias =====

// Bloque como sentencias (cuerpo de main): cada sentencia en una línea.
str generarSentencias(bloque(list[Sentencia] ss))
  = intercalate("\n", [ generar(s) | s <- ss ]);

// Bloque que devuelve un valor (métodos y bloques como expresión): el valor es el de la última sentencia.
str generarRetorno(bloque([]), str _) = "return null;";
default str generarRetorno(bloque(list[Sentencia] ss), str tipo)
  = "<for (s <- prefix(ss)) {><generar(s)>
    '<}><retorno(last(ss), tipo)>";

str retorno(sentExpresion(Expresion e), "Object") = "return <generar(e)>;";
str retorno(sentExpresion(Expresion e), str tipo) = "return (<tipo>) (Object) <generar(e)>;";
str retorno(s:sentDeclaracion(_), str _) = "<generar(s)>
                                          'return null;";

// val x: T = e  ==>  final var x = e;
str generar(sentDeclaracion(declaracion(_, str n, _, Expresion v))) = "final var <id(n)> = <generar(v)>;";

// if y for usados como sentencia se generan como if y for de Java.
str generar(sentExpresion(ifSinElse(Expresion c, Expresion a)))
  = "if (OL.cond(<generar(c)>)) {
    '  <generar(sentExpresion(a))>
    '}";
str generar(sentExpresion(ifConElse(Expresion c, Expresion a, Expresion b)))
  = "if (OL.cond(<generar(c)>)) {
    '  <generar(sentExpresion(a))>
    '} else {
    '  <generar(sentExpresion(b))>
    '}";
str generar(sentExpresion(ciclo(VariableIteracion v, Expresion col, Expresion cuerpo))) {
  contador += 1;
  str e = "e<contador>$";
  return "for (Object <e> : OL.elementos(<generar(col)>)) {
         '  <generarVariable(v, e)>
         '  <generar(sentExpresion(cuerpo))>
         '}";
}
// En Java solo las llamadas pueden ir solas como sentencia; el resto se envuelve en OL.ignorar.
default str generar(sentExpresion(Expresion e)) = esLlamada(e) ? "<generar(e)>;" : "OL.ignorar(<generar(e)>);";

bool esLlamada(operacion(base(primario(llamada(_, _), [])))) = true;
bool esLlamada(operacion(base(primario(instancia(_), [])))) = true;
bool esLlamada(operacion(base(primario(_, [*_, llamadaMetodo(_, _)])))) = true;
default bool esLlamada(Expresion _) = false;

// Variable(s) de un for: x  o  (x, y, ...)
str generarVariable(varSimple(str n), str e) = "final var <id(n)> = <e>;";
str generarVariable(varTupla(str p, list[str] resto), str e) {
  list[str] vs = [p] + resto;
  return intercalate(" ", [ "final var <id(vs[i])> = OL.parte(<e>, <i>);" | i <- index(vs) ]);
}

// ===== Expresiones =====

str generar(ifSinElse(Expresion c, Expresion a)) = "(OL.cond(<generar(c)>) ? (Object) <generar(a)> : null)";
str generar(ifConElse(Expresion c, Expresion a, Expresion b))
  = "(OL.cond(<generar(c)>) ? (Object) <generar(a)> : (Object) <generar(b)>)";
// for usado como expresión (por ejemplo dentro de otro for): se recorre con una función.
str generar(ciclo(VariableIteracion v, Expresion col, Expresion cuerpo)) {
  contador += 1;
  str e = "e<contador>$";
  return "OL.paraCada(<generar(col)>, (Object <e>) -\> {
         '  <generarVariable(v, e)>
         '  <generar(sentExpresion(cuerpo))>
         '  return null;
         '})";
}
str generar(operacion(Operacion op)) = generar(op);

// ===== Operaciones =====
// Cada operación llama a una función de la clase OL (al final del archivo generado), que revisa
// los tipos de los valores en ejecución y da un mensaje claro si no se puede aplicar.
str generar(base(Primario p)) = generar(p);
str generar(bloqueExp(Bloque b))
  = "OL.bloque(() -\> {
    '  <generarRetorno(b, "Object")>
    '})";
str generar(negacion(Operacion a)) = "(!OL.cond(<generar(a)>))";
str generar(negativo(Operacion a)) = "OL.negativo(<generar(a)>)";
str generar(potencia(Operacion a, Operacion b)) = binaria("potencia", a, b);
str generar(mult(Operacion a, Operacion b)) = binaria("mult", a, b);
str generar(div(Operacion a, Operacion b)) = binaria("div", a, b);
str generar(modulo(Operacion a, Operacion b)) = binaria("modulo", a, b);
str generar(suma(Operacion a, Operacion b)) = binaria("suma", a, b);
str generar(resta(Operacion a, Operacion b)) = binaria("resta", a, b);
str generar(menor(Operacion a, Operacion b)) = binaria("menor", a, b);
str generar(mayor(Operacion a, Operacion b)) = binaria("mayor", a, b);
str generar(menorIgual(Operacion a, Operacion b)) = binaria("menorIgual", a, b);
str generar(mayorIgual(Operacion a, Operacion b)) = binaria("mayorIgual", a, b);
str generar(distinto(Operacion a, Operacion b)) = binaria("distinto", a, b);
str generar(igual(Operacion a, Operacion b)) = binaria("igual", a, b);
str generar(pertenece(Operacion a, Operacion b)) = binaria("pertenece", a, b);
str generar(conjuncion(Operacion a, Operacion b)) = "(OL.cond(<generar(a)>) && OL.cond(<generar(b)>))";
str generar(disyuncion(Operacion a, Operacion b)) = "(OL.cond(<generar(a)>) || OL.cond(<generar(b)>))";
str generar(flecha(Operacion a, Operacion b)) = "OL.sinSemantica(\"-\>\", <generar(a)>, <generar(b)>)";
str generar(flechaDoble(Operacion a, Operacion b)) = "OL.sinSemantica(\"=\>\", <generar(a)>, <generar(b)>)";

str binaria(str f, Operacion a, Operacion b) = "OL.<f>(<generar(a)>, <generar(b)>)";

// ===== Primarios: elemento base seguido de .campo y .metodo(...) =====
str generar(primario(ElementoBase e, list[Sufijo] sufijos)) {
  str rVal = generar(e);
  for (s <- sufijos) rVal = generarSufijo(rVal, s);
  return rVal;
}

// x.campo: si no es un campo de ningún objeto se toma como método sin argumentos de Java
// (por ejemplo getClass y getSimpleName en el Snippet 3).
str generarSufijo(str r, acceso(str n)) = (n in campos) ? "<r>.<id(n)>" : "<r>.<n>()";
str generarSufijo(str r, llamadaMetodo(str n, Argumentos as)) = "<r>.<id(n)>(<generar(as)>)";

str generar(argumentos(list[Expresion] lista)) = intercalate(", ", [ generar(e) | e <- lista ]);

str generar(variable(str n)) = id(n);
str generar(llamada("print", argumentos(list[Expresion] lista))) = "OL.print(<arreglo(lista)>)";
str generar(llamada("println", argumentos(list[Expresion] lista))) = "OL.println(<arreglo(lista)>)";
default str generar(llamada(str n, _)) = "OL.error(\"funcion no definida: <n>\")";
str generar(literal(Literal l)) = generar(l);
str generar(instancia(nueva(Tipo t, list[Argumentos] as, list[CuerpoInstancia] cs))) {
  str n = nombreDe(t);
  if (n notin objetos) return "OL.error(\"objeto no definido: <n>\")";
  str args = intercalate(", ", [ generar(a) | a <- as ]);
  str anonima = "<for (cuerpo(ovs) <- cs) {> {
                '  <for (ov <- ovs) {><generar(ov)>
                '  <}>
                '}<}>";
  return "new <n>(<args>)<anonima>";
}
str generar(tupla(tuplaExp(Expresion p, list[Expresion] resto))) = arreglo([p] + resto);
str generar(agrupacion(Expresion e)) = "(<generar(e)>)";

// Los argumentos de print, println y los strings se pasan como arreglo, para que una tupla
// (que en Java es un Object[]) llegue como un solo valor.
str arreglo(list[Expresion] lista) = "new Object[] {<intercalate(", ", [ generar(e) | e <- lista ])>}";

// ===== Literales =====
str generar(litEntero(int n)) = "<n>";
str generar(litBooleano(verdadero())) = "true";
str generar(litBooleano(falso())) = "false";
str generar(litChar(str c)) = "\'<escaparJava(c)>\'";
str generar(litString(list[ParteString] partes))
  = "OL.texto(new Object[] {<intercalate(", ", [ generar(p) | p <- partes ])>})";

str generar(texto(str t)) = "\"<escaparJava(t)>\"";
str generar(interpVariable(str n)) = id(n);
str generar(interpExpresion(Expresion e)) = generar(e);

str escaparJava(str s)
  = replaceAll(replaceAll(replaceAll(replaceAll(s, "\\", "\\\\"), "\"", "\\\""), "\'", "\\\'"), "\n", "\\n");

// ===== Nombres =====
// Un nombre de Objectilang que sea palabra reservada de Java se genera con _ al final.
set[str] reservadasJava = {"abstract", "assert", "boolean", "break", "byte", "case", "catch", "char",
  "class", "const", "continue", "default", "do", "double", "enum", "final", "finally", "float",
  "goto", "implements", "import", "instanceof", "int", "interface", "long", "native", "package",
  "private", "protected", "public", "return", "short", "static", "strictfp", "super", "switch",
  "synchronized", "this", "throw", "throws", "transient", "try", "void", "volatile", "while",
  "null", "record", "yield", "sealed", "permits", "OL"};

str id(str n) = (n in reservadasJava) ? n + "_" : n;

// ===== Funciones de apoyo del programa generado =====
// Van dentro de cada archivo .java, para que se pueda ejecutar solo con java Archivo.java.
str runtimeOL =
  "// Funciones de apoyo: imprimir, operadores y errores de ejecucion de Objectilang.
  'static class OL {
  '  static boolean inicioDeLinea = true;
  '
  '  static Object print(Object[] xs) {
  '    String s = texto(xs);
  '    System.out.print(s);
  '    if (!s.isEmpty()) inicioDeLinea = s.endsWith(\"\\n\");
  '    return null;
  '  }
  '  static Object println(Object[] xs) {
  '    print(xs);
  '    System.out.println();
  '    inicioDeLinea = true;
  '    return null;
  '  }
  '  static void reportar(RuntimeException e) {
  '    if (!inicioDeLinea) System.out.println();
  '    System.out.println(\"Error de ejecucion: \" + e.getMessage());
  '  }
  '
  '  // Texto de un valor: los objetos se muestran con el nombre de su objeto y las tuplas como (a, b).
  '  static String str(Object o) {
  '    if (o == null) return \"\";
  '    if (o instanceof Object[]) {
  '      Object[] t = (Object[]) o;
  '      StringBuilder sb = new StringBuilder(\"(\");
  '      for (int i = 0; i \< t.length; i++) { if (i \> 0) sb.append(\", \"); sb.append(str(t[i])); }
  '      return sb.append(\")\").toString();
  '    }
  '    if (o instanceof String || o instanceof Integer || o instanceof Boolean || o instanceof Character) return o.toString();
  '    if (o instanceof Class) return ((Class\<?\>) o).getSimpleName();
  '    Class\<?\> c = o.getClass();
  '    while (c.isAnonymousClass()) c = c.getSuperclass();
  '    return c.getSimpleName();
  '  }
  '  static String texto(Object[] partes) {
  '    StringBuilder sb = new StringBuilder();
  '    for (Object p : partes) sb.append(str(p));
  '    return sb.toString();
  '  }
  '
  '  static Object ignorar(Object o) { return o; }
  '  static Object error(String mensaje) { throw new RuntimeException(mensaje); }
  '  static Object bloque(java.util.function.Supplier\<Object\> b) { return b.get(); }
  '
  '  static boolean cond(Object o) {
  '    if (o instanceof Boolean) return (Boolean) o;
  '    throw new RuntimeException(\"se esperaba un Boolean y se obtuvo \" + str(o));
  '  }
  '  static int entero(Object o, String op) {
  '    if (o instanceof Integer) return (Integer) o;
  '    throw new RuntimeException(\"el operador \" + op + \" necesita Integer y se obtuvo \" + str(o));
  '  }
  '  static boolean esTexto(Object o) { return o instanceof String || o instanceof Character; }
  '
  '  static Object suma(Object a, Object b) {
  '    if (a instanceof Integer && b instanceof Integer) return (Integer) a + (Integer) b;
  '    if (esTexto(a) || esTexto(b)) return str(a) + str(b);
  '    throw new RuntimeException(\"el operador + no se puede aplicar a \" + str(a) + \" y \" + str(b));
  '  }
  '  static Object resta(Object a, Object b) { return entero(a, \"-\") - entero(b, \"-\"); }
  '  static Object mult(Object a, Object b) { return entero(a, \"*\") * entero(b, \"*\"); }
  '  static Object div(Object a, Object b) {
  '    int d = entero(b, \"/\");
  '    if (d == 0) throw new RuntimeException(\"division entre cero\");
  '    return entero(a, \"/\") / d;
  '  }
  '  static Object modulo(Object a, Object b) {
  '    int d = entero(b, \"%\");
  '    if (d == 0) throw new RuntimeException(\"modulo entre cero\");
  '    return entero(a, \"%\") % d;
  '  }
  '  static Object potencia(Object a, Object b) {
  '    int base = entero(a, \"**\"), exp = entero(b, \"**\"), r = 1;
  '    if (exp \< 0) throw new RuntimeException(\"exponente negativo en **\");
  '    for (int i = 0; i \< exp; i++) r *= base;
  '    return r;
  '  }
  '  static Object negativo(Object a) { return -entero(a, \"-\"); }
  '
  '  static int comparar(Object a, Object b, String op) {
  '    if (a instanceof Integer && b instanceof Integer) return Integer.compare((Integer) a, (Integer) b);
  '    if (esTexto(a) && esTexto(b)) return str(a).compareTo(str(b));
  '    throw new RuntimeException(\"el operador \" + op + \" no se puede aplicar a \" + str(a) + \" y \" + str(b));
  '  }
  '  static Object menor(Object a, Object b) { return comparar(a, b, \"\<\") \< 0; }
  '  static Object mayor(Object a, Object b) { return comparar(a, b, \"\>\") \> 0; }
  '  static Object menorIgual(Object a, Object b) { return comparar(a, b, \"\<=\") \<= 0; }
  '  static Object mayorIgual(Object a, Object b) { return comparar(a, b, \"\>=\") \>= 0; }
  '  static Object igual(Object a, Object b) { return java.util.Objects.deepEquals(a, b); }
  '  static Object distinto(Object a, Object b) { return !java.util.Objects.deepEquals(a, b); }
  '  static Object pertenece(Object a, Object b) {
  '    if (b instanceof Object[]) {
  '      for (Object x : (Object[]) b) if (java.util.Objects.deepEquals(a, x)) return true;
  '      return false;
  '    }
  '    if (b instanceof String) return ((String) b).contains(str(a));
  '    throw new RuntimeException(\"el operador in necesita una tupla o un String y se obtuvo \" + str(b));
  '  }
  '  static Object sinSemantica(String op, Object a, Object b) {
  '    throw new RuntimeException(\"operador sin semantica definida: \" + op);
  '  }
  '
  '  // for: recorre los elementos de una tupla.
  '  static java.util.List\<Object\> elementos(Object c) {
  '    if (c instanceof Object[]) return java.util.Arrays.asList((Object[]) c);
  '    throw new RuntimeException(\"for necesita una tupla y se obtuvo \" + str(c));
  '  }
  '  static Object parte(Object e, int i) {
  '    if (e instanceof Object[] && i \< ((Object[]) e).length) return ((Object[]) e)[i];
  '    throw new RuntimeException(\"no se puede tomar la parte \" + (i + 1) + \" de \" + str(e));
  '  }
  '  static Object paraCada(Object c, java.util.function.Function\<Object, Object\> cuerpo) {
  '    for (Object e : elementos(c)) cuerpo.apply(e);
  '    return null;
  '  }
  '}";
