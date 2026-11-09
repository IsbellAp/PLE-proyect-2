// Prueba de resaltado: un elemento de cada clase del lenguaje
object Animal
object Lista[+A, -B](val item: A) extends Animal
Animal.hablar = method(n: Integer, c: Char): String { "Hola $n y ${n + 1}" }

method main {
  var x: Boolean = true and false or neg true
  val t: (Integer, String) = (1 * 2 / 3 % 4 ** 5 - 6, "s")
  val c = if x then 'a' else 'b'
  for ((k, v) <- t) println(k <= v, k >= v, k < v, k > v, k <> v, k = v, k in v, k -> v, k => v)
  val e = new Animal { override hablar(n: Integer, c: Char): String = { -n } }
  e.hablar(1, 'z').length
}
