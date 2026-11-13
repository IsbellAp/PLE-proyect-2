// errores: 0
// Tipos basicos: anotaciones de Integer, Boolean, Char, String y tuplas, operadores, if y for.
// Salida esperada (Generador):
//   ana: 6 / bob: 4 / 10 / 20 / 30 / 5 / -5 / true / true / x / n vale 5 y el doble 10 / letra x / n vale 5 y el doble 105 / true / true / 5 / 4
method main {
  val n: Integer = 1 + 2 * 3 - 4 / 2 % 3 ** 2
  val neg1: Integer = -n
  val b: Boolean = n > 2 and neg (n = 3) or n <> 4
  val menor: Boolean = 'a' < 'b'
  val c: Char = 'x'
  val s: String = "n vale $n y el doble ${n * 2}"
  val s2: String = "letra " + c
  val s3: String = s + n
  val t: (Integer, String) = (1, "uno")
  val tt: ((String, Integer), (String, Integer)) = (("ana", 5), ("bob", 3))
  val esta: Boolean = 1 in t
  val sub: Boolean = "an" in "ana"
  val r: Integer = if b then n else 0
  val bloque: Integer = { val x: Integer = 2
                          x * x }
  for ((nombre, nota) <- tt) println("$nombre: ${nota + 1}")
  for (x <- (1, 2, 3)) println(x * 10)
  println(n)
  println(neg1)
  println(b)
  println(menor)
  println(c)
  println(s)
  println(s2)
  println(s3)
  println(esta)
  println(sub)
  println(r)
  println(bloque)
}
