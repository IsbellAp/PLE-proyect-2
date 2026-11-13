// errores: 12
// Operadores, if y for con tipos que no corresponden (un error por linea).
method main {
  val a = 1 + true
  val b = "a" - 1
  val c = neg 5
  val d = -true
  val e = 1 and true
  val f = if 5 then 1 else 2
  val g = 1 < "a"
  val h = 1 = "a"
  val i = if true then 1 else "a"
  val j = 2 -> 3
  val k = 1 in 5
  for (x <- 5) println(x)
  println(a, b, c, d, e, f, g, h, i, j, k)
}
