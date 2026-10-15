module AST

// ===== Programa y definiciones =====
data Programa = programa(list[Definicion] definiciones, Metodo main);

data Definicion
  = defObjeto(DefinicionObjeto objeto)
  | defMetodo(DefinicionObjetoMetodo metodo)
  ;

data Metodo = metodoMain(Bloque cuerpo);

data DefinicionObjeto
  = objeto(str nombre, list[DefinicionGenerico] generico,
           list[ConstructorParametros] constructor, list[Herencia] herencia);

data Herencia = herencia(str padre);
data DefinicionGenerico = generico(list[ParametroGenerico] parametros);
data ParametroGenerico = parametroGenerico(list[Varianza] varianza, str nombre);
data Varianza = covariante() | contravariante();

data ConstructorParametros = constructor(list[ParametroConstructor] parametros);
data ParametroConstructor = parametro(str nombre, Tipo tipo);

data DefinicionObjetoMetodo
  = metodo(str objeto, str nombre, Parametros parametros, Tipo retorno, Bloque cuerpo);

data Parametros = parametros(list[Parametro] lista);
data Parametro = parametroMetodo(str nombre, Tipo tipo);

// ===== Tipos =====
data Tipo
  = tipoString()
  | tipoInteger()
  | tipoBoolean()
  | tipoNombre(str nombre)
  | tipoGenerico(str nombre, list[Tipo] argumentos)
  ;

// ===== Bloques y sentencias =====
data Bloque = bloque(list[Sentencia] sentencias);

data Sentencia
  = sentDeclaracion(DeclaracionVariable declaracion)
  | sentExpresion(Expresion expresion)
  ;

data DeclaracionVariable
  = declaracion(Modificador modificador, str nombre, list[AnotacionTipo] tipo, Expresion valor);

data Modificador = inmutable() | mutable();
data AnotacionTipo = anotacion(Tipo tipo);

data VariableIteracion
  = varSimple(str nombre)
  | varTupla(str primero, list[str] resto)
  ;

// ===== Expresiones =====
data Expresion
  = base(Primario primario)
  | bloqueExp(Bloque bloque)
  | negacion(Expresion e)
  | negativo(Expresion e)
  | potencia(Expresion izq, Expresion der)
  | mult(Expresion izq, Expresion der)
  | div(Expresion izq, Expresion der)
  | modulo(Expresion izq, Expresion der)
  | suma(Expresion izq, Expresion der)
  | resta(Expresion izq, Expresion der)
  | menor(Expresion izq, Expresion der)
  | mayor(Expresion izq, Expresion der)
  | menorIgual(Expresion izq, Expresion der)
  | mayorIgual(Expresion izq, Expresion der)
  | distinto(Expresion izq, Expresion der)
  | igual(Expresion izq, Expresion der)
  | pertenece(Expresion izq, Expresion der)
  | conjuncion(Expresion izq, Expresion der)
  | disyuncion(Expresion izq, Expresion der)
  | flecha(Expresion izq, Expresion der)
  | flechaDoble(Expresion izq, Expresion der)
  | ifSinElse(Expresion condicion, Expresion entonces)
  | ifConElse(Expresion condicion, Expresion entonces, Expresion sino)
  | ciclo(VariableIteracion variable, Expresion coleccion, Expresion cuerpo)
  ;

data Primario = primario(ElementoBase elemento, list[Sufijo] sufijos);

data ElementoBase
  = variable(str nombre)
  | llamada(str nombre, Argumentos argumentos)
  | literal(Literal literal)
  | instancia(NuevaInstancia instancia)
  | tupla(Tupla tupla)
  | agrupacion(Expresion expresion)
  ;

data Sufijo
  = acceso(str nombre)
  | llamadaMetodo(str nombre, Argumentos argumentos)
  ;

data Argumentos = argumentos(list[Expresion] lista);
data Tupla = tuplaExp(Expresion primero, list[Expresion] resto);

data NuevaInstancia
  = nueva(Tipo tipo, list[Argumentos] argumentos, list[CuerpoInstancia] cuerpo);

data CuerpoInstancia = cuerpo(list[OverrideMetodo] metodos);
data OverrideMetodo
  = sobrescribir(str nombre, Parametros parametros, Tipo retorno, Bloque cuerpo);

// ===== Literales =====
data Literal
  = litEntero(int numero)
  | litBooleano(LiteralBooleano booleano)
  | litString(str texto)
  ;

data LiteralBooleano = verdadero() | falso();
