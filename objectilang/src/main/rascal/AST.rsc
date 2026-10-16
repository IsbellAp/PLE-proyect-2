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
  = ifSinElse(Expresion condicion, Expresion entonces)
  | ifConElse(Expresion condicion, Expresion entonces, Expresion sino)
  | ciclo(VariableIteracion variable, Expresion coleccion, Expresion cuerpo)
  | operacion(Operacion operacion)
  ;

data Operacion
  = base(Primario primario)
  | bloqueExp(Bloque bloque)
  | negacion(Operacion e)
  | negativo(Operacion e)
  | potencia(Operacion izq, Operacion der)
  | mult(Operacion izq, Operacion der)
  | div(Operacion izq, Operacion der)
  | modulo(Operacion izq, Operacion der)
  | suma(Operacion izq, Operacion der)
  | resta(Operacion izq, Operacion der)
  | menor(Operacion izq, Operacion der)
  | mayor(Operacion izq, Operacion der)
  | menorIgual(Operacion izq, Operacion der)
  | mayorIgual(Operacion izq, Operacion der)
  | distinto(Operacion izq, Operacion der)
  | igual(Operacion izq, Operacion der)
  | pertenece(Operacion izq, Operacion der)
  | conjuncion(Operacion izq, Operacion der)
  | disyuncion(Operacion izq, Operacion der)
  | flecha(Operacion izq, Operacion der)
  | flechaDoble(Operacion izq, Operacion der)
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
