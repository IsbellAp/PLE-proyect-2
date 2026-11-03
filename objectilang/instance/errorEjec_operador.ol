// Error de ejecucion: operadores sin semantica definida (->, => e in).
// Salida esperada: mensaje claro "operador sin semantica definida: ->".
method main {
  val a = 1
  val b = 2
  println(a -> b)
}
