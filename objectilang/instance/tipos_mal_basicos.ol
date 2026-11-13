// errores: 6
// Anotaciones de tipos basicos que no corresponden con el valor (un error por linea).
method main {
  val x: Integer = true
  val s: String = 5
  val c: Char = "a"
  val b: Boolean = 'x'
  val t: (Integer, String) = (1, 2)
  val u: (Integer, String) = (1, "a", true)
  println(x, s, c, b, t, u)
}
