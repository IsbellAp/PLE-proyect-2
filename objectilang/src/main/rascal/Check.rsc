module Check

// Chequeador de tipos de Objectilang con TypePal (puntos 3, 5 y 6 del enunciado).
// Sigue la sección 9 del tutorial: el módulo extiende TypePal, define sus IdRole y AType, y tiene
// una función collect por construcción del lenguaje que usa define, use, fact, calculate y require.
//
// Qué revisa:
//   - Correspondencia de tipos (punto 5): literales, operadores, if, for (sobre tuplas), tuplas, declaraciones con
//     tipo, argumentos de new y de los métodos, valor de retorno de los métodos y de los override,
//     y subtipos con herencia y varianza de los genéricos (+A covariante, -A contravariante).
//   - Regla de existencia (punto 6): todo lo que usa la definición de un objeto existe: el padre de
//     extends, los tipos de los campos y de los métodos, los parámetros genéricos, el objeto de
//     Objeto.metodo, el método que se sobrescribe con override, y los campos y métodos que se usan
//     con x.campo y x.metodo(...). También revisa duplicados y herencia cíclica.
//
// Uso desde la terminal de Rascal (en la carpeta objectilang):
//   import Check;
//   errores(|project://objectilang/instance/enunciado1.ol|);   errores de un archivo
//   main();                                                     pruebas de tipos de instance/

import IO;
import List;
import Set;
import Map;
import String;
import Message;
import ParseTree;

extend analysis::typepal::TypePal;

import Syntax;
import Parser;

// ===== Tipos en el idioma de TypePal =====
data AType
  = intType()
  | boolType()
  | strType()
  | charType()
  | objType(str nombre, list[AType] args)   // Dog, List[Dog]
  | tupleType(list[AType] elems)            // (Integer, String)
  | genType(str nombre)                     // parámetro genérico A dentro de su objeto
  | anyType()                               // desconocido (print, getClass): compatible con todo
  ;

// Roles de los nombres que se registran con define
data IdRole
  = objectId()
  | variableId()
  | paramId()
  ;

str prettyAType(intType())  = "Integer";
str prettyAType(boolType()) = "Boolean";
str prettyAType(strType())  = "String";
str prettyAType(charType()) = "Char";
str prettyAType(objType(str n, [])) = n;
str prettyAType(objType(str n, list[AType] as)) = "<n>[<intercalate(", ", [prettyAType(a) | a <- as])>]";
str prettyAType(tupleType(list[AType] es)) = "(<intercalate(", ", [prettyAType(e) | e <- es])>)";
str prettyAType(genType(str n)) = n;
str prettyAType(anyType()) = "desconocido";

// ===== Tabla de objetos y métodos =====
// Se arma antes de recolectar (como las tablas del Listing 5 del tutorial). Guarda lo que declara
// cada objeto para poder revisar los usos aunque estén antes de la definición en el archivo.
data Obj = obj(list[str] gens, list[str] varianzas, lrel[str nombre, Tipo tipo] campos, list[Tipo] padre);
data Met = met(lrel[str nombre, Tipo tipo] params, Tipo ret);

map[str, Obj] objetos = ();
map[str, map[str, Met]] metodos = ();
set[str] funciones = {"print", "println"};          // funciones predefinidas
set[str] miembrosJava = {"getClass", "getSimpleName"}; // se generan como métodos de Java

// Contexto del método que se está revisando (para los campos y genéricos del objeto)
str ctxObjeto = "";
map[str, AType] ctxSub = ();
set[str] ctxGens = {};
set[str] ctxOcultos = {};   // parámetros y variables locales que tapan un campo con el mismo nombre
set[loc] repetidos = {};    // definiciones de objetos repetidas (no se registran con define)

void construirTabla(start[Programa] pt) {
  objetos = ();
  metodos = ();
  for (/DefinicionObjeto d := pt, (DefinicionObjeto)`object <Id n> <DefinicionGenerico? gs> <ConstructorParametros? cps> <Herencia? hs>` := d) {
    list[str] gens = [];
    list[str] vars = [];
    for (DefinicionGenerico g <- gs, /ParametroGenerico p := g, (ParametroGenerico)`<Varianza? v> <Id x>` := p) {
      gens += ["<x>"];
      vars += ["<v>"];
    }
    lrel[str, Tipo] campos = [ <"<x>", t> | ConstructorParametros cp <- cps, /ParametroConstructor pc := cp,
                                 (ParametroConstructor)`val <Id x> : <Tipo t>` := pc ];
    list[Tipo] padre = [ t | Herencia h <- hs, (Herencia)`extends <Tipo t>` := h ];
    if ("<n>" notin objetos) objetos["<n>"] = obj(gens, vars, campos, padre);
  }
  for (/DefinicionObjetoMetodo d := pt,
       (DefinicionObjetoMetodo)`<Id ob> . <Id m> = method ( <Parametros ps> ) : <Tipo r> <Bloque? _>` := d) {
    map[str, Met] ms = ("<ob>" in metodos) ? metodos["<ob>"] : ();
    if ("<m>" notin ms) ms["<m>"] = met(paramsDe(ps), r);
    metodos["<ob>"] = ms;
  }
}

lrel[str, Tipo] paramsDe(Parametros ps) = [ <"<x>", t> | /Parametro p := ps, (Parametro)`<Id x> : <Tipo t>` := p ];
list[Expresion] argsDe(Argumentos a) = [ e | (Argumentos)`( <{Expresion ","}* es> )` := a, Expresion e <- es ];
list[Sentencia] sentenciasDe(Bloque b) { list[Sentencia] r = []; top-down-break visit (b.args[2]) { case Sentencia s: r += [s]; } return r; }

// ===== De la anotación de tipo al AType =====
// gens son los parámetros genéricos visibles (los del objeto donde se escribe el tipo).
AType aTipo(Tipo t, set[str] gens) {
  switch (t) {
    case (Tipo)`String`:  return strType();
    case (Tipo)`Integer`: return intType();
    case (Tipo)`Boolean`: return boolType();
    case (Tipo)`Char`:    return charType();
    case (Tipo)`<Id n>`:
      return "<n>" in gens ? genType("<n>") : ("<n>" in objetos ? objType("<n>", []) : anyType());
    case (Tipo)`<Id n> [ <{Tipo ","}+ as> ]`:
      return "<n>" in objetos ? objType("<n>", [ aTipo(a, gens) | a <- as ]) : anyType();
    case (Tipo)`( <Tipo p> , <{Tipo ","}+ rs> )`:
      return tupleType([aTipo(p, gens)] + [ aTipo(x, gens) | x <- rs ]);
  }
  return anyType();
}

// Regla de existencia para un tipo escrito en el programa: cada nombre debe ser un objeto
// definido o un parámetro genérico visible, con el número correcto de argumentos de tipo.
void revisarTipo(Tipo t, set[str] gens, Collector c, bool exigirArgs) {
  switch (t) {
    case (Tipo)`<Id n>`: {
      if ("<n>" in gens) return;
      c.use(n, {objectId()});
      if ("<n>" in objetos && exigirArgs && size(objetos["<n>"].gens) > 0)
        c.report(error(t, "El tipo %v necesita %v argumento(s) de tipo", "<n>", size(objetos["<n>"].gens)));
    }
    case (Tipo)`<Id n> [ <{Tipo ","}+ as> ]`: {
      if ("<n>" in gens) {
        c.report(error(t, "El parámetro genérico %v no recibe argumentos de tipo", "<n>"));
        return;
      }
      c.use(n, {objectId()});
      list[Tipo] lista = [ a | a <- as ];
      if ("<n>" in objetos && size(lista) != size(objetos["<n>"].gens))
        c.report(error(t, "El tipo %v espera %v argumento(s) de tipo y recibió %v", "<n>", size(objetos["<n>"].gens), size(lista)));
      for (a <- lista) revisarTipo(a, gens, c, true);
    }
    case (Tipo)`( <Tipo p> , <{Tipo ","}+ rs> )`: {
      revisarTipo(p, gens, c, true);
      for (x <- rs) revisarTipo(x, gens, c, true);
    }
  }
}

// ===== Genéricos, herencia y subtipos =====
AType sust(AType t, map[str, AType] s) = visit (t) { case genType(str n) => s[n] when n in s };

map[str, AType] sustitucion(str n, list[AType] args) {
  list[str] gs = objetos[n].gens;
  return ( gs[i] : (i < size(args) ? args[i] : anyType()) | i <- index(gs) );
}

// Cadena de herencia de un tipo objeto: el objeto y sus ancestros, cada uno con la sustitución
// de sus genéricos. Ej.: object Caja[+A] extends Base[A]; Caja[Dog] da [<Caja,(A:Dog)>, <Base,(B:Dog)>]
lrel[str, map[str, AType]] cadena(str n, list[AType] args) {
  lrel[str, map[str, AType]] res = [];
  set[str] vistos = {};
  while (n in objetos && n notin vistos) {
    vistos += {n};
    map[str, AType] s = sustitucion(n, args);
    res += [<n, s>];
    if ([Tipo p] := objetos[n].padre, objType(str pn, list[AType] pas) := aTipo(p, toSet(objetos[n].gens))) {
      n = pn;
      args = [ sust(a, s) | a <- pas ];
    } else break;
  }
  return res;
}

bool esSubtipo(AType a, AType b) {
  if (a == b || a == anyType() || b == anyType()) return true;
  if (objType(str n, list[AType] as) := a, objType(str m, list[AType] bs) := b) {
    for (<k, s> <- cadena(n, as), k == m) {
      if (bs == []) return true;
      list[str] gs = objetos[m].gens;
      for (i <- index(gs), i < size(bs)) {
        AType x = s[gs[i]] ? anyType();
        str v = objetos[m].varianzas[i];
        if (v == "+" && !esSubtipo(x, bs[i])) return false;
        if (v == "-" && !esSubtipo(bs[i], x)) return false;
        if (v == "" && !(esSubtipo(x, bs[i]) && esSubtipo(bs[i], x))) return false;
      }
      return true;
    }
    return false;
  }
  if (tupleType(list[AType] xs) := a, tupleType(list[AType] ys) := b)
    return size(xs) == size(ys) && all(i <- index(xs), esSubtipo(xs[i], ys[i]));
  return false;
}

// Tipo común de dos tipos (para las ramas del if y los elementos de un for). anyType si no hay.
AType comun(AType a, AType b) {
  if (esSubtipo(a, b)) return b;
  if (esSubtipo(b, a)) return a;
  if (objType(str n, list[AType] as) := a)
    for (<k, s> <- cadena(n, as)) {
      AType anc = objType(k, [ s[g] | g <- objetos[k].gens ]);
      if (esSubtipo(b, anc)) return anc;
    }
  return anyType();
}

bool sonComparables(AType a, AType b) = esSubtipo(a, b) || esSubtipo(b, a) || comun(a, b) != anyType();

// Busca un campo o un método en un tipo objeto, subiendo por la herencia.
tuple[bool, AType] buscarCampo(objType(str n, list[AType] as), str x) {
  for (<k, s> <- cadena(n, as), <x, Tipo t> <- objetos[k].campos)
    return <true, sust(aTipo(t, toSet(objetos[k].gens)), s)>;
  return <false, anyType()>;
}
default tuple[bool, AType] buscarCampo(AType _, str _) = <false, anyType()>;

tuple[bool, list[AType], AType] buscarMetodo(objType(str n, list[AType] as), str x) {
  for (<k, s> <- cadena(n, as), k in metodos, x in metodos[k]) {
    set[str] gs = toSet(objetos[k].gens);
    Met m = metodos[k][x];
    return <true, [ sust(aTipo(t, gs), s) | <_, t> <- m.params ], sust(aTipo(m.ret, gs), s)>;
  }
  return <false, [], anyType()>;
}
default tuple[bool, list[AType], AType] buscarMetodo(AType _, str _) = <false, [], anyType()>;

// ===== Programa y definiciones =====

void collect(current: (Programa) `<Definicion* ds> <Metodo m>`, Collector c) {
  // Nombres de objetos, campos, genéricos y métodos duplicados
  map[str, int] vistos = ();
  for (/DefinicionObjeto d := ds, (DefinicionObjeto)`object <Id n> <DefinicionGenerico? _> <ConstructorParametros? _> <Herencia? _>` := d) {
    if ("<n>" in vistos) { c.report(error(n, "El objeto %v ya está definido", "<n>")); repetidos += {n.src}; }
    vistos["<n>"] = 1;
  }
  set[str] metodosVistos = {};
  for (/DefinicionObjetoMetodo d := ds, (DefinicionObjetoMetodo)`<Id ob> . <Id x> = method ( <Parametros _> ) : <Tipo _> <Bloque? _>` := d) {
    if ("<ob>.<x>" in metodosVistos) c.report(error(x, "El método %v.%v ya está definido", "<ob>", "<x>"));
    metodosVistos += {"<ob>.<x>"};
  }
  collect(ds, m, c);
}

// object Nombre[+A, ...](val campo: T, ...) extends Padre
void collect(current: (DefinicionObjeto) `object <Id name> <DefinicionGenerico? gs> <ConstructorParametros? cps> <Herencia? hs>`, Collector c) {
  str n = "<name>";
  if (name.src notin repetidos)
    c.define(n, objectId(), name, defType(objType(n, [ genType(g) | g <- objetos[n].gens ])));
  set[str] gens = toSet(objetos[n].gens);

  // Genéricos sin repetir
  set[str] vistos = {};
  for (DefinicionGenerico g <- gs, /ParametroGenerico p := g, (ParametroGenerico)`<Varianza? _> <Id x>` := p) {
    if ("<x>" in vistos) c.report(error(x, "El parámetro genérico %v está repetido en %v", "<x>", n));
    if ("<x>" in objetos) c.report(error(x, "El parámetro genérico %v tiene el nombre de un objeto", "<x>"));
    vistos += {"<x>"};
  }
  // Campos sin repetir y con tipos que existen
  set[str] campos = {};
  for (ConstructorParametros cp <- cps, /ParametroConstructor pc := cp, (ParametroConstructor)`val <Id x> : <Tipo t>` := pc) {
    if ("<x>" in campos) c.report(error(x, "El campo %v está repetido en %v", "<x>", n));
    campos += {"<x>"};
    // Un campo no puede repetir el nombre de un campo heredado
    for (<k, _> <- tail(cadena(n, [])), "<x>" in { y | <y, _> <- objetos[k].campos })
      c.report(error(x, "El campo %v ya existe en %v, del que hereda %v", "<x>", k, n));
    revisarTipo(t, gens, c, true);
  }
  // Herencia: el padre existe, es un objeto, y no hay ciclos
  for (Herencia h <- hs, (Herencia)`extends <Tipo t>` := h) {
    switch (t) {
      case (Tipo)`<Id p>`:                        revisarPadre(n, p, t, gens, c);
      case (Tipo)`<Id p> [ <{Tipo ","}+ _> ]`:    revisarPadre(n, p, t, gens, c);
      default: c.report(error(t, "%v solo puede heredar de un objeto, no de %v", n, "<t>"));
    }
  }
}

void revisarPadre(str n, Id p, Tipo t, set[str] gens, Collector c) {
  if ("<p>" in gens) { c.report(error(t, "%v no puede heredar de su parámetro genérico %v", n, "<p>")); return; }
  revisarTipo(t, gens, c, true);
  if ("<p>" == n) { c.report(error(t, "El objeto %v no puede heredar de sí mismo", n)); return; }
  // Ciclo: subir desde el padre hasta volver a n
  str actual = "<p>";
  set[str] vistos = {};
  while (actual in objetos && actual notin vistos) {
    vistos += {actual};
    if ([Tipo pt] := objetos[actual].padre, objType(str sig, _) := aTipo(pt, toSet(objetos[actual].gens))) {
      if (sig == n) { c.report(error(t, "Herencia cíclica: %v termina heredando de sí mismo", n)); return; }
      actual = sig;
    } else return;
  }
}

// Objeto.metodo = method(p: T, ...): R { ... }
void collect(current: (DefinicionObjetoMetodo) `<Id ob> . <Id m> = method ( <Parametros ps> ) : <Tipo r> <Bloque? cuerpo>`, Collector c) {
  str n = "<ob>";
  c.use(ob, {objectId()});
  if (n notin objetos) return;   // el objeto no existe (ya se reportó); no se revisa el resto
  set[str] gens = toSet(objetos[n].gens);
  map[str, AType] identidad = ( g : genType(g) | g <- gens );

  c.enterScope(current);
    revisarParametros(ps, gens, c);
    revisarTipo(r, gens, c, true);
    AType ret = aTipo(r, gens);
    list[AType] tiposParams = [ aTipo(t, gens) | <_, t> <- paramsDe(ps) ];

    // Si un ancestro ya tiene el método, la nueva versión debe ser compatible
    if ([Tipo pt] := objetos[n].padre) {
      AType padre = aTipo(pt, gens);
      <existe, psPadre, retPadre> = buscarMetodo(padre, "<m>");
      if (existe) revisarFirma("<m>", psPadre, retPadre, tiposParams, ret, m, c);
    }

    for (Bloque b <- cuerpo) {
      conContexto(n, identidad, gens, ps, b, c);
      c.require("retorno de <n>.<m>", b, [b], void (Solver s) {
        AType t = s.getType(b);
        if (!esSubtipo(t, ret))
          s.report(error(b, "El método %v.%v debe devolver %v pero su cuerpo devuelve %v", n, "<m>", prettyAType(ret), prettyAType(t)));
      });
    }
  c.leaveScope(current);
}

void revisarParametros(Parametros ps, set[str] gens, Collector c) {
  set[str] vistos = {};
  for (/Parametro p := ps, (Parametro)`<Id x> : <Tipo t>` := p) {
    if ("<x>" in vistos) c.report(error(x, "El parámetro %v está repetido", "<x>"));
    vistos += {"<x>"};
    revisarTipo(t, gens, c, true);
    c.define("<x>", paramId(), x, defType(aTipo(t, gens)));
  }
}

// Firma de un método que reemplaza a otro (redefinición en un hijo u override):
// mismo número de parámetros, parámetros contravariantes y retorno covariante.
void revisarFirma(str m, list[AType] psOrig, AType retOrig, list[AType] psNuevo, AType retNuevo, Tree donde, Collector c) {
  if (size(psOrig) != size(psNuevo)) {
    c.report(error(donde, "%v debe tener %v parámetro(s), como el método original", m, size(psOrig)));
    return;
  }
  for (i <- index(psOrig), !esSubtipo(psOrig[i], psNuevo[i]))
    c.report(error(donde, "El parámetro %v de %v debe aceptar %v (el original) y es %v", i + 1, m, prettyAType(psOrig[i]), prettyAType(psNuevo[i])));
  if (!esSubtipo(retNuevo, retOrig))
    c.report(error(donde, "%v debe devolver un subtipo de %v (el original) y devuelve %v", m, prettyAType(retOrig), prettyAType(retNuevo)));
}

// Recolecta el cuerpo de un método con los campos y genéricos de su objeto visibles.
void conContexto(str n, map[str, AType] sub, set[str] gens, Parametros ps, Bloque b, Collector c) {
  <o1, o2, o3, o4> = <ctxObjeto, ctxSub, ctxGens, ctxOcultos>;
  ctxObjeto = n; ctxSub = sub; ctxGens = gens;
  ctxOcultos = { x | <x, _> <- paramsDe(ps) }
             + { "<x>" | /DeclaracionVariable d := b, (DeclaracionVariable)`<Modificador _> <Id x> <AnotacionTipo? _> = <Expresion _>` := d };
  collect(b, c);
  <ctxObjeto, ctxSub, ctxGens, ctxOcultos> = <o1, o2, o3, o4>;
}

void collect(current: (Metodo) `method main <Bloque b>`, Collector c) {
  collect(b, c);
}

// ===== Bloques y sentencias =====

// El valor de un bloque es el de su última sentencia
void collect(Bloque current, Collector c) {
  list[Sentencia] ss = sentenciasDe(current);
  c.enterScope(current);
    for (s <- ss) collect(s, c);
    if (ss == []) c.fact(current, anyType());
    else igualQue(current, last(ss), c);
  c.leaveScope(current);
}

// El tipo de a es el mismo de b
void igualQue(Tree a, Tree b, Collector c) {
  c.calculate("igual", a, [b], AType (Solver s) { return s.getType(b); });
}

// val x: T = e
void collect(current: (DeclaracionVariable) `<Modificador _> <Id name> : <Tipo t> = <Expresion e>`, Collector c) {
  set[str] gens = ctxGens;
  revisarTipo(t, gens, c, true);
  AType declarado = aTipo(t, gens);
  c.define("<name>", variableId(), name, defType(declarado));
  c.fact(current, declarado);
  collect(e, c);
  c.require("tipo de <name>", current, [e], void (Solver s) {
    AType valor = s.getType(e);
    if (!esSubtipo(valor, declarado))
      s.report(error(e, "El valor es %v pero %v se declaró como %v", prettyAType(valor), "<name>", prettyAType(declarado)));
  });
}

// val x = e  (el tipo de x es el del valor)
void collect(current: (DeclaracionVariable) `<Modificador _> <Id name> = <Expresion e>`, Collector c) {
  c.define("<name>", variableId(), name, defType([e], AType (Solver s) { return s.getType(e); }));
  igualQue(current, e, c);
  collect(e, c);
}

// ===== Expresiones =====

void collect(current: (Expresion) `if <Expresion cnd> then <Expresion a>`, Collector c) {
  collect(cnd, a, c);
  requiereBooleano(cnd, "La condición del if", c);
  c.fact(current, anyType());
}

void collect(current: (Expresion) `if <Expresion cnd> then <Expresion a> else <Expresion b>`, Collector c) {
  collect(cnd, a, b, c);
  requiereBooleano(cnd, "La condición del if", c);
  c.calculate("if", current, [a, b], AType (Solver s) {
    AType ta = s.getType(a);
    AType tb = s.getType(b);
    AType t = comun(ta, tb);
    if (t == anyType() && ta != anyType() && tb != anyType())
      s.report(error(current, "Las ramas del if tienen tipos incompatibles: %v y %v", prettyAType(ta), prettyAType(tb)));
    return t;
  });
}

void requiereBooleano(Tree e, str que, Collector c) {
  c.require(que, e, [e], void (Solver s) {
    AType t = s.getType(e);
    if (!esSubtipo(t, boolType())) s.report(error(e, "%v debe ser Boolean y es %v", que, prettyAType(t)));
  });
}

// for (x <- coleccion) cuerpo   y   for ((a, b) <- coleccion) cuerpo
void collect(current: (Expresion) `for ( <VariableIteracion v> \<- <Expresion col> ) <Expresion cuerpo>`, Collector c) {
  collect(col, c);
  c.enterScope(current);
    switch (v) {
      case (VariableIteracion)`<Id x>`:
        c.define("<x>", variableId(), x, defType([col], AType (Solver s) { return elemento(s.getType(col)); }));
      case (VariableIteracion)`( <Id x> , <{Id ","}+ xs> )`: {
        list[Id] ids = [x] + [ y | y <- xs ];
        for (i <- index(ids)) {
          int k = i;
          c.define("<ids[k]>", variableId(), ids[k], defType([col], AType (Solver s) {
            if (tupleType(list[AType] es) := elemento(s.getType(col)), k < size(es)) return es[k];
            return anyType();
          }));
        }
        c.require("desestructurar", v, [col], void (Solver s) {
          AType el = elemento(s.getType(col));
          if (el != anyType() && !(tupleType(list[AType] es) := el && size(es) == size(ids)))
            s.report(error(v, "No se puede separar un %v en %v variables", prettyAType(el), size(ids)));
        });
      }
    }
    collect(cuerpo, c);
  c.leaveScope(current);
  c.require("coleccion del for", col, [col], void (Solver s) {
    AType t = s.getType(col);
    if (!(t is tupleType || t == anyType()))
      s.report(error(col, "El for recorre los elementos de una tupla, no un %v", prettyAType(t)));
  });
  c.fact(current, anyType());
}

// Tipo de los elementos que recorre un for
AType elemento(tupleType(list[AType] es)) = ( es[0] | comun(it, e) | e <- es[1..] );
default AType elemento(AType _) = anyType();

// ===== Operaciones =====

void collect(current: (Operacion) `neg <Operacion a>`, Collector c) { unaria(current, "neg", a, boolType(), c); }
void collect(current: (Operacion) `- <Operacion a>`, Collector c) { unaria(current, "-", a, intType(), c); }

void unaria(Tree current, str op, Operacion a, AType t, Collector c) {
  collect(a, c);
  c.calculate(op, current, [a], AType (Solver s) {
    AType ta = s.getType(a);
    if (!esSubtipo(ta, t)) s.report(error(current, "El operador %v necesita %v y recibió %v", op, prettyAType(t), prettyAType(ta)));
    return t;
  });
}

void collect(current: (Operacion) `<Operacion a> ** <Operacion b>`, Collector c) { binaria(current, "**", a, b, c); }
void collect(current: (Operacion) `<Operacion a> * <Operacion b>`, Collector c) { binaria(current, "*", a, b, c); }
void collect(current: (Operacion) `<Operacion a> / <Operacion b>`, Collector c) { binaria(current, "/", a, b, c); }
void collect(current: (Operacion) `<Operacion a> % <Operacion b>`, Collector c) { binaria(current, "%", a, b, c); }
void collect(current: (Operacion) `<Operacion a> + <Operacion b>`, Collector c) { binaria(current, "+", a, b, c); }
void collect(current: (Operacion) `<Operacion a> - <Operacion b>`, Collector c) { binaria(current, "-", a, b, c); }
void collect(current: (Operacion) `<Operacion a> \< <Operacion b>`, Collector c) { binaria(current, "\<", a, b, c); }
void collect(current: (Operacion) `<Operacion a> \> <Operacion b>`, Collector c) { binaria(current, "\>", a, b, c); }
void collect(current: (Operacion) `<Operacion a> \<= <Operacion b>`, Collector c) { binaria(current, "\<=", a, b, c); }
void collect(current: (Operacion) `<Operacion a> \>= <Operacion b>`, Collector c) { binaria(current, "\>=", a, b, c); }
void collect(current: (Operacion) `<Operacion a> \<\> <Operacion b>`, Collector c) { binaria(current, "\<\>", a, b, c); }
void collect(current: (Operacion) `<Operacion a> = <Operacion b>`, Collector c) { binaria(current, "=", a, b, c); }
void collect(current: (Operacion) `<Operacion a> in <Operacion b>`, Collector c) { binaria(current, "in", a, b, c); }
void collect(current: (Operacion) `<Operacion a> and <Operacion b>`, Collector c) { binaria(current, "and", a, b, c); }
void collect(current: (Operacion) `<Operacion a> or <Operacion b>`, Collector c) { binaria(current, "or", a, b, c); }
void collect(current: (Operacion) `<Operacion a> -\> <Operacion b>`, Collector c) { binaria(current, "-\>", a, b, c); }
void collect(current: (Operacion) `<Operacion a> =\> <Operacion b>`, Collector c) { binaria(current, "=\>", a, b, c); }

void binaria(Tree current, str op, Operacion a, Operacion b, Collector c) {
  collect(a, b, c);
  c.calculate(op, current, [a, b], AType (Solver s) {
    AType ta = s.getType(a);
    AType tb = s.getType(b);
    <valido, t> = tipoOperador(op, ta, tb);
    if (!valido) {
      if (op in {"-\>", "=\>"})
        s.report(error(current, "El operador %v no tiene semántica definida en Objectilang", op));
      else
        s.report(error(current, "El operador %v no se puede aplicar a %v y %v", op, prettyAType(ta), prettyAType(tb)));
    }
    return t;
  });
}

bool esNum(AType t)   = t == intType() || t == anyType();
bool esTexto(AType t) = t == strType() || t == charType();

// Reglas de tipo de los operadores binarios: <se puede aplicar, tipo del resultado>
tuple[bool, AType] tipoOperador(str op, AType a, AType b) {
  switch (op) {
    case /^(\*\*|\*|\/|%|-)$/: return <esNum(a) && esNum(b), intType()>;
    case "+":
      if (esTexto(a) || esTexto(b)) return <true, strType()>;             // concatena
      else if (a == anyType() || b == anyType()) return <true, anyType()>;
      else return <a == intType() && b == intType(), intType()>;
    case /^(\<|\>|\<=|\>=)$/:
      return <(esNum(a) && esNum(b)) || (a == charType() && b == charType()) || a == anyType() || b == anyType(), boolType()>;
    case /^(=|\<\>)$/: return <sonComparables(a, b), boolType()>;
    case "in": return <b is tupleType || b == anyType() || (b == strType() && (esTexto(a) || a == anyType())), boolType()>;
    case /^(and|or)$/: return <esSubtipo(a, boolType()) && esSubtipo(b, boolType()), boolType()>;
  }
  return <false, anyType()>;   // -> y =>
}

// ===== Primarios: elemento base seguido de .campo y .metodo(...) =====

void collect(current: (Primario) `<ElementoBase b> <Sufijo* sufs>`, Collector c) {
  list[Sufijo] ss = [ x | x <- sufs ];
  collect(b, c);
  // Sin sufijos el tipo es el del elemento base (el Primario incluye el espacio que le sigue,
  // por eso es otro árbol para TypePal)
  if (ss == []) { igualQue(current, b, c); return; }
  list[Expresion] args = [ *argsDe(a) | (Sufijo)`. <Id _> <Argumentos a>` <- ss ];
  for (e <- args) collect(e, c);
  c.calculate("acceso", current, [b] + args, AType (Solver s) {
    AType t = s.getType(b);
    for (suf <- ss) t = tipoSufijo(t, suf, s);
    return t;
  });
}

AType tipoSufijo(AType t, Sufijo suf, Solver s) {
  if (t == anyType()) return anyType();
  switch (suf) {
    case (Sufijo)`. <Id x>`: {
      <hay, tc> = buscarCampo(t, "<x>");
      if (hay) return tc;
      <hayM, ps, ret> = buscarMetodo(t, "<x>");
      if (hayM) {
        if (ps != []) s.report(error(suf, "El método %v necesita %v argumento(s)", "<x>", size(ps)));
        return ret;
      }
      if ("<x>" in miembrosJava && t is objType) return anyType();
      s.report(error(x, "%v no tiene un campo o método llamado %v", prettyAType(t), "<x>"));
      return anyType();
    }
    case (Sufijo)`. <Id x> <Argumentos a>`: {
      <hayM, ps, ret> = buscarMetodo(t, "<x>");
      if (!hayM) {
        if ("<x>" in miembrosJava && t is objType) return anyType();
        s.report(error(x, "%v no tiene un método llamado %v", prettyAType(t), "<x>"));
        return anyType();
      }
      revisarArgumentos("<x>", ps, argsDe(a), suf, s);
      return ret;
    }
  }
  return anyType();
}

void revisarArgumentos(str que, list[AType] ps, list[Expresion] args, Tree donde, Solver s) {
  if (size(ps) != size(args)) {
    s.report(error(donde, "%v(...) recibe %v argumento(s) y se le pasaron %v", que, size(ps), size(args)));
    return;
  }
  for (i <- index(ps)) {
    AType ta = s.getType(args[i]);
    if (!esSubtipo(ta, ps[i]))
      s.report(error(args[i], "%v(...): el argumento %v debe ser %v y es %v", que, i + 1, prettyAType(ps[i]), prettyAType(ta)));
  }
}

// ===== Elementos base =====

// Uso de una variable, un parámetro o un campo del objeto del método actual
void collect(current: (ElementoBase) `<Id name>`, Collector c) {
  str x = "<name>";
  if (ctxObjeto != "" && x notin ctxOcultos) {
    <hay, t> = buscarCampo(objType(ctxObjeto, [ ctxSub[g] ? genType(g) | g <- objetos[ctxObjeto].gens ]), x);
    if (hay) { c.fact(current, t); return; }
  }
  c.use(name, {variableId(), paramId()});
}

// print(...) y println(...) son las únicas funciones; el resto de llamadas no existe
void collect(current: (ElementoBase) `<Id name> <Argumentos a>`, Collector c) {
  for (e <- argsDe(a)) collect(e, c);
  if ("<name>" notin funciones)
    c.report(error(name, "La función %v no existe (solo hay print y println)", "<name>"));
  c.fact(current, anyType());
}

void collect(current: (ElementoBase) `( <Expresion e> )`, Collector c) {
  collect(e, c);
  igualQue(current, e, c);
}

void collect(current: (Tupla) `( <Expresion p> , <{Expresion ","}+ rs> )`, Collector c) {
  list[Expresion] es = [p] + [ x | x <- rs ];
  for (e <- es) collect(e, c);
  c.calculate("tupla", current, es, AType (Solver s) { return tupleType([ s.getType(e) | e <- es ]); });
}

// ===== Literales =====
void collect(current: (Literal) `<Entero _>`, Collector c)          { c.fact(current, intType()); }
void collect(current: (Literal) `<LiteralBooleano _>`, Collector c) { c.fact(current, boolType()); }
void collect(current: (Literal) `<LiteralChar _>`, Collector c)     { c.fact(current, charType()); }

// En un String se revisan las partes interpoladas: $nombre debe existir y ${e} se revisa completa.
void collect(current: (Literal) `<LiteralString ls>`, Collector c) {
  c.fact(current, strType());
  top-down-break visit (ls) {
    case appl(prod(label("interpVariable", _), _, _), [_, Tree name]): usarNombre(name, c);
    case appl(prod(label("interpExpresion", _), _, _), [_, _, Tree e, _, _]): collect(e, c);
  }
}

void usarNombre(Tree name, Collector c) {
  str x = "<name>";
  if (ctxObjeto != "" && x notin ctxOcultos) {
    <hay, _> = buscarCampo(objType(ctxObjeto, []), x);
    if (hay) return;
  }
  c.use(name, {variableId(), paramId()});
}

// ===== new Tipo(args) { override ... } =====
void collect(current: (NuevaInstancia) `new <Tipo t> <Argumentos? as> <CuerpoInstancia? cu>`, Collector c) {
  list[Expresion] args = [ *argsDe(a) | a <- as ];
  bool conArgs = [_] := [ a | a <- as ];
  for (e <- args) collect(e, c);

  str n = "";
  list[AType] targs = [];
  bool explicitos = false;
  switch (t) {
    case (Tipo)`<Id x>`: n = "<x>";
    case (Tipo)`<Id x> [ <{Tipo ","}+ _> ]`: { n = "<x>"; explicitos = true; }
  }
  if (n == "" || n in ctxGens) {
    c.report(error(t, "Con new solo se crean objetos, no %v", "<t>"));
    c.fact(current, anyType());
    return;
  }
  revisarTipo(t, ctxGens, c, false);
  if (n notin objetos) { c.fact(current, anyType()); return; }
  if (objType(_, list[AType] xs) := aTipo(t, ctxGens)) targs = xs;

  Obj od = objetos[n];
  set[str] gs = toSet(od.gens);
  list[AType] campos = [ aTipo(ct, gs) | <_, ct> <- od.campos ];
  if (!conArgs && campos != [])
    c.report(error(current, "new %v necesita %v argumento(s): %v", n, size(campos), intercalate(", ", [ x | <x, _> <- od.campos ])));

  // Override de métodos dentro de new
  map[str, AType] sub = sustitucion(n, explicitos ? targs : [ genType(g) | g <- od.gens ]);
  AType tipoObj = objType(n, explicitos ? targs : [ genType(g) | g <- od.gens ]);
  for (CuerpoInstancia ci <- cu, /OverrideMetodo ov := ci) revisarOverride(ov, n, tipoObj, sub, c);

  c.calculate("new", current, args, AType (Solver s) {
    list[AType] tas = [ s.getType(e) | e <- args ];
    list[AType] actuales = targs;
    if (!explicitos) {
      // Se infieren los argumentos de tipo a partir de los argumentos del constructor
      map[str, AType] b = ();
      for (i <- index(campos), i < size(tas)) b = unificar(campos[i], tas[i], b);
      actuales = [ b[g] ? anyType() | g <- od.gens ];
    }
    map[str, AType] sb = sustitucion(n, actuales);
    if (conArgs) revisarArgumentos("new <n>", [ sust(x, sb) | x <- campos ], args, current, s);
    return objType(n, actuales);
  });
}

map[str, AType] unificar(genType(str g), AType a, map[str, AType] b) = (g in b) ? b + (g : comun(b[g], a)) : b + (g : a);
map[str, AType] unificar(objType(str n, list[AType] ps), objType(n, list[AType] as), map[str, AType] b)
  = ( b | unificar(ps[i], as[i], it) | i <- index(ps), i < size(as) );
map[str, AType] unificar(tupleType(list[AType] ps), tupleType(list[AType] as), map[str, AType] b)
  = ( b | unificar(ps[i], as[i], it) | i <- index(ps), i < size(as) );
default map[str, AType] unificar(AType _, AType _, map[str, AType] b) = b;

// override m(p: T, ...): R = { ... }  dentro de new Objeto { ... }
void revisarOverride(OverrideMetodo ov, str n, AType tipoObj, map[str, AType] sub, Collector c) {
  if ((OverrideMetodo)`override <Id m> ( <Parametros ps> ) : <Tipo r> = <Bloque b>` := ov) {
    c.enterScope(ov);
      revisarParametros(ps, ctxGens, c);
      revisarTipo(r, ctxGens, c, true);
      AType ret = aTipo(r, ctxGens);
      <existe, psOrig, retOrig> = buscarMetodo(tipoObj, "<m>");
      if (!existe)
        c.report(error(m, "%v no tiene un método %v para sobrescribir", n, "<m>"));
      else
        revisarFirma("<m>", psOrig, retOrig, [ aTipo(t, ctxGens) | <_, t> <- paramsDe(ps) ], ret, m, c);
      conContexto(n, sub, ctxGens, ps, b, c);
      c.require("retorno de override <m>", b, [b], void (Solver s) {
        AType t = s.getType(b);
        if (!esSubtipo(t, ret))
          s.report(error(b, "El override %v debe devolver %v pero su cuerpo devuelve %v", "<m>", prettyAType(ret), prettyAType(t)));
      });
    c.leaveScope(ov);
  }
}

// ===== Configuración y punto de entrada =====

// Una variable solo se puede usar después de su declaración (los objetos y parámetros, en cualquier parte).
Accept antesDeUso(loc def, Use u, Solver s) {
  Define d = s.getDefine(def);
  if (d.idRole == variableId() && u.occ.top == def.top && u.occ.offset < def.offset) return ignoreContinue();
  return acceptBinding();
}

TypePalConfig configuracion() = tconfig(isAcceptableSimple = antesDeUso);

// Como TModelFromTree del Listing 16 del tutorial, pero arma antes la tabla de objetos.
TModel modeloDeArbol(start[Programa] pt) {
  construirTabla(pt);
  <ctxObjeto, ctxSub, ctxGens, ctxOcultos, repetidos> = <"", (), {}, {}, {}>;
  return collectAndSolve(pt, config = configuracion());
}

TModel revisarArchivo(loc archivo) = modeloDeArbol(parsePrograma(archivo));

list[Message] erroresDe(loc archivo) = sort([ m | m <- revisarArchivo(archivo).messages, m is error ],
                                            bool (Message a, Message b) { return a.at.offset < b.at.offset; });

// Imprime los errores de un archivo
void errores(loc archivo) {
  list[Message] errs = erroresDe(archivo);
  if (errs == [])
    println("<archivo.file>: sin errores");
  else {
    println("<archivo.file>: <size(errs)> error(es):");
    for (e <- errs) println("    linea <e.at.begin.line>: <e.msg>");
  }
}

// ===== Pruebas de tipos =====
// Cada archivo tipos_*.ol y t_*.ol trae una línea "// errores: N" con el número de errores esperado
// (si no la trae, se esperan 0). Además se revisan los ejemplos ejecutables y los del enunciado.
loc carpeta = |project://objectilang/instance|;

int main() {
  list[str] archivos = sort([ f | f <- listEntries(carpeta), endsWith(f, ".ol"),
                                  startsWith(f, "tipos_") || startsWith(f, "t_") || startsWith(f, "ejec") || startsWith(f, "errorEjec") || startsWith(f, "enunciado") || f == "cadenas.ol" ]);
  int fallidas = 0;
  for (f <- archivos) {
    loc l = carpeta + f;
    int esperado = 0;
    for (linea <- readFileLines(l), /^\/\/ errores: <n:[0-9]+>/ := linea) esperado = toInt(n);
    list[Message] errs = erroresDe(l);
    bool pasa = size(errs) == esperado;
    if (!pasa) fallidas += 1;
    println("<pasa ? "PASA " : "FALLA"> <f>: <size(errs)> error(es), se esperaban <esperado>");
    for (e <- errs) println("        linea <e.at.begin.line>: <e.msg>");
  }
  println("<size(archivos) - fallidas> de <size(archivos)> pruebas de tipos pasan");
  return fallidas;
}
